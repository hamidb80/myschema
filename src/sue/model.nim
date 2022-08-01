import std/[tables]
import ../common/[coordination, domain]
import lexer

type
  FontSize* = enum
    fzStandard = "standard"
    fzVerySmall = "very-small"
    fzSmall = "small"
    fzLarge = "large"
    fzVeryLarge = "very-large"

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

  Icon* = ref object
    ports*: seq[Port]
    labels*: seq[Label]
    lines*: seq[Line]
    size*: Size
    # properties*: for Generics

  Schematic* = ref object
    instances*: seq[Instance]
    wires*: seq[Wire]
    labels*: seq[Label]

  ModuleKind* = enum
    mkRef # instance
    mkCtx

  ArchitectureKind* = enum
    akSchematic
    akFile

  Architecture* = object
    case kind*: ArchitectureKind
    of akSchematic:
      schema*: Schematic

    of akFile:
      file*: MCodeFile

  Module* = ref object
    name*: string

    case kind*: ModuleKind
    of mkRef: discard
    # of mkPreDefined:
    of mkCtx:
      icon*: Icon
      arch*: Architecture
      params*: seq[Parameter]
      isTemporary*: bool # do not generate file for these modules

  Parameter* = object
    name*: string
    defaultValue*: string

  Argument* = object
    name*: string
    value*: string


  Instance* = ref object
    name*: string
    parent* {.cursor.}: Module
    location*: Point
    args*: seq[Argument]
    orient*: Orient

  ModuleLookUp* = Table[string, Module]

  Project* = ref object
    modules*: ModuleLookUp

