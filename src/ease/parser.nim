import std/[tables]
import lisp

type
  Properties = Table[string, string]
  # Attributes =

  HDL_Ident* = object
    name: string
    username: int
    # atrributes:

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
func toLispNode(l: Entity, mode: LibraryEncodeMode): LispNode = discard



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

  (FREE_PLACED_TEXT)
  (GENERIC) ...
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
  ]#


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


# -----------------------------------
#[

OBID:
  proj => project (PROJECT_FILE)
  pack => package (PROJECT_FILE->PACKAGE | PACKAGE_FILE)
  lib => library (DESIGN_FILE)
  ent => entity (ENTITY_FILE->ENTITY)
  Arch => architecture (ARCH_DEFINITION)

  eprt => entity port (ENTITY->PORT)
  cprt => component port (COMPONENT->PORT)
  aprt => architecture port (ARCH_DEFINITION->PORT)
  nprt => net port (NET->PART->PORT)
  pprt => process port (PROCESS->PORT)

  proc => process (PROCESS)

  ttab => truth table (TABLE)
  thdr => truth header (HEADER)
  trow => truth row (ROW)
  cell => cell (CELL)

  ncon => node connection (CONNECTION)
  
  Comp => component (COMPONENT)

  igen => instance generic (GENERIC)
  egen => entity generic (GENERIC)

  file => file content (VHDL_FILE)
  lab => ??? (ACTION | CONDITION)
  itxt => included text (FSM_DIAGRAM->INCLUDED_TEXT)

  fsm => (STATE_MACHINE_V2 | TRANS_LINE/TRANS_SPLINE->[FROM_CONN, TO_CONN] | GLOBAL)
  diag => diagram (SCHEMATIC | FSM_DIAGRAM)
  tran => transition (TRANS_LINE | TRANS_SPLINE)
  stat => state (STATE)
  lab => (ACTION | CONDITION)

  act => action (ACTION)

  net => net (NET)

  hook => bus ripper (BUS_RIPPER)

  cbn => ??? (CBN)

]#
