import std/[xmltree, strtabs, sequtils, strformat]
import ../common/[coordination, domain]

type
  ColorRange = range[0..255]

  Color* = object
    r*, g*, b*: ColorRange
    a*: Percent

  FontStyle* = object
    family*: string
    size*: float
    color*: Color

  ShapeStyle* = object
    width*: float  # AKA strokeWidth
    border*: Color # AKA stroke
    fill*: Color
    corner*: float

# --- utils

func `$`*(c: Color): string =
  fmt"rgba({c.r},{c.g},{c.b},{c.a})"

func initColor*(red, green, blue: ColorRange, alpha: Percent): Color =
  Color(r: red, g: green, b: blue, a: alpha)

func add(parent: var XmlNode, newChildren: openArray[XmlNode]) =
  for ch in newChildren:
    parent.add ch

# --- main

func newCanvas*(x, y, w, h: int): XmlNode =
  result = <>svg(xmlns = "http://www.w3.org/2000/svg",
      viewBox = fmt"{x} {y} {w} {h}", version = "1.1")

func newGroup*(children: openArray[XmlNode]): XmlNode =
  result = <>g()
  result.add children

func newRect*(x, y, w, h: int, style: ShapeStyle): XmlNode =
  <>rect(x = $x, y = $y, width = $w, height = $h,
    fill = $style.fill,
    strokeWidth = $style.width,
    stroke = $style.border,
    rx = $style.corner)

func newCircle*(cx, cy, r: int, style: ShapeStyle): XmlNode =
  <>circle(cx = $cx, cy = $cy, r = $r,
    fill = $style.fill,
    strokeWidth = $style.width,
    stroke = $style.border)

func newLine*(head, tail: Point, style: ShapeStyle): XmlNode =
  <>line(x1 = $head.x, y1 = $head.y, x2 = $tail.x, y2 = $tail.y,
    stroke-width = $style.width,
    stroke = $style.border)

func newPartialText(sentence: string): XmlNode =
  # alignment-baseline
  # anchor-text
  <>tspan(newText(sentence))

func newTextBox*(sentences: seq[string], font: FontStyle): XmlNode =
  result = <>text()
  result.add sentences.map(newPartialText)
