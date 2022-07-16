import ../src/sue/lexer

iterator expressions(sf: SueFile): SueExpression =
  for expr in sf.icon:
    yield expr

  for expr in sf.schematic:
    yield expr

template searchSueFiles*(dir, beforeLex, afterLex, exprCode): untyped =
  for path {.inject.} in walkDirRec dir:
    if path.endsWith(".sue") and ("SCCS" notin path):
      beforeLex
      let s {.inject.} = lexSue readfile path
      afterLex

      for expr {.inject.} in expressions s:
        exprCode