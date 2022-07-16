import std/[os, sets, strutils]
import ../../src/ease/lisp
import print

# ----------------------------------

type Path = seq[string]

const dir = r"C:\ProgramData\HDL Works\Ease80Rev4\ease\examples"

var uniqPortTypes: HashSet[string]

# ----------------------------------

func endsWith(s, suffix: seq[string]): bool =
  if suffix.len > s.len:
    false
  else:
    for i in 1 .. suffix.len:
      if s[^i] != suffix[^i]:
        return false

    true

proc traverse(s: seq[LispNode], path: Path)

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


  elif node.kind == lnkList:
    traverse node.args, path & node.ident.name

proc traverse(s: seq[LispNode], path: Path) =
  for node in s:
    traverse node, path

# ----------------------------------

when isMainModule:
  for path in walkDirRec dir:
    if path.endsWith(".eas"):
      traverse parseLisp readfile path, @[]

  print uniqPortTypes
