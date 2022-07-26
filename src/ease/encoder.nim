import std/[tables]
import model, lisp


func encode*(g: Geometry): LispNode =
  toLisp (!GEOMETRY, g.x1, g.y1, g.x2, g.y2)

func encode*(w: Wire): LispNode =
  toLisp (!WIRE, w.a.x, w.a.y, w.b.x, w.b.y)

func encode*(s: Side): LispNode =
  toLisp (!SIDE, s.int)

func encode*(a: Alignment): LispNode =
  toLisp (!ALIGNMENT, a.int)

func encode*(d: NumberDirection): LispNode =
  toLisp (!DIRECTION, d.int)

func encode*(prs: Properties): LispNode =
  result = toLisp (!PROPERTIES)
  for k, v in prs:
    result.add toLisp (!PROPERTY, k, v)

# ---- named

func encodeMode*(i: int): LispNode =
  toLisp (!MODE, i)
