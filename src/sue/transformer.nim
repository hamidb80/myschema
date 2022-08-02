import std/[tables, sequtils, strformat, strutils, sugar, options]

import ../common/[coordination, seqs, minitable]

import model as sm
import ../middle/model as mm

import logic
import ../middle/logic as ml


func toMiddleModel*(sch: sm.SSchematic): mm.MSchematic =
  mm.MSchematic(
    nets: toNets sch.wires
  )

func toMiddleModel*(ico: sm.Icon): mm.MIcon =
  discard

func toMiddleModel*(mo: sm.Module): MElement =
  MElement(
    name: mo.name,
    # icon:
  )

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

func toSue(id: MIdentifier): string =
  case id.kind:
  of mikSingle: id.name
  of mikIndex: fmt"{id.name}[{toSue id.index}]"
  of mikRange: fmt"{id.name}[{toSue id.indexes.a}:{toSue id.indexes.b}]"

func iconPort(p: MPort): Port =
  Port(
    kind: toSue p.dir,
    name: toSue p.id,
    location: p.position)

func iconPortLabel(p: Port): Label =
  Label(
    content: p.name,
    location: p.location,
    anchor: c,
    size: fzStandard)

func toLine(g: Geometry): Line =
  Line(kind: straight, points: points(g) & @[g.topleft])

func buildIcon(ico: MIcon): Icon =
  let
    myPorts = ico.ports.map(iconPort)
    myLabels = myPorts.map(iconPortLabel)

  Icon(
    ports: myPorts,
    labels: myLabels,
    size: ico.size,
    lines: @[toLine toGeometry ico.size])

func toSue(tr: MTransform): Orient =
  Orient(rotation: tr.rotation, flips: tr.flips)

func toSue(sch: MSchematic, lookup: ModuleLookUp): SSchematic =
  result = new SSchematic

  for n in sch.nets:
    case n.kind:
    of mnkWire:
      for w in segments n:
        result.wires.add w

    else:
      discard


  for p in sch.ports:
    result.instances.add Instance(
      name: toSue p.parent.id,
      parent: lookup[$p.parent.dir],
      location: p.position)

  for br in sch.busRippers:
    result.instances.add Instance(
      name: toSue br.select,
      parent: lookup["name_net"],
      location: br.position)

    result.wires.add br.position .. br.connection

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
      args: @[], # TODO
      location: loc,
      orient: toSue ins.transform)

func toSue(tt: MTruthTable): SSchematic =
  result = new SSchematic

  const
    w = 200
    h = 100

  var y, x = 0

  proc makeLabel(c: string): Label =
    Label(
      content: c,
      location: (x, y),
      anchor: e,
      size: fzStandard)

  proc makeLine(y: int): Line =
    Line(kind: straight,
      points: @[(0, y), (tt.headers.len * w, y)])


  for h in tt.headers:
    result.labels.add makeLabel h
    inc x, w

  for r in tt.rows:
    reset x
    inc y, h
    result.lines.add makeLine y

    for cell in r:
      inc x, w
      result.labels.add makeLabel cell

func toSue(arch: MArchitecture, lookup: ModuleLookUp): Architecture =
  case arch.kind:
  of makSchema: toArch toSue(arch.schema, lookup)
  of makTruthTable: toArch toSue arch.truthTable
  of makCode, makExternalCode: toArch arch.file

func tempModule(n: string): Module =
  Module(
    name: n,
    kind: mkCtx,
    isTemporary: true,
    icon: Icon(
      ports: @[
        Port(
          kind: pdInout,
          location: (0, 0))
    ],
      size: (1, 1)))

func toSue*(proj: mm.MProject): sm.Project =
  result = new Project
  result.modules = toTable {
    "input": tempModule("input"),
    "inout": tempModule("inout"),
    "output": tempModule("output"),
    "name_net": tempModule("name_net"),
    # "global": ## TODO for open ports
  }

  for name, mmdl in proj.modules:

    let myParams = collect:
      for p in values mmdl.parameters:
        Parameter(
          name: p.name,
          defaultValue: map(p.defaultValue, toSue))

    result.modules[name] = Module(
      kind: mkCtx,
      name: name,
      params: myParams,
      icon: buildIcon mmdl.icon)

  for name, mmdl in proj.modules:
    result.modules[name].arch = toSue(mmdl.arch, result.modules)
