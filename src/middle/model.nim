import std/[tables, options]
import ../common/[coordination, domain, minitable]

type
  WrapperKind* = enum
    wkSchematic
    wkIcon
    wkInstance

  MPortDir* = enum
    mpdInput, mpdOutput, mpdInout

  MArchitectureKind* = enum
    makSchema
    makTruthTable
    makCode, makExternalCode

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

  MBusRipper* = ref object
    select*: MIdentifier
    source*, dest*: MNet
    position*, connection*: Point

  MTokenGroup* = seq[MToken]

  MTokenKind* = enum
    mtkOpenPar, mtkClosePar
    mtkOpenBracket, mtkCloseBracket
    mtkNumberLiteral, mtkStringLiteral
    mtkSymbol, mtkOperator

  MToken* = object
    kind*: MTokenKind
    content*: string

  MTruthTable* = object
    headers*: seq[string]
    rows*: seq[seq[string]]

  MWrapper* = object
    case kind*: WrapperKind
    of wkSchematic:
      schematic: MSchematic

    of wkIcon:
      icon: MIcon

    of wkInstance:
      instance: MInstance

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
    texts*: seq[MText]
    size*: Size

  MArchitecture* = ref object
    case kind*: MArchitectureKind
    of makSchema:
      schema*: MSchematic

    of makTruthTable:
      truthTable*: MTruthTable

    of makCode, makExternalCode:
      file*: MCodeFile

  MIcon* = ref object
    ports*: seq[MPort]
    size*: Size

  MParamsLookup* = MiniTable[string, MParameter]

  GenerateInfoKind* = enum
    gikIf, gikFor

  GenerateInfo* = object
    case kind*: GenerateInfoKind
    of gikIf:
      cond*: MTokenGroup

    of gikFor:
      varname*: string
      dir*: NumberDirection
      slice*: Slice[MTokenGroup]

  MElement* = ref object
    name*: string
    icon*: MIcon
    parameters*: MParamsLookup
    archs*: seq[MArchitecture]

    case kind*: MElementKind
    of mekModule, mekCode, mekPartialCode, mekFSM, mekTruthTable: discard
    of mekGenerator:
      info*: GenerateInfo

  MTransform* = object
    rotation*: Rotation
    flips*: set[Flip]

  MInstance* = ref object
    name*: string
    parent* {.cursor.}: MElement
    args*: seq[MArg]
    ports*: seq[MPort]
    geometry*: Geometry
    transform*: MTransform

  MParameter* = ref object
    name*: string
    kind*: Option[string]
    defaultValue*: Option[MTokenGroup]

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

  MModuleLookup* = Table[string, MElement]

  MProject* = ref object
    modules*: MModuleLookup

# FIXME in `transformer.nim` types with the same name cause gcc error
