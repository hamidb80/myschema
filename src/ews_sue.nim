import std/[strutils]

type
  ParserStates = enum
    psModule
    psComment

    psProcName
    psProcBody
    psProcArgs

    psCurlyBracket

    psIdent
    psNumber
    psCommand


proc lex(code: string) =
  var pStateStack = @[psModule]
  
  template enter(s): untyped =
    pStateStack.add s

  template exit(): untyped =
    pStateStack.del pStateStack.high
    

  for ch in code:
    case pStateStack[^1]:
    of psModule:
      case ch:
      of '#': enter psComment
      of '\n': exit
      else: discard

    of psComment: discard
    of psProcName: discard
    of psProcBody: discard
    of psProcArgs: discard
    of psCurlyBracket: discard
    of psIdent: discard
    of psNumber: discard
    of psCommand: discard


when isMainModule:
  let content = readfile "./examples/eg1.sue"
  lex content
