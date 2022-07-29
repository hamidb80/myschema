import std/[xmltree] # , browser

import ../common/[coordination]

import svg, model, logic


func draw*(container: var XmlNode, net: MNet) =
  for sg in net.segments:
    container.add newLine(sg.a, sg.b)

func draw*(container: var XmlNode, ins: MInstance) =
  let
    geo = afterTransform(ins)
    box = toRect geo

  container.add newRect(box.x, box.y, box.w, box.h)

  for p in ins.ports:
    container.add newCircle(p.position.x, p.position.y, 40)

template genGroup(canvas): untyped =
  var g = newGroup([])
  canvas.add g
  g

func visualize*(canvas: var XmlNode, schema: MSchematic) =
  for ins in schema.instances:
    draw genGroup canvas, ins

  for n in schema.nets:
    draw genGroup canvas, n

