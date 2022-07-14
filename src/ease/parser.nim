import std/[tables]

type
  Properties = Table[string, string]

  HDL_Ident* = object
    name: string
    # username: int
    # atrributes: 

  PackageInfo* = ref object
    obid, library, name: string

  Design* = object # AKA library
    name, obid: string

  WorkSpace* = ref object
    obid: string
    properties: Properties
    designs: seq[Design]
    # packages: seq[PackageInfo]
    # usedPackages: seq[tuple[suffix: string, pkg: PackageInfo]]

  Library* = ref object
    obid: string
    properties: Properties

  Entity* = ref object



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

  (GENERIC) ...
  (PROCESS) ...
  (PORT) ...
  (NET) ...
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