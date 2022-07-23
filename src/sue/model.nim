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
    # properties*:

  Schematic* = ref object
    instances*: seq[Instance]
    wires*: seq[Wire]
    texts*: seq[Label]

  Module* = ref object
    name*: string
    schematic*: Schematic
    icon*: Icon

  Instance* = ref object
    name*: string
    parent* {.cursor.}: Module
    location*: Point
    orient*: Orient

  ModuleLookUp* = TableRef[string, Module]

  Project* = ref object
    lookup*: ModuleLookUp
    modules*: seq[Module]


func isNone*(o: Orient): bool =
  o.flips.len == 0 and o.rotation == r0

func isNone*(a: Anchor): bool =
  a == c

func isNone*(fz: FontSize): bool =
  fz == fzMedium