import std/[tables]
import ../common/defs

type
  Wire* = Slice[Point]

  Bounds* = object
    x1*, y1*, x2*, y2*: int

  Flip* = enum
    X, Y

  FontSize* = enum
    fzMedium, fzSmall, fzLarge

  Rotation* = enum
    r0, r90, r180, r270

  Orient* = object
    rotation*: Rotation
    flips*: set[Flip]

  Anchor* = enum
    c, s, w, e, n
    sw, se, nw, ne

  Label* = ref object
    content*: string
    location*: Point
    anchor*: Anchor
    size*:FontSize

  SueSize* = enum
    ssNormal = ""
    ssSmall = "small"
    ssLarge = "large"


  PortDir* = enum
    input, output, inout

  Port* = ref object
    kind*: PortDir
    location*: Point
    name*: string


  Schematic* = ref object
    instances*: seq[Instance]
    wires*: seq[Wire]
    texts*: seq[Label]

  Icon* = ref object
    ports*: seq[Port]
    bounds*: Bounds
    labels*: seq[Label]

  Module* = ref object
    name*: string
    schematic*: Schematic
    icon*: Icon

  Instance* = ref object
    name*: string
    parent* {.cursor.}: Module
    location*: Point
    orient*: Orient

  LookUp* = TableRef[string, Module]

  Project* = ref object
    lookup*: LookUp
    modules*: seq[Module]

