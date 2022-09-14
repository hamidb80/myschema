import std/[os, tables]
import lexer, parser, model


var basicModules*: ModuleLookUp

for path in walkFiles "./elements/*.sue":
  let 
    (_, name, _) = splitFile path
    module = parseSue lexSue readfile path
  module.isTemp = true
  basicModules[name] = module
