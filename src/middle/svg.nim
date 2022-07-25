import std/[xmltree, strtabs, sequtils, strformat]
import ../common/[coordination, domain]

type
  Color* = object
    r, g, b: range[0..255]
    a: Percent

  Font* = object
    family*: string
    size*: float
    color*: Color

  ShapeDrawingSettings* = object
    width*: float # AKA strokeWidth
    line*: Color  # AKA stroke
    fill*: Color

# --- utils

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

func newRect*(x, y, w, h: int): XmlNode =
  <>rect(x = $x, y = $y, width = $w, height = $h)

func newCircle*(cx, cy, r: int): XmlNode =
  <>circle(cx = $cx, ct = $cy, r = $r)

func newLine*(head, tail: Point): XmlNode =
  <>line(x1 = $head.x, y1 = $head.y, x2 = $tail.x, y2 = $tail.y,
      stroke-width = "0.5", stroke = "black")

func newPartialText(sentence: string): XmlNode =
  # alignment-baseline
  # anchor-text
  <>tspan(newText(sentence))

func newTextBox*(sentences: seq[string], font: Font): XmlNode =
  result = <>text()
  result.add sentences.map(newPartialText)
