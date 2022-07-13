import ../common/defs

type

  MSchema* = ref object
    instances: seq[MInstance]
    conntections: seq[MWire]
    lables: seq[MLabel]

  MPortDir* = enum
    input, output, inout

  MPort = tuple
    name: string
    dir: MPortDir
    position: Point

  MComponent* = ref object
    ports: seq[MPort]
    schema: MSchema

  MInstance* = ref object
    parent {.cursor.}: MComponent
    name, label: string

  MLabel* = ref object
    text: string
    position: Point

  MSegment* = HSlice[Point, Point]

  MWire* = ref object
    segments: seq[MSegment]
    isBus: bool



func toSvg*(sch: MSchema): XmlNode =
  discard
