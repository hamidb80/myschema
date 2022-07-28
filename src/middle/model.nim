import std/[tables, options]
import ../common/[coordination]

type
  Label* = ref object
    text*: string
    position*: Point

  PortDir* = enum
    input, output, inout

  Port = ref object
    name*: string
    dir*: PortDir
    position*: Point
    parent*: Option[Port]

  MIcon* = ref object
    ports*: seq[Port]
    size*: Point

  Schema* = ref object
    instances*: seq[Instance]
    connections*: seq[WireGraphNode]
    lables*: seq[Label]

  MModule* = ref object
    name*: string
    icon*: MIcon
    schema*: Schema

  Instance* = ref object
    parent* {.cursor.}: MModule
    name*: string

  WireGraphNode* = ref object # AKA Net
    location*: Point
    connections*: seq[WireGraphNode]      # only forward connections

  MNet* = ref object
    startWire: WireGraphNode

  ModuleLookup* = Table[string, MModule] 

  MProject* = ref object # FIXME in `transformer.nim` types with the same name cause gcc error
    modules*: ModuleLookup

