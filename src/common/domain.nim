import coordination

type
  Percent* = range[0.0 .. 1.0]
  Degree* = range[-359 .. 359]

  Wire* = Slice[Point]

  NumberDirection* = enum
    ndDec = 1
    ndInc

  IndetifierKind* = enum
    ikSingle
    ikIndex
    ikRange

  Identifier* = object
    name*: string

    case kind*: IndetifierKind
    of ikSingle: discard

    of ikIndex:
      index*: string # TODO actually it's either a parameter/variable or a number

    of ikRange:
      direction*: NumberDirection
      indexes*: Slice[string] # TODO this too
