import std/[xmltree, tables, strformat, os]

import ease/[model, transformer, parser]
import middle/[model, visualizer, svg]

const path = r"C:\ProgramData\HDL Works\Ease80Rev4\ease\examples\uart\uart.ews"
let proj = toMiddleMode parseEws path

removeDir "./temp"
createDir "./temp"

for name, el in proj.modules:
  case el.kind:

  of mekModule:
    for a in el.archs:
      case a.kind:
      of makSchema:
        let (w, h) = a.schema.size
        var c = newCanvas(0, 0, w, h)
        c.visualize a.schema
        writeFile fmt"./temp/{name}.svg", $c

      else: discard
  else: discard
