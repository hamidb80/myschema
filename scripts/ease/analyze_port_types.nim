import std/[os, sets, strutils, tables]
import ../../src/ease/[lisp, parser]
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

func safeIncl[K, V](container: var Table[K, HashSet[V]], key: K, val: V) =
  if key notin container:
    container[key] = initHashSet[V]()

  container[key].incl val

# -----------------------------------

const dir = r"C:\ProgramData\HDL Works\Ease80Rev4\ease\examples"

var
  uniqPortTypes: HashSet[string]
  uniqIdentsByParent: Table[string, HashSet[string]]
  uniqIdentsByNode: Table[string, HashSet[string]]

proc goFind(node: LispNode, path: Path) =
  if path.endsWith(@["PORT", "HDL_IDENT"]) and node.matchCaller("ATTRIBUTES"):
    var
      `type` = ""
      hasRange = false

    for a in node.args:
      if a.matchCaller "TYPE":
        `type` = $a
      elif a.matchCaller "CONSTRAINT":
        hasRange = true

    if hasRange and not `type`.isEmptyOrWhitespace:
      uniqPortTypes.incl `type`

  let
    parent = path[^1]
    value = case node.kind:
      of lnkList: node.ident
      of lnkInt: "<INT_VALUE>"
      of lnkString: "<STR_VALUE>"
      else: "<..>"

  uniqIdentsByParent.safeIncl parent, value
  uniqIdentsByNode.safeIncl value, parent

  if node.kind == lnkList:
    for s in node.args:
      goFind s, path & node.ident


# ----------------------------------

when isMainModule:
  for path in walkDirRec dir:
    if path.endsWith(".eas") and "ease.db" in path:
      # echo ">> ", path
      let ctx = select parseLisp readfile path
      goFind ctx, @["/"]

  print uniqPortTypes
  print uniqIdentsByParent
  print uniqIdentsByNode
