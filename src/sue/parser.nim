import std/[tables, os, strformat, strutils, sequtils, options]
import ../common/[errors, coordination, tuples, domain, graph]
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

func parseMake*(expr: SueExpression): Instance =
  let
    p = expr.args[0].strVal
    n = expr[sfName].strval
    l = getOrigin expr
    o = getOrient expr

  Instance(name: n, parent: moduleRef p, location: l, orient: o)

func parseWire*(expr: SueExpression): Wire =
  let v = expr.args.mapIt it.intval
  (v[0], v[1]) .. (v[2], v[3])

func parseMakeText*(expr: SueExpression): Label =
  let
    c = expr[sfText].strval
    o = getOrigin expr
    r = getRotate expr
    s = getSize expr
    a = getAnchor expr

  Label(content: c, location: o, anchor: a, fnsize: s)

func add(nets: var Graph[Point], w: Wire) =
  nets.addBoth w.a, w.b

func parseSchematic(se: seq[SueExpression]): Schematic =
  result = new Schematic

  for expr in se:
    case expr.command:
    of scMakeLine: discard

    of scMakeText:
      result.labels.add parseMakeText expr

    of scMakeWire:
      result.nets.add parseWire expr

    of scMake:
      result.instances.add parseMake expr

    # of scGenerate: err "'generate' is not implemented yet"
    else:
      err fmt"invalid command in schematic: {expr.command}"

func parseIcon(se: seq[SueExpression]): Icon =
  result = new Icon

  for expr in se:
    case expr.command:
    of scIconSetup, scIconProperty, scIconLine, scIconArc: discard

    of scIconTerm:
      result.ports.add Port(
        kind: pkIconTerm,
        name: expr[sfName].strval,
        dir: parsePortType expr[sfType].strval,
        location: parseOrigin expr[sfOrigin].strval)

    else:
      err fmt"invalid command in icon: {expr.command}"

proc parseSue(sfile: SueFile): Module =
  Module(
    name: sfile.name,
    kind: mkCtx,
    icon: parseIcon sfile.icon,
    schema: parseSchematic sfile.schematic)


func instantiate(o: Port, p: Instance): Port =
  Port(kind: pkInstance, parent: p, origin: o)

type Transfrom = proc(p: Point): Point {.noSideEffect.}

func genTransformer(geo: Geometry, pin: Point, o: Orient): Transfrom =
  let
    r = o.rotation
    f = o.flips
    rotatedGeo = rotate(geo, pin, r)
    vec = pin - topleft geo
    finalGeo = rotatedGeo.placeAt pin
    c = center finalGeo

  return func(p: Point): Point =
    (rotate(p, pin, r) + vec).flip(c, f)


func resolve*(proj: var Project) =
  ## add meta data for instances, resolve modules
  for _, module in mpairs proj.modules:
    for ins in mitems module.schema.instances:
      let mref = proj.modules[ins.parent.name]
      ins.parent = mref

      let t = genTransformer(
        mref.icon.size.toGeometry,
        ins.location,
        ins.orient)

      for p in mref.icon.ports:
        let loc = t(p.location + ins.location)
        ins.ports[loc] = instantiate(p, ins)

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
