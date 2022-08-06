import std/[options, tables, strutils, strformat]

import model
import ../common/[coordination, errors, domain, minitable]


type
  Transformer* = proc(p: Point): Point

  IndetifierKind* = enum
    ikSingle, ikIndex, ikRange

  Identifier* = object
    name*: string

    case kind*: IndetifierKind
    of ikSingle: discard
    of ikIndex:
      index*: string

    of ikRange:
      direction*: NumberDirection
      indexes*: Slice[string]


# basics ---

func toRotation*(s: Side): Rotation =
  case s:
  of sTopToBottom: r0
  of sRightToLeft: r90
  of sBottomToTop: r180
  of sLeftToRight: r270

func rotation*[T: Thing](c: T): Rotation =
  toRotation c.side

func position*(p: Port): Point =
  center p.geometry

func flips*[T: Thing](element: T): set[Flip] =
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

func getIfCond*(gb: GenerateBlock): string =
  gb.properties["IF_CONDITION"]

func getForInfo*(gb: GenerateBlock): tuple[ident: string, `range`: Range] =
  (gb.properties["FOR_LOOP_VAR"], gb.constraint.get.`range`)

func translationAfter*(geo: Geometry, ro: Rotation): Vector =
  ## returns a vector that if added to the result,
  ## it will keep the whole shape at the original top left
  geo.placeAt(P0).rotate(P0, ro).topleft

func getIconTransformer*(iconGeo: Geometry,
    rotated: Rotation): Transformer =

  let
    pin = topLeft iconGeo
    translate = -translationAfter(iconGeo, -rotated)

  proc transformer(p: Point): Point =
    let
      t1 = p.rotate(pin, -rotated)
      t2 = t1 + translate - pin

    t2

  transformer

func getIconSize*(geo: Geometry, ro: Rotation): Size =
  toSize rotate(geo, P0, -ro)
