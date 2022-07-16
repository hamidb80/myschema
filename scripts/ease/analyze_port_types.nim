import std/[os, sets, strutils]
import ../../src/ease/lisp
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
  uniqElements: HashSet[string]
  uniqIdents: HashSet[string]

proc traverse1(s: seq[LispNode], path: Path)

proc traverse1(node: LispNode, path: Path) =
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


  elif node.kind == lnkList:
    traverse1 node.args, path & node.ident.name

proc traverse1(s: seq[LispNode], path: Path) =
  for node in s:
    traverse1 node, path


proc traverse2(s: seq[LispNode], path: Path)

proc traverse2(node: LispNode, path: Path) =
  if path.endsWith(@["SCHEMATIC"]):
    uniqElements.incl:
      if node.kind == lnkList: node.ident.name
      else: $node

  elif node.kind == lnkList:
    traverse2 node.args, path & node.ident.name

proc traverse2(s: seq[LispNode], path: Path) =
  for node in s:
    traverse2 node, path


proc traverse3(s: seq[LispNode])

proc traverse3(node: LispNode) =
  case node.kind:
  of lnkList:
    uniqIdents.incl node.ident.name
    traverse3 node.args

  else: discard

proc traverse3(s: seq[LispNode]) =
  for node in s:
    traverse3 node

# ----------------------------------

when isMainModule:
  for path in walkDirRec dir:
    if path.endsWith(".eas"):
      let ctx = parseLisp readfile path
      traverse1 ctx, @[]
      traverse2 ctx, @[]
      traverse3 ctx

  print uniqPortTypes
  print uniqElements
  print uniqIdents
