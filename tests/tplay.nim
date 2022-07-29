import std/[xmltree, tables, strformat, os]

import ease/[model, transformer, parser]
import middle/[visualizer, svg]

const path = r"C:\ProgramData\HDL Works\Ease80Rev4\ease\examples\uart\uart.ews"
let proj = toMiddleMode parseEws path

removeDir "./temp"
createDir "./temp"

for name, module in proj.modules:
  if module.schema != nil:
    let (w, h) = module.schema.size
    var c = newCanvas(0, 0, w, h)
    c.visualize module.schema
    writeFile fmt"./temp/{name}.svg", $c
