import std/[os, strutils, sets]
import ../../src/sue/[lexer]
import ./utils
import print

# ----------------------------------

const dir = r"C:\Users\HamidB80\Desktop\set4"

var
  availableModules: HashSet[string]
  usedModeles: HashSet[string]

searchSueFiles dir:
  echo ">> ", path
do:
  availableModules.incl s.name
do:
  if expr.command == scMake:
    usedModeles.incl expr.args[0].strval

print usedModeles - availableModules
