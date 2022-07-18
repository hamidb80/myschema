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

# -----------------------------------

const dir = r"C:\ProgramData\HDL Works\Ease80Rev4\ease\examples"

var
  uniqPortTypes: HashSet[string]
  uniqIdents: Table[string, HashSet[string]]

proc traverse(node: LispNode, path: Path) =
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

  block:
    let parent = path[^1]

    if parent notin uniqIdents:
      uniqIdents[parent] = initHashSet[string]()

    uniqIdents[parent].incl:
      if node.kind == lnkList: node.ident
      else: "<VALUE>"

  if node.kind == lnkList:
    for s in node.args:
      traverse s, path & node.ident


# ----------------------------------

when isMainModule:
  for path in walkDirRec dir:
    if path.endsWith(".eas") and "ease.db" in path:
      # echo ">> ", path
      let ctx = select parseLisp readfile path
      traverse ctx, @["/"]

  print uniqPortTypes
  print uniqIdents
