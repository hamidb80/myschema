import std/[os, strutils, macros]
import errors


proc projectPath*: string =
  var path = getProjectPath()

  for _ in 1 .. 10:
    for (_, p) in walkDir path:
      if p.endsWith ".nimble":
        return path

    path = path / "../"

  err "no project found"
