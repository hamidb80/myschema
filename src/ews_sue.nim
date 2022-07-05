import std/[strutils, strformat, nre, options, sequtils, macros]

type
  ParserStates = enum
    psModule, psSchematic, psIcon


  SueCommands = enum
    scMake = "make"
    scMakeWire = "make_wire"
    scMakeText = "make_text"
    scIconSetup = "icon_setup"
    scIconTerm = "icon_term"
    scIconProperty = "icon_property"
    scIconLine = "icon_line"
    scIconArc = "icon_arc"

  SueFlags = enum
    soLabel = "label"
    soText = "text"
    soName = "name"
    soOrigin = "origin"
    soOrient = "orient"
    soRotate = "rotate"
    soSize = "size"
    soType = "type"
    soAnchor = "anchor"
    soStart = "start"
    soExtent = "extent"

  SuePorts = enum
    spInput = "input"
    spOutput = "output"
    spInOut = "inout"
    spUser = "user"

  SueSize = enum
    ssSmall = "small"
    ssLarge = "large"


  SuePoint = tuple[x, y: int]

  SueOption = object
    case flag: SueFlags
    of soText:
      text: string

    of soOrigin:
      position: SuePoint

    of soName:
      name: string

    of soType:
      portType: SuePorts

    of soSize:
      size: SueSize

    of soLabel:
      label: string

    of soOrient:
      # orient: seq[Orientation]
      discard # TODO

    of soAnchor:
      anchor: string

    of soRotate:
      rotation: int

    of soStart, soExtent:
      degree: int

  SueExperssion = object
    case command: SueCommands
    of scMake:
      ident: string

    of scMakeWire, scIconArc:
      head, tail: SuePoint

    of scIconSetup:
      discard # TODO

    of scIconTerm, scIconProperty, scMakeText:
      discard

    of scIconLine:
      points: seq[SuePoint]

    options: seq[SueOption]

  SueFile = object
    schematic, icon: seq[SueExperssion]


template err(msg: string): untyped =
  raise newException(ValueError, msg)

template impossible: untyped =
  err "impossible"


func hasLetter(s: string): bool =
  for ch in s:
    if ch in Letters:
      return true


template findGoImpl(s, pat, i, after): untyped {.dirty.} =
  let m = s.match(pat, i)
  assert issome m, "cannot match"

  i = m.get.matchBounds.b + 1 + after

func findGo(s: string, pat: Regex, i: var int, after = 1): string =
  findGoImpl s, pat, i, after
  m.get.captures[0]

func findGoMulti(s: string, pat: Regex, i: var int, after = 1): seq[string] =
  findGoImpl s, pat, i, after
  for s in m.get.captures:
    result.add s.get


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
  initObjConstrConventionImpl bindsym"SueExperssion", t, c, args


func foldPoints(nums: seq[int]): seq[SuePoint] =
  for i in countup(0, nums.high, 2):
    result.add (nums[i], nums[i+1])

func removebraces(s: string): string {.inline.} =
  s.strip(chars = {'{', '}'})


# loc: line of code
proc matchProcLine(loc: string): SueExperssion =
  var i = 0
  let cmd = loc.findGo(re"(\w+)", i).parseEnum[:SueCommands]

  result = case cmd: # parse params
    of scMake:
      let moduleName = loc.findGo(re"(\w+)", i)
      cmd.initSueExpr(ident, moduleName)

    of scMakeWire, scIconArc:
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
      let args = loc.substr(i+1).split.mapit(parseInt it)
      i = loc.high

      cmd.initSueExpr(points, foldPoints(args))

  while i < loc.high: # parse options
    let flag = loc.findgo(re"-(\w+)", i).parseEnum[:SueFlags]

    result.options.add:
      case flag:
      of soOrigin:
        let p = loc
          .findGoMulti(re"\{(-?\d+) (-?\d+)\}", i)
          .mapit(parseInt it)
          .toTuple(2)

        flag.initSueOption(position, p)

      of soText:
        let t = loc.findGo(re"(\{.*?\}|[^ ]+)", i).removebraces
        flag.initSueOption(text, t)

      of soStart, soExtent:
        let n = loc.findGo(re"(-?\d+)", i).parseInt
        flag.initSueOption(degree, n)

      of soOrient, soName, soType, soSize, soAnchor, soLabel, soRotate:
        let s = loc.findGo(re"(\w+|\{.*?\})", i).removebraces

        case flag:
        of soOrient: flag.initSueOption()
        of soName: flag.initSueOption(name, s)
        of soType: flag.initSueOption(portType, parseEnum[SuePorts](s))
        of soSize: flag.initSueOption(size, parseEnum[SueSize](s))
        of soAnchor: flag.initSueOption(anchor, s)
        of soLabel: flag.initSueOption(label, s)
        of soRotate: flag.initSueOption()
        else: impossible


import print

when isMainModule:
  var pstate = psModule

  for loc in lines "./examples/eg1.sue":

    if (not hasLetter loc) or (loc.startsWith '#'): # empty line or comment
      discard

    elif loc.startsWith '}': # end of proc body
      pstate = psModule

    elif loc.startsWith "proc": # proc def
      let
        res = loc.find(re"([a-zA-Z]+)_", "proc ".len).get
        prefix = res.captures[0]

      pstate = case prefix:
        of "SCHEMATIC": psSchematic
        of "ICON": psIcon
        else: err "invalid proc name"

    elif pstate != psModule:
      let expr = matchProcLine loc.substr 2
      print expr

    else:
      err fmt"cannot happen: {loc}"
