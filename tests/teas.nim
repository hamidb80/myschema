import std/[unittest, os, tables]
import ease/lisp
import ease/parser {.all.}

# --- helpers

template first(smth): untyped = smth[0]
template lfName(subPath): untyped =
  first parseLisp readFile "./examples/ease" / subPath

# --- tests

suite "basic":
  test "OBID":
    check parseOBID(lfName "basic/OBID.eas") == "filedadas7d987f89"

  test "GEOMETRY":
    check parseGeometry(lfName "basic/GEOMETRY.eas") == (0, -1, -2, 3)

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
    check parseType(lfName "basic/TYPE.eas") == "std_logic"

  test "FORMAT":
    check parseFormat(lfName "basic/FORMAT.eas") == 129

  test "ENTITY_ref":
    check parseEntityRef(lfName "basic/ENTITY_ref.eas") == ("libdsa34d3o", "ent9890eda")

  test "WIRE":
    check parseWire(lfName "basic/WIRE.eas") == (200, 50)..(250, 50)

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
    check fpt.label.text == "Connected to interconnect_mux_slave1-3"

  test "OBJSTAMP":
    let to = parseObjStamp(lfName "compound/OBJSTAMP.eas")
    check to.designer == "EASE example"
    check to.created == 1086260762
    check to.modified == 1340886594


suite "complex":
  test "COMPONENT":
    let c = parseComp(lfname "complex/COMPONENT.eas")

    check c.obid == "comp0c8a100706e3b3a4853033fc44480000"
    check c.name == "u_slavecontroller"
    check c.geometry == (2560, 4800, 4672, 7104)
    check c.side.int == 0
    check c.instanceof == ("lib0c8a", "ent0c8")
    check c.label.text == "u_slavecontroller:slavecontroller"


# ---

# import print
# print parseLisp readFile "./examples/eg1.eas"
