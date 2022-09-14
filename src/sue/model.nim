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
      relativeLocation*: Point

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
    labels*: seq[Label]
    properties*: seq[IconProperty]

  PortID* = distinct string

  Schematic* = ref object
    instances*: seq[Instance]
    wiredNodes*: Graph[Point]
    connections*: Graph[PortID]
    labels*: seq[Label]
    lines*: seq[Line]

    # --- meta data
    portsTable*: Table[PortID, seq[Port]]

  Parameter* = ref object
    name*: string
    defaultValue*: Option[string]

  Argument* = ref object
    name*: string
    value*: string

  Instance* = ref object
    kind*: InstanceKind
    name*: string
    module* {.cursor.}: Module
    args*: seq[Argument]
    location*: Point
    orient*: Orient

  Module* = ref object
    name*: string

    case kind*: ModuleKind
    of mkRef: discard
    of mkCtx:
      icon*: Icon
      schema*: Schematic
      code*: Option[string]
      params*: seq[Parameter]
      isTemp*: bool # is temporaty - do not generate file for temporary modules
      isGenerator*: bool

  ModuleLookUp* = Table[string, Module]

  Project* = ref object
    modules*: ModuleLookUp


import std/hashes

func hash*(pid: PortID): Hash {.borrow.}
func `==`*(pid1, pid2: PortID): bool {.borrow.}

func newModule*(): Module = 
  Module(kind: mkCtx, icon: Icon(), schema: Schematic())