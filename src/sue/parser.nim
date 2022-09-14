import std/[tables, sets, os, strformat, strutils, sequtils, options]
import ../common/[errors, coordination, collections, domain, graph, seqtable, rand]
import lexer, model, logic


func parsePortType*(s: string): PortDir =
  case s:
  of "input": pdInput
  of "output": pdOutput
  of "inout": pdInout
  else: err fmt"not a port type: {s}"

func parseOrient(s: string): Orient =
  parseEnum[Orient](s)

func parseOrigin*(s: string): Point =
  s.split(" ").map(parseInt).toTuple(2)

func getOrigin(expr: SueExpression): Point =
  parseOrigin expr[sfOrigin].strval

func getOrient(expr: SueExpression): Orient =
  let tk = expr.find(sfOrient)

  if issome tk:
    parseOrient tk.get.strval
  else:
    default Orient

# func getRotate(expr: SueExpression): bool =
#   let tk = expr.find(sfRotate)

#   if issome tk: tk.get.intval == 1
#   else: false

func getSize(expr: SueExpression): FontSize =
  let tk = expr.find(sfSize)

  if issome tk:
    parseEnum[FontSize](tk.get.strval)
  else:
    fzStandard

func getAnchor(expr: SueExpression): Anchor =
  let tk = expr.find(sfAnchor)
  if issome tk:
    let str = tk.get.strval
    case str:
    of "c", "center": c
    of "s": s
    of "w": w
    of "e": e
    of "n": n
    of "sw": sw
    of "se": se
    of "nw": nw
    of "ne": ne
    else: err fmt"invalid '-anchor' value: {str}"
  else: w

func moduleRef(name: string): Module =
  Module(name: name, kind: mkRef)

proc parseMake*(expr: SueExpression): Instance =
  let
    p = expr.args[0].strVal
    n =
      try: 
        expr[sfName].strval
      except ValueError:
        randomIdent(10)

    l = getOrigin expr
    o = getOrient expr

  Instance(name: n, module: moduleRef p, location: l, orient: o)

func parseWire*(expr: SueExpression): Wire =
  let v = expr.args.mapIt it.intval
  (v[0], v[1]) .. (v[2], v[3])

func parseMakeText*(expr: SueExpression): Label =
  let
    c = expr[sfText].strval
    o = getOrigin expr
    # r = getRotate expr
    s = getSize expr
    a = getAnchor expr

  Label(content: c, location: o, anchor: a, fnsize: s)

func incl(nets: var Graph[Point], w: Wire) =
  nets.incl w.a, w.b

proc parseSchematic(se: seq[SueExpression]): Schematic =
  result = new Schematic

  for expr in se:
    case expr.command:
    of scMakeLine: discard

    of scMakeText:
      result.labels.add parseMakeText expr

    of scMakeWire:
      result.wireNets.incl parseWire expr

    of scMake:
      result.instances.add parseMake expr

    # of scGenerate: err "'generate' is not implemented yet"
    else:
      err fmt"invalid command in schematic: {expr.command}"

func foldPoints(xyValues: seq[int]): seq[Point] =
  for i in countup(0, xyValues.high, 2):
    result.add (i, i+1)

func parseIcon(se: seq[SueExpression]): Icon =
  result = new Icon

  for expr in se:
    case expr.command:
    of scIconSetup, scIconProperty, scIconArc: discard

    of scIconLine:
      result.lines.add Line(
        kind: straight,
        points: foldPoints mapIt(expr.args, it.intval))

    of scIconTerm:
      result.ports.add Port(
        kind: pkIconTerm,
        name: expr[sfName].strval,
        dir: parsePortType expr[sfType].strval,
        relativeLocation: parseOrigin expr[sfOrigin].strval)

    else:
      err fmt"invalid command in icon: {expr.command}"

proc parseSue*(sfile: SueFile): Module =
  Module(
    name: sfile.name,
    kind: mkCtx,
    icon: parseIcon sfile.icon,
    schema: parseSchematic sfile.schematic)
    # paramters: ) # TODO

proc parseSueProject*(mainDir: string, lookupDirs: seq[string]): Project =
  result = Project(modules: ModuleLookUp())

  template walkSue(dir): untyped {.dirty.} =
    for path in walkFiles dir / "*.sue":
      let m = parseSue lexSue readFile path
      result.modules[m.name] = m

  walkSue mainDir
  for d in lookupDirs:
    walkSue d

  resolve result
