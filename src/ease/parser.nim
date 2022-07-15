import std/[tables]
import lisp

type
  Properties = Table[string, string]
  # Attributes =

  HDL_Ident* = object
    name: string
    username: int
    # atrributes:

# Ease HDL 8.0

type
  ProcessTypes* = enum
    ptProcess = 1
    ptStateDiagram = 2
    ptConcurrentStatement = 3
    ptTruthTable = 5

  GenerateBlockType* = enum
    gbtForGenerate = 1
    gbtIfGenerate = 2

  EntityType* = enum
    etBlockDiagram = 1
    etHDLFile
    etStateDiagram
    etTableDiagram
    etExternalHDLFIle

  PortMode* = enum
    pmInput = 1
    pmOutput
    pmInout
    pmBuffer


  Alignment* = enum
    BottomRight = 0
    Bottom = 1
    BottomLeft = 2
    Right = 3
    Center = 4
    Left = 5
    TopRight = 6
    Top = 7
    TopLeft = 8
    # 8 7 6
    # 5 4 3
    # 2 1 0

  Side* = enum
    TopToBottom
    RightToLeft
    BottomToTop
    LeftToRight
    #   0
    # 3   1
    #   2


type
  Package* = ref object
    obid, library, name: string

  WorkSpace* = ref object
    obid: string
    properties: Properties
    designs: seq[Library]
    # packages: seq[Package]
    # usedPackages: seq[tuple[suffix: string, pkg: Package]]

  Library* = ref object
    obid: string
    name: string
    properties: Properties

  Entity* = ref object



type
  LibraryEncodeMode* = enum
    lemRef
    lemDef

  EntityEncodeMode* = enum
    eemRef
    eemDef


func toLispNode(l: Library, mode: LibraryEncodeMode): LispNode = discard



# --- all .eas files
#[
(DATABASE_VERSION 17)
...
(END_OF_FILE)
]#

# --- project.eas
#[
(PROJECT_FILE
  (OBID)
  (PROPERTIES ...)

  (DESIGN "libname" "id") ...
  (ENTITY "entity_name" "id") ...

  (PACKAGE "pkg_name" "id") ...
  (PACKAGE_USE ...) ...
)
]#

# --- lib<id>/library.eas
#[
(DESIGN_FILE
  (OBID)
  (PROPERTIES)

  (COMPONENT_LIB 0)
  (NAME "Lib_name">)

  (ENTITY "entity_name" "id") ...
  (PACKAGE "pkg_name" "id") ...
  (PACKAGE_USE ...) ...
)
]#


# --- lib<id>/ent<id>.eas
#[
(ENTITY_FILE
  (ENTITY
    (OBID)
    (PROPERTIES ...)
    (HDL_IDENT)

    (GEOMETRY 0 0 <ComponentWidth> <ComponentHeight>)
    (SIDE 0)
    (HDL 1)
    (EXTERNAL 0)
    (OBJSTAMP)

    (GENERIC) ...
    (PORT) ...

    (ARCH_DECLARATION <TYPE_NO> "<id>" "<name>") ...
  )

  (ARCH_DEFINITION
    (OBID)
    (HDL_IDENT)
    (PROPERTIES ...)

    (TYPE <TYPE_NO>)
    (SCHEMATIC ...)
  ) ...
)
]#

# =================================

#[

(SCHEMATIC
  (OBID)
  (SHEETSIZE 0 0 <Width> <Height>)

  (FREE_PLACED_TEXT) ...
  (GENERIC) ...
  (GENERATE) ...
  (COMPONENT) ...
  (PROCESS) ...
  (PORT) ...
  (NET) ...
)

(FREE_PLACED_TEXT
  (LABEL)
)

(COMPONENT
  (OBID "Comp<id>")
  (HDL_IDENT)
  (GEOMETRY)
  (SIDE)
  (LABEL)
  (ENTITY "<lib_id>" "<entity_id>")
)

(LABEL
  (POSITION)
  (SCALE)
  (COLOR_LINE)
  (SIDE)
  (ALIGNMENT)
  (FORMAT 1)
  (TEXT "Instruction Decoder")
)

(ALIGNMENT 0..8)
(SIDE 0..3)
(COLOR_LINE N)
(SCALE N)
(POSITION X Y)

(HDL_IDENT
  (NAME "halt")
  (USERNAME 1)
  (ATTRIBUTES ...)
)

(OBJSTAMP
  (DESIGNER "HamidB80")
  (CREATED 939908873 "Thu Oct 14 17:17:53 1999")
  (MODIFIED 1340886716 "Thu Jun 28 17:01:56 2012")
)

(LABEL
  (POSITION 1384 128)
  (SCALE 96)
  (COLOR_LINE 0)
  (SIDE 3)
  (ALIGNMENT 3)
  (FORMAT 129)
  (TEXT "dbus(8)")
)

(PORT
  (OBID)
  (PROPERTIES)
  (HDL_IDENT)
  (GEOMETRY -40 344 40 424)
  (SIDE 3)
  (LABEL ...)

  if GENERATE:
    (GENERATE "port ref ")

  # ARCH_DEF:
    (CONNECTION)
)

(NET
  (OBID)
  (HDL_IDENT)

  (PART
    (OBID "nprt<UNIQ_ID>")
    (CBN 1)
  )
  (PART
    (OBID "nprt<UNIQ_ID>")
    (LABEL)

    (WIRE) ...

    (PORT
      (OBID "<Port_Instance_Id>")
      (NAME "<Port_Name>")
    ) ... (2+)
  )
)

(CONNECTION
  (OBID)
  (GEOMETRY X1 Y1 X1 Y1)
  (SIDE 0)
  (LABEL)
)

(WIRE X1 Y1 X2 Y2)

(GENERATE
  (OBID)
  (PROPERTIES
    (PROPERTY "IF_CONDITION" "my_cond")
    (PROPERTY "FOR_LOOP_VAR" "ident")
  )
  (HDL_IDENT)
  (GEOMETRY)
  (SIDE)
  (LABEL)

  (TYPE 2)

  if for:
    (CONSTRAINT
      (DIRECTION 1)
      (RANGE "max" "min")
    )

  (SCHEMATIC
    (OBID)
    (SHEETSIZE)
  )
)

(EXTERNAL_FILE
  (OBID "extff700001022bc0d264002b4d2a9a05a77")
  (HDL_IDENT)
  (FILE <Path>)
)

(TABLE
  (OBID)
  (PROPERTIES)
  (HEADER) ...
  (ROW) ...
)

(HEADER
  (OBID)
  (LABEL)
)

(ROW
  (OBID)
  (CELL) ...
)

(CELL
  (OBID)
  (LABEL)
)

(HDL_FILE
  (VHDL_FILE
    (OBID)
    (NAME "pr0.vhd")
    (VALUE "lines of the file" ...)
  )
)

# -----------------------------------


OBID:
  proj => project (PROJECT_FILE)
  pack => package (PROJECT_FILE->PACKAGE | PACKAGE_FILE)
  lib => library (DESIGN_FILE)
  ent => entity (ENTITY_FILE->ENTITY)
  Arch/arch => architecture (ARCH_DEFINITION)

  eprt => entity port (ENTITY->PORT)
  cprt => component port (COMPONENT->PORT)
  aprt => architecture port (ARCH_DEFINITION->PORT)
  nprt => net port (NET->PART->PORT)
  pprt => process port (PROCESS->PORT)
  gprt => generate port (GENERATE->PORT)

  proc => process (PROCESS)
  genb => generate block

  ttab => truth table (TABLE)
  thdr => table header (HEADER)
  trow => table row (ROW)
  cell => cell (CELL)

  Comp/comp => component [instance of a block] (COMPONENT)
  ncon => node connection (CONNECTION)
  net => net (NET)

  hook => bus ripper (BUS_RIPPER)
  cbn => ??? (CBN)

  igen => instance generic (GENERIC)
  egen => entity generic (GENERIC)

  file => file content (VHDL_FILE)
  itxt => included text (FSM_DIAGRAM->INCLUDED_TEXT)
  extf => external file

  fsm => (STATE_MACHINE_V2 | TRANS_LINE/TRANS_SPLINE->[FROM_CONN, TO_CONN] | GLOBAL)
  diag => diagram (SCHEMATIC | FSM_DIAGRAM)
  tran => transition (TRANS_LINE | TRANS_SPLINE)
  lab => ??? (ACTION | CONDITION)
  stat => state (STATE)
  lab => (ACTION | CONDITION)
  act => action (ACTION)

]#
