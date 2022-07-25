import std/[xmltree, tables]

import sue/[parser, transformer]
import middle/[visualizer, svg]


let 
  s = parseSueProject("./examples/sample", @[])
  mm = toMiddleModel s

var cnv = newCanvas(-100, -100, 200, 200)
visualize cnv, mm.modules["wires"].schema

writeFile "play.svg", $cnv

