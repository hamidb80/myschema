import std/[random, strutils]
import coordination

# types ---

type
  Percent* = range[0.0 .. 1.0]
  Degree* = range[-359 .. 359]


  Alignment* = enum
    aBottomRight
    aBottom
    aBottomLeft
    aRight
    aCenter
    aLeft
    aTopRight
    aTop
    aTopLeft
    # 8 7 6
    # 5 4 3
    # 2 1 0

  Wire* = Slice[Point]

  NumberDirection* = enum
    ndDec = 1
    ndInc
    ndStop # like in range 0 .. 0


proc randomHdlIdent*(len = 10): string =
  result = newStringOfCap len

  result.add sample Letters

  for _ in 1..<len:
    result.add sample IdentChars
