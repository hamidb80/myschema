import std/[os]

import ease/[transformer, parser]
import middle/[visualizer]
import sue/[transformer, encoder]


const path =
  # r"C:\ProgramData\HDL Works\Ease80Rev4\ease\examples\uart\uart.ews"
  # r"C:\ProgramData\HDL Works\Ease80Rev4\ease\examples\i2c\i2c.ews"
  # r"C:\ProgramData\HDL Works\Ease80Rev4\ease\examples\mc8051\mc8051.ews"
  # r"C:\ProgramData\HDL Works\Ease80Rev4\ease\examples\pump\pump.ews"
  # r"C:\ProgramData\HDL Works\Ease80Rev4\ease\examples\roundrobin\roundrobin.ews"
  # r"C:\ProgramData\HDL Works\Ease80Rev4\ease\examples\system09\system09.ews"
  # r"C:\ProgramData\HDL Works\Ease80Rev4\ease\examples\microprocessor\microprocessor.ews"
  # r"C:\ProgramData\HDL Works\Ease80Rev4\ease\examples\usb_hs\usbhostslave.ews"
  # r"C:\ProgramData\HDL Works\Ease80Rev4\ease\examples\fsm_verilog\master_slave.ews"
  r"C:\ProgramData\HDL Works\Ease80Rev4\ease\examples\amba\amba.ews"
  # r"C:\ProgramData\HDL Works\Ease80Rev4\ease\examples\amba\rotate_test.ews" # TODO add visual testing like this

proc createDirs(dirs: varargs[string]) =
  for dir in dirs:
    createDir dir

when isMainModule:
  removeDir "./temp"
  createDirs "./temp", "./temp/sue", "./temp/svg"

  let proj = toMiddle parseEws path
  proj.toSVG "./temp/svg/"
  proj.toSue.writeProject "./temp/sue/"
