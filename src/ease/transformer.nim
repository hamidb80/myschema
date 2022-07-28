import std/[tables, options, strutils, sequtils]

import ../common/[coordination, domain, seqs]

import model as em
import ../middle/model as mm

import ../middle/logic as mlogic
import logic

# ------------------------------- sue model -> middle model

func extractNet(net: em.Net): mm.MNet =
  let temp = toNets net.wires
  assert temp.len == 1
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
  pos.rotate(t.center, t.rotation) + t.movement

func copyPort(p: MPort, t: MTransform): MPort =
  MPort(
    id: p.id,
    dir: p.dir,
    position: p.position.apply(t),
    refersTo: some p,
    # TODO wrapper:
  )

func buildSchema(schema: em.Schematic,
  icon: em.Entity,
  mlk: Table[em.Obid, mm.MModule]
  ): mm.MSchematic =

  result = mm.MSchematic()

  # for gr in schema.generics:
  #   discard

  for fpt in schema.freePlacedTexts:
    result.lables.add toLable fpt

  for p in schema.ports:
    result.ports.add mm.MPort(
      id: p.identifier,
      dir: MPortDir p.mode,
      position: p.position,
      refersTo: none MPort, # FIXME refers to icon port
      # wrapper:  # FIXME
    )

  for n in schema.nets:
    result.nets.add extractNet n

  for c in schema.components:
    let
      ro = c.rotation
      fs = c.flips
      geo = c.geometry
      originalGeo = rotate(geo, topLeft geo, -ro)
      translate = geo.topleft - originalGeo.topleft
      
      t = MTransform(
        center: geo.center,
        rotation: ro,
        flips: fs,
        movement: translate)

      ins = mm.MInstance(
        name: c.ident.name,
        parent: mlk[c.parent.obid],
        position: topLeft originalGeo,
        transform: t,
        # copies ports with new location
        ports: mlk[c.obid].icon.ports.mapIt copyPort(it, t))


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
      dir: MPortDir mode p
    )

func initModule(en: em.Entity): mm.MModule =
  # TODO generics

  mm.MModule(
    name: en.name,
    icon: extractIcon en,
  )

func toMiddleMode*(proj: em.Project): mm.MProject =
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
    discard
