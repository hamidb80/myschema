import std/[sequtils]
import ../common/[domain, errors]
import model, lexer

func encodeStart(s: Degree): SueOption =
  SueOption(flag: sfStart, value: toToken s)

func encode(l: Line): SueExpression =
  case l.kind:
  of straight:
    err "cannot draw custom line here"
    
  of arc:
    SueExpression(
      command: scMakeLine,
      args: @[l.head.x, l.head.y, l.tail.x, l.tail.y].map(toToken),
      options: @[]
    )