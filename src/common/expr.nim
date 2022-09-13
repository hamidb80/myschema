import std/[strutils, strformat]
import errors

const
  EOS = '\0' # end of string
  Operators = {'+', '-', '*', '&', '!', '?', '|', '/', ':', ',', '=', '<', '>'}

type 
  LexerState = enum
    lsInitial
    lsString, lsNumber
    lsOperator, lsSymbol

  TokenGroup* = seq[Token]

  TokenKind* = enum
    mtkOpenPar, mtkClosePar
    mtkOpenBracket, mtkCloseBracket
    mtkNumberLiteral, mtkStringLiteral
    mtkSymbol, mtkOperator

  Token* = object
    kind*: TokenKind
    content*: string

func toTokenKind(ch: char): TokenKind =
  case ch:
  of '(': mtkOpenPar
  of ')': mtkClosePar
  of '[': mtkOpenBracket
  of ']': mtkCloseBracket
  else: err "invalid char"


func `$`*(tkn: Token): string =
  case tkn.kind:
  of mtkOpenPar: "("
  of mtkClosePar: ")"
  of mtkOpenBracket: "["
  of mtkCloseBracket: "]"
  of mtkOperator, mtkNumberLiteral, mtkSymbol: tkn.content
  of mtkStringLiteral: '"' & tkn.content & '"'

func `$`*(mtg: TokenGroup): string =
  join mtg

func lexCode*(s: string): TokenGroup =
  var
    capture = -1
    i = 0
    state = lsInitial
    isEscaped = false

  while i <= s.len:
    let ch =
      if i == s.len: EOS
      else: s[i]

    case state:
    of lsInitial:
      case ch:
      of Whitespace, EOS: discard
      of Digits:
        capture = i
        state = lsNumber

      of Letters, '`':
        capture = i
        state = lsSymbol

      of '"', '\'':
        capture = i+1
        state = lsString

      of Operators:
        capture = i
        state = lsOperator

      of '(', ')', '[', ']':
        result.add Token(kind: toTokenKind ch)

      else:
        err fmt"invalid char: {ch}, {s}"

    of lsString:
      if ch in {'"', '\''} and not isEscaped:
        result.add Token(kind: mtkStringLiteral, content: s[capture ..< i])
        reset state

      else:
        isEscaped =
          if ch == '\\':
            if isEscaped: false
            else: true
          else: false

    of lsNumber:
      case ch:
      of Digits, '\'', '#', 'z', 'h', 'b', 'x', 'd', '.': discard
      else:
        result.add Token(kind: mtkNumberLiteral, content: s[capture ..< i])
        reset state
        dec i

    of lsOperator:
      case ch:
      of Operators: discard
      else:
        result.add Token(kind: mtkOperator, content: s[capture ..< i])
        reset state
        dec i

    of lsSymbol:
      case ch:
      of IdentChars: discard
      else:
        result.add Token(kind: mtkSymbol, content: s[capture ..< i])
        reset state
        dec i

    inc i
