import std/[unittest]
import src/middle/[logic, expr]

import print

suite "lex":
  test "correctness":
    print lexCode """(11) + 3'b001 - Slama[1:22] && "hello""""

suite "wire direction":
  test "south":
    check detectDir((0, 7) .. (0, 3)) == wdSouth

  test "north":
    check detectDir((0, 3) .. (0, 7)) == wdNorth

  test "west":
    check detectDir((7, 0) .. (3, 0)) == wdWest

  test "east":
    check detectDir((3, 0) .. (7, 0)) == wdEast
