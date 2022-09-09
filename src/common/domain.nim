import std/[random, strutils]
import coordination


type
  Percent* = range[0.0 .. 1.0]
  Degree* = range[-359 .. 359]

  Wire* = Slice[Point]

  NumberDirection* = enum
    ndDec = 1
    ndInc
    ndStop # like in range 0 .. 0

  Language* = enum
    Verilog, VHDL

  CodeFile* = object
    name*: string
    content*: string

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


proc randomHdlIdent*(len = 10): string =
  result = newStringOfCap len

  result.add sample Letters

  for _ in 1..<len:
    result.add sample IdentChars
