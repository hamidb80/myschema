import std/[xmltree]

type
  MPoint* = tuple[x, y: int]

  MSchema* = ref object
    instances: seq[MInstance]
    conntections: seq[MWire]
    lables: seq[MLabel]

  MPortDir* = enum
    input, output, inout

  MPort = tuple
    name: string
    dir: MPortDir
    position: MPoint

  MComponent* = ref object
    ports: seq[MPort]
    schema: MSchema

  MInstance* = ref object
    parent {.cursor.}: MComponent
    name, label: string

  MLabel* = ref object
    text: string
    position: MPoint

  MSegment* = HSlice[MPoint, MPoint]

  MWire* = ref object
    segments: seq[MSegment]
    isBus: bool



func toSvg*(sch: MSchema): XmlNode =
  discard
