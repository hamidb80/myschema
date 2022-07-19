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

  BusRipperSide* = enum
    brsTopLeft
    brsTopRight
    brsBottomRight
    brsBottomLeft
    # 0 1
    # 3 2

type
  Properties* = Table[string, string]

  Package* = ref object
    obid*, library*, name*: string

  Project* = ref object
    obid*: string
    properties*: Properties
    designs*: seq[Library]
    packages*: seq[Package]
    # usedPackages: seq[tuple[suffix: string, pkg: Package]]

  Library* = ref object
    obid*, name*: string
    isResolved*: bool
    properties*: Properties
    entities*: seq[Entity]

  Size* = tuple[w, h: int]

  BusRipper* = ref object

  Schematic* = ref object
    obid*: string
    sheetSize*: Size

  Architecture* = ref object
    obid*, name*: string
    kind*: ArchitectureMode
    schematic*: Schematic
    properties*: Properties

  EntityRef* = tuple
    libObid, entityObid: string

  Component* = ref object
    obid*, name*: string
    geometry*: Geometry
    side*: Side
    label*: Label
    instanceof*: EntityRef

  EntityGeneric* = ref object
  
  InstanceGeneric* = ref object

  PortInfo* = object
    name*: string
    mode*: PortMode
    `type`*: string
    busIndex*: Option[Range[int]]

  EntityPort* = ref object
    info*: PortInfo

  ArchitecturePort* = ref object
    info*: PortInfo

  GeneratePort* = ref object
    info*: PortInfo

  ComponentPort* = ref object
    info*: PortInfo

  ProcessPort* = ref object
    info*: PortInfo

  ConnectByName* = ref object

  Connection* = ref object

  Net* = ref object
  Generate* = ref object
  
  FreePlacedText* = object
    label*: Label

  Geometry* = tuple
    x1, y1, x2, y2: int

  Wire* = Range[Point]

  Label* = object
    position*: Point
    side*: Side
    scale*: int
    colorLine*: EaseColor
    alignment*: Alignment
    format*: int
    text*: string


  ObjStamp* = object
    designer*: string
    created*, modified*: int

  Entity* = object
    obid*, name*: string
    isResolved*: bool
    properties*: Properties
    architectures*: seq[Architecture]
    ports*: seq[EntityPort]
    componentSize*: Size

type
  LibraryEncodeMode* = enum
    lemRef
    lemDef

  EntityEncodeMode* = enum
    eemRef
    eemDef
