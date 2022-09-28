import std/[unittest, os, tables, options]
import src/ease/[lisp, model]
import src/ease/parser {.all.}
import src/common/[collections, minitable]

# --- helpers

template lfName(subPath): untyped =
  first parseLisp readFile "./samples/ease" / subPath

# --- tests

suite "basic":
  test "OBID":
    check parseOBID(lfName "OBID.eas").string == "filedadas7d987f89"

  test "GEOMETRY":
    check parseGeometry(lfName "GEOMETRY.eas") == (0, -1, -2, 3)

  test "SHEETSIZE":
    check parseSheetSize(lfName "SHEETSIZE.eas") == (0, 0, 2000, 1000)

  test "INDEX":
    check parseIndex(lfName "INDEX.eas") == "5"

  test "POSITION":
    check parsePosition(lfName "POSITION.eas") == (670, 403)

  test "SCALE":
    check parseScale(lfName "SCALE.eas") == 60

  test "NAME":
    check parseName(lfName "NAME.eas") == "me:"

  test "PROPERTIES":
    let pt = parseProperties(lfName "PROPERTIES.eas")
    check pt.len == 3
    check pt["VHDL_VECTOR"] == "std_logic_vector"
    check pt["VerilogExt"] == "v"
    check pt["VhdlExt"] == "vhd"

  test "ALIGNMENT":
    check parseAligment(lfName "ALIGNMENT.eas").int == 6

  test "SIDE":
    check parseSide(lfName "SIDE.eas").int == 1

  test "COLOR_LINE":
    check parseColor(lfName "COLOR_LINE.eas").int == 12

  test "COLOR_FILL":
    check parseColor(lfName "COLOR_FILL.eas").int == 3

  test "MODE":
    check parseMode(lfName "MODE.eas") == 4

  test "TYPE":
    check parseType(lfName "TYPE.eas").str == "std_logic"

  test "FORMAT":
    check parseFormat(lfName "FORMAT.eas") == 129

  test "ENTITY_ref":
    let ef = parseEntityRef(lfName "ENTITY_ref.eas")
    check ef.obid.string == "ent9890eda"
    check ef.libObid.string == "libdsa34d3o"

  test "WIRE":
    check parseWire(lfName "WIRE.eas") == (200, 50)..(250, 50)

  test "DIRECTION":
    check parseDirection(lfName "DIRECTION.eas") == ndInc

  test "TEXT":
    check parseText(lfName "TEXT.eas") == @["line.1", "line.2", "line.3"]

suite "compound":
  test "HDL_IDENT_simple":
    let ident = parseHDLIdent(lfName "HDL_IDENT/simple.eas")
    check ident.name == "comp"

  test "HDL_IDENT_without_name":
    let ident = parseHDLIdent(lfName "HDL_IDENT/without_name.eas")
    check ident.name == ""

  test "HDL_IDENT_with_attrs":
    let ident = parseHDLIdent(lfName "HDL_IDENT/with_attrs.eas")
    check ident.attributes.mode.get == 1


  test "LABEL":
    let l = parseLabel(lfName "LABEL.eas")

    check l.position == (2304, 1024)
    check l.scale == 96
    check l.colorLine.int == 0
    check l.side.int == 1
    check l.format == 35
    check l.alignment.int == 5
    check l.texts[0] == "fullSpeedRate"

  test "FREE_PLACED_TEXT":
    let fpt = parseFreePlacedText(lfName "FREE_PLACED_TEXT.eas")
    check fpt.Label.texts == @["Connected to interconnect_mux_slave1-3"]

  test "OBJSTAMP":
    let to = parseObjStamp(lfName "OBJSTAMP.eas")
    check to.designer == "EASE example"
    check to.created == 1086260762
    check to.modified == 1340886594

  test "CONSTRAINT_RANGE":
    let co = parseConstraint lfName "CONSTRAINT/RANGE.eas"
    check co.`range`.direction == ndDec
    check co.`range`.indexes == "HIGH" .. "LOW"

  test "CONSTRAINT_INDEX":
    let co = parseConstraint lfName "CONSTRAINT/INDEX.eas"
    check co.index == "2"

  test "ATTRIBUTES":
    let ao = parseAttributes(lfName "ATTRIBUTES.eas")
    check ao.mode == some 1
    check ao.kind == some "yo"
    check ao.def_value.get == "3'b011"
    check ao.constraint.get.`range`.indexes.a == "9"

  test "CONNECTION":
    let co = parseNCon lfName "CONNECTION.eas"
    check co.obid.string == "ncona0a0a056f0f80505c4914b456fa7a454"
    check co.position == (1152, 1280)
    check co.side.int == 2
    check co.label.format == 128

  template checkPort(po, id, nm, geo_x1, sde, lbl): untyped =
    check po.obid.string == id
    check po.hdlident.name == nm
    check po.geometry.x1 == geo_x1
    check po.side.int == sde

    if lbl.len == 0:
      check po.label.texts.len == 0
    else:
      check po.label.texts == @[lbl]

  template checkPortRef(po, refId, connId): untyped =
    check po.parent.obid.string == refId
    check po.connection.obid.string == connId

  test "PORT_eprt":
    let po = parsePort(lfName "PORT/eprt.eas", eprt)
    checkPort po, "eprta0a0a056f0f80505c4914b45e9a7a454", "new_cy_o", 2328, 1, "new_cy_o((DWIDTH-1)/4:0)"
    check po.hdlident.attributes.kind.get == "STD_LOGIC_VECTOR"

  test "PORT_aprt":
    let po = parsePort(lfName "PORT/aprt.eas", aprt)
    checkPort po, "aprtf70000101260fb040e4033fc87810000", "HRESP", 664, 1, "HRESP[1:0]"
    checkPortRef po, "eprtf70000101260fb040e4033fc86810000", "ncona0a0a0bc22ebab6449507394b7600000"

  test "PORT_cprt":
    let po = parsePort(lfName "PORT/cprt.eas", cprt)
    checkPort po, "cprtf7000010d4884404803033fcce630000", "HTRANS", 3416, 3, "HTRANS[1:0]"
    check po.properties["SensitivityList"] == "Yes"
    check po.parent.obid.string == "eprtf7000010b203330479045600affd1607"
    check po.connection.obid.string == "ncona0a0a0bc32ebab64495073947d800000"

  test "PORT_pprt":
    let po = parsePort(lfName "PORT/pprt.eas", pprt)
    checkPort po, "pprtf7000010d90d4304848033fc75f70000", "resetn", 7768, 3, ""
    check po.connection.obid.string == "ncona0a0a0bc32ebab64495073949b900000"

  test "PORT_gprt":
    let po = parsePort(lfName "PORT/gprt.eas", gprt)
    checkPort po, "gprta0a0a056f0f80505c4914b455aa7a454", "s_mltplctr", 2008, 1, "s_mltplctr(DWIDTH-1:0)"
    checkPortRef po, "gprta0a0a056f0f80505c4914b454aa7a454", "ncona0a0a056f0f80505c4914b45f6b7a454"

  test "PORT_ref_1":
    let po = parseRefPort(lfName "PORT/ref_1.eas")
    check po.obid.string == "cprtabc987acvwv"

  test "PORT_ref_2":
    let po = parsePort(lfName "PORT/ref_2.eas", refprt)
    check po.obid.string == "cprtf7000010a20333047904560005dd1607"
    check po.name == "HSEL"

  test "CBN":
    let co = parseCbn lfName "CBN.eas"
    check co.obid.string == "cbna0a0a0bc32ebab64495073946e800000"
    check co.hdlident.name == "HCLK"
    check co.geometry.x1 == 3256
    check co.side.int == 2
    check co.kind.int == 1
    check co.label.texts == @["HCLK"]

  test "BUS_RIPPER":
    let bo = parseHook lfName "BUS_RIPPER.eas"
    check bo.obid.string == "hookf7000010a203330479045600dddd1607"
    check bo.hdlident.attributes.constraint.get.index == "1"
    check bo.geometry.x1 == 10560
    check bo.side.int == 2
    check bo.label.texts == @["layer2_HSEL[1]"]
    check bo.destNet.obid.string == "netf7000010a203330479045600eddd1607"
    check (issome bo.cbn) and bo.cbn.get.obid.string == "cbn0c8ab227dda8fd2644b4b4d295f4cf40"

  test "": discard # fsm table

  template genericCheck(o, id, nm, xxx, s, f): untyped =
    check o.obid.string == id
    check o.hdlident.name == nm
    check o.geometry.x1 == xxx
    check o.side.int == s
    check o.label.format == f

  test "GENERIC_egen":
    let go = parseGeneric(lfName "GENERIC/egen.eas", gkEntity)
    genericCheck go, "egenf7000010b203330479045600b40e1607", "DATA_PHASE", 1304, 2, 128
    check go.parent == nil

  test "GENERIC_igen":
    let go = parseGeneric(lfName "GENERIC/igen.eas", gkInstance)
    genericCheck go, "igena0a0a056f0f80505c4914b4527b7a454", "DWIDTH", 3224, 3, 129
    check go.parent.obid.string == "egena0a0a056f0f80505c4914b455f87a454"

suite "complex":

  template generate_check(o, id, nm, xx, sd, t, p0id, p0k, schid): untyped =
    check o.obid.string == id
    check o.hdlident.name == nm
    check o.geometry.x1 == xx
    check o.side.int == sd
    check o.label.texts == @[t]
    check o.ports[0].obid.string == p0id
    check o.ports[0].kind == p0k
    check o.schematic.obid.string == schid

  test "GENERATE_if":
    let go = parseGenB lfName "GENERATE/if.eas"
    check go.properties["IF_CONDITION"] == "mycond"

    generate_check go, "genb0c8a108663c39d268903b4d275301dd7", "ifgen_block",
        1600, 2, "ifgen_block: if mycond generate",
        "gprt0c8a1086b7c39d268903b4d246301dd7", gprt, "diag0c8a108663c39d268903b4d265301dd7"

  test "GENERATE_for":
    let go = parseGenB lfName "GENERATE/for.eas"
    check go.properties["FOR_LOOP_VAR"] == "iterator_var"
    check go.constraint.get.`range`.indexes.b == "low_range"

    generate_check go, "genb0c8a1086a5c39d268903b4d2a5301dd7", "forgen_block",
        1600, 1, "forgen_block: for iterator_var in (high_range downto low_range) generate",
        "gprt0c8a1086a6c39d268903b4d2c5301dd7", gprt, "diag0c8a1086a5c39d268903b4d295301dd7"

  test "PROCESS":
    let po = parseProc lfName "PROCESS.eas"
    check po.obid.string == "proca000000a062824244fa033fcc3040000"
    check po.kind.int == 1
    check po.hdlident.name == "Control"
    check po.side.int == 2
    check po.geometry.x1 == 3008
    check po.label.texts == @["Control(V)"]
    check po.sensitivityList
    check po.ports[0].label.format == 65539

  test "COMPONENT":
    let c = parseComp(lfname "COMPONENT.eas")

    check c.obid.string == "comp0c8a100706e3b3a4853033fc44480000"
    check c.hdlident.name == "u_slavecontroller"
    check c.geometry == (2560, 4800, 4672, 7104)
    check c.side.int == 0
    check c.parent.libObid.string == "lib0c8a"
    check c.parent.obid.string == "ent0c8"
    check c.label.texts == @["u_slavecontroller:slavecontroller"]

  test "NET_tag":
    let no = parseNet lfName "NET/tag.eas"
    check no.parts[0].kind == pkTag
    check no.parts[0].ports[0].obid.string == "aprtf700001024784404803033fc89630000"
    check no.parts[0].ports[^1].obid.string == "cprtf70000103b5feb040e4033fcd5810000"

  test "NET_wire":
    let no = parseNet lfName "NET/wire.eas"
    check no.parts[1].kind == pkWire
    check no.obid.string == "netf7000010a2033304790456008ddd1607"
    check no.parts[1].ports[1].obid.string == "cprtf7000010a203330479045600d7dd1607"
    check no.parts[1].label.texts == @["layer2_HSEL[2:0]"]
    check no.parts[1].wires[0] == (4416, 3712) .. (10624, 3712)
    check no.parts[1].wires[^1] == (10624, 9536) .. (10624, 10560)
    check no.parts[1].busRippers[^1].destNet.obid.string == "netf7000010a203330479045600cddd1607"

  test "TABLE":
    let to = parseTtab lfName "TABLE.eas"
    check to.obid.string == "ttaba000000a7ed2e254835033fc48560000"
    check to.headers == @["HADDRESS", "HSEL"]
    check to.rows == @[
      @["`Slave6", "8'b10000000"],
      @["`Slave5", "8'b01000000"],
      @["`Slave4", "8'b00100000"],
      @["`Slave3", "8'b00010000"],
      @["`Slave2", "8'b00001000"],
      @["`Slave1", "8'b00000100"],
      @["`Slave10", "8'b00000010"],
      @["", "8'b00000001"],
    ]

  test "":
    discard

suite "file":
  test "PROJECT_FILE":
    let pf = parseProj lfName "PROJECT_FILE.eas"
    check pf.obid.string == "proj41a0a0a0442cfdc32c4156006e933346"
    check pf.properties["HdlFileEncoding"] == "ASCII"

    check pf.designs[0].name == "design"
    check pf.designs[^1].obid.string == "liba0a0a040a917bec393c656007ab6f6b3"

    check pf.packages[0].name == "std_logic_1164"
    check pf.packages[0].obid.string == "packf7000010e91aaec3c740799098b60000"
    check pf.packages[^1].library == "std"

  test "DESIGN_FILE":
    let df = parseLib lfName "DESIGN_FILE.eas"
    check df.obid.string == "lib9aef568962fb27a3023079900d800000"
    check df.properties["STAMP_REVISION"] == "Release Candidate 1"
    check df.name == "design"
    # check df.entities["Toplevel"].name == "Toplevel"

  test "ENTITY_FILE":
    let ef = parseEntityFile lfName "ENTITY_FILE.eas"
    check ef.obid.string == "enta000000a9a859424478033fcaea30000"
    check ef.properties["STAMP_TOOL"] == "Ease"
    check ef.hdlident.name == "ram_2k"
    check ef.geometry == (0, 0, 1088, 896)
    check ef.objStamp.created == 1112103081

    check ef.ports[0].obid.string == "eprta000000a9a859424478033fcbea30000"
    check ef.ports[0].kind == eprt
    check ef.ports[^1].obid.string == "eprta000000a9a859424478033fc1fa30000"

    check ef.archs[0].obid.string == "archa000000a9a859424478033fc2fa30000"
    check ef.archs[0].kind.int == 2
    check ef.archs[1].obid.string == "archa000000a4d386524405033fc9f670000"
    check ef.archs[1].kind.int == 1
