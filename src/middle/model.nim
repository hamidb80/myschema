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

  Icon* = ref object
    ports*: seq[Port]
    # bounds*:

  Schema* = ref object
    instances*: seq[Instance]
    connections*: seq[NetGraphNode]
    lables*: seq[Label]

  MModule* = ref object
    name*: string
    icon*: Icon
    schema*: Schema

  Instance* = ref object
    parent* {.cursor.}: MModule
    name*: string

  # Net = ref object
  #   ports

  NetGraphNode* {.acyclic.} = ref object # AKA Net
    location*: Point
    connections*: seq[NetGraphNode]      # only forward connections

  ModuleLookup* = Table[string, MModule] 

  MProject* = ref object # FIXME in `transformer.nim` types with the asme name cause gcc error
    modules*: ModuleLookup

