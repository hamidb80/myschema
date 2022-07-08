import std/[strutils, strformat, sequtils]
import ../utils


type
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

  SueOption* = object
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


  LexExpect = enum
    leAny
    leText

  LexerState = enum
    lsBeforeMatch
    lsActiveMatch

  ParserState = enum
    psModule
    psProcName, psProcArg
    psExprCmd, psExprArgs, psExprFlag, psExprValue

  ProcKinds = enum
    pkSchematic, pkIcon


using
  code: ptr string
  bounds: HSlice[int, int]


const 
  SueVersion = "MMI_SUE4.4"
  eos = '\0' ## end of string

# --- utility

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

# --- lexer

func nextToken(code; bounds; limit: LexExpect): tuple[token: SueToken; index: int] =
  let offside = bounds.b + 1
  var
    i = bounds.a
    marker = i
    state = lsBeforeMatch
    bracketText = false
    isComment = false

  while i <= offside:
    let ch =
      if i == offside: eos
      else: code[i]

    case ch:
    of Whitespace, eos:
      case state:
      of lsBeforeMatch:
        if ch == '\n':
          return (toToken ch, i+1)
      of lsActiveMatch:
        case limit:
        of leText:
          if not bracketText:
            return (toToken code[marker ..< i], i)
        of leAny:
          if (isComment and ch in {'\n', eos}) or (not isComment):
            return (toToken code[marker ..< i], i)

    of '}':
      case state:
      of lsBeforeMatch:
        if code[i-1] != '\\':
          return (toToken code[i], i+1)

      of lsActiveMatch:
        return case limit:
        of leAny: (toToken code[marker ..< i], i)
        of leText: (toToken code[marker .. i], i+1)

    else:
      case state:
      of lsActiveMatch: discard
      of lsBeforeMatch:
        case limit:
        of leAny:
          case ch:
          of '{':
            return (toToken code[i], i+1)
          else:
            marker = i
            state = lsActiveMatch
            isComment = ch == '#'

        of leText:
          marker = i
          state = lsActiveMatch
          bracketText = ch == '{'

    inc i

  err "not matched"

func lexSue(code; bounds; result: var SueFile) =
  var
    i = bounds.a
    limit = leAny
    pstate = psModule
    whichProc: ProcKinds
    expressionsAcc: seq[SueExpression]

  while i <= bounds.b:
    var goNext = true
    let (t, newi) =
      try: nextToken(code, i .. bounds.b, limit)
      except ValueError: break

    case pstate:
    of psModule:
      if t == "proc":
        pstate = psProcName

    of psProcName:
      assert (t.kind == sttLiteral) and ('_' in t.strval), "invalid proc pattern"
      let (prefix, pname) = t.strval.split('_', 1).toTuple(2)

      result.name = pname
      whichProc = case prefix:
        of "ICON": pkIcon
        of "SCHEMATIC": pkSchematic
        else: err fmt"invalid proc name: {t.strval}"

      pstate = psProcArg

    of psProcArg:
      if t == '\n':
        pstate = psExprCmd

    of psExprCmd:
      if t == '}':
        pstate = psModule
        case whichProc:
        of pkIcon: result.icon = expressionsAcc
        of pkSchematic: result.schematic = expressionsAcc

        expressionsAcc = @[]

      else:
        let cmd = t.strval.parseEnum[:SueCommand]
        expressionsAcc.add SueExpression(command: cmd)
        pstate = psExprArgs


    elif t == '\n':
      pstate = psExprCmd

    else:
      case pstate
      of psExprArgs:
        case t.kind:
        of sttCommand:
          pstate = psExprFlag
          goNext = false

        else:
          expressionsAcc[^1].args.add t

      of psExprFlag:
        let (flag, field) =
          try: (t.strval.parseEnum[:SueFlag], "")
          except: (sfCustom, t.strval)

        expressionsAcc[^1].options.add:
          SueOption(flag: flag, field: field)

        pstate = psExprValue

      of psExprValue:
        template addTo: untyped =
          expressionsAcc[^1].options[^1].values.add t

        case expressionsAcc[^1].options[^1].flag:
        of sfOrigin:
          case t.kind:
          of sttCurlyOpen: discard
          of sttCurlyClose: pstate = psExprFlag
          else: addTo

        else:
          addTo
          pstate = psExprFlag


      else: impossible

    # debugEcho t
    if goNext:
      i = newi
      limit =
        if (t.kind == sttCommand) and (t.strval in ["-text", "-name", "-label"]):
          leText
        else:
          leAny

func lexSue*(code: string): SueFile =
  lexSue(addr code, 0 .. code.high, result)

# --- serializer

func dump*(t: SueToken): string =
  case t.kind:
  of sttNumber: $t.intval
  of sttString, sttLiteral, sttCommand, sttComment: t.strval
  of sttCurlyOpen: "{"
  of sttCurlyClose: "}"
  else: err "not a valid token to string conversion: {t.kind}"

func dumpValue*(o: SueOption): string =
  case o.flag:
  of sfOrigin: "{" & dump(o.values[0]) & " " & dump(o.values[1]) & "}"
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

  template addLinesFor(exprWrapper, args): untyped =
    lines.add "proc ICON_" & sf.name & " {args} {"
    for expr in exprWrapper:
      lines.add dump expr
    lines.add "}\n"

  addLinesFor sf.schematic, "{}"
  if sf.icon.len != 0:
    addLinesFor sf.icon, "args"

  lines.join "\n"
