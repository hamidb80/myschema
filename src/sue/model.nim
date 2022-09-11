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

  InstanceKind* = enum
    ikPort
    ikNameNet
    ikCustom

  ModuleKind* = enum
    mkRef # instance
    mkCtx

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

  PortId* = distinct string

  Schematic* = ref object
    instances*: seq[Instance]
    wireNets*: Graph[Point]
    connections*: Graph[PortId]
    labels*: seq[Label]
    lines*: seq[Line]

  Parameter* = ref object
    name*: string
    defaultValue*: Option[string]

  Argument* = ref object
    name*: string
    value*: string

  Instance* = ref object
    kind*: InstanceKind
    name*: string
    parent* {.cursor.}: Module
    # args*: seq[Argument]
    location*: Point
    orient*: Orient

    # --- meta data
    portsPlot*: Table[Point, seq[Port]] # `seq` because multiply ports can be at the same place!

  Module* = ref object
    name*: string

    case kind*: ModuleKind
    of mkRef: discard
    of mkCtx:
      icon*: Icon
      schema*: Schematic
      code*: Option[string]
      isTemp*: bool # is temporaty - do not generate file for temporary modules
                    # params*: seq[Parameter]
                    # isGenerator*: bool

  ModuleLookUp* = Table[string, Module]

  Project* = ref object
    modules*: ModuleLookUp


import std/hashes

func hash*(pid: PortId): Hash {.borrow.}
func `==`*(pid1, pid2: PortId): bool {.borrow.}