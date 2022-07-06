import std/[strformat, strutils]
import parser_common

const EOF = '\0'

type
  TokenType = enum
    ttComment

    ttNumber
    ttString
    ttLiteral

    ttCommand

    ttCurlyOpen
    ttCurlyClose
    ttparOpen
    ttparClose

    ttNewLine

  Token = object
    case kind: TokenType
    of ttNumber:
      intval: int

    of ttString, ttLiteral, ttCommand, ttComment:
      strval: string

    of ttCurlyOpen, ttCurlyClose, ttparOpen, ttparClose, ttNewLine:
      discard


  LexerState = enum
    lsModule
    lsProcHead
    lsProcBody

  Bound = HSlice[int, int]



func nextToken(code: ptr string, bounds: Bound, state: LexerState
  ): Token =

  let offside = bounds.b + 1
  var 
    i = bounds.a
    depth = 0


  while i <= offside:
    let ch =
      if i == offside: EOF
      else: code[i]

    case ch:
    of '#'
    of '-': discard
    of '{': discard
    of '}': discard
    else: discard


func parseSue(s: string): SueFile =
  var lstate = lsModule 

  let t = nextToken(addr s, 0 .. s.high, lsModule)



when isMainModule:
  import print
  print parseSue readfile r"C:\Users\HamidB80\Desktop\set4"
