import std/[macros]

static:
  when compileOption("mm", "arc"):
    error "the app is incompatible with 'ARC', use 'refC' or 'ORC' for memory management"

import sue/parser as sue_parser
import ease/parser as eas_parser
