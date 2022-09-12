import coordination

type
  Percent* = range[0.0 .. 1.0]
  Degree* = range[-359 .. 359]

  Wire* = Slice[Point]

  CodeFile* = object
    name*: string
    content*: string
