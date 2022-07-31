import std/[options]
import ../common/[coordination, domain, minitable]

## NOTE: `type` fields is replaced with `kind`

# --- enums
type
  EaseColor* = enum
    ncBlack1, ncBlack2, ncBlack3, ncBlack4, ncBlack5, ncBlack6, ncBlack7, ncBlack8
    ncGray1, ncGray2, ncGray3, ncGray4, ncSmokeWhite, ncWhite, ncYellow, ncOrange1
    ncLemon, ncSkin, ncKhaki, ncBrown1, ncOrange2, ncOrange3, ncPeach, ncRed1
    ncRed2, ncRed3, ncRed4, ncRed5, ncBrown2, ncPink1, ncPink2, ncPink3
    ncPink4, ncGreen1, ncGreen2, ncGreen3, ncGreen4, ncGreen5, ncGreen6, ncGreen7
    ncGreen8, ncGreen9, ncGreen10, ncGreen11, ncGreen12, ncGreen13, ncTeal1, ncTeal2
    ncTeal3, ncTeal4, ncTeal5, ncCyan, ncBlue1, ncBlue2, ncPurplishBlue, ncBlue3
    ncBlue4, ncBlue5, ncBlue6, ncBlue7, ncBlue8, ncBlue9, ncBlue10, ncPurple1
    ncPurple2, ncPink5, ncPink6, ncPink7, ncPink8, ncPink9, ncPink10, ncPurple3

  Side* = enum
    sTopToBottom
    sRightToLeft
    sBottomToTop
    sLeftToRight
    #   0
    # 3   1
    #   2

  BusRipperSide* = enum
    brsTopLeft
    brsTopRight
    brsBottomRight
    brsBottomLeft
    # 0 1
    # 3 2

  PortMode* = enum
    pmInput = 1
    pmOutput
    pmInout
    pmBuffer
    pmUnknown

  CbnKind* = enum
    ctConnectByName
    ctConnectByValue
    ctIntentionallyOpen

  ArchitectureKind* = enum
    amBlockDiagram = 1 # Schema
    amHDLFile          # HDL code
    amStateDiagram     # FSM
    amTableDiagram     # truth table
    amExternalHDLFIle  # HDL code

  ProcessKind* = enum
    ptProcess
    ptStateDiagram
    ptConcurrentStatement
    ptTruthTable

  GenerateBlockKind* = enum
    gbtForGenerate = 1
    gbtIfGenerate

  ConstraintKind* = enum
    ckIndex, ckRange

  GenerateKind* = enum
    ifGen, forGen

  GenericKind* = enum
    gkRef, gkEntity, gkInstance

  NetKind* = enum
    netRef, netDef

  PartKind* = enum
    pkTag, pkWire

  PortKind* = enum
    refprt
    eprt, pprt, aprt, cprt, gprt

  EntityKind* = enum
    ekRef, ekDecl, ekDef

  LibraryKind* = enum
    lkDecl, lkDef

  LineKind* = enum
    straight = "TRANS_LINE"
    curved = "TRANS_SPLINE"

  StateKind* = enum
    skRef, skDef

  ConnectionKind* = enum
    ckRef, ckDef

  LinkKind* = enum
    linkRef, linkDef

  ActionKind* = enum
    actRef, actImpl, actDef

  ConditionKind* = enum
    condRef, condDef

  ConnectionNodeKind* = enum
    cnkLink, cnkState

  BodyKind* = enum
    bkSchematic
    bkStateMachine
    bkTruthTable
    bkCode


# --- type defs
type
  Obid* = distinct string

  Properties* = MiniTable[string, string]

  Range* = object
    direction*: NumberDirection
    indexes*: Slice[string]

  Constraint* = object
    case kind*: ConstraintKind
    of ckIndex:
      index*: string
    of ckRange:
      `range`*: Range

  Attributes* = object
    mode*: Option[int]
    kind*: Option[string]
    constraint*: Option[Constraint]
    defValue*: Option[string]

  HdlIdent* = ref object
    name*: string
    attributes*: Attributes

  ObjStamp* = object
    designer*: string
    created*, modified*: int

  Label* = object
    position*: Point
    side*: Side
    scale*: int
    colorLine*: EaseColor
    alignment*: Alignment
    format*: int
    texts*: seq[string]

  FreePlacedText* = distinct Label

  ConnectByName* = ref object # AKA CBN
    obid*: Obid
    kind*: CbnKind
    ident*: HdlIdent
    geometry*: Geometry
    side*: Side
    label*: Label

  Generic* = ref object ## entity generic
    obid*: Obid

    case kind*: GenericKind
    of gkRef: discard
    of gkEntity, gkInstance:
      ident*: HdlIdent
      properties*: Properties
      geometry*: Geometry
      side*: Side
      label*: Label
      parent*: Option[Generic]
      actValue*: Option[string]

  GenerateBlock* = ref object
    obid*: Obid
    ident*: HdlIdent
    properties*: Properties
    geometry*: Geometry
    side*: Side
    label*: Label
    constraint*: Option[Constraint]
    ports*: seq[Port]
    kind*: GenerateBlockKind
    schematic*: Schematic

  BusRipper* = ref object
    obid*: Obid
    ident*: HdlIdent
    geometry*: Geometry
    side*: BusRipperSide
    label*: Label
    cbn*: Option[ConnectByName]
    destNet*: Net

  Global* = ref object
    geometry*: Geometry
    label*: Label

  Link* = ref object
    obid*: Obid

    case kind*: LinkKind
    of linkRef: discard
    of linkDef:
      ident*: HdlIdent
      geometry*: Geometry
      side*: Side
      label*: Label
      connection*: Connection

  State* = ref object
    obid*: Obid

    case kind*: StateKind
    of skRef: discard
    of skDef:
      ident*: HdlIdent
      geometry*: Geometry
      side*: Side
      label*: Label
      number*: int
      coding*: string

  ConnectionNode* = object
    case kind*: ConnectionNodeKind
    of cnkLink:
      link*: Link

    of cnkState:
      state*: State

  Connection* = ref object
    obid*: Obid

    case kind*: ConnectionKind
    of ckRef: discard
    of ckDef:
      properties*: Properties
      geometry*: Geometry
      node*: ConnectionNode

  Arrow* = ref object
    number*: int
    points*: array[3, Point]
    label*: Label

  TransitionLine* = ref object
    obid*: Obid
    geometry*: Geometry
    side*: Side
    label*: Label
    # priority*: int
    # async*: bool
    connections*: Slice[Connection]
    condition*: Condition
    action*: Action
    arrow*: Arrow

    case kind*: LineKind
    of straight:
      points*: seq[Point]

    of curved:
      biezier*: seq[int]

  FsmDiagram* = ref object
    obid*: Obid
    sheetSize*: Geometry
    global*: Global
    states*: seq[State]
    transitions*: seq[TransitionLine]

  Code* = ref object
    lang*: Language
    lines*: seq[string]

  Slave* = ref object

  Condition* = ref object
    obid*: Obid

    case kind*: ConditionKind
    of condRef: discard
    of condDef:
      code*: Code

  Action* = ref object
    obid*: Obid

    case kind*: ActionKind
    of actRef: discard
    of actDef:
      geometry*: Geometry
      side*: Side
      label*: Label
      action*: Action
      index*: int

    of actImpl:
      name*: string
      mealy*: bool
      moore*: bool
      code*: Code

  StateMachineV2* = ref object
    obid*: Obid
    properties*: Properties
    actions*: seq[Action]
    conditions*: seq[Condition]
    fsm*: FsmDiagram

  Cell* = string
  Row* = seq[Cell]
  TruthTable* = ref object
    obid*: Obid
    properties*: Properties
    headers*: seq[string]
    rows*: seq[Row]

  Part* = ref object
    obid*: Obid
    ports*: seq[Port]

    case kind*: PartKind:
    of pkTag: discard
    of pkWire:
      label*: Label
      wires*: seq[Wire]
      busRippers*: seq[BusRipper]

  Net* = ref NetImpl

  NetImpl* = object
    obid*: Obid

    case kind*: NetKind:
    of netRef: discard
    of netDef:
      ident*: HdlIdent
      part*: Part # FIXME convert to seq[PART] / in system09 example

  PointConnection* = ref object
    obid*: Obid
    position*: Point # AKA geometry
    side*: Side
    label*: Label

  Port* = ref PortImpl

  HdlFile* = ref object
    name*: string
    lang*: Language
    content*: seq[string]

  PortImpl* = object
    obid*: Obid

    case kind*: PortKind
    of refprt:
      name*: string

    else:
      ident*: HdlIdent
      properties*: Properties
      geometry*: Geometry
      side*: Side
      label*: Label
      cbn*: Option[ConnectByName]
      connection*: Option[PointConnection]
      parent*: Option[Port]

  Process* = ref object
    obid*: Obid
    kind*: ProcessKind
    ident*: HdlIdent
    properties*: Properties
    sensitivityList*: bool
    geometry*: Geometry
    side*: Side
    ports*: seq[Port]
    label*: Label
    body*: Body

  Component* = ref object
    obid*: Obid
    ident*: HdlIdent
    properties*: Properties
    geometry*: Geometry
    side*: Side
    label*: Label
    ports*: seq[Port]
    generics*: seq[Generic]
    parent*: Entity

  Schematic* = ref object
    obid*: Obid
    sheetSize*: Geometry
    properties*: Properties

    freePlacedTexts*: seq[FreePlacedText]
    generics*: seq[Generic]
    generateBlocks*: seq[GenerateBlock]
    components*: seq[Component]
    processes*: seq[Process]
    ports*: seq[Port]
    nets*: seq[Net]

  Body* = object
    case kind*: BodyKind
    of bkCode:
      file*: HdlFile

    of bkStateMachine:
      stateMachine*: StateMachineV2

    of bkSchematic:
      schematic*: Schematic

    of bkTruthTable:
      truthTable*: TruthTable

  Architecture* = ref object
    obid*: Obid
    properties*: Properties
    ident*: HdlIdent
    kind*: ArchitectureKind
    body*: Body

  Entity* = ref object
    obid*: Obid

    case kind*: EntityKind
    of ekRef:
      libObid*: Obid

    of ekDecl:
      name*: string

    of ekDef:
      ident*: HdlIdent
      properties*: Properties
      side*: Side
      objStamp*: ObjStamp
      geometry*: Geometry
      generics*: seq[Generic]
      ports*: seq[Port]
      architectures*: seq[Architecture]

  Library* = ref object
    obid*: Obid
    name*: string

    case kind*: LibraryKind
    of lkDecl: discard
    of lkDef:
      properties*: Properties
      entities*: seq[Entity]

  Package* = ref object
    obid*: Obid
    library*, name*: string

  Project* = ref object
    obid*: Obid
    properties*: Properties
    designs*: seq[Library]
    packages*: seq[Package]
    # usedPackages: seq[tuple[suffix: string, pkg: Package]]

  Visible* = Component or Entity or Process or GenerateBlock

# semantics ---------------------------------

import std/[hashes]

func `==`*(o1, o2: Obid): bool {.borrow.}
func hash*(o: Obid): Hash {.borrow.}

func isEmpty*(attrs: Attributes): bool =
  (isNone attrs.mode) and
  (isNone attrs.kind) and
  (isNone attrs.constraint) and
  (isNone attrs.def_value)
