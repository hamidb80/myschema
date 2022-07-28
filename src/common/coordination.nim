type
  Point* = tuple
    x, y: int

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

# logic ---

func `+`*(p1, p2: Point): Point =
  ((p1.x + p2.x), (p1.y + p2.y))

func `-`*(p: Point): Point =
  (-p.x, -p.y)

func `-`*(p1, p2: Point): Point =
  p1 + -p2


func `-`*(r: Rotation): Rotation =
  case r:
  of r0: r0
  of r90: r270
  of r180: r180
  of r270: r90

func rotate0_unit(p: Point): Point =
  ## rotate `p` 90 degrees around (0, 0)
  (-p.y, p.x)

func rotate0(p: Point, r: Rotation): Point =
  ## rotate `p` around (0, 0) `r` degrees
  result = p
  for d in countup(90, r.int, 90):
    result = rotate0_unit p

func rotate*(p, center: Point, r: Rotation): Point =
  ## rptates `p` around `center``r` degrees
  rotate0(p - center, r) + center

