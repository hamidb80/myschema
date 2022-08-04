import std/[macros]

import sue/parser as sp
import ease/parser as ep


static:
  when compileOption("mm", "arc"):
    error "the app is incompatible with 'ARC', use 'refC' or 'ORC' for memory management"


when isMainModule:
  echo "Hi!"