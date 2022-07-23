import ../common/defs

type

  Schema* = ref object
    instances*: seq[Instance]
    conntections*: seq[Wire]
    lables*: seq[Label]

  PortDir* = enum
    input, output, inout

  Port = object
    name*: string
    dir*: PortDir
    position*: Point

  Component* = ref object
    ports*: seq[Port]
    schema*: Schema

  Instance* = ref object
    parent* {.cursor.}: Component
    name*: string

  Label* = ref object
    text*: string
    position*: Point

  Net* = object

    
  Wire* = ref object
    segments*: seq[Segment]
    isBus*: bool


# func toSvg*(sch: MSchema): XmlNode =
#   discard
