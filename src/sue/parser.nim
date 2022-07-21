import std/[strutils, strformat, sequtils]
import ../utils
import ../common/defs

type
  SueSegemnt = Slice[Point]

  SueLabel = ref object
    content: string
    location: Point

  SueSchematic = ref object
    instances: seq[SueInstance]
    wires: seq[SueSegemnt]
    labels: seq[SueLabel]

  SueIcon = ref 
  
  SueComponent* = ref object
    name: string
    schematic: SueSchematic
    icon: SueIcon

  SueInstance = ref object
    name: string
    parent {.cursor.}: SueComponent
