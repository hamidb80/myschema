import std/[xmltree]
import ../common/defs

type
  Color* = object
    r, g, b: range[0..255]
    a: Percent

  DesignSettings* = object
    stroke: Color
    strokeWidth: float
    fill: Color


func newCanvas*(x, y, w, h: int): XmlNode =
  discard

func newGroup*(children: seq[XmlNode]): XmlNode =
  discard

func newRect*(x, y, w, h: int): XmlNode =
  discard

func newCircle*(cx, cy, r: int): XmlNode =
  discard

func newLine*(points: seq[Point]): XmlNode =
  discard

func newPoly*(points: seq[Point]): XmlNode =
  discard

func newText*(font, size, weight: string): XmlNode =
  discard
