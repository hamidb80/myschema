import std/[tables, sequtils, strutils, strformat, options]

import ../common/[coordination, seqs, minitable, domain, graph]

import model as sm
import ../middle/model as mm

import logic
import ../middle/logic as ml

import ../middle/expr


func toMiddleModel*(sch: sm.SSchematic): mm.MSchematic =
  mm.MSchematic(
    nets: toNets sch.wires)

func toMiddleModel*(ico: sm.Icon): mm.MIcon =
  discard

func toMiddleModel*(mo: sm.Module): MElement =
  MElement(name: mo.name)

func toMiddleModel*(proj: sm.Project): mm.MProject =
  result = new mm.MProject

  for name, sueModule in proj.modules:
    result.modules[name] = toMiddleModel sueModule

# ------------------------------- middle model -> sue model

func toSue(pd: MPortDir): PortDir =
  case pd:
  of mpdInput: pdInput
  of mpdOutput: pdOutput
  of mpdInout: pdInout

func toSue(gt: MTokenGroup): string =
  for t in gt:
    result.add:
      case t.kind:
      of mtkSymbol: '$' & $t
      else: $t

func toSue(tr: MTransform): Orient =
  Orient(rotation: tr.rotation, flips: tr.flips)

func toSue(a: MArg): Argument =
  Argument(name: a.parameter.name, value: toSue a.value.get)

func toLine(g: Geometry): Line =
  let ps = points g
  Line(kind: straight, points: ps & ps[0])

func iconPort(p: MPort): Port =
  Port(
    kind: toSue p.dir,
    name: dump p.id,
    location: p.position)

func toLabel(p: Port): Label =
  Label(
    content: p.name,
    location: p.location,
    anchor: c,
    size: fzStandard)

func toProperty(p: Parameter): IconProperty =
  IconProperty(
    kind: ipUser,
    name: p.name,
    defaultValue: p.defaultValue)


func buildIcon(name: string, ico: MIcon, params: seq[Parameter]): Icon =
  let
    myPorts = ico.ports.map(iconPort)
    defaultLabel = Label(
      content: name,
      location: ico.size.toGeometry.center,
      anchor: c,
      size: fzLarge)

  Icon(
    ports: myPorts,
    properties: params.map(toProperty),
    size: ico.size,
    labels: @[defaultLabel] & myPorts.map(toLabel),
    lines: @[toLine toGeometry ico.size])

func addIconPorts(s: var SSchematic, ico: Icon, lookup: ModuleLookUp) =
  var y = 0
  for p in ico.ports:
    s.instances.add Instance(
      name: p.name,
      parent: lookup[$p.kind],
      location: (-100, y))

    inc y, 100

func findDriectInputs(br: MBusRipper): seq[tuple[port: MPort, net: MNet]] =
  var hasOutput = false

  for n in br.allNets:
    for p in n.ports:
      if p.wrapperKind == wkSchematic:
        case p.parent.dir:
        of mpdOutput:
          hasOutput = true

        of mpdInput:
          result.add (p, n)

        else: discard

  if not hasOutput:
    reset result

func toSue(sch: MSchematic, lookup: ModuleLookUp): SSchematic =
  result = new SSchematic

  for n in sch.nets:
    case n.kind:
    of mnkTag:
      for p in n.ports:
        result.instances.add Instance(
          name: dump p.parent.id,
          parent: lookup["name_net"],
          location: p.position)

    of mnkWire:
      for w in segments n:
        result.wires.add w

  for p in sch.ports:
    result.instances.add Instance(
      name: dump p.parent.id,
      parent: lookup[$p.parent.dir],
      location: p.position)

  var seenPorts: seq[MPort]
  for br in sch.busRippers:
    result.instances.add [
      Instance(
        name: dump(br.source.ports[0].parent.id, true),
        parent: lookup["name_net"],
        location: br.position),

      Instance(
        name: dump(br.select, true),
        parent: lookup["name_net"],
        location: br.connection)]

    result.wires.add br.position .. br.connection

    block directInputs: # detect busRppers that contain both input and output shcematic input
      for (p, n) in findDriectInputs br:
        if p notin seenPorts:
          seenPorts.add p

          let
            lastPos = p.position
            nextNode = n.connections[lastPos][0]
            dir = detectDir(lastPos .. nextNode)
            vdir = toUnitPoint dir
            buffOut = lastPos - vdir * 20
            buffIn = lastPos - vdir * 40
            o =
              case dir:
              of vdEast: Orient()
              of vdWest: Orient(rotation: r180)
              of vdNorth: Orient(rotation: -r90)
              of vdSouth: Orient(rotation: r90)

          n.connections.removeBoth lastPos, nextNode
          n.connections.addBoth buffOut, nextNode

          p.position = buffIn
          result.instances.add Instance(
            name: "helper",
            orient: o,
            parent: lookup["buffer0"],
            location: buffIn)


  for t in sch.texts:
    result.labels.add Label(
      location: t.position,
      size: fzStandard,
      content: t.texts.join "\n")

  for ins in sch.instances:
    let
      m = lookup[ins.parent.name]
      loc =
        ins.geometry.topleft -
        m.icon.size.toGeometry.rotate(P0, ins.transform.rotation).topleft

    result.instances.add Instance(
      name: ins.name,
      parent: m,
      args: ins.args.filterIt(it.value.issome).map(toSue),
      location: loc,
      orient: toSue ins.transform)

func toSue(tt: MTruthTable): SSchematic =
  result = new SSchematic

  const
    W = 200
    H = 100

  var y, x = 0

  template makeLabel(c): untyped =
    Label(
      content: c,
      location: (x, y),
      anchor: w,
      size: fzStandard)

  template makeLine(y): untyped =
    Line(kind: straight,
      points: @[(0, y), (tt.headers.len * W, y)])


  for h in tt.headers:
    result.labels.add makeLabel h
    inc x, W

  inc y, H
  result.lines.add makeLine y

  for r in tt.rows:
    reset x

    for cell in r:
      result.labels.add makeLabel cell
      inc x, W

    inc y, H

func toSue(arch: MArchitecture, ico: Icon,
  lookup: ModuleLookUp, m: Module): Architecture =

  result = case arch.kind:
    of makSchema, makFSM: toArch toSue(arch.schema, lookup)
    of makTruthTable: toArch toSue(arch.truthTable)
    of makCode, makExternalCode: toArch(arch.file)

  if arch.kind != makSchema:
    result.schema.addIconPorts ico, lookup


func inoutModule(n: string): Module =
  Module(
    name: n,
    kind: mkCtx,
    isTemporary: true,
    icon: Icon(
      ports: @[
        Port(
          kind: pdInout,
          location: (0, 0))],
      size: (1, 1)))

func toSue*(proj: mm.MProject): sm.Project =
  result = new Project
  result.modules = toTable {
    "input": inoutModule("input"),
    "inout": inoutModule("inout"),
    "output": inoutModule("output"),
    "name_net": inoutModule("name_net"),
    "buffer0": inoutModule("buffer0")}

  for name, mmdl in proj.modules:
    var
      myParams = @[
        Parameter(name: "name", defaultValue: some "{}"),
        Parameter(name: "origin", defaultValue: some "{0 0}"),
        Parameter(name: "orient", defaultValue: some "R0")]

    for p in values mmdl.parameters:
      myParams.add Parameter(
        name: p.name,
        defaultValue: map(p.defaultValue, toSue))

    result.modules[name] = Module(
      kind: mkCtx,
      name: name,
      params: myParams,
      icon: buildIcon(name, mmdl.icon, myParams))

  for name, mmdl in mpairs proj.modules:
    var m = result.modules[name]
    debugEcho "finalizing module sue: ", name
    m.arch = toSue(mmdl.arch, m.icon, result.modules, m)
