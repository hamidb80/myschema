import std/[tables, options]
import ../common/[coordination, domain, graph]

type
  FontSize* = enum
    fzStandard = "standard"
    fzVerySmall = "very-small"
    fzSmall = "small"
    fzLarge = "large"
    fzVeryLarge = "very-large"

  Orient* = enum
    R0, R90, R270
    R90X, R90Y
    RX, RY, RXY

  Anchor* = enum
    w, s, e, n, c
    sw, se, nw, ne

  PortDir* = enum
    pdInput, pdOutput, pdInout

  PortKind* = enum
    pkIconTerm
    pkInstance

  LineKind* = enum
    arc, straight

  IconPropertyKind* = enum
    ipFixed = "fixed" # static
    ipUser = "user"   # dynamic

  ModuleKind* = enum
    mkRef # instance
    mkCtx

  ArchitectureKind* = enum
    akSchematic
    akFile

type
  Label* = object
    content*: string
    location*: Point
    anchor*: Anchor
    fnsize*: FontSize

  Line* = object
    case kind*: LineKind
    of arc:
      head*, tail*: Point
      start*, extent*: Degree

    of straight:
      points*: seq[Point]

  Port* = ref object
    case kind*: PortKind
    of pkIconTerm:
      dir*: PortDir
      name*: string
      location*: Point

    of pkInstance:
      parent* {.cursor.}: Instance
      origin* {.cursor.}: Port

  IconProperty* = object
    kind*: IconPropertyKind
    name*: string
    location*: Point
    defaultValue*: Option[string]

  Icon* = ref object
    ports*: seq[Port]
    lines*: seq[Line]
    size*: Size
    labels*: seq[Label]
    properties*: seq[IconProperty]

  Net* = Graph[Point]

  Schematic* = ref object
    instances*: seq[Instance]
    nets*: seq[Net]
    labels*: seq[Label]
    lines*: seq[Line]

  Architecture* = object
    schema*: Schematic
    code*: Option[string]

  Parameter* = ref object
    name*: string
    defaultValue*: Option[string]

  Argument* = ref object
    name*: string
    value*: string

  Instance* = ref object
    name*: string
    parent* {.cursor.}: Module
    # args*: seq[Argument]
    location*: Point
    orient*: Orient

    # --- meta data
    ports*: seq[Port]

  Module* = ref object
    name*: string

    case kind*: ModuleKind
    of mkRef: discard
    of mkCtx:
      icon*: Icon
      arch*: Architecture
      # params*: seq[Parameter]
      # isGenerator*: bool

  ModuleLookUp* = Table[string, Module]

  Project* = ref object
    modules*: ModuleLookUp
