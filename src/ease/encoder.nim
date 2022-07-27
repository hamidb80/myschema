import std/[tables, macros, options]
import model, lisp
import ../common/coordination


macro `!`(c): untyped =
  ## convert list function call to nim functiona call

  runnableExamples:
    echo !(SCALE, 2) # => encodeScale(2)

  newCall("encode" & c[0].strval).add c[1 .. ^1]

func add(ln: var LispNode, v: Option[LispNode]) =
  if isSome v:
    ln.add v.get

template toLispNode(v: Option[LispNode]): untyped =
  v

func encodeGeometry*(g: Geometry): LispNode =
  toLisp (\GEOMETRY, g.x1, g.y1, g.x2, g.y2)

func encodeWire*(w: Wire): LispNode =
  toLisp (\WIRE, w.a.x, w.a.y, w.b.x, w.b.y)

func encodeSide*(s: Side): LispNode =
  toLisp (\SIDE, s.int)

func encodeAlignment*(a: Alignment): LispNode =
  toLisp (\ALIGNMENT, a.int)

func encodeDirection*(d: NumberDirection): LispNode =
  toLisp (\DIRECTION, d.int)

func encodeProperties*(prs: Properties): LispNode =
  result = toLisp (\PROPERTIES)
  for k, v in prs:
    result.add toLisp (\PROPERTY, k, v)

func encodeMode*(i: int): LispNode =
  toLisp (\MODE, i)

func encodeFormat*(s: int): LispNode =
  toLisp (\FORMAT, s)

func encodeType*(t: int): LispNode =
  toLisp (\TYPE, t)

func encodeColorFill*(c: EaseColor): LispNode =
  toLisp (\COLOR_FILL, c.int)

func encodeColorLine*(c: EaseColor): LispNode =
  toLisp (\COLOR_LINE, c.int)

func encodeObjStamp*(username: string, created, modified: int): LispNode =
  toLisp (
    (\DESIGNER, username),
    (\CREATED, created, "..."),
    (\MODIFIED, modified, "..."),
  )

func encodePosition(pos: Point): LispNode =
  toLisp (\POSITION, pos.x, pos.y)

func encodeText(ss: seq[string]): Option[LispNode] =
  if ss.len != 0:
    var ln = newLispList()
    ln.add toLispSymbol "TEXT"

    for s in ss:
      ln.add toLispNode s

    some ln

  else:
    none LispNode

func encodeLabel*(lbl: Label): LispNode =
  toLisp (\LABEL,
    !(POSITION, lbl.position),
    (\SCALE, lbl.scale),
    (\COLOR_LINE, lbl.colorLine.int),
    !(SIDE, lbl.side),
    !(ALIGNMENT, lbl.alignment),
    (\FORMAT, lbl.format),
    !(TEXT, lbl.texts),
  )

func encodeFreePlacedText(fpt: FreePlacedText): LispNode =
  toLisp (\FREE_PLACED_TEXT,
    !(LABEL, fpt.Label)
  )
