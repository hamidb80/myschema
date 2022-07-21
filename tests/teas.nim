import std/[unittest, os, tables, sequtils, options]
import ease/[lisp, defs]
import ease/parser {.all.}

# --- helpers

template first(smth): untyped = smth[0]

template pl(subPath): untyped =
  parseLisp readFile "./examples/ease" / subPath

template lfName(subPath): untyped =
  first pl subpath

# --- tests

suite "basic":
  test "OBID":
    check parseOBID(lfName "basic/OBID.eas").string == "filedadas7d987f89"

  test "GEOMETRY":
    check parseGeometry(lfName "basic/GEOMETRY.eas") == (0, -1, -2, 3)

  test "SHEETSIZE":
    check parseSheetSize(lfName "basic/SHEETSIZE.eas") == (0, 0, 2000, 1000)

  test "INDEX":
    check parseIndex(lfName "basic/INDEX.eas") == "5"

  test "POSITION":
    check parsePosition(lfName "basic/POSITION.eas") == (670, 403)

  test "SCALE":
    check parseScale(lfName "basic/SCALE.eas") == 60

  test "NAME":
    check parseName(lfName "basic/NAME.eas") == "me:"

  test "PROPERTIES":
    let pt = parseProperties(lfName "basic/PROPERTIES.eas")
    check pt.len == 3
    check pt["VHDL_VECTOR"] == "std_logic_vector"
    check pt["VerilogExt"] == "v"
    check pt["VhdlExt"] == "vhd"

  test "ALIGNMENT":
    check parseAligment(lfName "basic/ALIGNMENT.eas").int == 6

  test "SIDE":
    check parseSide(lfName "basic/SIDE.eas").int == 1

  test "COLOR_LINE":
    check parseColor(lfName "basic/COLOR_LINE.eas").int == 12

  test "COLOR_FILL":
    check parseColor(lfName "basic/COLOR_FILL.eas").int == 3

  test "MODE":
    check parseMode(lfName "basic/MODE.eas") == 4

  test "TYPE":
    check parseType(lfName "basic/TYPE.eas").str == "std_logic"

  test "FORMAT":
    check parseFormat(lfName "basic/FORMAT.eas") == 129

  test "ENTITY_ref":
    let ef = parseEntityRef(lfName "basic/ENTITY_ref.eas")
    check ef.obid.string == "ent9890eda"
    check ef.libObid.string == "libdsa34d3o"

  test "WIRE":
    check parseWire(lfName "basic/WIRE.eas") == (200, 50)..(250, 50)

  test "DIRECTION":
    check parseDirection(lfName "basic/DIRECTION.eas") == ndInc

  test "TEXT":
    check parseText(lfName "basic/TEXT.eas") == @["line.1", "line.2", "line.3"]



suite "compound":
  test "LABEL":
    let l = parseLabel(lfName "compound/LABEL.eas")

    check l.position == (2304, 1024)
    check l.scale == 96
    check l.colorLine.int == 0
    check l.side.int == 1
    check l.format == 35
    check l.alignment.int == 5
    check l.text == "fullSpeedRate"

  test "FREE_PLACED_TEXT":
    let fpt = parseFreePlacedText(lfName "compound/FREE_PLACED_TEXT.eas")
    check fpt.Label.text == "Connected to interconnect_mux_slave1-3"

  test "OBJSTAMP":
    let to = parseObjStamp(lfName "compound/OBJSTAMP.eas")
    check to.designer == "EASE example"
    check to.created == 1086260762
    check to.modified == 1340886594

  test "CONSTRAINT":
    let co = pl("compound/CONSTRAINT.eas").map(parseConstraint)

    # RANGE + DIRECTION
    check co[0].`range`.get.direction == ndDec
    check co[0].`range`.get.indexes == "HIGH" .. "LOW"
    # INDEX
    check co[1].index.get == "2"

  test "ATTRIBUTES":
    let ao = parseAttributes(lfName "compound/ATTRIBUTES.eas")
    check ao.mode == some 1
    check ao.kind == some "yo"
    check ao.constraint.get.`range`.get.indexes.a == "9"

  template checkPort(po, id, nm, geo_x1, sde, lbl): untyped =
    check po.obid.string == id
    check po.ident.name == nm
    check po.geometry.x1 == geo_x1
    check po.side.int == sde
    check po.label.text == lbl

  template checkPortRef(po, refId, connId): untyped =
    check po.refObid.string == refId
    check po.connection.obid.string == connId

  test "PORT_eprt":
    let po = parsePort(lfName "compound/PORT/eprt.eas", eprt)
    checkPort po, "eprta0a0a056f0f80505c4914b45e9a7a454", "new_cy_o", 2328, 1, "new_cy_o((DWIDTH-1)/4:0)"
    check po.ident.attributes.kind.get == "STD_LOGIC_VECTOR"

  test "PORT_aprt":
    let po = parsePort(lfName "compound/PORT/aprt.eas", aprt)
    checkPort po, "aprtf70000101260fb040e4033fc87810000", "HRESP", 664, 1, "HRESP[1:0]"
    checkPortRef po, "eprtf70000101260fb040e4033fc86810000", "ncona0a0a0bc22ebab6449507394b7600000"

  test "PORT_cprt":
    let po = parsePort(lfName "compound/PORT/cprt.eas", cprt)
    checkPort po, "cprtf7000010d4884404803033fcce630000", "HTRANS", 3416, 3, "HTRANS[1:0]"
    check po.properties["SensitivityList"] == "Yes"
    check po.refObid.string == "eprtf7000010b203330479045600affd1607"
    check po.connection.obid.string == "ncona0a0a0bc32ebab64495073947d800000"

  test "PORT_pprt":
    let po = parsePort(lfName "compound/PORT/pprt.eas", pprt)
    checkPort po, "pprtf7000010d90d4304848033fc75f70000", "resetn", 7768, 3, ""
    check po.connection.obid.string == "ncona0a0a0bc32ebab64495073949b900000"

  test "PORT_gprt":
    let po = parsePort(lfName "compound/PORT/gprt.eas", gprt)
    checkPort po, "gprta0a0a056f0f80505c4914b455aa7a454", "s_mltplctr", 2008, 1, "s_mltplctr(DWIDTH-1:0)"
    checkPortRef po, "gprta0a0a056f0f80505c4914b454aa7a454", "ncona0a0a056f0f80505c4914b45f6b7a454"



suite "complex":
  test "GENERIC":
    discard

  # test "GENERATE":
  #   discard

  # test "PROCESS":
  #   discard

  test "COMPONENT":
    let c = parseComp(lfname "complex/COMPONENT.eas")

    check c.obid.string == "comp0c8a100706e3b3a4853033fc44480000"
    # FIXME check c.name == "u_slavecontroller"
    check c.geometry == (2560, 4800, 4672, 7104)
    check c.side.int == 0
    check c.instanceof.libObid.string == "lib0c8a"
    check c.instanceof.obid.string == "ent0c8"
    check c.label.text == "u_slavecontroller:slavecontroller"

  test "NET":
    discard

  # test "BUS_RIPPER":
  #   discard

  # test "CBN":
  #   discard


suite "file":
  test "DESIGN_FILE":
    discard

  test "PROJECT_FILE":
    discard

  test "ENTITY_FILE":
    discard

# ---


# import print
# print parseLisp readFile "./examples/eg1.eas"
