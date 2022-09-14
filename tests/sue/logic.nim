import std/[unittest, sequtils, tables]
import src/sue/logic {.all.}
import src/sue/model
import src/common/[coordination, graph, collections]


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

suite "advanced":
  # TODO test with sue files
  test "extractConnection":
    discard

  test "resolve":
    discard

  test "addBuffer":
    discard

  test "fixErrors":
    discard
