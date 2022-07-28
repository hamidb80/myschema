import std/[tables]
import ../common/[coordination, domain]

type
  Wire* = Slice[Point]

  Bounds* = object
    x1*, y1*, x2*, y2*: int

  Flip* = enum
    X, Y

  FontSize* = enum
    fzStandard = "standard"
    fzVerySmall = "very-small"
    fzSmall = "small"
    fzLarge = "large"
    fzVeryLarge = "very-large"

  Rotation* = enum
    r0 = 0
    r90 = 90
    r180 = 180
    r270 = 270

  Orient* = object
    rotation*: Rotation
    flips*: set[Flip]

  Anchor* = enum
    w, s, e, n, c
    sw, se, nw, ne

  Label* = ref object
    content*: string
    location*: Point
    anchor*: Anchor
    size*: FontSize

  PortDir* = enum
    input, output, inout

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

  Icon* = ref object
    ports*: seq[Port]
    labels*: seq[Label]
    lines*: seq[Line]
    # properties*: for Generics

  Schematic* = ref object
    instances*: seq[Instance]
    wires*: seq[Wire]
    texts*: seq[Label]

  ModuleKind* = enum
    mkRef # instance
    mkCtx

  Module* = ref object
    name*: string

    case kind*: ModuleKind
    of mkRef: discard
    of mkCtx:
      icon*: Icon
      schema*: Schematic

  Instance* = ref object
    name*: string
    parent* {.cursor.}: Module
    location*: Point
    orient*: Orient

  ModuleLookUp* = Table[string, Module]

  Project* = ref object
    modules*: ModuleLookUp

