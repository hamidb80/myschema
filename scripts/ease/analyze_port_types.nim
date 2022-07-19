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

func safeIncl[K, V](container: var Table[K, HashSet[V]], key: K, val: V) =
  if key notin container:
    container[key] = initHashSet[V]()

  container[key].incl val

template jump: untyped =
  raise newException(ValueError, "JUMP!")

# -----------------------------------

const dir = r"C:\ProgramData\HDL Works\Ease80Rev4\ease\examples"

var
  uniqPortTypes: HashSet[string]
  uniqIdentsByParent: Table[string, HashSet[string]]
  uniqIdentsByNode: Table[string, HashSet[string]]
  lastPath: string


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

  # if parent == "PROCESS" and node.ident == "PORT":
  #   echo ">> ", lastPath
  #   jump()

  if node.kind == lnkList:
    for s in node.args:
      let id = case node.ident:
        of "PORT":
          let sub = node.findNode(it.matchCaller "OBID")

          if issome sub:
            "PORT" & '#' & sub.get.parseOBID[0..<4]
          else:
            "PORT"

        else: node.ident

      goFind s, path & id



# ----------------------------------

when isMainModule:
  for path in walkDirRec dir:
    if path.endsWith(".eas") and "ease.db" in path:
      lastPath = path
      let ctx = select parseLisp readfile path
      goFind ctx, @["/"]

  print uniqPortTypes
  print uniqIdentsByParent
  print uniqIdentsByNode