import std/[strutils, strformat, sequtils]
import ../utils

type
  SuePoint = tuple[x, y: int]

  SueSegemnt = HSlice[SuePoint, SuePoint]

  SueLabel = ref object
    content: string
    location: SuePoint

  SueSchematic = ref object
    instances: seq[SueInstance]
    wires: seq[SueSegemnt]
    labels: seq[SueLabel]

  SueIcon = ref object

  SueComponent* = ref object
    name: string
    schematic: SueSchematic
    icon: SueIcon

  SueInstance = ref object
    name: string
    parent {.cursor.}: SueComponent
