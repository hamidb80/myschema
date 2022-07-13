import std/[xmltree]
import ../common/defs

func newCanvas*(x, y, w, h: int): XmlNode = discard
func newRect*(x, y, w, h: int): XmlNode = discard
func newCircle*(cx, cy, r: int): XmlNode = discard
func newLine*(points: seq[Point]): XmlNode = discard
func newText*(font, size, weight: string): XmlNode = discard
func newGroup*(children: seq[XmlNode]): XmlNode = discard
