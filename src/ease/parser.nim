import std/[tables, strformat, strutils, os, sequtils, options]
import lisp
import ../utils, ../common/defs


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
  Properties = Table[string, string]

  Package* = ref object
    obid, library, name: string

  Project* = ref object
    obid: string
    properties: Properties
    designs: seq[Library]
    packages: seq[Package]
    # usedPackages: seq[tuple[suffix: string, pkg: Package]]

  Library* = ref object
    obid, name: string
    isResolved: bool
    properties: Properties
    entities: seq[Entity]

  Size = tuple[w, h: int]

  BusRipper = ref object

  Schematic = ref object
    obid: string
    sheetSize: Size

  Architecture = ref object
    obid, name: string
    kind: ArchitectureMode
    schematic: Schematic
    properties: Properties

  Component = ref object

  EntityGeneric = ref object
  InstanceGeneric = ref object

  PortInfo = tuple
    name: string
    mode: PortMode
    `type`: string
    busIndex: Option[Range[int]]

  EntityPort = ref object
    info: PortInfo
  
  ArchitecturePort = ref object
    info: PortInfo
   
  GeneratePort = ref object
    info: PortInfo

  ComponentPort = ref object
    info: PortInfo
    
  ProcessPort = ref object
    info: PortInfo
    
  NetPort = ref object
    info: PortInfo

  CBN = ref object
  
  Connection = ref object
  
  # TruthTable = ref object
  # ExtternalFile = ref object
  # HdlFile = ref object

  Net = ref object
  
  Generate = ref object

  FreePlacedText = object

  Geometry = tuple
    x1, y1, x2, y2: int

  Wire = Range[Point]

  Label = object
    position: Point
  
  ObjStamp = object
    designer: string
    created, modified: int

  Entity = object
    obid, name: string
    isResolved: bool
    properties: Properties
    architectures: seq[Architecture]
    ports: seq[EPort]
    componentSize: Size

type
  LibraryEncodeMode* = enum
    lemRef
    lemDef

  EntityEncodeMode* = enum
    eemRef
    eemDef


func select(sl: seq[LispNode]): LispNode {.inline.} =
  ## all .eas file styles:
  ## (DATABASE_VERSION 17)
  ## (...)
  ## (END_OF_FILE)
  ##
  ## this function selects the important one (second node)

  assert sl.len == 3
  sl[1]


func extractObid(obidNode: LispNode): string {.inline.} =
  obidNode.arg(0).str

func extractMode(hdlIdentNode: LispNode): int =
  ## (HDL_IDENT
  ##   (NAME)
  ##   (USERNAME)
  ##   (ATTRIBUTES 
  ##      (MODE <NUM>)
  ##      ...
  ##   )
  ## )
  
  try:
    hdlIdentNode
      .arg(2).assertIdent("ATTRIBUTES")
      .findNode(it |< "MODE").get
      .arg(0).vint

  except UnpackDefect, AssertionDefect:
    err "{ATTRIBUTES/MODE} not found"

func extractName(hdlIdentNode: LispNode): string {.inline.} =
  ## (HDL_IDENT
  ##   (NAME "...")
  ## )

  hdlIdentNode.arg(0).assertIdent("NAME").str

func parseGeometry(geometryNode: LispNode): Geometry = 
  ## (GEOMETRY startX startY endX endY)
  (geometryNode.args.mapIt it.vint).toTuple 4

func parsePosition(positionNode: LispNode): Point = 
  ## (POSITION X Y)
  (positionNode.arg(0).vint, positionNode.arg(1).vint)

func parseScale(scaleNode: LispNode): Positive = 
  # (SCALE N)
  scaleNode.arg(0).vint

func parseName(nameNode: LispNode): string {.inline.} = 
  nameNode.arg(0).str

func parseLabel(labelNode: LispNode): Label =
  ## (LABEL
  ##   (POSITION)
  ##   (SCALE)
  ##   (COLOR_LINE)
  ##   (SIDE)
  ##   (ALIGNMENT)
  ##   (FORMAT 1)
  ##   (TEXT "Instruction Decoder")
  ## )
  discard

func parseObjStamp(objStampNode: LispNode): ObjStamp = 
  ## (OBJSTAMP
  ##   (DESIGNER "HamidB80")
  ##   (CREATED 939908873 "Thu Oct 14 17:17:53 1999")
  ##   (MODIFIED 1340886716 "Thu Jun 28 17:01:56 2012")
  ## )

func parseProperties(propertiesNode: LispNode): Properties =
  for property in propertiesNode:
    result[property.arg(0).str] = property.arg(1).str

func parseAligment(alignmentNode: LispNode): Alignment {.inline.} = 
  ## (ALIGNMENT 0..8)
  alignmentNode.arg(0).vint.Alignment

func parseSide(sideNode: LispNode): Side {.inline.} = 
  ## (SIDE 0..3) 
  ## -- FOR TEXTS 0, 2 And 1, 3 looks similar
  Side sideNode.arg(0).vint

func parseColor(colorNode: LispNode): EaseColor {.inline.} = 
  ## (COLOR_LINE 0..71)
  EaseColor colorNode.arg(0).vint

func parseNet(netNode: LispNode): Net = 
  ## (NET
  ##   (OBID)
  ##   (HDL_IDENT)
  ##   (PART
  ##     (OBID "nprt<UNIQ_ID>")
  ##     (CBN 1)
  ##   )
  ##   (PART
  ##     (OBID "nprt<UNIQ_ID>")
  ##     (LABEL)
  ##     (WIRE) ...
  ##     (PORT
  ##       (OBID "<Port_Instance_Id>")
  ##       (NAME "<Port_Name>")
  ##     ) ... (2+)
  ##   )
  ## )

func parseWire(wireNode: LispNode): Wire {.inline.} = 
  ## (WIRE X1 Y1 X2 Y2)
  template s(n): untyped =  wireNode.arg(n).vint 
  (s 0, s 1) .. (s 2, s 3)

func parseMode(modeNode: LispNode): int = 
  ## (MODE N)
  modeNode.arg(0).vint

func parseType(typeNode: LispNode): string = 
  ## (TYPE "...")
  typeNode.arg(0).str

func extractPortInfoAttrImpl(attributesNode: LispNode, result: var PortInfo) =
  ## (ATTRIBUTES
  ##   (MODE 1)
  ##   (TYPE "TYPE NAME") ?
  ##   (DEF_VALUE "VALUE") ?
  ##   (CONSTRAINT ;; for BUS
  ##     (DIRECTION 1)
  ##     (RANGE "HIGH" "LOW")
  ##   )
  ## )
  
  for n in attributesNode:
    case n.ident:
    of "MODE":
      result.mode = PortMode parseMode n
    
    of "TYPE":
      result.`type` = parseType n

    of "CONSTRAINT":
      result.busIndex = some:
        n.arg(1).assertIdent("RANGE")
        .args.mapit(it.str.parseInt)
        .toRange()

    of "DEF_VALUE": discard
    else:
      err fmt"invalid node: {n.ident}"

func extractPortInfo(hdlIdentNode: LispNode): PortInfo =
  ## (HDL_IDENT
  ##   (NAME "Port Name")
  ##   (USERNAME 1)
  ##   (ATTRIBUTES)
  ## )
  
  for n in hdlIdentNode:
    case n.ident:
    of "NAME": 
      result.name = parseName n
    
    of "ATTRIBUTES":
      extractPortInfoAttrImpl n, result

    else:
      err fmt"invalid node: {n.ident}"

func parseEprt(portNode: LispNode): EPort =
  ## (PORT
  ##   (OBID)
  ##   (PROPERTIES)
  ##   (HDL_IDENT)
  ##   (GEOMETRY)
  ##   (SIDE)
  ##   (LABEL)
  ##   (GENERATE "port ref") ;; generate
  ##   (CONNECTION) ...
  ## )
  
  for n in portNode:
    case n.ident:
    of "HDL_IDENT":
      discard extractPortInfo(n)

    of "GEOMETRY":
      discard

    of "SIDE":
      discard

    of "LABEL":
      discard

    of "PROPERTIES":
      discard

    else:
      err "what?"

func parseIgen(): InstanceGeneric =
  discard

func parseGenB(): Generate =
  ## (GENERATE
  ##   (OBID)
  ##   (PROPERTIES
  ##     (PROPERTY "IF_CONDITION" "my_cond")
  ##     (PROPERTY "FOR_LOOP_VAR" "ident")
  ##   )
  ##   (HDL_IDENT)
  ##   (GEOMETRY)
  ##   (SIDE)
  ##   (LABEL)
  ##   (TYPE 2)
  ##   if for:
  ##     (CONSTRAINT
  ##       (DIRECTION 1)
  ##       (RANGE "max" "min")
  ##     )
  ##   (SCHEMATIC
  ##     (OBID)
  ##     (SHEETSIZE)
  ##   )
  ## )

func parseFreePlacedText(textNode: LispNode): FreePlacedText = 
  ## (FREE_PLACED_TEXT
  ##   (LABEL)
  ## )

func parseHook(busRipperNode: LispNode): BusRipper = 
  ## (BUS_RIPPER
  ##   (OBID)
  ##   (HDL_IDENT
  ##     (USERNAME 1)
  ##     (ATTRIBUTES
  ##       (CONSTRAINT
  ##         ;; single:
  ##           (INDEX "0")
  ##         ;; bus:
  ##           (DIRECTION 1)
  ##           (RANGE 0 1)
  ##       )
  ##     ) 
  ##   )
  ##   (GEOMETRY)
  ##   (SIDE)
  ##   (LABEL)
  ## )

func parseNCon(connectionNode: LispNode): Connection = 
  ## (CONNECTION
  ##   (OBID)
  ##   (GEOMETRY)
  ##   (SIDE 0)
  ##   (LABEL)
  ## )

func parseCbn(cbnNode: LispNode): CBN = 
  ## (CBN
  ##   (OBID)
  ##   (HDL_IDENT
  ##   (GEOMETRY)
  ##   (SIDE 1)
  ##   (LABEL
  ##     (POSITION 1462 694)
  ##     (SCALE 96)
  ##     (COLOR_LINE 0)
  ##     (SIDE 3)
  ##     (ALIGNMENT 5)
  ##     (FORMAT 1)
  ##   )
  ##   (TYPE 0)
  ## )

func parseComp(componentNode: LispNode): Component = 
  ## (COMPONENT
  ##   (OBID)
  ##   (HDL_IDENT)
  ##   (GEOMETRY)
  ##   (SIDE)
  ##   (LABEL)
  ##   (ENTITY "<lib_id>" "<entity_id>")
  ##   (PORT) ...
  ## )

func parseDiag(schematicNode: LispNode): Schematic = 
  ## (SCHEMATIC
  ##   (OBID)
  ##   (SHEETSIZE 0 0 <Width> <Height>)
  ##   (FREE_PLACED_TEXT) ...
  ##   (GENERIC) ...
  ##   (GENERATE) ...
  ##   (COMPONENT) ...
  ##   (PROCESS) ...
  ##   (PORT) ...
  ##   (NET) ...
  ## )
  
  for n in schematicNode:
    case n.ident:
    of "OBID": 
      result.obid = extractObid n
    
    of "FREE_PLACED_TEXT":
      discard

    of "GENERIC":
      discard

    of "GENERATE":
      discard

    of "COMPONENT":
      discard

    of "PROCESS":
      discard

    of "PORT":
      discard

    of "NET":
      discard

    else: 
      discard

func parseEnt(entityNode: LispNode, result: var Entity) {.inline.} =
  ## (ENTITY
  ##   (OBID)
  ##   (PROPERTIES ...)
  ##   (HDL_IDENT)
  ##   (GEOMETRY)
  ##   (SIDE 0)
  ##   (HDL 1)
  ##   (EXTERNAL 0)
  ##   (OBJSTAMP)
  ##   (GENERIC) ...
  ##   (PORT) ...
  ##   (ARCH_DECLARATION <TYPE_NO> "<id>" "<name>") ...
  ## )

  for n in entityNode:
    case n.ident:
    of "PROPERTIES":
      result.properties = parseProperties n

    of "OBID":
      result.obid = extractObid n

    of "HDL_IDENT":
      result.name = extractName n

    of "GEOMETRY":
      result.componentSize = parseGeometry(n).pickTuple([2, 3])

    of "PORT":
      result.ports.add parseEprt n

    of "ARCH_DECLARATION":
      result.obid = n.arg(0).str

    else: discard

func parseArch(archDefNode: LispNode): Architecture {.inline.} =
  ## (ARCH_DEFINITION
  ##   (OBID)
  ##   (HDL_IDENT)
  ##   (PROPERTIES ...)
  ##   (TYPE <TYPE_NO>)
  ##   (SCHEMATIC ...)
  ## )

  for n in archDefNode:
    case n.ident:
    of "OBID":
      result.obid = extractObid n

    of "TYPE":
      result.kind = ArchitectureMode n.arg(0).vint

    of "HDL_IDENT":
      result.name = extractName n
    
    of "PROPERTIES":
      result.properties = parseProperties n

    of "SCHEMATIC":
      result.schematic = parseDiag n

    else: discard

func parseEnt(entityFileNode: LispNode): Entity =
  ## (ENTITY_FILE
  ##   (ENTITY)
  ##   (ARCH_DEFINITION) ...
  ## )

  result.isResolved = true

  for n in entityFileNode:
    case n.ident:
    of "ENTITY":
      parseEnt(n, result)

    of "ARCH_DEFINITION":
      result.architectures.add parseArch n

    else: discard

func parseLib(designFileNode: LispNode): Library =
  ## (DESIGN_FILE
  ##   (OBID)
  ##   (PROPERTIES)
  ##   (COMPONENT_LIB 0)
  ##   (NAME "Lib_name")
  ##   (ENTITY "entity_name" "id") ...
  ##   (PACKAGE "pkg_name" "id") ...
  ##   (PACKAGE_USE) ...
  ## )

  result.isResolved = true

  for n in designFileNode:
    case n.ident:
    of "OBID":
      result.obid = extractObid n

    of "NAME":
      result.name = parseName n

    of "ENTITY":
      result.entities.add Entity(obid: n.arg(1).str, name: n.arg(0).str)

    of "PROPERTIES":
      result.properties = parseProperties n

    else: discard

func parseProj(projectFileNode: LispNode): Project =
  ## (PROJECT_FILE
  ##   (OBID)
  ##   (PROPERTIES ...)
  ##   (DESIGN "libname" "id") ...
  ##   (ENTITY "entity_name" "id") ...
  ##   (PACKAGE "pkg_name" "id") ...
  ##   (PACKAGE_USE ...) ...
  ## )

  for n in projectFileNode:
    case n.ident:
    of "PROPERTIES":
      result.properties = parseProperties n

    of "DESIGN":
      result.designs.add Library(obid: n.arg(0).str, name: n.arg(1).str)

    of "PACKAGE":
      result.packages.add Package(
        obid: n.arg(0).str,
        library: n.arg(1).str,
        name: n.arg(2).str)

    else: # PACKAGE_USE OBID
      discard

proc parseEws*(dir: string): Project =
  doAssert dir.endsWith ".ews", fmt"the workspace directory name must end with .ews"

  result = parseProj select parseLisp readfile dir / "project.ews"
  for d in mitems result.designs:
    let libdir = dir / d.obid
    d = parseLib select parseLisp libdir

    for e in mitems d.entities:
      e = parseEnt select parseLisp readfile libdir / e.obid & ".eas"


# FIXME add eprt gprt ....
# FIXME do not ignore other fields, eather raise error of ingonre them explicitly


# --- fliping a component:
#[
  (COMPONENT
    ...
    (PROPERTIES
      ...
      (PROPERTY "Flip" "1")
    )
    ...
  )
]#

# --- draft 
#[

  func parseExtf(externalFileNode: LispNode): ExtternalFile = 
    ## (EXTERNAL_FILE
    ##   (OBID "extff700001022bc0d264002b4d2a9a05a77")
    ##   (HDL_IDENT)
    ##   (FILE <Path>)
    ## )

  func parseHdlFile(hdlFileNode: LispNode): HdlFile =
    ## (HDL_FILE
    ##   (VHDL_FILE
    ##     (OBID)
    ##     (NAME "pr0.vhd")
    ##     (VALUE "lines of the file" ...)
    ##   )
    ## )

  func parseTtab(tableNode: LispNode): TruthTable = 
    ## (TABLE
    ##   (OBID)
    ##   (PROPERTIES)
    ##   (HEADER) ...
    ##   (ROW) ...
    ## )
    ## 
    ## (HEADER
    ##   (OBID)
    ##   (LABEL)
    ## )
    ## 
    ## (ROW
    ##   (OBID)
    ##   (CELL) ...
    ## )
    ## 
    ## (CELL
    ##   (OBID)
    ##   (LABEL)
    ## )
]#