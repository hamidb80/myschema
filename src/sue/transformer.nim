import std/[tables, sequtils, strformat]

import ../common/[coordination, errors, seqs, domain]

import model as sm
import ../middle/model as mm

import logic
import ../middle/logic


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
  Line(kind: straight, points: @(points g))

func buildIcon(ico: MIcon): Icon =
  let
    myPorts = ico.ports.map(iconPort)
    myLabels = myPorts.map(iconPortLabel)

  Icon(
    ports: myPorts,
    labels: myLabels,
    size: ico.size,
    lines: @[toLine toGeometry ico.size])

func toSue(sch: MSchematic, lookup: ModuleLookUp): Schematic =
  result = new Schematic

  for n in sch.nets:
    for w in segments n:
      result.wires.add w

  for p in sch.ports:
    result.instances.add Instance(
      location: p.position,
      name: toSue p.parent.id)

  for br in sch.busRippers:
    discard

  for t in sch.texts:
    discard

  for ins in sch.instances:
    discard


func toSue(tt: MTruthTable): Schematic =
  result = new Schematic


func toSue(arch: MArchitecture, lookup: ModuleLookUp): Architecture =
  case arch.kind:
  of makSchema: toArch toSue(arch.schema, lookup)
  of makTruthTable: toArch toSue arch.truthTable
  of makCode, makExternalCode: toArch arch.file


func tempModule(): Icon =
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

const preDefinedModules = toTable {
  "input": tempModule(),
  "inout": tempModule(),
  "output": tempModule(),
  "name_net": tempModule(),
  # "global": ## TODO for open ports
}

func toSue(proj: mm.MProject): sm.Project =
  var lkp: ModuleLookUp = preDefinedModules

  for name, mmdl in proj.modules:
    lkp[name] = Module(
      kind: mkCtx,
      name: name,
      icon: buildIcon mmdl.icon
    )

  for name, mmdl in proj.modules:
    let a = mmdl.archs.choose
    lkp[name].arch = toSue(a, lkp)
