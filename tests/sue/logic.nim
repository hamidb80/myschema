import std/[unittest, sequtils, tables, sets, os]
import src/sue/logic {.all.}
import src/sue/[model, lexer, parser]
import src/common/[coordination, graph, collections]

import print

# utility
func vis(s: string): string =
  "./samples/sue/visual_tests" / s

template findInstanceOf(moduleName, mdl): untyped =
  findOne[Instance](mdl.schema.instances, it.module.name == moduleName)

template findBuffer(mdl): untyped =
  findInstanceOf "buffer0", mdl


suite "basics":
  test "dropIndexes":
    check:
      dropIndexes("id[a:b]") == "id"
      dropIndexes("id[a]") == "id"
      dropIndexes("id") == "id"

  test "seqids":
    template c(s): untyped =
      cast[seq[string]](s)

    check sepids("out").toseq.c == @["out"]
    check sepids("out[1]").toseq.c == @["out"]
    check sepids("out[2:0]").toseq.c == @["out"]
    check sepids("out[2:0],in[2],io").toseq.c == @["out", "in", "io"]

  test "wires":
    let
      ps = [
        (0, 0),
        (1, 0),
        (1, 1),
        (1, 2),
        (1, 3),
        (2, 1),
        (3, 1)]

      ws = [
        ps[0] .. ps[1],
        ps[1] .. ps[2],
        ps[2] .. ps[3],
        ps[3] .. ps[4],
        ps[2] .. ps[5],
        ps[5] .. ps[6]]

    var net: Graph[Point]
    for w in ws:
      net.incl w

    let pws = toseq wires net
    for w in pws:
      check (w in ws) or (w.reversed in ws)

    check pws.len == ws.len

  test "location & geometry":
    let
      proj = parseSueProject @[
        vis "location.sue",
        vis "square.sue",
        vis "kite.sue"]

      m = proj.modules["location"]

    var tt: Table[string, HashSet[Point]]
    for loc, ps in m.schema.portsPlot:
      for p in ps:
        let n = p.parent.name

        withValue tt, n, wrapper:
          wrapper[].incl p.location
        do:
          tt[n] = toHashSet @[p.location]

    check:
      tt["nothing"] == %[(-210, -110), (-140, -50), (-110, -110)]
      tt["rotated"] == %[(40, 190), (40, 90), (100, 120)]
      tt["flipped"] == %[(-220, 130), (-150, 70), (-120, 130)]
      tt["rotated_and_flipped"] == %[(150, -180), (150, -80), (210, -110)]
      tt["raw"] == %[(-240, 500), (-210, 520), (-210, 430), (-190, 480)]
      tt["r90"] == %[(-150, 490), (-130, 460), (-110, 510), (-60, 490)]
      tt["r180"] == %[(-10, 470), (10, 430), (10, 520), (40, 450)]
      tt["r270"] == %[(130, 450), (180, 430), (200, 480), (220, 450)]
      tt["fx"] == %[(-250, 640), (-230, 590), (-230, 680), (-200, 660)]
      tt["fy"] == %[(-110, 600), (-80, 580), (-80, 670), (-60, 620)]
      tt["r90x"] == %[(0, 660), (50, 680), (70, 630), (90, 660)]
      tt["r90y"] == %[(120, 610), (140, 640), (160, 590), (210, 610)]
      tt["rxy"] == %[(-270, 800), (-250, 760), (-250, 850), (-220, 780)]


    template withName(n): untyped =
      findOne[Instance](m.schema.instances, it.name == n)

    check:
      withName("nothing").geometry == (-210, -130, -110, -50)
      withName("rotated").geometry == (20, 90, 100, 190)
      withName("flipped").geometry == (-220, 70, -120, 150)
      withName("rotated_and_flipped").geometry == (130, -180, 210, -80)
      withName("raw").geometry == (-240, 430, -190, 520)
      withName("r90").geometry == (-150, 460, -60, 510)
      withName("r180").geometry == (-10, 430, 40, 520)
      withName("r270").geometry == (130, 430, 220, 480)
      withName("fx").geometry == (-250, 590, -200, 680)
      withName("fy").geometry == (-110, 580, -60, 670)
      withName("r90x").geometry == (0, 630, 90, 680)
      withName("r90y").geometry == (120, 590, 210, 640)
      withName("rxy").geometry == (-270, 760, -220, 850)

suite "advanced":
  test "extractConnection":
    let
      proj = parseSueProject @[vis "net_graphs.sue"]
      conns = proj.modules["net_graphs"].schema.connections

    check cast[Table[string, HashSet[string]]](conns) == toTable {
      "a": %["b", "d", "c"],
      "b": %["a", "d", "c"],
      "c": %["a", "b", "d"],
      "d": %["a", "b", "c"],
      "e": %["f", "g"],
      "f": %["g", "e"],
      "g": %["f", "e"],
      "h": %["j", "i"],
      "i": %["j", "h"],
      "j": %["k", "h", "l", "i"],
      "k": %["j", "l", "m"],
      "l": %["j", "k"],
      "m": %["k"]}

  let iconGeo = (0, -10, 20, 10)

  test "fixErrors :: addBuffer":
    var
      p = parseSueProject @[
        vis "add_buffer/schema_input/left.sue",
        vis "add_buffer/schema_input/right.sue",
        vis "add_buffer/schema_input/up.sue",
        vis "add_buffer/schema_input/bottom.sue"]

    fixErrors p

    let
      left = p.modules["left"]
      right = p.modules["right"]
      up = p.modules["up"]
      bottom = p.modules["bottom"]

    block test_left:
      let buff = findBuffer left
      check:
        buff.location == (80, 100)
        buff.orient == R0
        buff.geometry == iconGeo + (80, 100)

    block test_right:
      let buff = findBuffer right
      check:
        buff.location == (150, 260)
        buff.orient == RXY
        buff.geometry == iconGeo.rotate(P0, r180) + (150, 260)

    block test_up:
      let buff = findBuffer up
      check:
        buff.location == (90, 350)
        buff.orient == R270
        buff.geometry == iconGeo.rotate(P0, -r90) + (90, 350)

    block test_bottom:
      let buff = findBuffer bottom
      check:
        buff.location == (130, 260)
        buff.orient == R90
        buff.geometry == iconGeo.rotate(P0, r90) + (130, 260)

  test "addBuffer :: element_input":
    var
      p = parseSueProject @[
        vis "add_buffer/element_input/north.sue",
        vis "add_buffer/element_input/east.sue",
        vis "add_buffer/element_input/south.sue",
        vis "add_buffer/element_input/west.sue"]

      east = p.modules["east"]
      west = p.modules["west"]
      north = p.modules["north"]
      south = p.modules["south"]

    block test_east:
      let inp = findInstanceOf("input", east).ports[0]
      addBuffer inp, east.schema, p.modules["buffer0"]

      let buff = findBuffer east
      check:
        buff.location == (450, 340)
        buff.orient == R0
        buff.geometry == iconGeo + (450, 340)

    block test_west:
      let inp = findInstanceOf("input", west).ports[0]
      addBuffer inp, west.schema, p.modules["buffer0"]

      let buff = findBuffer west
      check:
        buff.location == (710, 260)
        buff.orient == RXY
        buff.geometry == iconGeo.rotate(P0, r180) + (710, 260)

    block test_north:
      let inp = findInstanceOf("input", north).ports[0]
      addBuffer inp, north.schema, p.modules["buffer0"]

      let buff = findBuffer north
      check:
        buff.location == (600, 380)
        buff.orient == R270
        buff.geometry == iconGeo.rotate(P0, -r90) + (600, 380)

    block test_south:
      let inp = findInstanceOf("input", south).ports[0]
      addBuffer inp, south.schema, p.modules["buffer0"]

      let buff = findBuffer south
      check:
        buff.location == (600, 230)
        buff.orient == R90
        buff.geometry == iconGeo.rotate(P0, r90) + (600, 230)
