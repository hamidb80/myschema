import std/[strutils, strformat, sequtils]
import ../common

type
  SueCommand* = enum
    scMake = "make"
    scMakeWire = "make_wire"
    scMakeLine = "make_line"
    scMakeText = "make_text"
    scIconSetup = "icon_setup"
    scIconTerm = "icon_term"
    scIconProperty = "icon_property"
    scIconLine = "icon_line"
    scIconArc = "icon_arc"

  SueFlag* = enum
    sfLabel = "-label"
    sfText = "-text"
    sfName = "-name"
    sfOrigin = "-origin"
    sfOrient = "-orient"
    sfRotate = "-rotate"
    sfSize = "-size"
    sfType = "-type"
    sfAnchor = "-anchor"
    sfStart = "-start"
    sfExtent = "-extent"
    sfCustom = "<CUSTOM_FIELD>"

  SueType* = enum
    spInput = "input"
    spOutput = "output"
    spInOut = "inout"
    spUser = "user"

  SueSize* = enum
    ssSmall = "small"
    ssLarge = "large"

  SueTokenType* = enum
    sttComment

    sttCommand
    sttNumber 
    sttString
    sttLiteral

    sttCurlyOpen
    sttCurlyClose
    sttNewLine

  SueToken* = object
    case kind*: SueTokenType
    of sttNumber:
      intval*: int

    of sttString, sttLiteral, sttCommand, sttComment:
      strval*: string

    of sttCurlyOpen, sttCurlyClose, sttNewLine:
      discard


  SuePoint* = tuple[x, y: int]

  SueOption* = object # TODO merge commom fields by types
    flag*: SueFlag
    field*: string
    values*: seq[SueToken]
    
  SueExpression* = object
    command*: SueCommand
    args*: seq[SueToken]
    options*: seq[SueOption]

  SueFile* = object
    name*: string
    schematic*, icon*: seq[SueExpression]


func isNumbic(s: string): bool =
  let startIndex =
    if s[0] == '-': 1
    else: 0

  for i in startIndex .. s.high:
    if s[i] notin Digits:
      return false

  true

func toToken*(s: string): SueToken =
  if isNumbic s:
    SueToken(kind: sttNumber, intval: s.parseInt)

  else:
    template gen(k): untyped =
      SueToken(kind: k, strval: s)

    case s[0]:
    of '#': gen sttComment
    of '-': # -50f vs -command
      if s[1] in Digits: gen sttLiteral
      else: gen sttCommand
    of '\'', '{': gen sttString
    else: gen sttLiteral

func toToken*(ch: char): SueToken =
  let k = case ch:
    of '{': sttCurlyOpen
    of '}': sttCurlyClose
    of '\n': sttNewLine
    else: err fmt"invalid conversion to token, char `{ch}`"

  SueToken(kind: k)

func `==`*(t: SueToken, s: string): bool =
  case t.kind:
  of sttString, sttLiteral, sttCommand: t.strval == s
  else: false

func `==`*(t: SueToken, ch: char): bool =
  t.kind == (toToken ch).kind


func expand*(points: seq[SuePoint]): seq[int] =
  for p in points:
    result.add [p.x, p.y]

func isPure*(s: string): bool =
  for ch in s:
    if ch notin IdentChars:
      return false

  true

func wrap*(s: string): string =
  if isPure s: s
  else: '{' & s & '}'

const SueVersion = "MMI_SUE4.4"


func dump*(t: SueToken): string = 
  case t.kind:
  of sttNumber: $t.intval
  of sttString, sttLiteral, sttCommand, sttComment:t.strval
  else: err fmt"illigal token to string conversion: {t.kind}"

func dumpValue*(o: SueOption): string = 
  case o.flag:
  of sfOrigin: "{" & dump(o.values[0]) & " " & dump(o.values[1]) &  "}"
  else: dump o.values[0]

func dumpFlag*(o: SueOption): string = 
  case o.flag:
  of sfcustom: o.field
  else: $o.flag

func dump*(expr: SueExpression): string =
  result = fmt"  {expr.command} "
  result.add expr.args.map(dump).join" "
  result = result.strip(leading = false)

  for op in expr.options:
    result.add fmt" {op.dumpFlag} {dumpValue op}"

func dump*(sf: SueFile): string =
  var lines = @[fmt "# SUE version {SueVersion}\n"]

  template addLinesFor(exprWrapper): untyped =
    for expr in exprWrapper:
      lines.add dump expr

  lines.add "proc SCHEMATIC_" & sf.name & " {} {"
  addLinesFor sf.schematic
  lines.add "}\n"

  if sf.icon.len != 0:
    lines.add "proc ICON_" & sf.name & " args {"
    addLinesFor sf.icon
    lines.add "}"

  lines.join "\n"
