import std/[xmltree, strtabs, sequtils]
import ../common/coordination

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
  result = <>svg(xmlns = "http://www.w3.org/2000/svg")
  result.attrs["xmlns:xlink"] = "http://www.w3.org/1999/xlink"
  #TODO add acanvas view-port

func newGroup*(children: seq[XmlNode]): XmlNode =
  result = <>g()
  result.add children

func newRect*(x, y, w, h: int): XmlNode =
  <>rect(x = $x, y = $y, width = $w, height = $h)

func newCircle*(cx, cy, r: int): XmlNode =
  <>circle(cx = $cx, ct = $cy, r = $r)

func newLine*(head, tail: Point): XmlNode =
  <>line(x1 = $head.x, y1 = $head.y, x2 = $tail.x, y2 = $tail.y)

func newPartialText(sentence: string): XmlNode =
  # alignment-baseline 
  # anchor-text
  <>tspan(newText(sentence))

func newTextBox*(sentences: seq[string], font: Font): XmlNode =
  result = <>text()
  result.add sentences.map(newPartialText)
