import std/[tables, strformat, strutils, os, sequtils, options]
import lisp, defs
import ../utils, ../common/defs as cdef


# FIXME do not ignore other fields, eather raise error of ingonre them explicitly

func select*(sl: seq[LispNode]): LispNode {.inline.} =
  ## all .eas file styles:
  ## (DATABASE_VERSION 17)
  ## (...)
  ## (END_OF_FILE)
  ##
  ## this function selects the important one (second node)

  assert sl.len == 3
  sl[1]

# --- basic

func parseOBID(obidNode: LispNode): Obid {.inline.} =
  Obid obidNode.arg(0).str

func parseGeometry(geometryNode: LispNode): Geometry {.inline.} = 
  ## (GEOMETRY startX startY endX endY)
  (geometryNode.args.mapIt it.vint).toTuple 4

func parseSheetSize(sheetSizeNode: LispNode): Geometry  {.inline.} = 
  ## (GEOMETRY startX startY endX endY)
  parseGeometry sheetSizeNode

func parsePosition(positionNode: LispNode): Point {.inline.} = 
  ## (POSITION X Y)
  (positionNode.arg(0).vint, positionNode.arg(1).vint)

func parseScale(scaleNode: LispNode): Positive {.inline.} = 
  ## (SCALE N)
  scaleNode.arg(0).vint

func parseName(nameNode: LispNode): string {.inline.} = 
  ## (NAME "...")
  nameNode.arg(0).str

func parseProperties(propertiesNode: LispNode): Properties =
  ## (PROPERTIES
  ##   (PROPERTY "Key" "Value") ...
  ## )

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

func parseMode(modeNode: LispNode): int  {.inline.}= 
  ## (MODE N)
  modeNode.arg(0).vint

func parseType(typeNode: LispNode): LispNode {.inline.} = 
  ## (TYPE "...")
  typeNode.arg(0)

func parseFormat(formatNode: LispNode): int {.inline.} =
  ## (FORMAT N)
  formatNode.arg(0).vint

func parseEntityRef(entityNode: LispNode): Entity {.inline.} =
  Entity(kind: ekRef, 
    libObid: entityNode.arg(0).str.Obid,
    obid: entityNode.arg(1).str.Obid)

func parseDirection(directionNode: LispNode): NumberDirection {.inline.} = 
  ## (DIRECTION 1|2)
  NumberDirection directionNode.arg(0).vint

func parseWire(wireNode: LispNode): Wire {.inline.} = 
  ## (WIRE X1 Y1 X2 Y2)
  template s(n): untyped =  wireNode.arg(n).vint 
  (s 0, s 1) .. (s 2, s 3)

func parseText(textNode: LispNode): seq[string] {.inline.}  =
  ## (TEXT "..."*)
  textNode.args.mapIt(it.str)

func parseIndex(indexNode: LispNode): string {.inline.} = 
  ## (INDEX "...")
  indexNode.arg(0).str

func parseDestNet(destNetNode: LispNode): Net = 
  Net(kind: netRef, obid: parseOBID destNetNode)

# --- compound

func parseConstraint(constraintNode: LispNode): Constraint =
  for n in constraintNode:
    case n.ident:
    of "INDEX":
      result.index = some parseIndex n

    of "DIRECTION":
      result.`range` = some Range(direction: parseDirection n)

    of "RANGE":
      result.`range`.get.indexes = (n.arg(0).str) .. (n.arg(1).str)
    
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
    
    of "DEF_VALUE": discard
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
  ## (LABEL
  ##   (POSITION)
  ##   (SCALE)
  ##   (COLOR_LINE)
  ##   (SIDE)
  ##   (ALIGNMENT)
  ##   (FORMAT 1)
  ##   (TEXT "Instruction Decoder")
  ## )
  
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
      result.text =  n.parseText.join "\n"

    else:
      err "invalid field"

func parseFreePlacedText(textNode: LispNode): FreePlacedText = 
  ## (FREE_PLACED_TEXT
  ##   (LABEL)
  ## )
  FreePlacedText parseLabel textNode.arg(0)


func parseObjStamp(objStampNode: LispNode): ObjStamp = 
  ## (OBJSTAMP
  ##   (DESIGNER "HamidB80")
  ##   (CREATED 939908873 "Thu Oct 14 17:17:53 1999")
  ##   (MODIFIED 1340886716 "Thu Jun 28 17:01:56 2012")
  ## )
  
  ObjStamp(
    designer: objStampNode.arg(0).arg(0).str,
    created: objStampNode.arg(1).arg(0).vint,
    modified: objStampNode.arg(2).arg(0).vint)

# --- complex

func parseHook(busRipperNode: LispNode): BusRipper = 
  ## (BUS_RIPPER
  ##   (OBID)
  ##   (HDL_IDENT)
  ##   (GEOMETRY)
  ##   (SIDE)
  ##   (LABEL)
  ##   (DEST_NET)
  ## )
  
  for n in busRipperNode:
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

    of "DEST_NET": 
      result.destNet = parseDestNet n

    else: err "invalid"

func parseCbn(cbnNode: LispNode): CBN = 
  ## (CBN
  ##   (OBID)
  ##   (HDL_IDENT
  ##   (GEOMETRY)
  ##   (SIDE 1)
  ##   (LABEL)
  ##   (TYPE 0)
  ## )
  
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
      result.kind = CbnType parseType(n).vint

    else:
      err "invalid field"

func parseNCon(connectionNode: LispNode): Connection  =
  result = new Connection

  for n in connectionNode:
    case n.ident:
    of "OBID":
      result.obid = parseOBID n

    of "GEOMETRY":
      result.geometry = parseGeometry n

    of "SIDE":
      result.side = parseSide n

    of "LABEL": 
      result.label = parseLabel n

    else: err "invalid"


func parsePort(portNode: LispNode, pk: PortKind): Port =
  ## (PORT
  ##   (OBID)
  ##   (PROPERTIES)
  ##   (HDL_IDENT)
  ##   (GEOMETRY)
  ##   (SIDE)
  ##   (LABEL)
  ##    
  ##   (GENERATE)?
  ##   (PORT#ref)?
  ##   (CONNECTION)? *
  ## )
  
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
      result.connection = parseNCon n

    of "GENERATE", "PORT":
      result.refObid = parseOBID n

    of "CBN":
      result.cbn = some parseCbn n

    else:
      err "what?"

func parseNetPart2(part2Node: LispNode, result : var Net) =
  ## (PART#2
  ##   (OBID)
  ##   (LABEL)
  ##   (WIRE)+
  ##   (PORT
  ##     (OBID "<Port_Instance_Id>")
  ##     (NAME "<Port_Name>")
  ##   )*
  ##   (BUS_RIPPER)*
  ## )
  
  for n in part2Node:
    case n.ident:
    of "OBID": discard

    of "LABEL": 
      result.label = parseLabel n

    of "WIRE": 
      result.wires.add parseWire n

    of "PORT": 
      result.ports.add parsePort(n, refprt)

    of "BUS_RIPPER": 
      result.busRippers.add parseHook n

    else: err "invalid"

func parseNet(netNode: LispNode): Net = 
  ## (NET
  ##   (OBID)
  ##   (HDL_IDENT)
  ##   (PART
  ##     (OBID)
  ##     (CBN 1)
  ##   )
  ##   (PART#2)
  ## )

  result = new Net
  var seenPart = false

  for n in netNode:
    case n.ident:
    of "OBID": 
      result.obid = parseOBID n

    of "HDL_IDENT": 
      result.ident = parseHDLIdent n

    of "PART": 
      if seenPart:
        parseNetPart2 n, result

      else: # ignore first PART 
        seenPart = true

    else:
      err "invalid field"

func parseIgen(): Generic =
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

func parseComp(componentNode: LispNode): Component = 
  ## (COMPONENT
  ##   (OBID)
  ##   (HDL_IDENT)
  ##   (GEOMETRY#igen)
  ##   (SIDE)
  ##   (LABEL)
  ##   (ENTITY#ref "<lib_id>" "<entity_id>")
  ##   (GENERIC)*
  ##   (PORT)*
  ## )
  
  result = new Component

  for n in componentNode:
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

    of "ENTITY": 
      result.instanceof = parseEntityRef n
    
    of "GENERIC": 
      discard

    of "PORT": #cprt
      discard
      # TODO

    else:
      err "invalid node"

func parseProc(processNode: LispNode): Process =
  result = new Process

  for n in processNode:
    case n.ident:
    of "STATE_MACHINE_V2": discard
    of "TABLE": discard
    of "TYPE": discard
    of "LABEL": discard
    of "SENSLIST": discard
    of "HDL_FILE": discard
    of "HDL_IDENT": discard

func parseDiag(schematicNode: LispNode): Schematic = 
  ## (SCHEMATIC
  ##   (OBID)
  ##   (SHEETSIZE 0 0 <Width> <Height>)
  ##   (PROPERTIES)
  ##   (FREE_PLACED_TEXT)*
  ##   (GENERIC)*
  ##   (GENERATE)*
  ##   (COMPONENT)*
  ##   (PROCESS)*
  ##   (PORT)*
  ##   (NET)*
  ## )
  
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

    # TODO
    # of "GENERIC":
    #   discard

    # of "GENERATE":
    #   discard

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

func parseArch(archDefNode: LispNode): Architecture  =
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
      result.obid = parseOBID n

    of "TYPE":
      discard
      # TODO
      # result.kind = ArchitectureMode n.arg(0).vint

    of "HDL_IDENT":
      result.ident = parseHDLIdent n
    
    of "PROPERTIES":
      result.properties = parseProperties n

    of "SCHEMATIC":
      result.schematic = parseDiag n

    else: err "invalid"

func parseEnt(entityNode: LispNode, result: var Entity) =
  ## (ENTITY
  ##   (OBID)
  ##   (PROPERTIES)
  ##   (HDL_IDENT)
  ##   (GEOMETRY)
  ##   (SIDE 0)
  ##   (HDL 1)
  ##   (EXTERNAL 0)
  ##   (OBJSTAMP)
  ##   (GENERIC)*
  ##   (PORT)*
  ##   (ARCH_DECLARATION <TYPE_NO> "<id>" "<name>")*
  ## )

  for n in entityNode:
    case n.ident:
    of "PROPERTIES":
      result.properties = parseProperties n

    of "OBID":
      result.obid = parseOBID n

    of "HDL_IDENT":
      result.ident = parseHDLIdent n

    of "GEOMETRY":
      result.componentSize = parseGeometry(n).pickTuple([2, 3])

    of "PORT":
      result.ports.add parsePort(n, eprt)

    of "ARCH_DECLARATION": discard
    else: err "invalid"

func parseEntityFile(entityFileNode: LispNode): Entity =
  ## (ENTITY_FILE
  ##   (ENTITY)
  ##   (ARCH_DEFINITION) ...
  ## )

  for n in entityFileNode:
    case n.ident:
    of "ENTITY":
      parseEnt n, result

    of "ARCH_DEFINITION":
      result.architectures.add parseArch n

    else: discard

func parseEntityDecl(edn: LispNode): Entity =
  Entity(kind: ekDecl,
    name: edn.arg(0).str,
    obid: edn.arg(1).str.Obid)

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

    else: discard

func parseLibDecl(libraryNode: LispNode): Library = 
  Library(kind: lkDecl, 
    name: libraryNode.arg(0).str, 
    obid: libraryNode.arg(1).str.Obid)

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
      result.designs.add parseLibDecl n

    of "PACKAGE":
      result.packages.add Package(
        obid: n.arg(0).str,
        library: n.arg(1).str,
        name: n.arg(2).str)

    else: # PACKAGE_USE OBID
      discard

proc parseEws*(dir: string): Project =
  doAssert dir.endsWith ".ews", fmt"the workspace directory name must end with .ews"
  let dbDir = dir / "ease.db"

  result = parseProj select parseLisp readfile dbDir / "project.ews"
  for d in mitems result.designs:
    let libdir = dbDir / d.obid.string
    d = parseLib select parseLisp libdir

    for e in mitems d.entities:
      e = parseEntityFile select parseLisp readfile libdir / e.obid.string & ".eas"


# --------------------------------------------

const 
  `workspace.eas` = """
    (VCM_FILE
      (PROPERTY "TL_VCM_SYSTEM" "None")
    )
    (END_OF_FILE)
  """

  `toolflow.xml` = """
    <?xml version="1.0" encoding="UTF-8"?>
    <document_root>
      <section type="section_root" name="section_root"/>
    </document_root>
  """


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