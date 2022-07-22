import std/[tables, os, strformat, sequtils]
import ../common/[errors, minmax]
import lexer, model


func parsePortType(s: string): PortDir =
  case s:
  of "input": input
  of "output": output
  of "inout": inout
  else: err fmt"not a port type: {s}"


func parseFlip(s: string): set[Flip] =
  for c in s:
    result.incl case c:
      of 'X': X
      of 'Y': Y
      else: err fmt"invalid flip axis: {c}"

func parseRotation(s: string): Rotation =
  case s:
  of "": r0
  of "90": r90
  of "180": r180
  of "270": r270
  else: err fmt"invalid rotation degree: {s}"

func flipIndex(s: string): Natural =
  for c in s:
    case c:
    of 'R': discard
    of '0' .. '9': inc result
    of 'X', 'Y': break
    else: err fmt"invalid '-orient' token: {c}"

func splitOrient(s: string): tuple[rotation, flips: string] =
  let fi = flipIndex s
  if fi == 0:
    ("", s.substr 1)
  else:
    (s[1 .. fi], s.substr fi+1)

func parseOrient(s: string): Orient =
  let t = splitOrient s
  Orient(
    rotation: parseRotation t[0],
    flips: parseFlip t[1])


func resolveSchematic(sf: seq[SueExpression],
  lookup: Table[string, Icon]): Schematic =

  result = new Schematic

  for expr in sf:
    case expr.command:
    of scMake:
      let
        parent = expr.args[0].strVal
        name = expr[sfName].strval
        orient = parseOrient expr[sfOrigin].strval

    of scMakeWire:
      let
        s = expr.args.mapIt it.intval
        w = (s[0], s[1]) .. (s[2], s[3])

    of scMakeText:
      # -text
      # -origin
      # -rotate
      # -size
      # -anchor
      discard

    of scMakeLine: discard
    of scGenerate: err "'generate' is not implemented"
    else:
      err fmt"invalid command in schematic: {expr.command}"

func resolveIcon(sf: seq[SueExpression]): Icon =
  result = new Icon

  var
    xs: MinMax[int]
    ys: MinMax[int]


  for expr in sf:
    case expr.command:
    of scIconSetup, scIconProperty, scIconLine, scIconArc: discard

    of scIconTerm:
      let p = Port(
        name: expr[sfName].strval,
        kind: parsePortType expr[sfType].strval,
        location: parseOrigin expr[sfOrigin].strval)

      xs.update(p.location.x)
      ys.update(p.location.y)
      result.ports.add p

    else:
      err fmt"invalid command in icon: {expr.command}"

  result.geometry = Rect(
    x: xs.min, y: ys.min,
    w: xs.len, h: ys.len)

proc parseProject*(mainDir: string, lookupDirs: seq[string]): Project =
  result = new Project

  template walkSue(dir, body): untyped {.dirty.} =
    for path in walkFiles dir / "*.sue":
      let sueFile = lexSue path

      body


  var mainFiles: seq[SueFile]

  walkSue mainDir:
    result.icons[sueFile.name] = resolveIcon sueFile.icon
    mainFIles.add sueFile

  for d in lookupDirs:
    walkSue d:
      result.icons[sueFile.name] = resolveIcon sueFile.icon

  for sf in mainFiles:
    result.modules.add Module(name: sf.name,
      schematic: resolveSchematic(sf.schematic, result.icons))
