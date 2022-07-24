import std/[tables]
import ../common/[coordination]

type
  Label* = ref object
    text*: string
    position*: Point

  PortDir* = enum
    input, output, inout

  Port = object
    name*: string
    dir*: PortDir
    position*: Point

  Icon* = ref object
    ports*: seq[Port]
    # bounds*: 

  Schema* = ref object
    instances*: seq[Instance]
    conntections*: seq[Wire]
    lables*: seq[Label]

  Module* = ref object
    icon*: Icon
    schema*: Schema

  Instance* = ref object
    parent* {.cursor.}: Module
    name*: string


  Wire* = ref object
    isBus*: bool

  NetGraphNode* {.acyclic.} = ref object # AKA Net
    location*: Point
    connections*: seq[NetGraphNode]      # only forward connections

  ModuleLookup* = Table[string, Module]

  Project* = ref object
    modulelookUp*: ModuleLookup
    mainModules*: seq[Module]

