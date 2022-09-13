## this module contains basics 2D-coordination types and functionalities

import minmax

type
  Point* = tuple
    x, y: int

  Vector* = Point

  Rotation* = enum
    r0 = 0
    r90 = 90
    r180 = 180
    r270 = 270

  Flip* = enum
    X, Y

  Size* = tuple
    w, h: int

  Geometry* = tuple
    x1, y1, x2, y2: int

  Rect* = tuple
    x, y, w, h: int

  VectorDirection* = enum
    vdNorth
    vdEast
    vdSouth
    vdWest

  Transform* = object
    rotation*: Rotation
    flips*: set[Flip]


func `+`*(p1, p2: Point): Point =
  ((p1.x + p2.x), (p1.y + p2.y))

func `-`*(p: Point): Point =
  (-p.x, -p.y)

func `-`*(p1, p2: Point): Point =
  p1 + -p2


proc `*`*(p: Vector, n: int): Vector =
  (p.x * n, p.y * n)


func `-`*(r: Rotation): Rotation =
  case r:
  of r0: r0
  of r90: r270
  of r180: r180
  of r270: r90

func rotate0*(p: Point, r: Rotation): Point =
  ## rotate `p` around (0, 0) `r` degrees
  case r:
  of r0: p
  of r90: (-p.y, p.x)
  of r180: (-p.x, -p.y)
  of r270: (p.y, -p.x)

func rotate*(p, center: Point, r: Rotation): Point =
  ## rptates `p` around `center``r` degrees
  rotate0(p - center, r) + center


func center*(g: Geometry): Point =
  ((g.x1 + g.x2) div 2, (g.y1 + g.y2) div 2)

func topLeft*(geo: Geometry): Point =
  (geo.x1, geo.y1)

func topRight*(geo: Geometry): Point =
  (geo.x2, geo.y1)

func bottomLeft*(geo: Geometry): Point =
  (geo.x1, geo.y2)

func bottomRight*(geo: Geometry): Point =
  (geo.x2, geo.y2)

func points*(geo: Geometry): seq[Point] =
  @[topLeft geo, topRight geo, bottomRight geo, bottomLeft geo]

func area*(ps: seq[Point]): Geometry =
  var
    xs: MinMax[int]
    ys: MinMax[int]

  for p in ps:
    xs.update p.x
    ys.update p.y

  (xs.min, ys.min, xs.max, ys.max)


func flipY(p: Point): Point =
  (p.x, -p.y)

func flipX(p: Point): Point =
  (-p.x, p.y)

template applyFlip(fn, p, c): untyped =
  fn(p - c) + c

func flip*(p, c: Point, flips: set[Flip]): Point =
  result = p

  for f in flips:
    result = case f:
      of X: applyFlip flipX, result, c
      of Y: applyFlip flipY, result, c


import std/sequtils

func rotate*(geo: Geometry, center: Point, r: Rotation): Geometry =
  area geo.points.mapIt rotate(it, center, r)

func `+`*(g: Geometry, v: Vector): Geometry =
  (g.x1 + v.x, g.y1 + v.y, g.x2 + v.x, g.y2 + v.y)

func `-`*(g: Geometry, v: Vector): Geometry =
  g + -v

func toPoint*(s: Size): Point =
  (s.w, s.h)

func toSize*(p: Point): Size =
  (p.x, p.y)

func toGeometry*(p: Point): Geometry =
  (0, 0, p.x, p.y)

func toGeometry*(s: Size): Geometry =
  toGeometry toPoint s

# func `or`*(g1, g2: Geometry): Geometry =
#   ## returns a geometry that  includes both `g1` and `g2`
#   (
#     min(g1.x1, g2.x1), min(g1.y1, g2.y1),
#     max(g1.x2, g2.x2), max(g1.y2, g2.y2),
#   )

func toSize*(g: Geometry): Size =
  (g.x2 - g.x1, g.y2 - g.y1)

func toRect*(g: Geometry): Rect =
  let size = toSize g
  (g.x1, g.y1, size.w, size.h)

func placeAt*(g: Geometry, at: Point): Geometry =
  let size = toSize g
  (at.x, at.y, at.x + size.w, at.y + size.h)

const P0* = (0, 0)


func `-`*(vd: VectorDirection): VectorDirection =
  case vd:
  of vdEast: vdWest
  of vdWest: vdEast
  of vdNorth: vdSouth
  of vdSouth: vdNorth

func toUnitPoint*(vd: VectorDirection): Point =
  case vd:
  of vdEast: (+1, 0)
  of vdWest: (-1, 0)
  of vdNorth: (0, +1)
  of vdSouth: (0, -1)

func whichEdge*(p: Point, geo: Geometry): VectorDirection =
  if p.x == geo.x1: vdWest
  elif p.x == geo.x2: vdEast
  elif p.y == geo.y1: vdNorth
  elif p.y == geo.y2: vdSouth
  else: raise newException(ValueError, "offside")


func translationAfter*(geo: Geometry, r: Rotation): Vector =
  topleft(geo.rotate(P0, r)) - (topleft geo)

