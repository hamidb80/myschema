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
    scGenerate = "generate"
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
    sfDefault = "-default"
    sfAnchor = "-anchor"
    sfStart = "-start"
    sfExtent = "-extent"
    sfCustom = "-<CUSTOM_FIELD>"

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
    value*: SueToken

  SueExpression* = object
    command*: SueCommand
    args*: seq[SueToken]
    options*: seq[SueOption]

  SueFile* = object
    name*: string
    schematic*, icon*: seq[SueExpression]


  TokenCaptureState = enum
    tcsBeforeMatch
    tcsActiveMatch

  LexerState = enum
    lsModule
    lsProcName, lsProcArg, lsProcBody
    lsExprCmd, lsExprArgs, lsExprFlag, lsExprValue

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
    template gen(k, val): untyped =
      SueToken(kind: k, strval: val)

    case s[0]:
    of '#': gen sttComment, s.substr(1).strip
    of '{': gen sttString, s[1 ..< ^1]
    of '-': # -50f vs -command
      if s[1] in Digits: gen sttLiteral, s
      else: gen sttCommand, s
    else: gen sttLiteral, s

func toToken*(ch: char): SueToken =
  let k = case ch:
    of '\n': sttNewLine
    of '{': sttCurlyOpen
    of '}': sttCurlyClose
    else: err fmt"invalid conversion to token, char `{ch}`"

  SueToken(kind: k)

func `==`*(t: SueToken, s: string): bool =
  case t.kind:
  of sttString, sttLiteral, sttCommand: t.strval == s
  else: false

func `==`*(t: SueToken, ch: char): bool =
  t.kind == (toToken ch).kind

# --- lexer

func nextToken(code; bounds; lstate: LexerState): tuple[token: SueToken; index: int] =
  let offside = bounds.b + 1
  var
    i = bounds.a
    marker = i
    state = tcsBeforeMatch
    bracketText = false
    isComment = false
    depth = 0

  template oneChar(): untyped =
    (toToken ch, i+1)

  while i <= offside:
    let
      ch =
        if i == offside: eos
        else: code[i]
      isScaped =
        (i > 0) and (code[i-1] == '\\')

    case ch:
    of Whitespace, eos:
      case state:
      of tcsBeforeMatch:
        if ch == '\n':
          return oneChar()

      of tcsActiveMatch:
        if (not isComment and not bracketText) or
          (isComment and ch == '\n'):
          return (toToken code[marker ..< i], i)

    of '{':
      if lstate == lsProcBody:
        return oneChar

      if not isScaped:
        inc depth

        if state == tcsBeforeMatch:
          marker = i
          state = tcsActiveMatch
          bracketText = true

    of '}':
      case state:
      of tcsBeforeMatch:
        if lstate == lsExprCmd:
          return oneChar

      of tcsActiveMatch:
        if not isScaped:
          dec depth

        if depth == 0:
          return (toToken code[marker .. i], i+1)

    else:
      case state:
      of tcsActiveMatch: discard
      of tcsBeforeMatch:
        if ch == '#':
          isComment = true

        marker = i
        state = tcsActiveMatch

    inc i

  err "not matched"

func lexSue(code; bounds; result: var SueFile) =
  var
    i = bounds.a
    lstate = lsModule
    whichProc: ProcKinds
    expressionsAcc: seq[SueExpression]

  while i <= bounds.b:
    let (t, newi) =
      try: nextToken(code, i .. bounds.b, lstate)
      except ValueError: break

    case lstate:
      of lsModule:
        if t == "proc":
          lstate = lsProcName

      of lsProcName:
        assert (t.kind == sttLiteral) and ('_' in t.strval), "invalid proc pattern"
        let (prefix, pname) = t.strval.split('_', 1).toTuple(2)

        result.name = pname
        whichProc = case prefix:
          of "ICON": pkIcon
          of "SCHEMATIC": pkSchematic
          else: err fmt"invalid proc prefix: {t.strval}"

        lstate = lsProcArg

      of lsProcArg:
        assert t.kind in {sttString, sttLiteral}
        lstate = lsProcBody

      of lsProcBody:
        assert t.kind == sttCurlyOpen
        lstate = lsExprCmd

      of lsExprCmd:
        if t.kind == sttComment or t == '\n':
          discard

        elif t == '}':
          lstate = lsModule
          case whichProc:
          of pkIcon: result.icon = expressionsAcc
          of pkSchematic: result.schematic = expressionsAcc

          expressionsAcc = @[]

        else:
          let cmd = t.strval.parseEnum[:SueCommand]
          expressionsAcc.add SueExpression(command: cmd)
          lstate = lsExprArgs

      of lsExprArgs:
        case t.kind:
        of sttCommand:
          lstate = lsExprFlag
          continue

        of sttNewLine:
          lstate = lsExprCmd

        else:
          expressionsAcc[^1].args.add t

      of lsExprFlag:
        lstate =
          if t == '\n': lsExprCmd
          else:
            let (flag, field) =
              try: (t.strval.parseEnum[:SueFlag], "")
              except: (sfCustom, t.strval)

            expressionsAcc[^1].options.add SueOption(flag: flag, field: field)
            lsExprValue

      of lsExprValue:
        expressionsAcc[^1].options[^1].value = t
        lstate = lsExprFlag

    i = newi

func lexSue*(code: string): SueFile =
  lexSue(addr code, 0 .. code.high, result)

# --- serializer

func dump*(t: SueToken): string =
  case t.kind:
  of sttNumber: $t.intval
  of sttLiteral, sttCommand: t.strval
  of sttString: '{' & t.strval & '}'
  of sttComment: fmt"# {t.strval}"
  else: err fmt"not a valid token to string conversion: {t.kind}"

func dumpValue*(o: SueOption): string =
  dump o.value

func dumpFlag*(o: SueOption): string =
  case o.flag:
  of sfcustom: o.field
  else: $o.flag

func dump*(expr: SueExpression): string =
  result = fmt"  {expr.command} "
  result.add expr.args.map(dump).join" "
  result = result.strip(leading = false)

  for op in expr.options:
    result.add fmt" {dumpFlag op} {dumpValue op}"

func dump*(sf: SueFile): string =
  var lines = @[fmt "# SUE version {SueVersion}\n"]

  template addProc(exprWrapper, args): untyped =
    lines.add "proc ICON_" & sf.name & " {args} {"
    for expr in exprWrapper:
      lines.add dump expr
    lines.add "}\n"

  addProc sf.schematic, "{}"
  if sf.icon.len != 0:
    addProc sf.icon, "args"

  lines.join "\n"
