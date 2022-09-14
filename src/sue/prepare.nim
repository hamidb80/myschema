import std/[os, tables]
import lexer, parser, model


var basicModules*: ModuleLookUp

for path in walkFiles "./elements/*.sue":
  let (_, name, _) = splitFile path
  basicModules[name] = parseSue lexSue readfile path
