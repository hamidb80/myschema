import ./coordination

type
  Percent* = range[0.0 .. 1.0]
  Degree* = range[-359 .. 359]

  Wire* = Slice[Point]

  CodeFile* = object
    name*: string
    content*: string


func dirOf*(w: Wire): VectorDirection =
  ## remeber when you go up, the y is - and the bottom is +

  if w.a.x == w.b.x: # vertical
    if w.b.y > w.a.y: vdSouth
    else: vdNorth

  elif w.a.y == w.b.y: # horizobtal
    if w.b.x > w.a.x: vdEast
    else: vdWest

  else:
    vdDiagonal
