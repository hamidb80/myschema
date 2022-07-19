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

func parseOBID(obidNode: LispNode): string {.inline.} =
  obidNode.arg(0).str

func parseGeometry(geometryNode: LispNode): Geometry = 
  ## (GEOMETRY startX startY endX endY)
  (geometryNode.args.mapIt it.vint).toTuple 4

func parsePosition(positionNode: LispNode): Point = 
  ## (POSITION X Y)
  (positionNode.arg(0).vint, positionNode.arg(1).vint)

func parseScale(scaleNode: LispNode): Positive = 
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

func parseMode(modeNode: LispNode): int = 
  ## (MODE N)
  modeNode.arg(0).vint

func parseType(typeNode: LispNode): string = 
  ## (TYPE "...")
  typeNode.arg(0).str

func parseFormat(formatNode: LispNode): int =
  ## (FORMAT N)
  formatNode.arg(0).vint

func parseWire(wireNode: LispNode): Wire {.inline.} = 
  ## (WIRE X1 Y1 X2 Y2)
  template s(n): untyped =  wireNode.arg(n).vint 
  (s 0, s 1) .. (s 2, s 3)

func parseText(textNode: LispNode): seq[string] =
  ## (TEXT "..."*)
  textNode.args.mapIt(it.str)


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
      .parseMode

  except UnpackDefect, AssertionDefect:
    err "{ATTRIBUTES/MODE} not found"

func extractName(hdlIdentNode: LispNode): string {.inline.} =
  ## (HDL_IDENT
  ##   (NAME "...")
  ## )

  hdlIdentNode.arg(0).assertIdent("NAME").parseName

# --- compound

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

# --- complex

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

func parseEprt(portNode: LispNode): EntityPort =
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

func parseNet(netNode: LispNode): Net = 
  ## (NET
  ##   (OBID)
  ##   (HDL_IDENT)
  ##   (PART
  ##     (OBID)
  ##     (CBN 1)
  ##   )
  ##   (PART
  ##     (OBID)
  ##     (LABEL)
  ##     (WIRE) ...
  ##     (PORT
  ##       (OBID "<Port_Instance_Id>")
  ##       (NAME "<Port_Name>")
  ##     ) ... (2+)
  ##   )
  ## )

  for n in netNode:
    case n.ident:
    of "OBID": discard
    of "HDL_IDENT": discard
    of "PART": discard
    else:
      err "invalid field"

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
  FreePlacedText(label: parseLabel textNode.arg(0))

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
  
  for n in busRipperNode:
    case n.ident:
    of "OBID": discard
    of "HDL_IDENT": discard
    of "GEOMETRY": discard
    of "SIDE": discard
    of "LABEL": discard
    else: 
      err "invalid field"

func parseNCon(connectionNode: LispNode): Connection = 
  ## (CONNECTION
  ##   (OBID)
  ##   (GEOMETRY)
  ##   (SIDE 0)
  ##   (LABEL)
  ## )
  
  for n in connectionNode:
    case n.ident:
    of "OBID": discard
    of "GEOMETRY": discard
    of "SIDE": discard
    of "LABEL": discard
    else:
      err "invalid field"

func parseCbn(cbnNode: LispNode): ConnectByName = 
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
  
  for n in cbnNode:
    case n.ident:
    of "OBID": discard
    of "HDL_IDENT": discard
    of "GEOMETRY": discard
    of "SIDE": discard
    of "LABEL": discard
    of "TYPE": discard
    else:
      err "invalid field"

func parseEntityRef(entityNode: LispNode): tuple[libObid, entityObid: string ] =
  (entityNode.arg(0).str, entityNode.arg(1).str)

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
      result.name = n.arg(0).parseName

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

    else:
      err "invalid node"

func parseDiag(schematicNode: LispNode): Schematic = 
  ## (SCHEMATIC
  ##   (OBID)
  ##   (SHEETSIZE 0 0 <Width> <Height>)
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

func parseEntImpl(entityNode: LispNode, result: var Entity) {.inline.} =
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
      result.obid = parseOBID n

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
      result.obid = parseOBID n

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
      parseEntImpl(n, result)

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
      result.obid = parseOBID n

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
  let dbDir = dir / "ease.db"

  result = parseProj select parseLisp readfile dbDir / "project.ews"
  for d in mitems result.designs:
    let libdir = dbDir / d.obid
    d = parseLib select parseLisp libdir

    for e in mitems d.entities:
      e = parseEnt select parseLisp readfile libdir / e.obid & ".eas"


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