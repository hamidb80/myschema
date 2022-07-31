import std/[tables, strformat, strutils, os, sequtils, options]
import lisp, model
import ../common/[coordination, tuples, errors, domain, minitable]

# {.experimental: "strictFuncs".}

func toBody(v: TruthTable): Body =
  Body(kind: bkTruthTable, truthTable: v)

func toBody(v: StateMachineV2): Body =
  Body(kind: bkStateMachine, stateMachine: v)

func toBody(v: Schematic): Body =
  Body(kind: bkSchematic, schematic: v)

func toBody(v: HdlFile): Body =
  Body(kind: bkCode, file: v)


func select*(sl: seq[LispNode]): LispNode {.inline.} =
  ## all .eas file styles:
  ## (DATABASE_VERSION 17)
  ## (...)
  ## (END_OF_FILE)
  ##
  ## this function selects the important one (second node)

  assert sl.len == 3
  sl[1]

func parseInt*(n: LispNode): int {.inline.} =
  n.arg(0).vint

func parseBool*(n: LispNode): bool {.inline.} =
  n.parseInt == 1

func parseStr*(n: LispNode): string {.inline.} =
  n.arg(0).str

# --- basic

func parseOBID(obidNode: LispNode): Obid {.inline.} =
  Obid obidNode.parseStr

func parseGeometry(geometryNode: LispNode): Geometry {.inline.} =
  (geometryNode.args.mapIt it.vint).toTuple 4

func parseSheetSize(sheetSizeNode: LispNode): Geometry {.inline.} =
  parseGeometry sheetSizeNode

func parsePosition(positionNode: LispNode): Point {.inline.} =
  (positionNode.arg(0).vint, positionNode.arg(1).vint)

func parseScale(scaleNode: LispNode): Positive {.inline.} =
  scaleNode.parseInt

func parseName(nameNode: LispNode): string {.inline.} =
  nameNode.parseStr

func parseProperties(propertiesNode: LispNode): Properties =
  for property in propertiesNode:
    result[property.arg(0).str] = property.arg(1).str

func parseAligment(alignmentNode: LispNode): Alignment {.inline.} =
  alignmentNode.parseInt.Alignment

func parseSide(sideNode: LispNode): Side {.inline.} =
  Side sideNode.parseInt

func parseColor(colorNode: LispNode): EaseColor {.inline.} =
  EaseColor colorNode.parseInt

func parseMode(modeNode: LispNode): int {.inline.} =
  modeNode.parseInt

func parseType(typeNode: LispNode): LispNode {.inline.} =
  typeNode.arg(0)

func parseFormat(formatNode: LispNode): int {.inline.} =
  formatNode.parseInt

func parseEntityRef(entityNode: LispNode): Entity {.inline.} =
  Entity(kind: ekRef,
    libObid: entityNode.arg(0).str.Obid,
    obid: entityNode.arg(1).str.Obid)

func parseDirection(directionNode: LispNode): NumberDirection {.inline.} =
  NumberDirection parseInt directionNode

func parseWire(wireNode: LispNode): Wire {.inline.} =
  template s(n): untyped = wireNode.arg(n).vint
  (s 0, s 1) .. (s 2, s 3)

func parseText(textNode: LispNode): seq[string] {.inline.} =
  textNode.args.mapIt(it.str)

func parseIndex(indexNode: LispNode): string {.inline.} =
  indexNode.parseStr

func parseDestNet(destNetNode: LispNode): Net =
  Net(kind: netRef, obid: parseOBID destNetNode)

func parseSensList(senslistNode: LispNode): bool {.inline.} =
  parseBool senslistNode

# --- compound

func parseConstraint(constraintNode: LispNode): Constraint =
  for n in constraintNode:
    case n.ident:
    of "INDEX":
      result = Constraint(kind: ckIndex, index: parseIndex n)

    of "DIRECTION":
      result = Constraint(kind: ckRange, `range`: Range(
          direction: parseDirection n))

    of "RANGE":
      result.`range`.indexes = (n.arg(0).str) .. (n.arg(1).str)

    of "NAME": discard
    else: err "invalid"

func parseAttributes(attributesNode: LispNode): Attributes =
  for n in attributesNode:
    case n.ident:
    of "MODE":
      result.mode = some parseMode n

    of "TYPE":
      result.kind = some parseType(n).str

    of "CONSTRAINT":
      result.constraint = some parseConstraint n

    of "DEF_VALUE":
      result.defValue = some parseStr n

    of "VERILOG_TYPE": discard
    else: err fmt"invalid attribute: {n.ident}"

func parseHDLIdent(hdlIdentNode: LispNode): HdlIdent =
  result = new HdlIdent

  for n in hdlIdentNode:
    case n.ident:
    of "NAME":
      result.name = parseName n

    of "ATTRIBUTES":
      result.attributes = parseAttributes n

    of "USERNAME": discard
    else: err "invalid"


func parseLabel(labelNode: LispNode): Label =
  for n in labelNode:
    case n.ident:
    of "POSITION":
      result.position = parsePosition n

    of "SCALE":
      result.scale = parseScale n

    of "COLOR_LINE":
      result.color_line = parseColor n

    of "SIDE":
      result.side = parseSide n

    of "ALIGNMENT":
      result.alignment = parseAligment n

    of "FORMAT":
      result.format = parseFormat n

    of "TEXT":
      result.texts = parseText n

    else: err "invalid field"

func parseFreePlacedText(textNode: LispNode): FreePlacedText =
  FreePlacedText parseLabel textNode.arg(0)


func parseObjStamp(objStampNode: LispNode): ObjStamp =
  ObjStamp(
    designer: objStampNode.arg(0).parseStr,
    created: objStampNode.arg(1).parseInt,
    modified: objStampNode.arg(2).parseInt)

# --- complex

func parseCbn(cbnNode: LispNode): ConnectByName =
  result = new ConnectByName

  for n in cbnNode:
    case n.ident:
    of "OBID":
      result.obid = parseOBID n

    of "HDL_IDENT":
      result.ident = parseHDLIdent n

    of "GEOMETRY":
      result.geometry = parseGeometry n

    of "SIDE":
      result.side = parseSide n

    of "LABEL":
      result.label = parseLabel n

    of "TYPE":
      result.kind = CbnKind parseType(n).vint

    else:
      err "invalid field"

func parseHook(busRipperNode: LispNode): BusRipper =
  result = new BusRipper

  for n in busRipperNode:
    case n.ident:
    of "OBID":
      result.obid = parseOBID n

    of "HDL_IDENT":
      result.ident = parseHDLIdent n

    of "GEOMETRY":
      result.geometry = parseGeometry n

    of "SIDE":
      result.side = BusRipperSide parseInt n

    of "LABEL":
      result.label = parseLabel n

    of "DEST_NET":
      result.destNet = parseDestNet n

    of "CBN":
      result.cbn = some parseCbn n

    else: err "invalid"

func parseNCon(connectionNode: LispNode): PointConnection =
  result = new PointConnection

  for n in connectionNode:
    case n.ident:
    of "OBID":
      result.obid = parseOBID n

    of "GEOMETRY":
      result.position = parsePosition n

    of "SIDE":
      result.side = parseSide n

    of "LABEL":
      result.label = parseLabel n

    else: err "invalid"


func parseRefPort(refNode: LispNode): Port =
  Port(obid: parseOBID refNode, kind: refprt)

func parsePort(portNode: LispNode, pk: PortKind): Port =
  result = Port(kind: pk)

  for n in portNode:
    case n.ident:
    of "OBID":
      result.obid = parseOBID n

    of "NAME":
      result.name = parseName n

    of "HDL_IDENT":
      result.ident = parseHDLIdent n

    of "PROPERTIES":
      result.properties = parseProperties n

    of "GEOMETRY":
      result.geometry = parseGeometry n

    of "SIDE":
      result.side = parseSide n

    of "LABEL":
      result.label = parseLabel n

    of "CONNECTION":
      result.connection = some parseNCon n

    of "PORT", "GENERATE":
      result.parent = some parseRefPort n

    of "CBN":
      result.cbn = some parseCbn n

    else: err "what?"

func parseNetPart(part2Node: LispNode, k: PartKind): Part =
  result = Part(kind: k)

  for n in part2Node:
    case n.ident:
    of "OBID":
      result.obid = parseOBID n

    of "LABEL":
      result.label = parseLabel n

    of "WIRE":
      result.wires.add parseWire n

    of "PORT":
      result.ports.add parsePort(n, refprt)

    of "BUS_RIPPER":
      result.busRippers.add parseHook n

    of "CBN": discard
    else: err "invalid"

func parseNet(netNode: LispNode): Net =
  result = Net(kind: netDef)

  for n in netNode:
    case n.ident:
    of "OBID":
      result.obid = parseOBID n

    of "HDL_IDENT":
      result.ident = parseHDLIdent n

    of "PART":
      result.part = parseNetPart n:
        if result.part == nil:
          pkTag
        elif result.part.ports.len == 0:
          pkWire
        else:
          pkWire
          # err fmt"part is already full: {result.obid.string}"

func parseGeneric(genericNode: LispNode, gkind: GenericKind): Generic =
  result = Generic(kind: gkind) # FIXME `scriptfunction` complains here

  for n in genericNode:
    case n.ident:
    of "OBID":
      result.obid = parseOBID n

    of "PROPERTIES":
      result.properties = parseProperties n

    of "HDL_IDENT":
      result.ident = parseHDLIdent n

    of "GEOMETRY":
      result.geometry = parseGeometry n

    of "SIDE":
      result.side = parseSide n

    of "LABEL":
      result.label = parseLabel n

    of "GENERIC":
      result.parent = some Generic(kind: gkRef, obid: parseOBID n)

    of "ACT_VALUE":
      result.actValue = some parseStr n

    else: err fmt"invalid field {n.ident}"

func parseComp(componentNode: LispNode): Component =
  result = new Component

  for n in componentNode:
    case n.ident:
    of "OBID":
      result.obid = parseOBID n

    of "PROPERTIES":
      result.properties = parseProperties n

    of "HDL_IDENT":
      result.ident = parseHDLIdent n

    of "GEOMETRY":
      result.geometry = parseGeometry n

    of "SIDE":
      result.side = parseSide n

    of "LABEL":
      result.label = parseLabel n

    of "ENTITY":
      result.parent = parseEntityRef n

    of "GENERIC":
      result.generics.add parseGeneric(n, gkInstance)

    of "PORT":
      result.ports.add parsePort(n, cprt)

    of "TYPE", "CONSTRAINT": discard
    else: err fmt"invalid {n.ident}"

func detectLanguage(tag: string): Language =
  case tag:
  of "VERILOG_FILE", "VERILOG_TEXT": Verilog
  of "VHDL_FILE", "VHDL_TEXT": VHDL
  else: err fmt"invalid code file: {tag}"

func parseHdlFileImple(fileNode: LispNode, result: var HdlFile) =
  result.lang = detectLanguage fileNode.ident

  for n in fileNode:
    case n.ident:
    of "OBID": discard
    of "NAME":
      result.name = parseName n

    of "VALUE":
      result.content = parseText n

func parseHdlFile(hdlFileNode: LispNode): HdlFile =
  result = new HdlFile
  parseHdlFileImple hdlFileNode.arg(0), result

func parseCode(codeTextNode: LispNode): Code =
  Code(
    lang: detectLanguage codeTextNode.ident,
    lines: parseText codeTextNode)

func parseFsmp(globalNode: LispNode): Global =
  result = new Global

  for n in globalNode:
    case n.ident:
    of "GEOMETRY":
      result.geometry = parseGeometry n

    of "LABEL":
      result.label = parseLabel n

func parseStat(stateNode: LispNode): State =
  result = State(kind: skDef)

  for n in stateNode:
    case n.ident:
    of "OBID":
      result.obid = parseOBID n

    of "HDL_IDENT":
      result.ident = parseHDLIdent n

    of "GEOMETRY":
      result.geometry = parseGeometry n

    of "SIDE":
      result.side = parseSide n

    of "LABEL":
      result.label = parseLabel n

    of "NUMBER":
      result.number = parseInt n

    of "CODING":
      result.coding = parseStr n

    of "FSM_DIAGRAM":
      err "what" # i think it's nested

    else:
      err fmt"invalid node '{n.ident}' for STATE"

func parseLab(actionNode: LispNode): Action =
  result = Action(kind: actImpl)

  for n in actionNode:
    case n.ident:
    of "OBID":
      result.obid = parseOBID n

    of "NAME":
      result.name = parseName n

    of "MEALY":
      result.mealy = parseBool n

    of "MOORE":
      result.moore = parseBool n

    of "VERILOG_TEXT", "VHDL_TEXT":
      result.code = parseCode(n)

    of "SHOW_LABEL": discard
    else:
      err fmt"invalid node '{n.ident}' for lab"

func parseLab(conditionNode: LispNode): Condition =
  result = Condition(kind: condDef)

  for n in conditionNode:
    case n.ident:
    of "OBID":
      result.obid = parseOBID n

    of "VERILOG_TEXT", "VHDL_TEXT":
      result.code = parseCode(n)

    of "NAME", "MEALY", "MOORE", "SHOW_LABEL": discard
    else:
      err fmt"invalid node '{n.ident}' for lab"

func parseActionRef(actionRefNode: LispNode): Action =
  Action(kind: actRef, obid: parseOBID actionRefNode)

func parseAct(actionNode: LispNode): Action =
  result = Action(kind: actDef)

  for n in actionNode:
    case n.ident:
    of "OBID":
      result.obid = parseOBID n

    of "GEOMETRY":
      result.geometry = parseGeometry n

    of "SIDE":
      result.side = parseSide n

    of "LABEL":
      result.label = parseLabel n

    of "ACTION":
      result.action = parseActionRef n

    of "INDEX":
      result.index = parseInt n

    else:
      err fmt"invalid node '{n.ident}'"

func toConnectionNode(state: State): ConnectionNode =
  ConnectionNode(kind: cnkState, state: state)

func toConnectionNode(link: Link): ConnectionNode =
  ConnectionNode(kind: cnkLink, link: link)

func parseLinkRef(connNode: LispNode): Link =
  Link(kind: linkRef, obid: parseOBID connNode)

func parseStateRef(connNode: LispNode): State =
  State(kind: skRef, obid: parseOBID connNode)

func parseConnection(connNode: LispNode): Connection =
  result = Connection(kind: ckDef)

  for n in connNode:
    case n.ident:
    # of "OBID": discard
    of "GEOMETRY":
      result.geometry = parseGeometry n

    of "PROPERTIES":
      result.properties = parseProperties n

    of "STATE":
      result.node = toConnectionNode parseStateRef n

    of "LINK":
      result.node = toConnectionNode parseLinkRef n

    else:
      err fmt"invalid node '{n.ident}'"

func parseArrow(arrowNode: LispNode): Arrow =
  for n in arrowNode:
    case n.ident:
    of "NUMBER":
      result.number = parseInt n

    of "ARROW_BPOS":
      result.points[0] = parsePosition n

    of "ARROW_MPOS":
      result.points[1] = parsePosition n

    of "ARROW_EPOS":
      result.points[2] = parsePosition n

    of "LABEL":
      result.label = parseLabel n

    else:
      err fmt"invalid node '{n.ident}'"

func parseBezier(bezierNode: LispNode): seq[int] =
  bezierNode.args.mapIt it.vint

func parsePoints(pointsNode: LispNode): seq[Point] =
  pointsNode.args.mapIt (it.arg(0).vint, it.arg(1).vint)

func parseConditionRef(connectionRefNode: LispNode): Condition =
  Condition(kind: condRef, obid: parseOBID connectionRefNode)

func parseTran(lineNode: LispNode): TransitionLine =
  result = TransitionLine(kind: parseEnum[LineKind](lineNode.ident))

  for n in lineNode:
    case n.ident:
    of "OBID":
      result.obid = parseOBID n

    of "GEOMETRY":
      result.geometry = parseGeometry n

    of "SIDE":
      result.side = parseSide n

    of "FROM_CONN":
      result.connections.a = parseConnection n

    of "TO_CONN":
      result.connections.b = parseConnection n

    of "ACTION":
      result.action = parseAct n

    of "CONDITION":
      result.condition = parseConditionRef n

    of "ARROW":
      result.arrow = parseArrow n

    of "BEZIER":
      result.biezier = parseBezier n

    of "POINTS":
      result.points = parsePoints n

    of "ASYNC, PRIORITY": discard
    else:
      err fmt"invalid node '{n.ident}'"

func parseFsm(fsmDiagramNode: LispNode): FsmDiagram =
  result = new FsmDiagram

  for n in fsmDiagramNode:
    case n.ident:
    of "OBID":
      result.obid = parseOBID n

    of "SHEETSIZE":
      result.sheetSize = parseSheetSize n

    of "GLOBAL":
      result.global = parseFsmp n

    of "STATE":
      result.states.add parseStat n

    of "TRANS_SPLINE":
      result.transitions.add parseTran n

func parseFsmx(stateDiagramNode: LispNode): StateMachineV2 =
  result = new StateMachineV2

  for n in stateDiagramNode:
    case n.ident:
    of "OBID":
      result.obid = parseOBID n

    of "PROPERTIES":
      result.properties = parseProperties n

    of "ACTION":
      result.actions.add parseLab(actionNode = n)

    of "CONDITION":
      result.conditions.add parseLab(conditionNode = n)

    of "FSM_DIAGRAM":
      result.fsm = parseFSM n

    else:
      err fmt"invalid node '{n.ident}' for STATE_MACHINE_V2"

func parseCell(cell: LispNode): string =
  for n in cell:
    case n.ident:
    of "LABEL":
      let txts = n.parseLabel.texts
      return
        if txts.len == 0: ""
        else: txts[0]

func parseTHdr(header: LispNode): string =
  parseCell header

func parseTRow(row: LispNode): Row =
  for n in row:
    case n.ident:
    of "OBID": discard
    of "CELL": result.add parseCell n
    else: err fmt"invalid node {n.ident} for ROW"

func parseTtab(truthTableNode: LispNode): TruthTable =
  result = new TruthTable

  for n in truthTableNode:
    case n.ident:
    of "OBID":
      result.obid = parseOBID n

    of "HEADER":
      result.headers.add parseTHdr n

    of "ROW":
      result.rows.add parseTRow n

    of "PROPERTIES":
      result.properties = parseProperties n

    else:
      err fmt"invalid node {n.ident} for TABLE"

func parseProc(processNode: LispNode): Process =
  result = new Process

  for n in processNode:
    case n.ident:
    of "OBID":
      result.obid = parseOBID n

    of "HDL_IDENT":
      result.ident = parseHDLIdent n

    of "PROPERTIES":
      result.properties = parseProperties n

    of "GEOMETRY":
      result.geometry = parseGeometry n

    of "SIDE":
      result.side = parseSide n

    of "TYPE":
      result.kind = ProcessKind (parseType n).vint

    of "LABEL":
      result.label = parseLabel n

    of "SENSLIST":
      result.sensitivityList = parseSensList n

    of "PORT":
      result.ports.add parsePort(n, pprt)

    of "TABLE":
      result.body = toBody parseTtab n

    of "STATE_MACHINE_V2":
      result.body = toBody parseFsmx n

    of "HDL_FILE":
      result.body = toBody parseHdlFile n

    else: err "invalid"

func parseDiag(schematicNode: LispNode): Schematic

func parseGenB(generateNode: LispNode): GenerateBlock =
  result = new GenerateBlock

  for n in generateNode:
    case n.ident:
    of "OBID":
      result.obid = parseOBID n

    of "PROPERTIES":
      result.properties = parseProperties n

    of "HDL_IDENT":
      result.ident = parseHDLIdent n

    of "GEOMETRY":
      result.geometry = parseGeometry n

    of "CONSTRAINT":
      result.constraint = some parseConstraint n

    of "SIDE":
      result.side = parseSide n

    of "LABEL":
      result.label = parseLabel n

    of "TYPE":
      result.kind = GenerateBlockKind parseType(n).vint

    of "PORT":
      result.ports.add parsePort(n, gprt)

    of "SCHEMATIC":
      result.schematic = parsediag n

    else: err "invalid"

func parseDiag(schematicNode: LispNode): Schematic =
  result = new Schematic

  for n in schematicNode:
    case n.ident:
    of "OBID":
      result.obid = parseOBID n

    of "PROPERTIES":
      result.properties = parseProperties n

    of "SHEETSIZE":
      result.sheetSize = parseSheetSize n

    of "FREE_PLACED_TEXT":
      result.freePlacedTexts.add parseFreePlacedText n

    of "GENERIC":
      result.generics.add parseGeneric(n, gkInstance)

    of "GENERATE":
      result.generateBlocks.add parseGenB n

    of "PROCESS":
      result.processes.add parseProc n

    of "COMPONENT":
      result.components.add parseComp n

    of "PORT":
      result.ports.add parsePort(n, aprt)

    of "NET":
      result.nets.add parseNet n

    of "INCLUDED_TEXT", "DECLARATION": discard
    else: err "invalid"

func parseArch(archDefNode: LispNode): Architecture =
  result = new Architecture

  for n in archDefNode:
    case n.ident:
    of "OBID":
      result.obid = parseOBID n

    of "TYPE":
      result.kind = ArchitectureKind n.parseInt

    of "HDL_IDENT":
      result.ident = parseHDLIdent n

    of "PROPERTIES":
      result.properties = parseProperties n

    of "SCHEMATIC":
      result.body = toBody parseDiag n

    of "TABLE":
      result.body = toBody parseTtab n

    of "STATE_MACHINE_V2":
      result.body = toBody parseFsmx n

    of "HDL_FILE":
      result.body = toBody parseHdlFile n

    else: err fmt"invalid field: {n.ident}"

func parseEnt(entityNode: LispNode, result: var Entity) =
  for n in entityNode:
    case n.ident:
    of "PROPERTIES":
      result.properties = parseProperties n

    of "OBID":
      result.obid = parseOBID n

    of "SIDE":
      result.side = parseSide n

    of "HDL_IDENT":
      result.ident = parseHDLIdent n

    of "GEOMETRY":
      result.geometry = parseGeometry n

    of "GENERIC":
      result.generics.add parseGeneric(n, gkEntity)

    of "PORT":
      result.ports.add parsePort(n, eprt)

    of "OBJSTAMP":
      result.objStamp = parseObjStamp n

    of "ARCH_DECLARATION", "PACKAGE_USE", "HDL", "EXTERNAL",
        "DEFAULT_CONFIG", "CONFIG_DECL", "INCLUDE_STATEMENT": discard
    else: err fmt"invalid {n.ident}"

func parseEntityFile(entityFileNode: LispNode): Entity =
  result = Entity(kind: ekDef)

  for n in entityFileNode:
    case n.ident:
    of "ENTITY":
      parseEnt n, result

    of "ARCH_DEFINITION":
      result.architectures.add parseArch n

    of "CONFIGURATION": discard
    else: err fmt"invalid {n.ident}"

func parseEntityDecl(edn: LispNode): Entity =
  Entity(kind: ekDecl,
    name: edn.arg(0).str,
    obid: edn.arg(1).str.Obid)

func parseLib(designFileNode: LispNode): Library =
  result = Library(kind: lkDef)

  for n in designFileNode:
    case n.ident:
    of "OBID":
      result.obid = parseOBID n

    of "NAME":
      result.name = parseName n

    of "ENTITY":
      result.entities.add parseEntityDecl n

    of "PROPERTIES":
      result.properties = parseProperties n

    of "COMPONENT_LIB", "PACKAGE", "PACKAGE_USE", "VIRTUAL_PACKAGE",
        "TEXT_FILE", "INCLUDE_STATEMENT": discard
    else: err fmt"invalid ident: {n.ident}"

func parseLibDecl(libraryNode: LispNode): Library =
  Library(kind: lkDecl,
    name: libraryNode.arg(0).str,
    obid: libraryNode.arg(1).str.Obid)

func parsePack(packageNode: LispNode): Package =
  Package(
    obid: packageNode.arg(0).parseOBID,
    library: packageNode.arg(1).parseStr,
    name: packageNode.arg(2).parseStr)

func parseProj(projectFileNode: LispNode): Project =
  result = new Project

  for n in projectFileNode:
    case n.ident:
    of "OBID":
      result.obid = parseOBID n

    of "PROPERTIES":
      result.properties = parseProperties n

    of "DESIGN", "COMPONENT_LIB":
      result.designs.add parseLibDecl n

    of "PACKAGE":
      result.packages.add parsePack n

    of "PACKAGE_USE", "EXTERNAL_DOC", "INCLUDE_STATEMENT": discard
    else: err fmt"invalid ident: {n.ident}"


func resolve(genb: var GenerateBlock) =
  ## resolves port references inside generate block
  ##
  ## generate def ports are referd to schematic port
  ## generate boy ports are refered to def port :-/
  ## 2 way connection

  var portMap: Table[Obid, Port]

  for p in genb.ports:
    portMap[p.obid] = p

  for p in genb.schematic.ports:
    let
      pg_obid = p.parent.get.obid
      pg = portMap[pg_obid]

    p.parent = some pg
    pg.parent = some p

func resolve(proj: var Project) =
  ## there are several types of resolving:
  ## schema:
  ##   ports <- refers to ports from entity def
  ##
  ## process:
  ##   ports
  ##
  ## net/part2:
  ##   port
  ##   BusRipper:
  ##     destination net
  ##
  ## component:
  ##   entity ref
  ##   ports ref
  ##

  var
    entityMap: Table[Obid, Entity]
    portMap: Table[Obid, Port]
    netMap: Table[Obid, Net]

  # phase 1. finding
  for d in proj.designs:
    for e in d.entities:
      entityMap[e.obid] = e

      for p in e.ports:
        portMap[p.obid] = p

      for a in e.architectures:
        case a.kind:
        of amBlockDiagram:
          let s = a.body.schematic

          for p in s.ports:
            portMap[p.obid] = p

          for n in s.nets:
            netMap[n.obid] = n

          for c in s.components:
            for p in c.ports:
              portMap[p.obid] = p

          for pr in s.processes:
            for p in pr.ports:
              portMap[p.obid] = p

          for gb in mitems s.generateBlocks:
            resolve gb

            for p in gb.ports:
              portMap[p.obid] = p

        else: discard

  # phasw 2. resolving
  for d in proj.designs:
    for e in d.entities:

      for a in e.architectures:
        if a.kind == amBlockDiagram:
          let s = a.body.schematic

          for c in s.components:
            c.parent = entityMap[c.parent.obid]

            for p in c.ports:
              p.parent = some portMap[p.parent.get.obid]

          for n in s.nets:
            if n.part.kind == pkWire:
              for br in n.part.busRippers:
                br.destNet = netMap[br.destNet.obid]

            for p in mitems n.part.ports:
              p = portMap[p.obid]


proc parseEws*(dir: string): Project =
  doAssert dir.endsWith ".ews", fmt"the workspace directory name must end with .ews"
  let dbDir = dir / "ease.db"


  result = parseProj select parseLisp readfile dbDir / "project.eas"
  for d in mitems result.designs:
    let libdir = dbDir / d.obid.string
    d = parseLib select parseLisp readFile libdir / "library.eas"

    for e in mitems d.entities:
      e = parseEntityFile select parseLisp readfile libdir / e.obid.string & ".eas"


  resolve result
