import std/[tables, options, strutils, sequtils, strformat]

import ../common/[coordination, domain, seqs]

import model as em
import ../middle/model as mm

import ../middle/logic as mlogic
import logic

# ------------------------------- sue model -> middle model

func extractNet(wires: seq[Wire]): mm.MNet =
  let temp = toNets wires
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


func getTransform[T: Visible](smth: T): MTransform =
  MTransform(
    rotation: smth.rotation,
    flips: smth.flips)

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

func extractIcon[T: Visible](smth: T): mm.MIcon =
  result = mm.MIcon(size: toSize smth.geometry)

  for p in smth.ports:
    result.ports.add mm.MPort(
      id: p.identifier,
      position: p.position - topleft smth.geometry,
      dir: toPortDir mode p)
    # TODO add wrapper

proc buildSchema(schema: em.Schematic,
  icon: mm.MIcon,
  mlk: Table[em.Obid, mm.MElement],
  elements: var Table[string, mm.MElement]
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

  for c in schema.components:
    let
      pid = c.parent.obid
      t = getTransform c

      geo = c.geometry
      pos = topLeft geo

      ins = mm.MInstance(
        name: c.ident.name,
        parent: mlk[pid],
        position: pos,
        transform: t,
        ports: mlk[pid].icon.ports.mapIt copyPort(it, t, pos))

    result.instances.add ins

  for pr in schema.processes:
    var el = case pr.kind:
      of ptProcess:
        mm.MElement(kind: mekCode)

      of ptStateDiagram:
        mm.MElement(kind: mekFSM)

      of ptConcurrentStatement:
        mm.MElement(kind: mekPartialCode)

      of ptTruthTable:
        mm.MElement(kind: mekTruthTable)

    el.icon = extractIcon pr
    el.name = randomHdlIdent()
    elements[el.name] = el

    # instansiate
    let
      pos = topleft pr.geometry
      t = getTransform pr

    result.instances.add mm.MInstance(
      name: pr.ident.name,
      position: pos,
      parent: el,
      transform: t,
      ports: el.icon.ports.mapIt copyPort(it, t, pos))

  for gb in schema.generateBlocks:
    var el = mm.MElement(kind: mekGenerator)
    el.icon = extractIcon gb
    el.name = randomHdlIdent()
    elements[el.name] = el

    # instansiate
    let
      pos = topleft gb.geometry
      t = getTransform gb

    result.instances.add mm.MInstance(
      name: gb.ident.name,
      position: pos,
      parent: el,
      transform: t,
      ports: el.icon.ports.mapIt copyPort(it, t, pos))

  for n in schema.nets:
    if n.part.kind == pkWire:
      var completeWires = n.part.wires

      for p in n.part.ports:
        let conn = p.connection.get
        completeWires.add conn.position .. p.position

      result.nets.add extractNet completeWires

    else:
      discard


  # TODO resolve connections for instance ports
  # TODO Tag

func initModule(en: em.Entity): mm.MElement =
  mm.MElement(
    name: en.ident.name,
    kind: mekModule,
    icon: extractIcon en,
  )

func toArch(sch: MSchematic): MArchitecture =
  MArchitecture(kind: makSchema, schema: sch)

proc toMiddleMode*(proj: em.Project): mm.MProject =
  result = mm.MProject()

  # TODO generics
  # phase 1. convert icons

  var
    en2mod: Table[em.Obid, mm.MElement]
    enlook: Table[em.Obid, em.Entity]

  for d in proj.designs:
    for en in d.entities:
      let m = initModule en
      en2mod[en.obid] = m
      enlook[en.obid] = en
      result.modules[m.name] = m

  # phase 2. convert schematics
  for id, m in en2mod.mpairs:
    for a in enlook[id].architectures:
      case a.kind:
      of amBlockDiagram:
        m.archs.add toArch buildSchema(
          a.schematic.get,
          m.icon,
          en2mod,
          result.modules)

      else: discard
