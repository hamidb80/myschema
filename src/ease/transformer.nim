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
    text: lbl.texts.join "\n"
  )

func toLable(fpt: em.FreePlacedText): mm.MLabel =
  toLable em.Label fpt

func apply(pos: Point, t: MTransform): Point =
  pos.rotate(t.pin, t.rotation) + t.movement

func copyPort(p: MPort, t: MTransform, parentPos: Vector): MPort =
  MPort(
    id: p.id,
    dir: p.dir,
    position: p.position.apply(t) + parentPos,
    refersTo: some p,
    # TODO wrapper:
  )

func buildSchema(schema: em.Schematic,
  icon: mm.MIcon,
  mlk: Table[em.Obid, mm.MModule]
  ): mm.MSchematic =

  result = mm.MSchematic(size: toSize bottomRight schema.sheetSize)

  # for gr in schema.generics:
  #   discard

  for fpt in schema.freePlacedTexts:
    result.lables.add toLable fpt

  for p in schema.ports:
    result.ports.add mm.MPort(
      id: p.identifier,
      dir: MPortDir min(2, int p.mode),
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
      geo = c.geometry
      originalGeo = rotate(geo, topLeft geo, -ro)
      translate = geo.topleft - originalGeo.topleft
      pos = topLeft originalGeo

      t = MTransform(
        pin: geo.topleft,
        rotation: ro,
        flips: fs,
        movement: translate)

      ins = mm.MInstance(
        name: c.ident.name,
        parent: mlk[pid],
        position: pos,
        transform: t,
        # copies ports with new location
        ports: mlk[pid].icon.ports.mapIt copyPort(it, t, pos))


    result.instances.add ins

    # TODO resolve connections for component ports

  for pr in schema.processes:
    discard

  for gb in schema.generateBlocks:
    discard

func extractIcon(entity: em.Entity): mm.MIcon =
  result = mm.MIcon(size: entity.size)

  for p in entity.ports:
    result.ports.add mm.MPort(
      id: p.identifier,
      position: position p,
      dir: MPortDir min(int mode p, 2)
    )

func initModule(en: em.Entity): mm.MModule =
  # TODO generics

  mm.MModule(
    name: en.ident.name,
    icon: extractIcon en,
  )

func toMiddleMode*(proj: em.Project): mm.MProject =
  result = mm.MProject()

  # phase 1. convert icons
  var
    en2mod: Table[em.Obid, mm.MModule]
    enlook: Table[em.Obid, em.Entity]

  for d in proj.designs:
    for en in d.entities:
      en2mod[en.obid] = initModule en
      enlook[en.obid] = en

  # phase 2. convert schematics
  for id, m in en2mod.mpairs:
    for a in enlook[id].architectures:
      if a.kind == amBlockDiagram:
        m.schema = buildSchema(a.schematic.get, m.icon, en2mod)
        result.modules[m.name] = m
        break
