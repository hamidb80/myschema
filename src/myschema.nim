import std/[os]

import ease/encoder as ee, sue/encoder as se
import ease/parser as ep, sue/parser as sp
import middle/transformer

static:
  assert not compileOption("mm", "arc"), "a memory management that supports cycles should be used"

when isMainModule:
  template l(msg): untyped =
    debugEcho msg

  if paramCount() == 2:
    let pathes = paramStr(1) .. paramStr(2)
    l "ews project: " & pathes.a
    l "destination: " & pathes.b
    l "-- PARSING .eas FILES ..."
    let proj = parseEws pathes.a
    l "-- CONVERTING TO .sue ..."
    writeProject proj.toSue, pathes.b
    l "-- DONE!"

  else: echo """
USAGE:
  app.exe <PROJECT.ews::folder> <dest::folder>
"""
