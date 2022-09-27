## this module contains basics 2D-coordination types and functionalities
import std/[sequtils]
import minmax, errors

type
  CircularDirection* = enum
    cdInwrad
    cdOutward

  Rotation* = enum
    r0 = 0
    r90 = 90
    r180 = 180
    r270 = 270

  Axis* = enum
    X, Y

  VectorDirection* = enum
    vdEast
    vdSouth
    vdWest
    vdNorth
    vdDiagonal

  Vector* = Point
  Point* = tuple
    x, y: int

  Geometry* = tuple
    x1, y1, x2, y2: int

  Rect* = tuple
    x, y, w, h: int

  Size* = tuple
    w, h: int

  Transformer* = proc(p: Point): Point {.noSideEffect.}


func `+`*(p1, p2: Point): Point =
  ((p1.x + p2.x), (p1.y + p2.y))

func `-`*(p: Point): Point =
  (-p.x, -p.y)

func `-`*(p1, p2: Point): Point =
  p1 + -p2

func dist*(p1, p2: Point): int =
  ## Manhattan distance
  abs(p1.x-p2.x) + abs(p1.y-p2.y)

proc `*`*(p: Vector, n: int): Vector =
  (p.x * n, p.y * n)

proc `*`*(n: int, p: Vector): Vector =
  p * n

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

func points*(geo: Geometry, closed = false): seq[Point] =
  result = @[topLeft geo, topRight geo, bottomRight geo, bottomLeft geo]
  if closed:
    result.add result[0]

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

func flip*(p, c: Point, flips: set[Axis]): Point =
  result = p

  for f in flips:
    result = case f:
      of X: applyFlip flipX, result, c
      of Y: applyFlip flipY, result, c

func flip*(geo: Geometry, c: Point, flips: set[Axis]): Geometry =
  area geo.points.mapIt flip(it, c, flips)

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

func size*(g: Geometry): Size =
  (g.x2 - g.x1, g.y2 - g.y1)

func toRect*(g: Geometry): Rect =
  let s = size g
  (g.x1, g.y1, s.w, s.h)

func placeAt*(g: Geometry, at: Point): Geometry =
  let s = size g
  (at.x, at.y, at.x + s.w, at.y + s.h)

const P0* = (0, 0)


func `-`*(vd: VectorDirection): VectorDirection =
  case vd:
  of vdEast: vdWest
  of vdWest: vdEast
  of vdNorth: vdSouth
  of vdSouth: vdNorth
  of vdDiagonal: err "cannot negate a diagonal vector direction"

func toVector*(vd: VectorDirection): Vector =
  ## converts vector direction `vd` to unit Vecotr
  ## remember north is -y
  case vd:
  of vdEast: (+1, 0)
  of vdWest: (-1, 0)
  of vdNorth: (0, -1)
  of vdSouth: (0, +1)
  of vdDiagonal: err "cannot represent a diagonal line as unit vector"

func axis*(vd: VectorDirection): Axis =
  case vd:
  of vdEast, vdWest: X
  of vdNorth, vdSouth: Y
  of vdDiagonal: err "both?"

func on*(v: Vector, a: Axis): int =
  case a:
  of X: v.x
  of Y: v.y

func on*(g: Geometry, a: Axis): Slice[int] =
  case a:
  of X: g.x1 .. g.x2
  of Y: g.y1 .. g.y2

func vector*(length: int, axis: Axis): Vector =
  case axis:
  of X: (length, 0)
  of Y: (0, length)