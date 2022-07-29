import std/[tables, options, strutils, sequtils, strformat]

import ../common/[coordination, domain, seqs]

import model as em
import ../middle/model as mm

import ../middle/logic as mlogic
import logic

# ------------------------------- sue model -> middle model

func extractNet(net: em.Net): mm.MNet =
  let temp = toNets net.wires
  assert temp.len == 1, fmt"expected len 1 but got: {temp.len}"
  temp[0]

func findInitialGeometry(): Geometry =
  discard


func toLable(lbl: em.Label): mm.MLabel =
  mm.MLabel(
    position: lbl.position,
    texts: lbl.texts
  )

func toLable(fpt: em.FreePlacedText): mm.MLabel =
  toLable em.Label fpt


func copyPort(p: MPort, t: MTransform, parentPos: Vector): MPort =
  MPort(
    id: p.id,
    dir: p.dir,
    position: rotate(p.position, (0, 0), t.rotation) + parentPos,
    refersTo: some p,
    # TODO wrapper:
  )

func toPortDir(m: em.PortMode): mm.MPortDir =
  MPortDir min(int m, 2)

func buildSchema(schema: em.Schematic,
  icon: mm.MIcon,
  mlk: Table[em.Obid, mm.MElement]
  ): mm.MSchematic =

  result = mm.MSchematic(size: toSize bottomRight schema.sheetSize)

  # for gr in schema.generics:
  #   discard

  for fpt in schema.freePlacedTexts:
    result.lables.add toLable fpt

  for p in schema.ports:
    result.ports.add mm.MPort(
      id: p.identifier,
      dir: toPortDir p.mode,
      position: p.position,
      refersTo: none MPort, # FIXME refers to icon port
      # wrapper:  # FIXME
    )

  for n in schema.nets:
    if n.wires.len > 0:
      result.nets.add extractNet n

    else:
      # TODO Tagged nets
      discard

  for c in schema.components:
    let
      pid = c.parent.obid

      ro = c.rotation
      fs = c.flips
      t = MTransform(rotation: ro, flips: fs)

      geo = c.geometry
      pos = topLeft rotate(geo, topLeft geo, -ro)

      ins = mm.MInstance(
        name: c.ident.name,
        parent: mlk[pid],
        position: pos,
        transform: t,
        ports: mlk[pid].icon.ports.mapIt copyPort(it, t, pos))

    result.instances.add ins

  for pr in schema.processes:
    discard

  for gb in schema.generateBlocks:
    discard

  # TODO resolve connections for instance ports
  # TODO Tag

func extractIcon(entity: em.Entity): mm.MIcon =
  result = mm.MIcon(size: entity.size)

  for p in entity.ports:
    result.ports.add mm.MPort(
      id: p.identifier,
      position: position p,
      dir: toPortDir mode p)

func initModule(en: em.Entity): mm.MElement =
  mm.MElement(
    name: en.ident.name,
    kind: mekModule,
    icon: extractIcon en,
  )

func toArch(sch: MSchematic): MArchitecture = 
  MArchitecture(kind: makSchema, schema: sch)

func toMiddleMode*(proj: em.Project): mm.MProject =
  result = mm.MProject()

  # TODO generics
  # phase 1. convert icons

  var
    en2mod: Table[em.Obid, mm.MElement]
    enlook: Table[em.Obid, em.Entity]

  for d in proj.designs:
    for en in d.entities:
      en2mod[en.obid] = initModule en
      enlook[en.obid] = en

  # phase 2. convert schematics
  for id, m in en2mod.mpairs:
    for a in enlook[id].architectures:
      case a.kind:
      of amBlockDiagram:
        m.archs.add toArch buildSchema(a.schematic.get, m.icon, en2mod)
        result.modules[m.name] = m

      else: discard