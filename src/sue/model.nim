import std/[tables, options]
import ../common/[coordination, domain, graph, minitable]

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
    pdInput = "input"
    pdOutput = "output"
    pdInout = "inout"

  PortKind* = enum
    pkIconTerm
    pkInstance

  LineKind* = enum
    arc, straight

  PropertyKind* = enum
    pFixed = "fixed" # static
    pUser = "user"   # dynamic

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
      hasSiblings*, isGhost*: bool

    of pkInstance:
      parent* {.cursor.}: Instance
      origin* {.cursor.}: Port

  Property* = object
    kind*: PropertyKind
    name*: string
    location*: Point
    defaultValue*: Option[string]

  Icon* = ref object
    params*: MiniTable[string, Option[string]]
    ports*: seq[Port]
    lines*: seq[Line]
    labels*: seq[Label]
    properties*: seq[Property]

  PortID* = distinct string

  Schematic* = ref object
    instances*: seq[Instance]
    wiredNodes*: Graph[Point]
    connections*: Graph[PortID]
    labels*: seq[Label]
    lines*: seq[Line]
    # --- meta data
    portsPlot*: Table[Point, seq[Port]]
    portsTable*: Table[PortID, seq[Port]]

  Instance* = ref object
    kind*: InstanceKind
    name*: string
    module* {.cursor.}: Module
    args*: MiniTable[string, string]
    location*: Point
    orient*: Orient

    ## cache
    ports*: seq[Port]

  Module* = ref object
    name*: string

    case kind*: ModuleKind
    of mkRef: discard
    of mkCtx:
      icon*: Icon
      schema*: Schematic
      code*: Option[string]
      isTemp*: bool # is temporaty - do not generate file for temporary modules
      isGenerator*: bool

  ModuleLookUp* = Table[string, Module]

  Project* = ref object
    modules*: ModuleLookUp


import std/hashes

func hash*(pid: PortID): Hash {.borrow.}
func `==`*(pid1, pid2: PortID): bool {.borrow.}
func `$`*(pid: PortID): string {.borrow.}

template `?`(smth): untyped =
  some smth

func newModule*(name: string): Module =
  Module(
    kind: mkCtx,
    icon: Icon(params: @{
      "name": ?"{}",
      "origin": ?"{0 0}",
      "orient": ?"R0"
    }),
    schema: Schematic(),
    name: name)

func refModule*(name: string): Module =
  Module(kind: mkRef, name: name)
