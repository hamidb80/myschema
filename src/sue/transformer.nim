import std/[tables, sequtils, strformat, strutils, sugar, options]

import ../common/[coordination, seqs, minitable]

import model as sm
import ../middle/model as mm

import logic
import ../middle/logic as ml


func toMiddleModel*(sch: sm.Schematic): mm.MSchematic =
  mm.MSchematic(
    nets: toNets sch.wires
  )

func toMiddleModel*(ico: sm.Icon): mm.MIcon =
  discard

func toMiddleModel*(mo: sm.Module): MElement =
  MElement(
    name: mo.name,
    # icon:
    archs: @[],
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

func toSue(sch: MSchematic, lookup: ModuleLookUp): Schematic =
  result = new Schematic

  for n in sch.nets:
    for w in segments n:
      result.wires.add w

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

func toSue(tt: MTruthTable): Schematic =
  result = new Schematic

func toSue(arch: MArchitecture, lookup: ModuleLookUp): Architecture =
  case arch.kind:
  of makSchema: toArch toSue(arch.schema, lookup)
  of makTruthTable: toArch toSue arch.truthTable
  of makCode, makExternalCode: toArch arch.file

func tempModule(): Module =
  Module(
    kind: mkCtx,
    isTemporary: true,
    icon: Icon(
      ports: @[
        Port(
          kind: pdInout,
          location: (0, 0))
    ],
    size: (1, 1),
  ))

func toSue*(proj: mm.MProject): sm.Project =
  var lkp = toTable {
    "input": tempModule(),
    "inout": tempModule(),
    "output": tempModule(),
    "name_net": tempModule(),
    # "global": ## TODO for open ports
  }

  for name, mmdl in proj.modules:

    let myParams = collect:
      for p in values mmdl.parameters:
        Parameter(
          name: p.name,
          defaultValue: map(p.defaultValue, toSue))

    lkp[name] = Module(
      kind: mkCtx,
      name: name,
      params: myParams,
      icon: buildIcon mmdl.icon)

  for name, mmdl in proj.modules:
    let a = mmdl.archs.choose
    debugEcho ">> ", name
    lkp[name].arch = toSue(a, lkp)
