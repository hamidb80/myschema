import std/[strutils, strformat]
import ../common


type
  TokenType = enum
    ttComment

    ttNumber
    ttString
    ttLiteral

    ttCommand

    ttCurlyOpen
    ttCurlyClose

    ttNewLine

  Token = object
    case kind: TokenType
    of ttNumber:
      intval: int

    of ttString, ttLiteral, ttCommand, ttComment:
      strval: string

    of ttCurlyOpen, ttCurlyClose, ttNewLine:
      discard

  LexForce = enum
    lfAny
    lfText

  LexerState = enum
    lsBefore
    lsActive

using
  code: ptr string
  bounds: HSlice[int, int]


const eos = '\0' ## end of string

func isNumbic(s: string): bool =
  let startIndex =
    if s[0] == '-': 1
    else: 0

  for i in startIndex .. s.high:
    if s[i] notin Digits:
      return false

  true

func toToken(s: string): Token =
  if isNumbic s:
    Token(kind: ttNumber, intval: s.parseInt)

  else:
    template gen(k): untyped = 
      Token(kind: k, strval: s)

    case s[0]:
    of '-': # -50f vs -command
      if s[1] in Digits: gen ttLiteral
      else: gen ttCommand
    of '\'', '{': gen ttString
    else: gen ttLiteral

func toToken(ch: char): Token =
  let k = case ch:
    of '{': ttCurlyOpen
    of '}': ttCurlyClose
    of '\n': ttNewLine
    else: err fmt"invalid conversion to token, char `{ch}`"

  Token(kind: k)


func nextToken(code; bounds; limit: LexForce): tuple[token: Token; index: int] =
  let offside = bounds.b + 1
  var
    i = bounds.a
    marker = i
    state = lsBefore
    bracketText = false

  while i <= offside:
    let ch =
      if i == offside: eos
      else: code[i]

    case ch:
    of Whitespace, eos:
      case state:
      of lsBefore:
        if ch == '\n':
          return (toToken ch, i+1)
      of lsActive:
        case limit:
        of lfText:
          if not bracketText:
            return (toToken code[marker ..< i], i)
        of lfAny:
          return (toToken code[marker ..< i], i)

    of '}':
      case state:
      of lsBefore:
        if code[i-1] != '\\':
          return (toToken code[i], i+1)

      of lsActive:
        return case limit:
        of lfAny: (toToken code[marker ..< i], i)
        of lfText: (toToken code[marker .. i], i+1)

    else:
      case state:
      of lsActive: discard
      of lsBefore:
        case limit:
        of lfAny:
          case ch:
          of '{':
            return (toToken code[i], i+1)
          else:
            marker = i
            state = lsActive

        of lfText:
          marker = i
          state = lsActive
          bracketText = ch == '{'

    inc i

  raise newException(ValueError, "out of scope")

func parseExpr(code, bounds): int =
  var i = bounds.a

  var limit = lfAny

  while i <= bounds.b:
    
    let (t, newi) = 
      try:
        nextToken(code, i .. bounds.b, limit)
      except ValueError:
        break

    debugEcho t
    i = newi

    limit =
      if t.kind == ttCommand and t.strval == "-text": lfText
      else: lfAny


func parseExpr(code: string): int =
  parseExpr(addr code, 0 .. code.high)

# func parseSue(s: string): SueFile =
#   let t = nextToken(addr s, 0 .. s.high)


when isMainModule:
  # import print

  const texts = [
    "make_wire -1800 -950 -1880 -950 -origin {10 20}",
    "  make_wire -1800 -950 -1880 -950",
    "make io_pad_ami_c5n -name pad1 -origin {560 -1440}",
    "make io_pad_ami_c5n -orient R90Y -name pad14 -origin {-1680 -2480}",
    "make global -orient RXY -name vdd -origin {380 -510}",
    "make name_net -name {memdataout_s1[15]} -origin {-1860 -2100}",
    "make name_net -name {memdatain_v1[15]} -origin {-1790 -2220}",
    """
    make_text -origin {-1740 -2690} -text {This is the 
      schematic for AMI-C5N 0.5um technology}
    make_text -origin {-1740 -2660} -text Lambda=0.35um
    """
  ]

  for i, t in texts:
    echo "--- >> ", i+1
    discard parseExpr t
