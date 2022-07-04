import std/[strutils, nre, strformat, options, sequtils, macros]

type
  ParserState = enum
    psModule, psSchematic, psIcon

template err(msg: string): untyped =
  raise newException(ValueError, msg)

func hasLetter(s: string): bool =
  for ch in s:
    if ch in Letters:
      return true

template findGoImpl(s, pat, i): untyped {.dirty.} =
  let m = s.find(pat, i)
  assert issome m, "cannot match"

  i = m.get.matchBounds.b

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

  # --- parse params

  case command:
  of "make":
    let moduleName = loc.findGo(re"(\w+) ", i)

  of "make_wire":
    let (x1, y1, x2, y2) = loc
      .findGoMulti(re"(-?\d+) (-?\d+) (-?\d+) (-?\d+)", i)
      .mapit(parseInt it)
      .toTuple(4)

  of "make_text":
    discard

  # of "icon_setup":
  #   discard

  # of "icon_term":
  #   discard

  # of "icon_property":
  #   discard

  of "icon_line":
    let args = loc.substr(i+1).split.mapit(parseInt it)
    echo args
    i = loc.high

  # of "icon_arc":
  #   discard

  else:
    discard
    # err fmt"undefined command: {command}"

  # parse options

  while i < loc.high:
    let flag =
      try: loc.findgo(re"-(\w+) ", i)
      except: break

    # echo flag

    case flag:
    of "origin":
      let (x, y) = loc
        .findGoMulti(re"\{(-?\d+) (-?\d+)\}", i)
        .mapit(parseInt it)
        .toTuple(2)

      echo (x, y)

    of "orient":
      discard

    of "name", "type", "size", "anchor", "label", "rotate":
      echo loc.findGo(re"(\w+)", i)

    of "text":
      echo loc.findGo(re"(\{.*\}|[^ ]+)", i)

    else:
      err fmt"invalid flag: {flag}"

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
