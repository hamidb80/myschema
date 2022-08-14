from std/macros import error
import std/[os]

import ease/[transformer as et, parser]
import sue/[transformer as st, encoder]


static:
  when compileOption("mm", "arc"):
    error "the app is incompatible with 'ARC', use 'refC' or 'ORC' for memory management"


when isMainModule:
  if paramCount() == 2: 
    let 
      ews = paramStr(1)
      dest = paramStr(2)

    debugEcho "ews project: ", ews
    debugEcho "destination: ", dest

    debugEcho "-- PARSING .eas FILES ..."
    let proj = toMiddle parseEws ews
    debugEcho "-- CONVERTING TO .sue ..."
    proj.toSue.writeProject dest
    debugEcho "-- DONE!"

    
  else: echo """
USAGE:
  app.exe <PROJECT.ews::folder> <dest::folder>
"""
