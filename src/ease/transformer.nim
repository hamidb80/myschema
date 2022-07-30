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

func copyPort(p: MPort, t: MTransform, fn: Transformer): MPort =
  MPort(
    id: p.id,
    dir: p.dir,
    position: fn(p.position),
    # TODO wrapper:
    refersTo: some p)

func toPortDir(m: em.PortMode): mm.MPortDir =
  MPortDir min(int m, 2)

func extractIcon[T: Visible](smth: T): mm.MIcon =
  let ro = toRotation smth.side
  result = mm.MIcon(size: toSize smth.geometry.rotate(P0, -ro))

  let geo = smth.geometry

  for p in smth.ports:
    result.ports.add mm.MPort(
      id: p.identifier,
      position: p.position.rotate(geo.topleft, -ro) - geo.topleft,
      dir: toPortDir mode p)

    # TODO add wrapper

proc buildSchema(schema: em.Schematic,
  icon: mm.MIcon,
  mlk: Table[em.Obid, mm.MElement],
  elements: var Table[string, mm.MElement]
  ): mm.MSchematic =

  result = mm.MSchematic(size: toSize bottomRight schema.sheetSize)
  var
    allPortsMap: Table[ptr em.PortImpl, MPort]
    allNetsMap: Table[ptr em.NetImpl, MNet]

  for gr in schema.generics:
    discard

  for fpt in schema.freePlacedTexts:
    result.labels.add toLable fpt

  for p in schema.ports:
    let mp = mm.MPort(
      id: p.identifier,
      dir: toPortDir p.mode,
      position: p.position,
      refersTo: none MPort, # FIXME refers to icon port
                            # wrapper:  # FIXME
    )

    result.ports.add mp
    allPortsMap[addr p[]] = mp

  for c in schema.components:
    let
      pid = c.parent.obid
      t = getTransform c
      pos = topLeft c.geometry
      tr = getIconTransformer(c.geometry, t.rotation)

    let
      ins = mm.MInstance(
        name: c.ident.name,
        parent: mlk[pid],
        position: pos,
        transform: t,
        ports: mlk[pid].icon.ports.mapIt copyPort(it, t, tr))

    result.instances.add ins

    for i, p in c.ports:
      allPortsMap[addr p[]] = ins.ports[i]

    result.labels.add toLable c.label

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

      ins = mm.MInstance(
        name: pr.ident.name,
        position: pos,
        parent: el,
        transform: t,
        # ports: el.icon.ports.mapIt copyPort(it, t,)
        )

    result.instances.add ins

    for i, p in pr.ports:
      allPortsMap[addr p[]] = ins.ports[i]

    result.labels.add toLable pr.label

  for gb in schema.generateBlocks:
    var el = mm.MElement(kind: mekGenerator)
    el.icon = extractIcon gb
    el.name = randomHdlIdent()
    elements[el.name] = el

    # instansiate
    let
      pos = topleft gb.geometry
      t = getTransform gb
      ins = mm.MInstance(
        name: gb.ident.name,
        position: pos,
        parent: el,
        transform: t,
        # ports: el.icon.ports.mapIt copyPort(it, t, gb.geometry, pos)
        )

    for i, p in gb.ports:
      allPortsMap[addr p[]] = ins.ports[i]

    result.instances.add ins

    result.labels.add toLable gb.label

  for n in schema.nets:
    var mn = case n.part.kind:
      of pkTag: MNet(kind: mnkTag)
      of pkWire:
        var completeWires = n.part.wires

        for p in n.part.ports:
          let conn = p.connection.get
          completeWires.add conn.position .. p.position

        extractNet completeWires

    for p in n.part.ports:
      mn.ports.add allPortsMap[addr p[]]

    result.nets.add mn
    allNetsMap[addr n[]] = mn

  for n in schema.nets:
    if n.part.kind == pkWire:
      for bp in n.part.busRippers:
        let connPos = case bp.side:
          of brsTopLeft: topLeft bp.geometry
          of brsTopRight: topRight bp.geometry
          of brsBottomRight: bottomRight bp.geometry
          of brsBottomLeft: bottomLeft bp.geometry

        result.busRippers.add MBusRipper(
          source: allNetsMap[addr n[]],
          dest: allNetsMap[addr bp.destNet[]],
          position: center bp.geometry,
          connection: connPos
        )

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
    modernIdMap: Table[em.Obid, mm.MElement]
    originalIdMap: Table[em.Obid, em.Entity]

  for d in proj.designs:
    for en in d.entities:
      let m = initModule en
      modernIdMap[en.obid] = m
      originalIdMap[en.obid] = en
      result.modules[m.name] = m

  # phase 2. convert schematics
  for id, m in modernIdMap.mpairs:
    for a in originalIdMap[id].architectures:
      case a.kind:
      of amBlockDiagram:
        m.archs.add toArch buildSchema(
          a.schematic.get,
          m.icon,
          modernIdMap,
          result.modules)

      else: discard
