import std/[unittest]
import src/common/minitable

suite "mini table":
  var mt: MiniTable[string, int]

  test "add":
    mt["1"] = 1

  test "get":
    check mt["1"] == 1

  test "contains":
    check "1" in mt
    check "2" notin mt

  test "get or default":
    check mt.getOrDefault("2", 2) == 2
