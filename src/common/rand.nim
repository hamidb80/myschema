import std/[strutils, random]

proc randomIdent*(len = 10): string =
  result = newStringOfCap len
  result.add sample Letters
  for _ in 1..<len:
    result.add sample IdentChars
