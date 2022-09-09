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
    size: size)


func parseSchematic(se: seq[SueExpression]): SSchematic =
  result = new SSchematic

  for expr in se:
    case expr.command:
    of scMake:
      result.instances.add parseMake expr

    of scMakeWire:
      result.wires.add parseWire expr

    of scMakeText:
      result.labels.add parseMakeText expr

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


proc parseSueProject*(mainDir: string, lookupDirs: seq[string]): Project =
  result = Project(modules: ModuleLookUp())

  template walkSue(dir): untyped {.dirty.} =
    for path in walkFiles dir / "*.sue":
      let sf = lexSue readFile path
      result.modules[sf.name] = Module(
        name: sf.name,
        kind: mkCtx,
        icon: parseIcon(sf.icon),
        arch: toArch parseSchematic(sf.schematic))

  walkSue mainDir

  for d in lookupDirs:
    walkSue d
