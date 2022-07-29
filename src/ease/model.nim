import std/[tables, options]
import ../common/[coordination, domain]

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
    amBlockDiagram = 1 # Schema
    amHDLFile          # HDL code
    amStateDiagram     # FSM
    amTableDiagram     # truth table
    amExternalHDLFIle  # HDL code

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
    # TODO add ACT_VALUE

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
      properties*: Properties
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
    cbn*: Option[ConnectByName]
    destNet*: Net

  NetKind* = enum
    netRef, netDef

  # FIXME add part1#cbn and part2

  PartKind* = enum
    pkTag, pkWire

  Part* = ref object
    obid*: Obid
    ports*: seq[Port]

    case kind*: PartKind:
    of pkTag: discard
    of pkWire:
      label*: Label
      wires*: seq[Wire]
      busRippers*: seq[BusRipper]

  Net* = ref object
    obid*: Obid

    case kind*: NetKind:
    of netRef: discard
    of netDef:
      ident*: HdlIdent
      part*: Part


  Connection* = ref object
    obid*: Obid
    position*: Point # AKA geometry
    side*: Side
    label*: Label

  PortKind* = enum
    refprt
    eprt, pprt, aprt, cprt, gprt

  Port* = ref PortImpl

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
      connection*: Option[Connection]
      parent*: Option[Port]

  Process* = ref object
    obid*: Obid
    ident*: HdlIdent
    properties*: Properties
    geometry*: Geometry
    side*: Side
    kind*: ProcessType
    label*: Label
    sensitivityList*: bool
    ports*: seq[Port]

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

  Architecture* = ref object
    obid*: Obid
    properties*: Properties
    ident*: HdlIdent
    kind*: ArchitectureMode
    schematic*: Option[Schematic]

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
      geometry*: Geometry
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

  Visible* = Component or Entity or Process or GenerateBlock


  # ----------------------------------------

import std/hashes

func `==`*(o1, o2: Obid): bool {.borrow.}
func hash*(o: Obid): Hash {.borrow.}

func isEmpty*(attrs: Attributes): bool =
  (isNone attrs.mode) and
  (isNone attrs.kind) and
  (isNone attrs.constraint) and
  (isNone attrs.def_value)
