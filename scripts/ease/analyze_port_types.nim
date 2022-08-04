import std/[os, sets, strutils, tables, options]
import ../../src/ease/lisp
import ../../src/ease/parser {.all.}
import print

# ----------------------------------

type Path = seq[string]

func endsWith(s, suffix: seq[string]): bool =
  if suffix.len > s.len:
    false
  else:
    for i in 1 .. suffix.len:
      if s[^i] != suffix[^i]:
        return false

    true

func incl[K, V](container: var Table[K, HashSet[V]], key: K, val: V) =
  if key notin container:
    container[key] = initHashSet[V]()

  container[key].incl val

template jump: untyped =
  raise newException(ValueError, "JUMP!")

# -----------------------------------

const dir = r"C:\ProgramData\HDL Works\Ease80Rev4\ease\examples"

var
  uniqPortTypes: HashSet[string]
  uniqIdentsRepeat: Table[string, tuple[fields: CountTable[string], total: int]]
  uniqIdentParent: Table[string, HashSet[string]]
  actvals: HashSet[string]
  lastPath: string

func newId(node: LispNode): string =
  case node.ident:
  of "PORT":
    let sub = node.findNode(it.matchCaller "OBID")

    if issome sub:
      "PORT" & '#' & sub.get.parseOBID.string[0..<4]
    else:
      "PORT"

  else:
    node.ident


proc goFind(node: LispNode, path: Path) =
  if path.endsWith(@["PORT", "HDL_IDENT"]) and node.matchCaller("ATTRIBUTES"):
    var
      `type` = ""
      hasSlice = false

    for a in node.args:
      if a.matchCaller "TYPE":
        `type` = dump a
      elif a.matchCaller "CONSTRAINT":
        hasSlice = true

    if hasSlice and not `type`.isEmptyOrWhitespace:
      uniqPortTypes.incL `type`

  let
    parent = path[^1]
    value = case node.kind:
      of lnkList: node.ident
      of lnkInt: "<INT_VALUE>"
      of lnkString: "<STR_VALUE>"
      else: "<..>"

  uniqIdentParent.incl value, parent

  if parent notin uniqIdentsRepeat:
    uniqIdentsRepeat[parent] = (initCountTable[string](), 0)

  uniqIdentsRepeat[parent].fields.inc value

  if value notin uniqIdentsRepeat:
    uniqIdentsRepeat[value] = (initCountTable[string](), 0)

  uniqIdentsRepeat[value].total.inc


  if node.kind == lnkList:
    if node.ident == "ACT_VALUE":
      actvals.incl node.arg(0).str

    for s in node:
      let id = newId node
      goFind s, path & id



# ----------------------------------

when isMainModule:
  for path in walkDirRec dir:
    if path.endsWith(".eas") and "ease.db" in path:
      lastPath = path
      let ctx = select parseLisp readfile path
      goFind ctx, @["/"]

  echo uniqIdentsRepeat["GENERIC"]
  print uniqIdentParent["GENERIC"]
  print actvals
