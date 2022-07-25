import std/[xmltree, tables, sequtils, options]

import ease/[model, lisp]
import ease/parser {.all.}

import middle/[svg]


var cnv: XmlNode

let e = parseEntityFile (parselisp readFile "./examples/ease/file/ENTITY_FILE.eas")[0]
for a in e.architectures:
  if issome a.schematic:
    let (x, y, w, h) = a.schematic.get.sheetSize
    cnv = newCanvas(x, y, w, h)

    for n in a.schematic.get.nets:
      var g = newGroup([])

      for w in n.wires:
        g.add newLine(w.a, w.b)

      cnv.add g


writeFile "play.svg", $cnv
