import std/[xmltree] # , browser

import svg, model, logic


func drawNet*(canvas: var XmlNode, ngn: NetGraphNode) =
  for sg in toSegments ngn:
    canvas.add newLine(sg.a, sg.b)

