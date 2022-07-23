import std/[tables, os, strformat, strutils, sequtils, options]
import ../common/[errors, minmax, defs, tuples]
import lexer, model


# -- options

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
  (s[1 .. fi], s.substr fi+1)

func parseOrient(s: string): Orient =
  let t = splitOrient s
  Orient(
    rotation: parseRotation t[0],
    flips: parseFlip t[1])

func parseOrigin*(s: string): Point =
  s.split(" ").map(parseInt).toTuple(2)

# -- experssions

func getOrigin(expr: SueExpression): Point =
  parseOrigin expr[sfOrigin].strval

func getOrient(expr: SueExpression): Orient =
  let tk = expr.find(sfOrigin)

  if issome tk:
    parseOrient tk.get.strval
  else:
    default Orient

func getRotate(expr: SueExpression): bool =
  let tk = expr.find(sfRotate)

  if issome tk: tk.get.intval == 1
  else: false

func getSize(expr: SueExpression): FontSize = 
  let tk = expr.find(sfSize)

  if issome tk: 
    let s = tk.get.strval
    case s:
    of "small": fzSmall
    of "large": fzLarge
    else: err fmt"invalid '-side' value: {s}"
  
  else: 
    fzMedium
  
func getAnchor(expr: SueExpression): Anchor = 
  discard

func parseMake(expr: SueExpression, lookup: LookUp): Instance =
  let
    parent = expr.args[0].strVal
    name = expr[sfName].strval
    origin = getOrigin expr
    orient = getOrient expr

  Instance(name: name,
    parent: lookup[parent],
    location: origin,
    orient: orient)

func parseWire(expr: SueExpression): Wire =
  let s = expr.args.mapIt it.intval
  (s[0], s[1]) .. (s[2], s[3])

func parseMakeText(expr: SueExpression): Label =
  let
    content = expr[sfText].strval
    origin = getOrigin expr
    rotated = getRotate expr
    size = getSize expr
    anchor = getAnchor expr

  # TODO
  Label()

# -- groups
# TODO: add stdlib icons

func resolveSchematic(sf: seq[SueExpression], lookup: LookUp): Schematic =
  result = new Schematic

  for expr in sf:
    case expr.command:
    of scMake:
      result.instances.add parseMake(expr, lookup)

    of scMakeWire:
      result.wires.add parseWire expr

    of scMakeText:
      result.texts.add parseMakeText expr

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

  result.bounds = Bounds(
    x1: xs.min, x2: xs.max,
    y1: ys.min, y2: ys.max)

proc parseProject*(mainDir: string, lookupDirs: seq[string]): Project =
  result = Project(lookup: new LookUp)

  template walkSue(dir, body): untyped {.dirty.} =
    for path in walkFiles dir / "*.sue":
      let
        sf = lexSue path
        m = Module(name: sf.name, icon: resolveIcon sf.icon)

      body


  var mainModules: seq[tuple[module: Module, file: SueFile]]

  walkSue mainDir:
    mainModules.add (m, sf)
    result.lookup[sf.name] = m

  for d in lookupDirs:
    walkSue d:
      result.lookup[sf.name] = m

  for (m, sf) in mainModules:
    m.schematic = resolveSchematic(sf.schematic, result.lookup)
