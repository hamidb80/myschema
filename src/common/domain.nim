import coordination, errors

type
  Percent* = range[0.0 .. 1.0]
  Degree* = range[-359 .. 359]

  Wire* = Slice[Point]

  CodeFile* = object
    name*: string
    content*: string


func dirOf*(w: Wire): VectorDirection =
  if w.a.x == w.b.x: # horizobtal
    if w.a.y > w.b.y: vdSouth
    else: vdNorth

  elif w.a.y == w.b.y: # horizobtal
    if w.a.x > w.b.x: vdWest
    else: vdEast

  else:
    err "invalid direction"
