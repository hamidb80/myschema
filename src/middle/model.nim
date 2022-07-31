import std/[tables, options]
import ../common/[coordination, domain, minitable]

type
  WrapperKind* = enum
    wkSchematic
    wkIcon
    wkInstance

  MPortDir* = enum
    input, output, inout

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
  MText* = ref object
    texts*: seq[string]
    position*: Point
    fontSize*: int

  MBusRipper* = ref object
    # constraint*:
    source*, dest*: MNet
    position*, connection*: Point

  MTokenGroup* = seq[MToken]

  MTokenKind* = enum
    mtkOpenPar, mtkClosePar
    mtkOpenBracket, mtkCloseBracket
    mtkNumberLiteral, mtkStringLiteral
    mtkSymbol, mtkOperator

  MToken* = object
    case kind*: MTokenKind
    of mtkOpenPar, mtkClosePar, mtkOpenBracket, mtkCloseBracket: discard
    of mtkOperator:
      operator*: string

    of mtkStringLiteral, mtkNumberLiteral:
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
      index*: MTokenGroup

    of mikRange:
      direction*: NumberDirection
      indexes*: Slice[MTokenGroup]

  MportKind* = enum
    mpOriginal
    mpCopy

  MPort* = ref object
    position*: Point
    # TOOD wrapper*: MWrapper

    case kind*: MportKind
    of mpOriginal:
      id*: MIdentifier
      dir*: MPortDir

    of mpCopy:
      parent*: MPort

  MSchematic* = ref object
    ports*: seq[MPort]
    nets*: seq[MNet]
    busRippers*: seq[MBusRipper]
    instances*: seq[MInstance]
    labels*: seq[MText]
    size*: Size

  MArchitecture* = ref object
    case kind*: MArchitectureKind
    of makSchema:
      schema*: MSchematic

    of makFSM:
      # fsm*:
      discard

    of makTruthTable:
      # truthTable*:
      discard

    of makCode:
      discard

    of makExternalCode:
      discard

  MIcon* = ref object
    ports*: seq[MPort]
    size*: Size

  IfCond = object
    cond: MTokenGroup

  ForLoop = object
    varname: string
    dir: NumberDirection
    slice: Slice[MTokenGroup]

  MParamsLookup* = MiniTable[string, MParameter]

  MElement* = ref object
    name*: string
    icon*: MIcon
    parameters*: MParamsLookup
    archs*: seq[MArchitecture]

    case kind*: MElementKind
    of mekModule, mekCode, mekPartialCode, mekFSM, mekTruthTable: discard
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
    default*: Option[MTokenGroup]

  MArg* = ref object
    parameter*: MParameter
    value*: Option[MTokenGroup]

  WireGraphNode* = ref object
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
