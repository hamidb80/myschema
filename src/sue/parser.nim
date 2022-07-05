import std/[strutils, strformat, nre, options, sequtils, macros]
import ../common

type
  ParserStates = enum
    psModule, psSchematic, psIcon


  SueCommands* = enum
    scMake = "make"
    scMakeWire = "make_wire"
    scMakeLine = "make_line"
    scMakeText = "make_text"
    scIconSetup = "icon_setup"
    scIconTerm = "icon_term"
    scIconProperty = "icon_property"
    scIconLine = "icon_line"
    scIconArc = "icon_arc"

  SueFlags* = enum
    sfLabel = "label"
    sfText = "text"
    sfName = "name"
    sfOrigin = "origin"
    sfOrient = "orient"
    sfRotate = "rotate"
    sfSize = "size"
    sfType = "type"
    sfAnchor = "anchor"
    sfStart = "start"
    sfExtent = "extent"
    sfCustom

  SuePorts* = enum
    spInput = "input"
    spOutput = "output"
    spInOut = "inout"
    spUser = "user"

  SueSize* = enum
    ssSmall = "small"
    ssLarge = "large"


  SuePoint* = tuple[x, y: int]

  SueOption* = object # TODO merge commom fields by types
    case flag*: SueFlags
    of sfText, sfName, sfLabel, sfOrient:
      strval*: string

    of sfOrigin:
      position*: SuePoint

    of sfType:
      portType*: SuePorts

    of sfSize:
      size*: SueSize

    of sfAnchor:
      anchor*: string

    of sfRotate:
      rotation*: int

    of sfStart, sfExtent:
      degree*: int

    of sfCustom:
      field*, value*: string

  SueExpression* = object
    case command*: SueCommands
    of scMake:
      ident*: string

    of scMakeWire, scMakeLine, scIconArc:
      head*, tail*: SuePoint

    of scIconSetup:
      discard # TODO

    of scIconTerm, scIconProperty, scMakeText:
      discard

    of scIconLine:
      points*: seq[SuePoint]

    options*: seq[SueOption]

  SueFile* = object
    name*: string
    schematic*, icon*: seq[SueExpression]


func hasLetter(s: string): bool {.inline.} =
  for ch in s:
    if ch in Letters:
      return true


template findGoImpl(s, pat, i): untyped {.dirty.} =
  let m = s.match(pat, i)
  assert issome m, "cannot match"

  i = m.get.matchBounds.b + 2

func findGo(s: string, pat: Regex, i: var int): string =
  findGoImpl s, pat, i
  m.get.captures[0]

func findGoMulti(s: string, pat: Regex, i: var int): seq[string] =
  findGoImpl s, pat, i
  for s in m.get.captures:
    result.add s.get

func matchCurlyBraceGo(s: string, i: var int): string =
  assert s[i] == '{'
  inc i

  var
    depth = 1
    marker = i

  while i <= s.high:
    case s[i]:
      of '{': inc depth
      of '}':
        dec depth
        if depth == 0:
          result = s[marker ..< i]
          inc i, 2
          break
      else: discard

    inc i

  assert depth == 0

func matchIdentGo(s: string, i: var int): string =
  let marker = i

  while i <= s.high:
    if s[i] in Whitespace:
      break

    inc i

  result = s[marker ..< i]
  inc i

func matchStrGo(s: string, i: var int): string =
  case s[i]:
  of '{': matchCurlyBraceGo s, i
  of IdentChars: matchIdentGo s, i
  else: err fmt"invalid char: {s[i]}"

macro toTuple(list: untyped, n: static[int]): untyped =
  let tempId = ident "temp"
  var tupleDef = newTree nnkTupleConstr

  for i in 0..(n-1):
    tupleDef.add newTree(nnkBracketExpr, tempid, newlit i)

  quote:
    block:
      let `tempId` = `list`
      `tupleDef`

func exprcc(field, value: NimNode): NimNode =
  newtree nnkExprColonExpr, field, value

template initObjConstrConventionImpl(objName,
  field, value, args): untyped {.dirty.} =

  result = newTree(nnkObjConstr, objName, exprcc(field, value))

  for i in countup(0, args.len - 1, 2):
    let
      field = args[i]
      value = args[i+1]

    result.add exprcc(field, value)


macro initSueOption(f: untyped, args: varargs[untyped]): untyped =
  let t = ident"flag"
  initObjConstrConventionImpl bindsym"SueOption", t, f, args

macro initSueExpr(c: untyped, args: varargs[untyped]): untyped =
  let t = ident"command"
  initObjConstrConventionImpl bindsym"SueExpression", t, c, args


func foldPoints(nums: seq[int]): seq[SuePoint] =
  for i in countup(0, nums.high, 2):
    result.add (nums[i], nums[i+1])

func expand(points: seq[SuePoint]): seq[int] =
  for p in points:
    result.add [p.x, p.y]

func isPure(s: string): bool =
  for ch in s:
    if ch notin IdentChars:
      return false

  true

func wrap(s: string): string =
  if isPure s: s
  else: '{' & s & '}'

# loc: line of code

# FIXME can go to next line inside { } 
# ّFIXME we have strings too [in single quotation '

func matchProcLine(loc: string): SueExpression =
  # debugecho loc, " ::::::"

  var i = 0
  let cmd = loc.findGo(re"(\w+)", i).parseEnum[:SueCommands]

  result = case cmd: # parse params
    of scMake:
      let moduleName = loc.findGo(re"(\w+)", i)
      cmd.initSueExpr(ident, moduleName)

    of scMakeWire, scMakeLine, scIconArc:
      let (x1, y1, x2, y2) = loc
        .findGoMulti(re"(-?\d+) (-?\d+) (-?\d+) (-?\d+)", i)
        .mapit(parseInt it)
        .toTuple(4)

      cmd.initSueExpr(head, (x1, y1), tail, (x2, y2))

    of scIconSetup:
      i = loc.high
      cmd.initSueExpr() # TODO

    of scIconTerm, scIconProperty, scMakeText:
      cmd.initSueExpr()

    of scIconLine:
      let args = loc.substr(i).split.mapit(parseInt it)
      i = loc.high

      cmd.initSueExpr(points, foldPoints(args))

  while i < loc.high: # parse options
    let 
      op = loc.findgo(re"-(\w+)", i)
      flag = 
        try: op.parseEnum[:SueFlags]
        except: sfCustom

    result.options.add:
      case flag:
      of sfOrigin:
        let p = loc
          .findGoMulti(re"\{(-?\d+) (-?\d+)\}", i)
          .mapit(parseInt it)
          .toTuple(2)

        flag.initSueOption(position, p)

      of sfStart, sfExtent:
        let n = loc.findGo(re"(-?\d+)", i).parseInt
        flag.initSueOption(degree, n)

      of sfText, sfName, sfLabel, sfOrient, sfType, sfSize, sfAnchor, sfRotate:
        let s = loc.matchStrGo(i)

        case flag:
        of sfName, sfLabel, sfText, sfOrient: flag.initSueOption(strval, s)
        of sfType: flag.initSueOption(portType, parseEnum[SuePorts](s))
        of sfSize: flag.initSueOption(size, parseEnum[SueSize](s))
        of sfAnchor: flag.initSueOption(anchor, s)
        of sfRotate: flag.initSueOption()
        else: impossible

      of sfCustom:
        let n = loc.matchIdentGo(i)
        flag.initSueOption(field, op, value, n)


func parseSue*(code: string): SueFile =
  var pstate = psModule

  for loc in splitLines code:
    if (not hasLetter loc) or (loc.startsWith '#'): # empty line or comment
      discard

    elif loc.startsWith '}': # end of proc body
      pstate = psModule

    elif loc.startsWith "proc": # proc def
      let (prefix, name) = loc.match(re"proc ([a-zA-Z]+)_(\w+)").get.captures.toTuple(2)

      result.name = name

      pstate = case prefix:
        of "SCHEMATIC": psSchematic
        of "ICON": psIcon
        else: err "invalid proc name"

    else:
      template expr: untyped = matchProcLine loc.strip

      case pstate:
      of psIcon: result.icon.add expr
      of psSchematic: result.schematic.add expr
      of psModule: err fmt"cannot happen: {loc}"

const SueVersion = "MMI_SUE4.4"

func dumpValue*(o: SueOption): string = 
  case o.flag:
  of sfLabel, sfText, sfName, sfOrient: wrap o.strval
  of sfOrigin: ["{", $o.position.x, " ", $o.position.y, "}"].join
  of sfRotate: $o.rotation
  of sfSize: $o.size
  of sfType: $o.portType
  of sfAnchor: o.anchor
  of sfStart, sfExtent: $o.degree
  of sfCustom: o.value

func dumpFlag*(o: SueOption): string = 
  case o.flag:
  of sfcustom: o.field
  else: $o.flag

func dumpArgs(expr: SueExpression): string = 
  case expr.command:
  of scMake: expr.ident
  of scMakeText, scIconTerm, scIconProperty: ""
  of scIconSetup: ""
  of scIconLine: expr.points.expand.join " "
  of scMakeWire, scMakeLine, scIconArc:
    @[expr.head.x, expr.head.y, expr.tail.x, expr.tail.y].join " "

func dump*(expr: SueExpression): string =
  result = fmt"  {expr.command} "
  result.add dumpArgs expr
  result = result.strip(leading = false)

  for op in expr.options:
    result.add fmt" -{op.dumpFlag} {dumpValue op}"

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
