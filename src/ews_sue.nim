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

  SueFile = object
    schematic: int
    icon: int

  SuePoint = tuple[x, y: int]

  SueOptions = enum
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
    ssSmall, ssLarge

  SueOption = object
    case flag: SueOptions
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

    of scMakeText:
      text: string

    of scIconSetup:
      discard # TODO

    of scIconTerm, scIconProperty:
      discard

    of scIconLine:
      points: seq[SuePoint]

    options: seq[SueOption]



template err(msg: string): untyped =
  raise newException(ValueError, msg)

func hasLetter(s: string): bool =
  for ch in s:
    if ch in Letters:
      return true


template findGoImpl(s, pat, i): untyped {.dirty.} =
  let m = s.match(pat, i)
  assert issome m, "cannot match"

  i = m.get.matchBounds.b + 1

func findGo(s: string, pat: Regex, i: var int): string =
  findGoImpl s, pat, i
  m.get.captures[0]

func findGoMulti(s: string, pat: Regex, i: var int): seq[string] =
  findGoImpl s, pat, i
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


# loc: line of code
proc matchProcLine(loc: string) =
  var i = 0
  let command = loc.findGo(re"(\w+) ", i)

  # --- parse params ---

  case parseEnum[SueCommands](command):
    of scMake:
      let moduleName = loc.findGo(re"(\w+) ", i)

    of scMakeWire, scIconArc:
      let (x1, y1, x2, y2) = loc
        .findGoMulti(re"(-?\d+) (-?\d+) (-?\d+) (-?\d+)", i)
        .mapit(parseInt it)
        .toTuple(4)

    of scMakeText:
      discard

    of scIconSetup:
      discard

    of scIconTerm:
      discard

    of scIconProperty:
      discard

    of scIconLine:
      let args = loc.substr(i+1).split.mapit(parseInt it)
      i = loc.high

  # --- parse options ---

  var tempOption: SueOption

  while i < loc.high:
    let flag =
      try: loc.findgo(re"-(\w+) ", i)
      except: break

    # echo "<< ", flag

    case parseEnum[SueOptions](flag):
      of soOrigin:
        let (x, y) = loc
          .findGoMulti(re"\{(-?\d+) (-?\d+)\}", i)
          .mapit(parseInt it)
          .toTuple(2)

      of soOrient, soName, soType, soSize, soAnchor, soLabel, soRotate:
        discard loc.findGo(re"(\w+|\{.*\}) ?", i)

      of soText:
        discard loc.findGo(re"(\{.*\}|[^ ]+) ?", i)

      of soStart, soExtent:
        let degree = loc.findGo(re"(-?\d+) ?", i)


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
      matchProcLine loc.substr 2

    else:
      err fmt"cannot happen: {loc}"
