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

func getBusSelect*(br: BusRipper, net: Net): MIdentifier =
  let cn = br.ident.attributes.constraint.get

  result =
    case cn.kind:
    of ckIndex:
      if cn.index == "?":
        MIdentifier(kind: mikSingle)
      else:
        MIdentifier(kind: mikIndex, index: lexCode cn.index)

    of ckRange:
      let
        r = cn.`range`
        i = r.indexes

      MIdentifier(kind: mikRange,
        direction: r.direction,
        indexes: (i.a.lexCode .. i.b.lexCode))

  result.name = net.ident.name

func extractGenerateBlockInfo(gb: GenerateBlock): GenerateInfo =
  case gb.kind:
  of gbtForGenerate:
    let
      gi = getForInfo gb
      ii = gi.`range`.indexes

    GenerateInfo(kind: gikFor,
      varname: gi.ident,
      dir: gi.`range`.direction,
      slice: (ii.a.lexCode .. ii.b.lexCode))

  of gbtIfGenerate:
    GenerateInfo(kind: gikIf, cond: lexCode getIfCond gb)

func makeGenerator(gb: GenerateBlock): MElement =
  result = MElement(kind: mekGenerator, info: extractGenerateBlockInfo gb)

func extractParams(en: Entity): MParamsLookup =
  for g in en.generics:
    let
      name = g.ident.name
      ga = g.ident.attributes

    result[name] = MParameter(
      name: name,
      kind: ga.kind,
      defaultValue: lexCode ga.defValue)

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

  of ptConcurrentStatement, ptInitialConstruct, ptSpecifyBlock:
    mm.MElement(kind: mekPartialCode)

  of ptTruthTable:
    mm.MElement(kind: mekTruthTable)


func toArch(sch: sink MSchematic): MArchitecture =
  MArchitecture(kind: makSchema, schema: sch)

func toArch(tt: sink MTruthTable): MArchitecture =
  MArchitecture(kind: makTruthTable, truthTable: tt)

func toArch(cf: sink MCodeFile): MArchitecture =
  MArchitecture(kind: makCode, file: cf)

proc initModule(en: em.Entity): mm.MElement =
  mm.MElement(
    name: en.ident.name,
    kind: mekModule,
    icon: extractIcon en,
    parameters: extractParams en
  )

# func makeArch(pr: Process): Body =


proc buildSchema(moduleName: string,
  schema: sink em.Schematic,
  icon: MIcon,
  mlk: Table[em.Obid, mm.MElement],
  elements: var Table[string, mm.MElement]
  ): mm.MSchematic =

  result = mm.MSchematic(size: toSize schema.sheetSize)
  var
    allPortsMap: Table[ptr em.PortImpl, MPort]
    allNetsMap: Table[ptr em.NetImpl, MNet]


  for fpt in schema.freePlacedTexts:
    result.texts.add toText fpt

  for p in schema.ports:
    let
      mid = toMIdent(p.identifier)
      mp = mm.MPort(
      kind: mpCopy,
      position: p.position,
      parent: icon.ports.search((it) => mid == it.id))

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
        geometry: afterTransform(parentEl.icon, t.rotation, pos),
        parent: parentEl,
        transform: t,
        args: argsSeq,
        ports: parentEl.icon.ports.mapIt copyPort(it, tFn))

    template makeParent(el, ico, a): untyped =
      let yourName{.inject.} = moduleName & "_" & randomHdlIdent()
      var parent = el
      parent.name = yourName
      parent.icon = ico
      parent.arch = a
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

      result.texts.add toText c.label

    for pr in schema.processes:
      let
        el = makeParent(initProcessElement pr, extractIcon pr,
            toArch MSchematic()) # FIXME
        ins = makeInstance(pr.ident.name, el, pr.geometry,
          getTransform pr, @[])

      result.instances.add ins

      for i, p in pr.ports:
        allPortsMap[addr p[]] = ins.ports[i]

      result.texts.add toText pr.label

    for gb in schema.generateBlocks:
      let
        ico = extractIcon gb
        el = makeParent(makeGenerator gb, ico, toArch buildSchema(yourName,
            gb.schematic, ico, mlk, elements))
        ins = makeInstance(gb.ident.name, el, gb.geometry,
          getTransform gb, @[])

      for i, p in gb.ports:
        allPortsMap[addr p[]] = ins.ports[i]

      result.instances.add ins
      result.texts.add toText gb.label

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
          select: getBusSelect(bp, n),
          source: allNetsMap[addr n[]],
          dest: allNetsMap[addr bp.destNet[]],
          position: center bp.geometry,
          connection: connPos
        )

func buildTruthTable(tt: sink TruthTable): MTruthTable =
  MTruthTable(headers: tt.headers, rows: tt.rows)

func buildCodeFile(hf: sink HdlFile): MCodeFile =
  MCodeFile(name: hf.name, content: hf.content.join "\n")

func buildFsm(stateMachine: sink StateMachineV2): MSchematic =
  result = mm.MSchematic()

func choose(sa: seq[Architecture]): Architecture =
  result = sa[0]

  for i in sa:
    if i.kind == amBlockDiagram:
      result = i

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
    let a = choose originalIdMap[id].architectures
    m.arch = case a.kind:
      of amBlockDiagram:
        toArch buildSchema(m.name,
          a.body.schematic,
          m.icon,
          modernIdMap,
          result.modules)

      of amStateDiagram: # FSM
        toArch buildFsm a.body.stateMachine

      of amHDLFile:
        toArch buildCodeFile a.body.file

      of amTableDiagram:
        err "what"
        toArch buildTruthTable a.body.truthTable

      of amExternalHDLFIle:
        err "not implemented"

# TODO extract cbn for bus ripper :: it may not have `dest` bus
