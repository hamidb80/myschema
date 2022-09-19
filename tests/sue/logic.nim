import std/[unittest, sequtils, tables, sets, os, sugar]
import src/sue/logic {.all.}
import src/sue/[model, lexer, parser]
import src/common/[coordination, graph, collections]

import print

func vis(s: string): string =
  "./examples/sue/visual_tests" / s

template `%`(smth): untyped =
  toHashSet smth


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

  test "location":
    let
      proj = parseSueProject @[
        vis "location.sue",
        vis "square.sue",
        vis "kite.sue"]

      m2 = proj.modules["location"]

    var tt: Table[string, HashSet[Point]]
    for loc, ps in m2.schema.portsPlot:
      for p in ps:
        let n = p.parent.name

        withValue tt, n, wrapper:
          wrapper[].incl p.location
        do:
          tt[n] = toHashSet @[p.location]

    check:
      # square
      tt["nothing"] == %[(-210, -110), (-140, -50), (-110, -110)]
      tt["rotated"] == %[(40, 190), (40, 90), (100, 120)]
      tt["flipped"] == %[(-220, 130), (-150, 70), (-120, 130)]
      tt["rotated_and_flipped"] == %[(150, -180), (150, -80), (210, -110)]

      # kite
      tt["raw"] == %[(-240, 500), (-210, 520), (-210, 430), (-190, 480)]
      tt["r90"] == %[(-150, 490), (-130, 460), (-110, 510), (-60, 490)]
      tt["r180"] == %[(-10, 470), (10, 430), (10, 520), (40, 450)]
      tt["r270"] == %[(130, 450), (180, 430), (200, 480), (220, 450)]
      tt["fx"] == %[(-250, 640), (-230, 590), (-230, 680), (-200, 660)]
      tt["fy"] == %[(-110, 600), (-80, 580), (-80, 670), (-60, 620)]
      tt["r90x"] == %[(0, 660), (50, 680), (70, 630), (90, 660)]
      tt["r90y"] == %[(120, 610), (140, 640), (160, 590), (210, 610)]
      tt["rxy"] == %[(-270, 800), (-250, 760), (-250, 850), (-220, 780)]

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

  test "addBuffer":
    var pSchema = parseSueProject @[
        # vis "add_buffer/schema_input/up.sue",
        # vis "add_buffer/schema_input/right.sue",
        # vis "add_buffer/schema_input/bottom.sue",
        vis "add_buffer/schema_input/left.sue"]

    fixErrors pSchema

    let kk = surf[Instance](
        pSchema.modules["left"].schema.instances,
        it.module.name == "buffer0")

    check kk.location == (80, 100)
    check kk.geometry == (80, 90, 80+20, 110)

    # var pElement = parseSueProject @[
    #   ab "element_input/north.sue",
    #   ab "element_input/east.sue",
    #   ab "element_input/south.sue",
    #   ab "element_input/west.sue"]


  test "fixErrors":
    discard
