import std/[xmltree] # , browser

import svg, model, logic


func draw*(canvas: var XmlNode, ngn: NetGraphNode) =
  for sg in toSegments ngn:
    canvas.add newLine(sg.a, sg.b)

func visualize*(canvas: var XmlNode, schema: Schema) =
  for n in schema.connections:
    canvas.draw n
