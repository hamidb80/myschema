import std/[tables, options, strutils, strformat, sugar]

import ../common/[coordination, domain, seqs, minitable, errors]

import model, logic
import ../middle/logic as mlogic
import ../middle/expr

# ------------------------------- sue model -> middle model

func extractNet(wires: seq[Wire]): MNet =
  let temp = toNets wires
  assert temp.len == 1, fmt"expected len 1 but got: {temp.len}"
  temp[0]

func toText(lbl: Label): MText =
  MText(
    position: lbl.position,
    texts: lbl.texts)

func toText(fpt: FreePlacedText): MText =
  toText Label fpt

func getTransform[T: Thing](smth: T): Transform =
  Transform(
    rotation: smth.rotation,
    flips: smth.flips)

func copyPort(pinstance: Port, pparent: MPort): MPort =
  MPort(
    kind: mpCopy,
    wrapperKind: wkInstance,
    position: pinstance.position,
    isSliced: "NET_SLICE" in pinstance.properties,
    parent: pparent)

func toPortDir(m: PortMode): MPortDir =
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

proc extractIcon[T: Thing](smth: T): MIcon =
  let
    geo = smth.geometry
    ro = smth.rotation
    tr = getIconTransformer(geo, ro)

  result = MIcon(size: getIconSize(geo, ro))

  for p in smth.ports:
    result.ports.add MPort(
      kind: mpOriginal,
      wrapperKind: wkIcon,
      id: toMIdent p.identifier,
      position: tr(p.position),
      wrapperIcon: result,
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
  result = MSchematic()


func toArch(sch: sink MSchematic): MArchitecture =
  result = MArchitecture(kind: makSchema)
  result.schema = sch

func toArch(tt: sink MTruthTable): MArchitecture =
  MArchitecture(kind: makTruthTable, truthTable: tt)

func toArch(cf: sink MCodeFile): MArchitecture =
  MArchitecture(kind: makCode, file: cf)

func toArch(pr: Process): MArchitecture =
  case toMElementKind pr.kind:
  of mekTruthTable: toArch toMiddle pr.body.truthTable
  of mekCode: toArch toMiddle pr.body.file
  of mekFSM: toArch toMiddle pr.body.stateMachine
  else: err "impossible"


proc initProcessElement(pr: Process): MElement =
  MElement(kind: toMElementKind pr.kind, arch: toArch pr)

proc initModule(en: Entity): MElement =
  MElement(
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
  schema: sink Schematic,
  icon: MIcon,
  lookup: Table[Obid, MElement],
  elements: var Table[string, MElement]
  ): MSchematic =

  result = MSchematic(size: toSize schema.sheetSize)

  var
    internalPortMap: Table[Obid, Port]
    externalPortMap: Table[Obid, MPort]
    externalNetMap: Table[Obid, MNet]
    connectionBusRippers: seq[(MBusRipper, MPort)]

  block instances:
    template makeInstance(el, parentEl, t, argsSeq): untyped =
      let
        iname = el.ident.name
        myPorts = collect newseq:
          for i in 0 .. el.ports.high:
            let
              originalPort = el.ports[i]

              p = copyPort(originalPort, parentEl.icon.ports[i]) # susspecius

            externalPortMap[originalPort.obid] = p
            internalPortMap[originalPort.obid] = originalPort

            if p.isSliced:
              let
                pos = originalPort.position
                b = MBusRipper(
                  select: netSlice2MIdent lexCode originalPort.properties[
                      "NET_SLICE"],
                  source: nil, dest: nil,
                  position: pos, connection: pos)

              connectionBusRippers.add (b, p)

            p

        ins = MInstance(
          name: iname,
          geometry: el.geometry,
          parent: parentEl,
          transform: t,
          args: argsSeq,
          ports: myPorts)

      result.instances.add ins
      ins

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
        parent = lookup[c.parent.obid]

      discard makeInstance(c, parent, getTransform c,
          extractArgs(c, parent.parameters))

    # FIXME do something about ports with the same name
    for pr in schema.processes:
      let
        el = makeParent(initProcessElement pr, extractIcon pr, toArch pr) # FIXME

      discard makeInstance(pr, el,
          getTransform pr, @[])


  for n in schema.nets:
    var mn =
      case n.part.kind:
      of pkTag: MNet(kind: mnkTag)
      of pkWire:
        var completeWires = n.part.wires

        for p in n.part.ports:
          let
            orgp = internalPortMap[p.obid]
            conn = orgp.connection.get
          completeWires.add conn.position .. orgp.position

        extractNet completeWires

    for p in n.part.ports:
      mn.ports.add externalPortMap[p.obid]

    result.nets.add mn
    externalNetMap[n.obid] = mn

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
          source: externalNetMap[n.obid],
          dest: externalNetMap[bp.destNet.obid],
          position: center bp.geometry,
          connection: connPos)

        result.busRippers.add myBr
        myBr.source.busRippers.add myBr
        myBr.dest.busRippers.add myBr


func choose(sa: seq[Architecture]): Architecture =
  result = sa[0]

  for i in sa:
    if i.kind == amBlockDiagram:
      result = i

