import std/[tables]

import ../common/[coordination, errors, seqs]

import model as sm
import ../middle/model as mm

import ../middle/logic


func toMiddleModel*(sch: sm.Schematic): mm.MSchematic =
  mm.MSchematic(
    nets: toNets sch.wires
  )

func toMiddleModel*(ico: sm.Icon): mm.MIcon =
  discard

func toMiddleModel*(mo: sm.Module): MModule =
  MModule(
    # mo.icon
    name: mo.name,
    schema: toMiddleModel mo.schema
  )

func toMiddleModel*(proj: sm.Project): mm.MProject =
  result = new mm.MProject

  for name, sueModule in proj.modules:
    result.modules[name] = toMiddleModel sueModule

# ------------------------------- middle model -> sue model
