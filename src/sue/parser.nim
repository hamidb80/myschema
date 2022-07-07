import std/[strutils, strformat, macros]
import ../common
import sue


type
  LexForce = enum
    lfAny
    lfText

  LexerState = enum
    lsBefore
    lsActive

  ParserState = enum
    psModule
    psProcName, psProcArg
    psExprCmd, psExprArgs, psExprFlag, psExprValue

  ProcKinds = enum
    pkSchematic, pkIcon

using
  code: ptr string
  bounds: HSlice[int, int]


const eos = '\0' ## end of string

macro toTuple(list: untyped, n: static[int]): untyped =
  let tempId = gensym()
  var tupleDef = newTree nnkTupleConstr

  for i in 0..(n-1):
    tupleDef.add newTree(nnkBracketExpr, tempid, newlit i)

  quote:
    block:
      let `tempId` = `list`
      `tupleDef`


func nextToken(code; bounds; limit: LexForce): tuple[token: SueToken; index: int] =
  let offside = bounds.b + 1
  var
    i = bounds.a
    marker = i
    state = lsBefore
    bracketText = false
    isComment = false

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
          if (isComment and ch in {'\n', eos}) or (not isComment):
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
            isComment = ch == '#'

        of lfText:
          marker = i
          state = lsActive
          bracketText = ch == '{'

    inc i

  raise newException(ValueError, "out of scope")

func parseSue(code, bounds; result: var SueFile) =
  var
    i = bounds.a
    limit = lfAny
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
          lfText
        else:
          lfAny


func parseSue*(code: string): SueFile =
  parseSue(addr code, 0 .. code.high, result)


import print
when isMainModule:

  block commands:
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
      # discard parseSue t

  block file:
    print parseSue readfile "./examples/eg1.sue"
