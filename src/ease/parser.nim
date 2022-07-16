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
  EntityType* = enum
    etBlockDiagram = 1
    etHDLFile
    etStateDiagram
    etTableDiagram
    etExternalHDLFIle

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

  FlipMode* = enum
    vertical = 1
    horizontal
    both

  NamedColor* = enum
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
  (NAME "Lib_name")

  (ENTITY "entity_name" "id") ...
  (PACKAGE "pkg_name" "id") ...
  (PACKAGE_USE) ...
)
]#


# --- lib<id>/ent<id>.eas
#[
(ENTITY_FILE
  (ENTITY
    (OBID)
    (PROPERTIES ...)
    (HDL_IDENT)

    (GEOMETRY)
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
  (PORT) ...
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
  (GEOMETRY)
  (SIDE 3)
  (LABEL ...)

  if GENERATE:
    (GENERATE "port ref ")

  # ARCH_DEF:
    (CONNECTION)
  )

  (CONNECTION) ...
)

(CONNECTION
  (OBID)
  (GEOMETRY)
  (SIDE 0)
  (LABEL)
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

    (BUS_RIPPER
      (OBID)
      (HDL_IDENT
        (USERNAME 1)
        (ATTRIBUTES
          (CONSTRAINT
            if is single:
              (INDEX "0")
            if is bus:
              (DIRECTION 1)
              (RANGE 0 1)
            )
          )
        ) ...

        (GEOMETRY)
        (SIDE 3)
        (LABEL
          (POSITION 1280 768)
          (SCALE 80)
          (COLOR_LINE 0)
          (SIDE 1)
          (ALIGNMENT 3)
          (FORMAT 3)
          (TEXT "iii(0)")
        )
      )
    )
  )


  (GEOMETRY startX startY endX endY)
  (ALIGNMENT 0..8)
  (COLOR_LINE N)
  (SCALE N)
  (POSITION X Y)
  (SIDE 0..3) -- FOR TEXTS 0, 2 And 1, 3 looks similar


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

  (CBN
    (OBID "cbna02000203cfb1d26caa3b4d28d47da31")
    (HDL_IDENT
      (NAME "in1")
      (USERNAME 1)
    )
    (GEOMETRY)
    (SIDE 1)
    (LABEL
      (POSITION 1462 694)
      (SCALE 96)
      (COLOR_LINE 0)
      (SIDE 3)
      (ALIGNMENT 5)
      (FORMAT 1)
    )
    (TYPE 0)
  )

    # -----------------------------------

  fliping a component:
    (COMPONENT
      ...
      (PROPERTIES
        ...
        (PROPERTY "Flip" "1")
      )
      ...
    )

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
    cbn => connect by name (CBN)

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
