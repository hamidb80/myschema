import std/[tables, options]
import ../common/[coordination, domain]

type
  MLabel* = ref object
    texts*: seq[string]
    position*: Point
    fontSize*: int
    anchor*: Alignment

  MBusRipper* = ref object
    # constraint*:
    source*, dest*: MNet
    position*, connection*: Point

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
    rotation*: Rotation
    wrapper*: MWrapper
    refersTo*: Option[MPort]


  MSchematic* = ref object
    ports*: seq[MPort]
    nets*: seq[MNet]
    busRippers*: seq[MBusRipper]
    instances*: seq[MInstance]
    labels*: seq[MLabel]
    size*: Size

  MArchitectureKind* = enum
    makSchema
    makFSM
    makTruthTable
    makCode
    makExternalCode

  MArchitecture* = ref object
    case kind*: MArchitectureKind
    of makSchema:
      schema*: MSchematic

    of makFSM:
      discard

    of makTruthTable:
      discard

    of makCode:
      discard

    of makExternalCode:
      discard

  MIcon* = ref object
    ports*: seq[MPort]
    size*: Size

  IfCond = object
    cond: string

  ForLoop = object

  MElementKind* = enum
    mekModule
    mekGenerator
    mekFSM, mekTruthTable
    mekCode, mekPartialCode

  MElement* = ref object
    name*: string
    icon*: MIcon

    case kind*: MElementKind
    of mekModule:
      archs*: seq[MArchitecture]

    of mekGenerator:
      ifCond*: Option[IfCond]
      forLopp*: Option[ForLoop]

    of mekCode, mekPartialCode: discard
    of mekFSM: discard
    of mekTruthTable: discard

  MTransform* = object
    rotation*: Rotation
    flips*: set[Flip]

  MInstance* = ref object
    name*: string
    parent* {.cursor.}: MElement
    ports*: seq[MPort]
    position*: Point
    transform*: MTransform


  WireGraphNode* = ref object        # AKA Net
    location*: Point
    connections*: seq[WireGraphNode] # only forward connections

  MNetKind* = enum
    mnkWire
    mnkTag

  MNet* = ref object
    ports*: seq[MPort]

    case kind*: MNetKind
    of mnkTag: discard
    of mnkWire:
      start*: WireGraphNode

  ModuleLookup* = Table[string, MElement]

  MProject* = ref object
    modules*: ModuleLookup

# FIXME in `transformer.nim` types with the same name cause gcc error
