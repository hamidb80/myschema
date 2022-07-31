import std/[tables, options]
import ../common/[coordination, domain, minitable]

type
  WrapperKind* = enum
    wkSchematic
    wkIcon
    wkInstance

  MPortDir* = enum
    input, output, inout
    # FIXME ease has buffer

  MArchitectureKind* = enum
    makSchema
    makFSM
    makTruthTable
    makCode
    makExternalCode

  MElementKind* = enum
    mekModule
    mekGenerator
    mekFSM, mekTruthTable
    mekCode, mekPartialCode

  MNetKind* = enum
    mnkWire
    mnkTag


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

  ETokenGroup* = seq[MToken]

  MTokenKind* = enum
    mtkOpenPar, mtkClosePar
    mtkOpenBracket, mtkCloseBracket
    mtkOperator
    mtkLiteral
    mtkSymbol

  MToken* = object
    case kind*: MTokenKind
    of mtkOpenPar, mtkClosePar, mtkOpenBracket, mtkCloseBracket: discard
    of mtkOperator:
      operator*: string

    of mtkLiteral:
      content*: string

    of mtkSymbol:
      sym*: string

  MTruthTable* = seq[seq[string]]

  MWrapper* = object
    case kind*: WrapperKind
    of wkSchematic:
      schematic: MSchematic

    of wkIcon:
      icon: MIcon

    of wkInstance:
      instance: MInstance

  MIndetifierKind* = enum
    mikSingle, mikIndex, mikRange

  MIdentifier* = object
    name*: string

    case kind*: MIndetifierKind
    of mikSingle: discard
    of mikIndex:
      index*: ETokenGroup

    of mikRange:
      direction*: NumberDirection
      indexes*: Slice[ETokenGroup]


  MPort* = ref object
    id*: MIdentifier
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
    cond: ETokenGroup

  ForLoop = object
    varname: string
    dir: NumberDirection
    slice: Slice[ETokenGroup]


  MParamsLookup* = MiniTable[string, MParameter]

  MElement* = ref object
    name*: string
    icon*: MIcon
    parameters*: MParamsLookup

    case kind*: MElementKind
    of mekModule, mekCode, mekPartialCode, mekFSM, mekTruthTable:
      archs*: seq[MArchitecture]

    of mekGenerator:
      ifCond*: Option[IfCond]
      forLopp*: Option[ForLoop]

  MTransform* = object
    rotation*: Rotation
    flips*: set[Flip]

  MInstance* = ref object
    name*: string
    parent* {.cursor.}: MElement
    args*: seq[MArg]
    ports*: seq[MPort]
    position*: Point
    transform*: MTransform

  MParameter* = ref object
    name*: string
    kind*: string
    default*: ETokenGroup

  MArg* = ref object
    parameter*: MParameter
    value*: Option[ETokenGroup]

  WireGraphNode* = ref object        # AKA Net
    location*: Point
    connections*: seq[WireGraphNode] # only forward connections

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
