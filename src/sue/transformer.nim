import std/[tables, sequtils, strutils, options, sugar, macros]

import ../common/[coordination, seqs, minitable, domain]

import model, logic
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


template flipCase(f: set[Flip], bxy, bx, by, b0: untyped): untyped =
  if f == {X, Y}: bxy
  elif f == {X}: bx
  elif f == {Y}: by
  else: b0

func toSue(tr: Transform): Orient =
  let fs = tr.flips

  case tr.rotation:
  of r0: flipCase(fs, RXY, RX, RY, R0)
  of r90: flipCase(fs, R270, R90X, R90Y, R90)
  of r180: flipCase(fs, R0, RY, RX, RXY)
  of r270: flipCase(fs, R90, R90Y, R90X, R270)

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

proc toSue(sch: MSchematic, lookup: ModuleLookUp): SSchematic =
  result = new SSchematic

  var seenPorts: seq[MPort]
  for br in sch.busRippers:
    let anotherId = br.source.ports.search((p) => not p.isSliced).parent.id

    result.instances.add [
      Instance(
        name: dump(anotherId, true),
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
            portPos = p.position
            nextNode = n.connections[portPos][0]
            dir = detectDir(portPos .. nextNode)
            vdir = toUnitPoint dir
            buffIn = portPos - vdir * 20
            newPos = portPos - vdir * 200
            o =
              case dir:
              of vdEast: R0
              of vdWest: RXY
              of vdNorth: R270
              of vdSouth: R90

          result.wires.add newPos .. buffIn

          p.position = newPos

          result.instances.add Instance(
            name: "hepler_" & randomHdlIdent(),
            orient: o,
            parent: lookup["buffer0"],
            location: buffIn)

          # assert false, $(p.position, buffIn, buffOut)

  for n in sch.nets:
    case n.kind:
    of mnkTag: # FIXME same input & output issue
      for p in n.ports:
        let ins = Instance(
            name: dump p.parent.id,
            parent: lookup["name_net"],
            location: p.position)

        result.instances.add ins

    of mnkWire:
      for w in segments n:
        result.wires.add w

  for p in sch.ports:
    result.instances.add Instance(
      name: dump p.parent.id,
      parent: lookup[$p.parent.dir],
      location: p.position)

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

proc toSue(arch: MArchitecture, ico: Icon,
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

proc toSue*(proj: mm.MProject): sm.Project =
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
