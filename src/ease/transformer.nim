import std/[tables, options, strutils, sequtils, strformat, sugar]

import ../common/[coordination, domain, seqs, minitable, errors, graph]

import model as em
import ../middle/model as mm

import ../middle/logic as mlogic
import logic

import ../middle/expr

# ------------------------------- sue model -> middle model

func extractNet(wires: seq[Wire]): mm.MNet =
  let temp = toNets wires
  assert temp.len == 1, fmt"expected len 1 but got: {temp.len}"
  temp[0]

func toText(lbl: em.Label): mm.MText =
  mm.MText(
    position: lbl.position,
    texts: lbl.texts)

func toText(fpt: em.FreePlacedText): mm.MText =
  toText em.Label fpt

func getTransform[T: Visible](smth: T): MTransform =
  MTransform(
    rotation: smth.rotation,
    flips: smth.flips)

func copyPort(pinstance: Port, pparent: MPort): MPort =
  MPort(
    kind: mpCopy,
    wrapperKind: wkInstance,
    position: pinstance.position,
    isSliced: "NET_SLICE" in pinstance.properties,
    parent: pparent)

func toPortDir(m: em.PortMode): mm.MPortDir =
  case m:
  of pmInput: mpdInput
  of pmOutput: mpdOutput
  of pmInout, pmBuffer: mpdInout
  of pmVirtual:
    debugecho "Ease/virtualRecord -> Middle/PORT_TYPE is converted to `inout`"
    mpdInout

func toMIdent(id: Identifier): MIdentifier =
  result = case id.kind:
    of ikSingle: MIdentifier(kind: mikSingle)

    of ikIndex: MIdentifier(kind: mikIndex,
        index: lexCode id.index)

    of ikRange: MIdentifier(kind: mikRange,
        direction: id.direction,
        indexes: (lexCode id.indexes.a) .. (lexCode id.indexes.b), )

  result.name = id.name

proc extractIcon[T: Visible](smth: T): mm.MIcon =
  let
    geo = smth.geometry
    ro = smth.rotation
    tr = getIconTransformer(geo, ro)

  result = mm.MIcon(size: getIconSize(geo, ro))

  for p in smth.ports:
    result.ports.add mm.MPort(
      kind: mpOriginal,
      wrapperKind: wkIcon,
      id: toMIdent p.identifier,
      position: tr(p.position),
      dir: toPortDir mode p)

func lexCode(s: Option[string]): Option[MTokenGroup] =
  map s, lexCode

func toMElementKind(prk: ProcessKind): MElementKind =
  case prk:
  of ptProcess, ptConcurrentStatement, ptInitialConstruct,
      ptSpecifyBlock: mekCode
  of ptStateDiagram: mekFSM
  of ptTruthTable: mekTruthTable

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


func toMiddle(tt: sink TruthTable): MTruthTable =
  MTruthTable(headers: tt.headers, rows: tt.rows)

func toMiddle(hf: sink HdlFile): MCodeFile =
  MCodeFile(name: hf.name, content: hf.content.join "\n")

func toMiddle(stateMachine: sink StateMachineV2): MSchematic =
  result = mm.MSchematic()


func toArch(sch: sink MSchematic, m: MArchitectureKind): MArchitecture =
  result = MArchitecture(kind: m)
  result.schema = sch

func toArch(tt: sink MTruthTable): MArchitecture =
  MArchitecture(kind: makTruthTable, truthTable: tt)

func toArch(cf: sink MCodeFile): MArchitecture =
  MArchitecture(kind: makCode, file: cf)

func toArch(pr: Process): MArchitecture =
  case toMElementKind pr.kind:
  of mekTruthTable: toArch toMiddle pr.body.truthTable
  of mekCode: toArch toMiddle pr.body.file
  of mekFSM: toArch(toMiddle pr.body.stateMachine, makFSM)
  else: err "impossible"


proc initProcessElement(pr: Process): MElement =
  mm.MElement(kind: toMElementKind pr.kind, arch: toArch pr)

proc initModule(en: em.Entity): mm.MElement =
  mm.MElement(
    name: en.ident.name,
    kind: mekModule,
    icon: extractIcon en,
    parameters: extractParams en)


func netSlice2MIdent(mg: MTokenGroup): MIdentifier =
  if mg.len == 1:
    MIdentifier(kind: mikIndex, index: mg)
  else:
    assert mg.len == 5
    assert mg[0].kind == mtkOpenBracket
    assert mg[4].kind == mtkCloseBracket
    assert mg[2] == MToken(kind: mtkOperator, content: ":")
    MIdentifier(kind: mikRange, indexes: @[mg[1]] .. @[mg[3]])

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
    connectionBusRippers: seq[(MBusRipper, MPort)]


  for fpt in schema.freePlacedTexts:
    result.texts.add toText fpt

  for p in schema.ports:
    let
      mid = toMIdent(p.identifier)
      io = p.cbn.issome and p.cbn.get.kind == ctIntentionallyOpen
      val = p.cbn.map (it) => it.ident.name

      mp = mm.MPort(
        kind: mpCopy,
        position: p.position,
        wrapperKind: wkSchematic,
        isOpen: io,
        assignedValue: val,
        parent: icon.ports.search((it) => mid == it.id))

    result.ports.add mp
    allPortsMap[addr p[]] = mp

  block instances:
    template makeInstance(el, parentEl, t, argsSeq): untyped =
      let
        iname = el.ident.name
        myPorts = collect newseq:
          for i in 0 .. el.ports.high:
            let 
              instancePort = el.ports[i]
              p = copyPort(instancePort, parentEl.icon.ports[i])

            if p.isSliced:
              let 
                pos = instancePort.position
                b  = MBusRipper(
                  select: netSlice2MIdent lexCode instancePort.properties["NET_SLICE"],
                  source: nil, dest: nil,
                  position: pos, connection: pos)

              connectionBusRippers.add (b, p)

            p

      mm.MInstance(
        name: iname,
        geometry: el.geometry,
        parent: parentEl,
        transform: t,
        args: argsSeq,
        ports: myPorts)

    template makeParent(el, ico, a): untyped =
      let yourName {.inject.} = moduleName & "_" & randomHdlIdent()
      var parent = el
      parent.name = yourName
      parent.icon = ico
      parent.arch = a
      elements[parent.name] = parent
      parent

    for c in schema.components:
      let
        parent = mlk[c.parent.obid]
        ins = makeInstance(c, parent,
          getTransform c,
          extractArgs(c, parent.parameters))

      result.instances.add ins

      for i, p in c.ports:
        allPortsMap[addr p[]] = ins.ports[i]

    for pr in schema.processes:
      let
        el = makeParent(initProcessElement pr, extractIcon pr, toArch pr) # FIXME
        ins = makeInstance(pr, el,
          getTransform pr, @[])

      result.instances.add ins

      for i, p in pr.ports:
        allPortsMap[addr p[]] = ins.ports[i]

    for gb in schema.generateBlocks:
      let
        ico = extractIcon gb
        el = makeParent(makeGenerator gb, ico, toArch(buildSchema(yourName,
            gb.schematic, ico, mlk, elements), makSchema))
        ins = makeInstance(gb, el,
          getTransform gb, @[])

      for i, p in gb.ports:
        allPortsMap[addr p[]] = ins.ports[i]

      result.instances.add ins

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
      var mp = allPortsMap[addr p[]]
      mn.ports.add mp
      mp.nets.add mn

    result.nets.add mn
    allNetsMap[addr n[]] = mn

  for n in schema.nets: # bus rippers
    if n.part.kind == pkWire:
      for bp in n.part.busRippers:
        let connPos = case bp.side:
          of brsTopLeft: topLeft bp.geometry
          of brsTopRight: topRight bp.geometry
          of brsBottomRight: bottomRight bp.geometry
          of brsBottomLeft: bottomLeft bp.geometry

        let myBr = MBusRipper(
          select: getBusSelect(bp, n),
          source: allNetsMap[addr n[]],
          dest: allNetsMap[addr bp.destNet[]],
          position: center bp.geometry,
          connection: connPos)

        result.busRippers.add myBr
        myBr.source.busRippers.add myBr
        myBr.dest.busRippers.add myBr

  for (b, p) in connectionBusRippers:
    assert p.nets.len == 1
    let n = p.nets[0]
    b.source = n
    b.dest = n
    result.busRippers.add b
    n.busRippers.add b
    b.select = n.id
    
    let
      lastPos = p.position
      nextNode = n.connections[lastPos][0]
      dir = detectDir(lastPos .. nextNode)
      vdir = toUnitPoint dir
      buffOut = lastPos + vdir * 20
      buffIn = lastPos + vdir * 40

    n.connections.removeBoth lastPos, nextNode
    n.connections.addBoth buffIn, buffOut
    n.connections.addBoth buffOut, nextNode
    
    b.position = buffIn
    b.connection = buffIn
    


func choose(sa: seq[Architecture]): Architecture =
  result = sa[0]

  for i in sa:
    if i.kind == amBlockDiagram:
      result = i

proc toMiddle*(proj: em.Project): mm.MProject =
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
        toArch(buildSchema(m.name,
          a.body.schematic,
          m.icon,
          modernIdMap,
          result.modules), makSchema)

      of amStateDiagram: # FSM
        toArch(toMiddle a.body.stateMachine, makFSM)

      of amHDLFile:
        toArch toMiddle a.body.file

      of amTableDiagram:
        toArch toMiddle a.body.truthTable

      of amExternalHDLFIle:
        err "not implemented"
