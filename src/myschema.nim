import std/[os]

import ease/[encoder, parser]
import sue/[encoder, parser]
import middle/transformer

static:
  assert compileOption("mm", "arc")

when isMainModule:
  template l(msg): untyped =
    debugEcho msg

  if paramCount() == 2:
    let pathes = paramStr(1) .. paramStr(2)
    l "ews project: ", pathes.a
    l "destination: ", pathes.b
    l "-- PARSING .eas FILES ..."
    let proj = parseEws pathes.a
    l "-- CONVERTING TO .sue ..."
    writeProject proj.toSue, pathes.b
    l "-- DONE!"

  else: echo """
USAGE:
  app.exe <PROJECT.ews::folder> <dest::folder>
"""
