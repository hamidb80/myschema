import std/[xmltree, tables]

import src/sue/[model, parser, transformer]
import src/middle/[visualizer, svg]


let 
  s = parseSueProject("./examples/sample", @[])
  mm = toMiddleModel s

var cnv = newCanvas(0, 0, 0, 0)
visualize cnv, mm.modules["wires"].schema

writeFile "play.svg", $cnv

