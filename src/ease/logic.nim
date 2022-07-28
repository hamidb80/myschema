import std/[options, strtabs, strutils, strformat, sequtils]

import model
# import ../middle/model as mm
import ../common/[coordination, errors, domain]


# basics ---

type Element = Component or Process or GenerateBlock


func toRotation*(s: Side): Rotation =
  case s.int:
  of 0: r0
  of 1: r90
  of 2: r180
  of 3: r270
  else: err ""

func rotation*(c: Component): Rotation =
  toRotation c.side

func position*(p: Port): Point =
  center p.geometry

func flips*[T: Element](element: T): set[Flip] =
  # vertical = 1
  # horizontal = 2
  # both = 3

  let f = element.properties.getOrDefault("Flip", "0").parseInt
  case f:
  of 0: {}
  of 1: {Y}
  of 2: {X}
  of 3: {X, Y}
  else: err fmt"invalid Flip code: '{f}'"


func identifier*(p: Port): Identifier =
  let cn = p.ident.attributes.constraint

  if isSome cn:
    case cn.get.kind:
    of ckIndex:
      result = Identifier(kind: ikIndex,
        index: cn.get.index)

    of ckRange:
      result = Identifier(kind: ikRange,
        indexes: cn.get.`range`.indexes,
        direction: cn.get.`range`.direction)

  else:
    result = Identifier(kind: ikSingle)

  result.name = p.ident.name

func mode*(p: Port): PortMode =
  PortMode p.ident.attributes.mode.get
