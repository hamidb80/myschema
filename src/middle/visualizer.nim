import std/[xmltree, strtabs, strformat] # , browser

import svg, model, logic


func draw*(container: var XmlNode, net: MNet) =
  for sg in net.segments:
    container.add newLine(sg.a, sg.b)

func draw*(container: var XmlNode, ins: MInstance) =
  let
    (w, h) = ins.parent.icon.size
    (x, y) = ins.position

  # TODO rotate and flip manually

  container.add newRect(x, y, x+w, y+h)

  for p in ins.ports:
    container.add newCircle(p.position.x, p.position.y, 4)


template genGroup(canvas): untyped =
  var g = newGroup([])
  canvas.add g
  g

func visualize*(canvas: var XmlNode, schema: MSchematic) =
  for n in schema.nets:
    genGroup(canvas).draw n

  for ins in schema.instances:
    genGroup(canvas).draw ins
