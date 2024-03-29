import std/[tables, os, strformat, strutils, sequtils, options, sugar]
import ../common/[errors, coordination, collections, domain, graph, rand, path, minitable]
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

proc parseMake*(expr: SueExpression): Instance =
  let
    p = expr.args[0].strVal
    n =
      try: expr[sfName].strval
      except ValueError: randomIdent(10)

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
    r = getRotate expr
    s = getSize expr
    a = getAnchor expr

  Label(content: c, location: o, anchor: a, fnsize: s)

func incl(nets: var Graph[Point], w: Wire) =
  nets.incl w.a, w.b

proc parseSchematic(se: seq[SueExpression]): Schematic =
  result = new Schematic

  for expr in se:
    case expr.command:
    of scMakeLine:
      result.lines.add Line(
        kind: straight,
        points: foldPoints expr.args.mapIt it.intval)

    of scMakeText:
      result.labels.add parseMakeText expr

    of scMakeWire:
      result.wiredNodes.incl parseWire expr

    of scMake:
      result.instances.add parseMake expr

    # of scGenerate: err "'generate' is not implemented yet"
    else:
      err fmt"invalid command in schematic: {expr.command}"

func parseIcon(se: seq[SueExpression]): Icon =
  result = new Icon

  for expr in se:
    case expr.command:
    of scIconSetup:
      assert expr.args[0] == "$args"
      result.params["origin"] = some "{0 0}"
      result.params["orient"] = some "R0"
      result.params["name"] = some "{}"
      # FIXME use a tested TCL parser

    of scIconProperty, scIconArc: discard

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


const basicModulesContent = collect:
  for _, path in walkDir projectPath() / "elements":
    readfile path

proc loadBasicModules*: ModuleLookUp =
  collect:
    for c in basicModulesContent:
      let
        f = lexSue c
        s = parseSue f

      s.isTemp = true
      {f.name: s}


proc parseSueProject*(mainDir: string, lookupDirs: seq[string]): Project =
  result = Project(modules: loadBasicModules())

  template walkSue(dir): untyped {.dirty.} =
    for path in walkFiles dir / "*.sue":
      let m = parseSue lexSue readFile path
      result.modules[m.name] = m

  walkSue mainDir
  for d in lookupDirs:
    walkSue d

  resolve result

proc parseSueProject*(paths: seq[string]): Project =
  ## parse custom files, mainly created for testing purposes

  result = Project(modules: loadBasicModules())

  for path in paths:
    let m = parseSue lexSue readFile path
    result.modules[m.name] = m

  resolve result
