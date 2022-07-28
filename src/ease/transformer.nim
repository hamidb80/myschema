import std/[tables]

import ../common/[coordination]

import model as em
import ../middle/model as mm



func extractNet(net: em.Net): mm.MNet =
  discard

func findInitialGeometry(): Geometry =
  discard

func buildSchema(sch: em.Schematic): mm.Schema =
  discard

func extractIcon(entity: em.Entity): mm.MIcon =
  discard

func initModule(en: em.Entity): mm.MModule =
  mm.MModule(
    name: en.name,
    icon: extractIcon en,
  )

func toMiddleMode(proj: em.Project): mm.MProject =
  # phase 1. convert icons

  type Both = tuple[middle: mm.MModule, ease: em.Entity]
  var en2mod: Table[em.Obid, Both]

  for d in proj.designs:
    for en in d.entities:
      en2mod[en.obid] = (initModule en, en)

  # phase 2. convert schematics

  for _, v in en2mod.mpairs:
    discard
    # v..schema = mm.buildSchema(m)
