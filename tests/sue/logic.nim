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
        vis "myelem.sue"]

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
      tt["nothing"] == %[(-110, -110), (-210, -110), (-140, -50)]
      tt["rotated"] == %[(100, 120), (40, 190), (40, 90)]
      tt["flipped"] == %[(-150, 70), (-120, 130), (-220, 130)]
      tt["rotated_and_flipped"] == %[(150, -180), (210, -110), (150, -80)]

suite "advanced":
  test "extractConnection":
    let
      proj = parseSueProject @["./examples/sue/visual_tests/net_graphs.sue"]
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

  test "resolve":
    discard

  test "addBuffer":
    discard

  test "fixErrors":
    discard
