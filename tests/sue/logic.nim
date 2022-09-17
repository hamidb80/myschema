import std/[unittest, sequtils, tables, sets, os]
import src/sue/logic {.all.}
import src/sue/[model, lexer, parser]
import src/common/[coordination, graph, collections]

import print

func vis(s: string): string =
  "./examples/sue/visual_tests" / s

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

      m1 = proj.modules["myelem"]
      m2 = proj.modules["location"]

    echo "-----------------------------"
    echo m1.icon.ports.mapIt it.name

    var tt: Table[string, HashSet[Point]]
    for loc, ps in m2.schema.portsPlot:
      for p in ps:
        let n = p.parent.name
        
        withValue  tt, n, wrapper:
          wrapper[].incl p.location
        do:
          tt[n] = toHashSet @[p.location]

    ## rotated and nothing is right, flipped is wrong

    print tt

suite "advanced":
  test "extractConnection":
    let proj = parseSueProject @["./examples/sue/visual_tests/net_graphs.sue"]
    # print proj.modules["net_graphs"].schema.connections

  test "resolve":
    discard

  test "addBuffer":
    discard

  test "fixErrors":
    discard
