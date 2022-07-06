import std/[strformat, strutils]


const EOF = '\0'

type 
  LexerState = enum
    lsModule
    lsNegetive

  TokenType = enum
    ttNumber
    ttCommand
    ttLiteral


func lexSue(s: ptr string, i: var int): string = 
  var 
    c = 0
    lstate = lsModule

  while c <= s.len:
    let ch = 
      if c == s.len: EOF
      else: s[i]

    case ch:
    of '-':


func parseSue()