import std/[tables, os, strformat, strutils, sequtils, options]
import ../common/[errors, coordination, tuples, domain]
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
    fnsize: size)


func parseSchematic(se: seq[SueExpression]): Schematic =
  result = new Schematic

  for expr in se:
    case expr.command:
    of scMakeLine: discard

    of scMakeText:
      result.labels.add parseMakeText expr

    of scMakeWire:
      let w = parseWire expr
      # TODO result.nets.add

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
