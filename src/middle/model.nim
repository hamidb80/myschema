import std/[tables, options]
import ../common/[coordination, domain]

type
  MLabel* = ref object
    text*: string
    position*: Point
    # TODO aligment*: Alignment

  # TODO bus ripper
  # TODO tag

  WrapperKind* = enum
    wkSchematic
    wkIcon
    wkInstance

  MWrapper* = object
    case kind*: WrapperKind
    of wkSchematic:
      schematic: MSchematic

    of wkIcon:
      icon: MIcon

    of wkInstance:
      instance: MInstance


  MPortDir* = enum
    input, output, inout
    # FIXME ease has buffer

  MPort* = ref object
    id*: Identifier
    dir*: MPortDir
    position*: Point
    wrapper*: MWrapper
    refersTo*: Option[MPort]

  MSchematic* = ref object
    ports*: seq[MPort]
    nets*: seq[MNet]
    instances*: seq[MInstance]
    lables*: seq[MLabel]
    size*: Size

  MIcon* = ref object
    ports*: seq[MPort]
    size*: Size

  MModule* = ref object
    name*: string
    icon*: MIcon
    schema*: MSchematic

  MTransform* = object
    movement*: Vector
    rotation*: Rotation
    flips*: set[Flip]
    pin*: Point

  MInstance* = ref object
    name*: string
    parent* {.cursor.}: MModule
    ports*: seq[MPort]
    position*: Point
    transform*: MTransform


  WireGraphNode* = ref object        # AKA Net
    location*: Point
    connections*: seq[WireGraphNode] # only forward connections

  MNet* = ref object
    start*: WireGraphNode

  ModuleLookup* = Table[string, MModule]

  MProject* = ref object
    modules*: ModuleLookup

# FIXME in `transformer.nim` types with the same name cause gcc error
