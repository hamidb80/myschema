import std/[tables, options]
import ../common/[coordination, domain]

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

  Label* = ref object
    content*: string
    location*: Point
    anchor*: Anchor
    size*: FontSize

  PortDir* = enum
    pdInput, pdOutput, pdInout

  Port* = ref object
    kind*: PortDir
    location*: Point # relative
    name*: string

  LineKind* = enum
    arc, straight

  Line* = object
    case kind*: LineKind
    of arc:
      head*, tail*: Point
      start*, extent*: Degree

    of straight:
      points*: seq[Point]

  IconPropertyKind* = enum
    ipFixed = "fixed" # static
    ipUser = "user"   # dynamic

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

  SSchematic* = ref object
    instances*: seq[Instance]
    wires*: seq[Wire]
    labels*: seq[Label]
    lines*: seq[Line]

  ModuleKind* = enum
    mkRef # instance
    mkCtx

  ArchitectureKind* = enum
    akSchematic
    akFile

  Architecture* = object
    schema*: SSchematic

    case kind*: ArchitectureKind
    of akSchematic: discard
    of akFile:
      file*: MCodeFile

  Parameter* = object
    name*: string
    defaultValue*: Option[string]

  Argument* = object
    name*: string
    value*: string

  Instance* = ref object
    name*: string
    parent* {.cursor.}: Module
    location*: Point
    # args*: seq[Argument]
    orient*: Orient

  Module* = ref object
    name*: string

    case kind*: ModuleKind
    of mkRef: discard
    of mkCtx:
      icon*: Icon
      arch*: Architecture
      params*: seq[Parameter]
      isGenerator*: bool
      isTemporary*: bool # do not generate file for these modules

  ModuleLookUp* = Table[string, Module]

  Project* = ref object
    modules*: ModuleLookUp
