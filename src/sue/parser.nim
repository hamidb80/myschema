import std/[tables, os, strformat, strutils, sequtils, options]
import ../common/[errors, coordination, tuples]
import lexer, model


# -- options

func parsePortType*(s: string): PortDir =
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

  else: fzMedium

func getAnchor(expr: SueExpression): Anchor =
  let tk = expr.find(sfAnchor)
  if issome tk:
    let str = tk.get.strval
    case str:
    of "c": c
    of "s": s
    of "w": w
    of "e": e
    of "n": n
    of "sw": sw
    of "se": se
    of "nw": nw
    of "ne": ne
    else: err fmt"invalid '-anchor' value: {str}"
  else: c

func moduleRef(name: string): Module = 
   Module(name: name, kind: mkRef)

func parseMake*(expr: SueExpression): Instance =
  let
    parent = expr.args[0].strVal
    name = expr[sfName].strval
    origin = getOrigin expr
    orient = getOrient expr

  Instance(name: name,
    parent: moduleRef parent,
    location: origin,
    orient: orient)

func parseWire*(expr: SueExpression): Wire =
  let s = expr.args.mapIt it.intval
  (s[0], s[1]) .. (s[2], s[3])

func parseMakeText*(expr: SueExpression): Label =
  let
    content = expr[sfText].strval
    origin = getOrigin expr
    rotated = getRotate expr
    size = getSize expr
    anchor = getAnchor expr

  Label(content: content,
    location: origin,
    anchor: anchor,
    size: size)

# -- groups

func parseSchematic(se: seq[SueExpression]): Schematic =
  result = new Schematic

  for expr in se:
    case expr.command:
    of scMake:
      result.instances.add parseMake expr

    of scMakeWire:
      result.wires.add parseWire expr

    of scMakeText:
      result.texts.add parseMakeText expr

    of scMakeLine: discard
    of scGenerate: err "'generate' is not implemented"
    else:
      err fmt"invalid command in schematic: {expr.command}"

func parseIcon(se: seq[SueExpression]): Icon =
  result = new Icon

  for expr in se:
    case expr.command:
    of scIconSetup, scIconProperty, scIconLine, scIconArc: discard

    of scIconTerm:
      result.ports.add Port(
        name: expr[sfName].strval,
        kind: parsePortType expr[sfType].strval,
        location: parseOrigin expr[sfOrigin].strval)

    else:
      err fmt"invalid command in icon: {expr.command}"

func resolve(proj: var Project) =
  # resolve module instances
  for _, m in mpairs proj.modules:
    for ins in mitems m.schema.instances:
      ins.parent = proj.modules[ins.parent.name]


import print
proc parseSueProject*(mainDir: string, lookupDirs: seq[string]): Project =
  result = Project(modules: ModuleLookUp())

  template walkSue(dir): untyped {.dirty.} =
    for path in walkFiles dir / "*.sue":
      let sf = lexSue readFile path
      result.modules[sf.name] = Module(
        name: sf.name, 
        kind: mkCtx,
        icon: parseIcon(sf.icon),
        schema: parseSchematic(sf.schematic))

  walkSue mainDir

  for d in lookupDirs:
    walkSue d

  resolve result
