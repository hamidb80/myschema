import std/[tables, options]
import ../common/defs

type
  ProcessType* = enum
    ptProcess = 1
    ptStateDiagram = 2
    ptConcurrentStatement = 3
    ptTruthTable = 5

  GenerateBlockType* = enum
    gbtForGenerate = 1
    gbtIfGenerate

  PortMode* = enum
    pmInput = 1
    pmOutput
    pmInout
    pmBuffer

  ArchitectureMode* = enum
    etBlockDiagram = 1 # Schema
    etHDLFile          # HDL code
    etStateDiagram     # FSM
    etTableDiagram     # truth table
    etExternalHDLFIle  # HDL code

  FlipMode* = enum
    vertical = 1
    horizontal
    both

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

  Alignment* = enum
    aBottomRight = 0
    aBottom = 1
    aBottomLeft = 2
    aRight = 3
    aCenter = 4
    aLeft = 5
    aTopRight = 6
    aTop = 7
    aTopLeft = 8
    # 8 7 6
    # 5 4 3
    # 2 1 0

  Side* = enum
    sTopToBottom
    sRightToLeft
    sBottomToTop
    sLeftToRight
    #   0
    # 3   1
    #   2

  # Rotation* = enum # AKA Side
  #   r0, r90, r180, r270

  BusRipperSide* = enum
    brsTopLeft
    brsTopRight
    brsBottomRight
    brsBottomLeft
    # 0 1
    # 3 2

  NumberDirection* = enum
    ndDec = 1
    ndInc

  CbnType* = enum
    ctConnectByName
    ctConnectByValue
    ctIntentionallyOpen

## NOTE: `type` fields is replaced with`kind`

type
  Obid* = distinct string

  Properties* = Table[string, string]

  Range* = object
    direction*: NumberDirection
    indexes*: Slice[string]

  ConstraintKind* = enum
    ckIndex, ckRange

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
    def_value*: Option[string]

  HdlIdent* = ref object
    name*: string
    attributes*: Attributes

  ObjStamp* = object
    designer*: string
    created*, modified*: int

  Size* = tuple
    w, h: int

  Geometry* = tuple
    x1, y1, x2, y2: int

  Wire* = Slice[Point]

  Label* = object
    position*: Point
    side*: Side
    scale*: int
    colorLine*: EaseColor
    alignment*: Alignment
    format*: int
    text*: string

  FreePlacedText* = distinct Label

  ConnectByName* = ref object # AKA CBN
    obid*: Obid
    kind*: CbnType
    ident*: HdlIdent
    geometry*: Geometry
    side*: Side
    label*: Label

  GenericKind* = enum
    gkRef, gkEntity, gkInstance

  Generic* = ref object ## entity generic
    obid*: Obid

    case kind*: GenericKind
    of gkRef: discard
    of gkEntity, gkInstance:
      ident*: HdlIdent
      geometry*: Geometry
      side*: Side
      label*: Label
      parent*: Option[Generic]

  GenerateKind* = enum
    ifGen, forGen

  GenerateBlock* = ref object
    obid*: Obid
    ident*: HdlIdent
    properties*: Properties
    geometry*: Geometry
    side*: Side
    label*: Label
    constraint*: Option[Constraint]
    ports*: seq[Port]
    kind*: GenerateBlockType
    schematic*: Schematic

  BusRipper* = ref object
    obid*: Obid
    ident*: HdlIdent
    geometry*: Geometry
    side*: Side
    label*: Label
    destNet*: Net

  NetKind* = enum
    netRef, netDef

  Net* = ref object
    obid*: Obid

    case kind*: NetKind:
    of netRef: discard
    of netDef:
      ident*: HdlIdent
      label*: Label
      wires*: seq[Wire]
      ports*: seq[Port]
      busRippers*: seq[BusRipper]


  Connection* = ref object
    obid*: Obid
    position*: Point # AKA geometry
    side*: Side
    label*: Label

  PortKind* = enum
    refprt
    eprt, pprt, aprt, cprt, gprt

  Port* = ref object
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
      connection*: Option[Connection]
      refObid*: Obid

  Process* = ref object
    obid*: Obid
    ident*: HdlIdent
    geometry*: Geometry
    side*: Side
    kind*: ProcessType
    label*: Label
    sensitivityList*: bool
    ports*: seq[Port]

  Component* = ref object
    obid*: Obid
    ident*: HdlIdent
    geometry*: Geometry
    side*: Side
    label*: Label
    ports*: seq[Port]
    parent*: Entity
    generics*: seq[Generic]

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


  Architecture* = ref object
    obid*: Obid
    properties*: Properties
    ident*: HdlIdent
    kind*: ArchitectureMode
    schematic*: Schematic


  EntityKind* = enum
    ekRef, ekDecl, ekDef

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
      objStamp*: ObjStamp
      componentSize*: Size
      generics*: seq[Generic]
      ports*: seq[Port]
      architectures*: seq[Architecture]


  LibraryKind* = enum
    lkDecl, lkDef

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


type
  LibraryEncodeMode* = enum
    lemRef
    lemDef

  EntityEncodeMode* = enum
    eemRef
    eemDef

# ----------------------------------------

func isEmpty*(attrs: Attributes): bool =
  (isNone attrs.mode) and
  (isNone attrs.kind) and
  (isNone attrs.constraint) and
  (isNone attrs.def_value)
