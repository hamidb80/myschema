import std/[tables, options]

import ../common/[coordination, domain, seqs]

import model as em
import ../middle/model as mm

import logic


# ------------------------------- sue model -> middle model


func extractNet(net: em.Net): mm.MNet =
  discard

func findInitialGeometry(): Geometry =
  discard

func buildSchema(
  schema: em.Schematic,
  icon: em.Entity,
  moduleLookUp: Table[em.Obid, mm.MModule]
  ): mm.MSchematic =

  result = mm.MSchematic()

  for p in schema.ports:
    result.ports.add mm.MPort(
      id: p.identifier,
      dir: MPortDir p.mode,
      position: p.position,
      refersTo: none MPort, # FIXME refers to icon port
      # wrapper:  # FIXME
    )

  for n in schema.nets:
    var net = MNet()


  for c in schema.components:
    let
      ro = c.rotation
      fs = c.flips
      geo = c.geometry

    # build instance
    # add ports to

    # TODO resolve connections for component ports

  for pr in schema.processes:
    discard

  for gb in schema.generateBlocks:
    discard

  for gr in schema.generics:
    discard

  for rpt in schema.freePlacedTexts:
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
