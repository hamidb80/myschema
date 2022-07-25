import std/[xmltree] # , browser

import svg, model, logic


func draw*(container: var XmlNode, ngn: NetGraphNode) =
  for sg in toSegments ngn:
    container.add newLine(sg.a, sg.b)

func visualize*(canvas: var XmlNode, schema: Schema) =
  for n in schema.connections:
    var g = newGroup([])
    canvas.add g
    g.draw n
