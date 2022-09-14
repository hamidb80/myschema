import std/unittest

suite "lex":
  test "correctness":
    print lexCode """(11) + 3'b001 - Slama[1:22] && "hello""""

suite "wire direction":
  test "south":
    check dirOf((0, 7) .. (0, 3)) == wdSouth

  test "north":
    check dirOf((0, 3) .. (0, 7)) == wdNorth

  test "west":
    check dirOf((7, 0) .. (3, 0)) == wdWest

  test "east":
    check dirOf((3, 0) .. (7, 0)) == wdEast
