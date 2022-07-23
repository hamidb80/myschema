import std/[tables]
import ../common/defs

type

  Schema* = ref object
    instances*: seq[Instance]
    conntections*: seq[Wire]
    lables*: seq[Label]

  PortDir* = enum
    input, output, inout

  Port = object
    name*: string
    dir*: PortDir
    position*: Point

  Module* = ref object
    icon*: Icon
    schema*: Schema

  Icon* = ref object
    ports*: seq[Port]
    # bounds*: 

  Instance* = ref object
    parent* {.cursor.}: Module
    name*: string

  Label* = ref object
    text*: string
    position*: Point


  Wire* = ref object
    isBus*: bool

  NetGraphNode* {.acyclic.} = ref object # AKA Net
    location*: Point
    connections*: seq[NetGraphNode]      # only forward connections

  ModuleLookup* = Table[string, Module]

  Project* = ref object
    modulelookUp*: ModuleLookup
    mainModules*: seq[Module]

