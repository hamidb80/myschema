import std/[tables, options, strutils, sequtils, strformat, sugar]

import ../common/[coordination, domain, seqs, minitable, errors]

import model as em
import ../middle/model as mm

import ../middle/logic as mlogic
import logic

# ------------------------------- sue model -> middle model

func extractNet(wires: seq[Wire]): mm.MNet =
  let temp = toNets wires
  assert temp.len == 1, fmt"expected len 1 but got: {temp.len}"
  temp[0]

func toText(lbl: em.Label): mm.MText =
  mm.MText(
    position: lbl.position,
    texts: lbl.texts
  )

func toText(fpt: em.FreePlacedText): mm.MText =
  toText em.Label fpt

func getTransform[T: Visible](smth: T): MTransform =
  MTransform(
    rotation: smth.rotation,
    flips: smth.flips)

func copyPort(p: MPort, fn: Transformer): MPort =
  # FIXME extract cbn from parent ports

  MPort(
    kind: mpCopy,
    position: fn(p.position),
    parent: p)

func toPortDir(m: em.PortMode): mm.MPortDir =
  MPortDir min(int m, 2)

func toMIdent(id: Identifier): MIdentifier =
  case id.kind:
  of ikSingle: MIdentifier(kind: mikSingle, name: id.name)

  of ikIndex: MIdentifier(kind: mikIndex, name: id.name,
      index: lexCode id.index)

  of ikRange: MIdentifier(kind: mikRange, name: id.name,
    direction: id.direction,
    indexes: (lexCode id.indexes.b)..(lexCode id.indexes.b), )

proc extractIcon[T: Visible](smth: T): mm.MIcon =
  let
    geo = smth.geometry
    ro = smth.rotation
    tr = getIconTransformer(geo, ro)

  result = mm.MIcon(size: getIconSize(geo, ro))

  for p in smth.ports:
    result.ports.add mm.MPort(
      kind: mpOriginal,
      id: toMIdent p.identifier,
      position: tr(p.position),
      dir: toPortDir mode p)

func lexCode(s: Option[string]): Option[MTokenGroup] =
  if isSome s:
    result = some lexCode s.get

func getBusSelect*(br: BusRipper): MSBusSelect =
  let
    cn = br.ident.attributes.constraint.get
    r = cn.`range`
    i = r.indexes

  case cn.kind:
  of ckIndex:
    if cn.index == "?":
      MSBusSelect(kind: mbsSingle)
    else:
      MSBusSelect(kind: mbsIndex, index: lexCode cn.index)

  of ckRange:
    MSBusSelect(kind: mbsSlice,
      dir: r.direction,
      slice: (i.a.lexCode .. i.b.lexCode))


func extractGenerateBlockInfo(gb: GenerateBlock): GenerateInfo =
  case gb.kind:
  of gbtForGenerate:
    GenerateInfo(kind: gikIf, cond: lexCode getIfCond gb)

  of gbtIfGenerate:
    let
      gi = getForInfo gb
      ii = gi.`range`.indexes

    GenerateInfo(kind: gikFor,
        varname: gi.ident,
        dir: gi.`range`.direction,
        slice: (ii.a.lexCode .. ii.b.lexCode))

func makeGenerator(gb: GenerateBlock): MElement =
  result = MElement(kind: mekGenerator, info: extractGenerateBlockInfo gb)

func extractParams(en: Entity): MParamsLookup =
  for g in en.generics:
    let
      name = g.ident.name
      ga = g.ident.attributes

    result[name] = MParameter(
      name: name,
      kind: ga.kind.get(""),
      default: lexCode ga.defValue)

func extractArgs(cp: Component, lookup: MParamsLookup): seq[MArg] =
  for ag in cp.generics:
    result.add MArg(
      parameter: lookup[ag.ident.name],
      value: lexCode ag.actValue)

proc initProcessElement(pr: Process): MElement =
  result = case pr.kind:
  of ptProcess:
    mm.MElement(kind: mekCode)

  of ptStateDiagram:
    mm.MElement(kind: mekFSM)

  of ptConcurrentStatement:
    mm.MElement(kind: mekPartialCode)

  of ptTruthTable:
    mm.MElement(kind: mekTruthTable)

proc buildSchema(schema: em.Schematic,
  mlk: Table[em.Obid, mm.MElement],
  elements: var Table[string, mm.MElement]
  ): mm.MSchematic =

  result = mm.MSchematic(size: toSize schema.sheetSize)
  var
    allPortsMap: Table[ptr em.PortImpl, MPort]
    allNetsMap: Table[ptr em.NetImpl, MNet]


  for fpt in schema.freePlacedTexts:
    result.labels.add toText fpt

  for p in schema.ports:
    let mp = mm.MPort(
      kind: mpCopy,
      position: p.position)

    result.ports.add mp
    allPortsMap[addr p[]] = mp

  block instances:
    template makeInstance(iname, parentEl, elGeo, rawT, argsSeq): untyped =
      let
        t = rawT
        pos = topLeft elGeo
        c = center elGeo

        translate = translationAfter(
          toGeometry parentEl.icon.size,
          t.rotation)

        tFn = (p: Point) =>
          (p.rotate0(t.rotation) + pos - translate).flip(c, t.flips)

      mm.MInstance(
        name: iname,
        position: pos,
        parent: parentEl,
        transform: t,
        args: argsSeq,
        ports: parentEl.icon.ports.mapIt copyPort(it, tFn))

    template makeParent(el, easeNode): untyped =
      var parent = el
      parent.name = randomHdlIdent()
      parent.icon = extractIcon easeNode
      elements[parent.name] = parent
      parent


    for c in schema.components:
      let
        parent = mlk[c.parent.obid]
        ins = makeInstance(c.ident.name, parent, c.geometry,
          getTransform c,
          extractArgs(c, parent.parameters))

      result.instances.add ins

      for i, p in c.ports:
        allPortsMap[addr p[]] = ins.ports[i]

      result.labels.add toText c.label

    for pr in schema.processes:
      let
        el = makeParent(initProcessElement pr, pr)
        ins = makeInstance(pr.ident.name, el, pr.geometry,
          getTransform pr, @[])

      result.instances.add ins

      for i, p in pr.ports:
        allPortsMap[addr p[]] = ins.ports[i]

      result.labels.add toText pr.label

    for gb in schema.generateBlocks:
      let
        el = makeParent(makeGenerator gb, gb)
        ins = makeInstance(gb.ident.name, el, gb.geometry,
          getTransform gb, @[])

      for i, p in gb.ports:
        allPortsMap[addr p[]] = ins.ports[i]

      result.instances.add ins
      result.labels.add toText gb.label

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

  # bus rippers
  for n in schema.nets:
    if n.part.kind == pkWire:
      for bp in n.part.busRippers:
        let connPos = case bp.side:
          of brsTopLeft: topLeft bp.geometry
          of brsTopRight: topRight bp.geometry
          of brsBottomRight: bottomRight bp.geometry
          of brsBottomLeft: bottomLeft bp.geometry

        result.busRippers.add MBusRipper(
          select: getBusSelect bp,
          source: allNetsMap[addr n[]],
          dest: allNetsMap[addr bp.destNet[]],
          position: center bp.geometry,
          connection: connPos
        )

proc initModule(en: em.Entity): mm.MElement =
  mm.MElement(
    name: en.ident.name,
    kind: mekModule,
    icon: extractIcon en,
    parameters: extractParams en
  )

func toArch(sch: MSchematic): MArchitecture =
  MArchitecture(kind: makSchema, schema: sch)

# func toArch()

# TODO extract cbn for bus ripper :: it may not have `dest` bus

proc toMiddleModel*(proj: em.Project): mm.MProject =
  result = mm.MProject()

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
      m.archs.add:
        case a.kind:
        of amBlockDiagram:
          toArch buildSchema(
            a.body.schematic,
            modernIdMap,
            result.modules)

        of amHDLFile:
          MArchitecture(kind: makTruthTable)

        of amStateDiagram:
          MArchitecture(kind: makTruthTable)

        of amTableDiagram:
          MArchitecture(kind: makTruthTable)

        of amExternalHDLFIle:
          err "not implemented"
