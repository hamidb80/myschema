import std/[xmltree, tables, strformat, os]

import ease/[model as m, transformer, parser]
import middle/[model, visualizer, svg]

const path = 
  #r"C:\ProgramData\HDL Works\Ease80Rev4\ease\examples\uart\uart.ews"
  # r"C:\ProgramData\HDL Works\Ease80Rev4\ease\examples\i2c\i2c.ews"
  # r"C:\ProgramData\HDL Works\Ease80Rev4\ease\examples\mc8051\mc8051.ews"
  # r"C:\ProgramData\HDL Works\Ease80Rev4\ease\examples\pump\pump.ews"
  # r"C:\ProgramData\HDL Works\Ease80Rev4\ease\examples\roundrobin\roundrobin.ews"
  # r"C:\ProgramData\HDL Works\Ease80Rev4\ease\examples\system09\system09.ews"
  # r"C:\ProgramData\HDL Works\Ease80Rev4\ease\examples\microprocessor\microprocessor.ews"
  # r"C:\ProgramData\HDL Works\Ease80Rev4\ease\examples\usb_hs\usbhostslave.ews"
  # r"C:\ProgramData\HDL Works\Ease80Rev4\ease\examples\amba\amba.ews"
  r"C:\ProgramData\HDL Works\Ease80Rev4\ease\examples\amba\rotate_test.ews" # TODO add visual testing like this

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
        var c = newCanvas(-400, -400, w, h)
        c.visualize a.schema
        writeFile fmt"./temp/{name}.svg", $c

      else: discard
  else: discard
