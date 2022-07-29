import std/[xmltree] # , browser

import ../common/[coordination]

import svg, model, logic

const
  moduleInstanceStyle = ShapeStyle(
    fill: initColor(50, 50, 50, 1.0),
  )
  processInstanceStyle = ShapeStyle(
    fill: initColor(100, 80, 200, 1.0),
    corner: 40
  )
  generatorBlockStyle = ShapeStyle(
    fill: initColor(40, 190, 110, 1.0),
  )
  wireStyle = ShapeStyle(
    width: 4,
    border: initColor(30, 30, 30, 1.0),
  )
  portStyle = ShapeStyle(
    fill: initColor(200, 30, 30, 1.0),
  )


func draw*(container: var XmlNode, p: MPort) =
  container.add newCircle(p.position.x, p.position.y, 40, portStyle)

func draw*(container: var XmlNode, net: MNet) =
  for sg in net.segments:
    container.add newLine(sg.a, sg.b, wireStyle)

func draw*(container: var XmlNode, label: MLabel) =
  container.add newTextBox(label.texts, FontStyle(size: 12))

func draw*(container: var XmlNode, ins: MInstance) =
  let
    geo = afterTransform(ins)
    box = toRect geo

  let style = case ins.parent.kind:
    of mekModule: moduleInstanceStyle
    of mekGenerator: generatorBlockStyle
    else: processInstanceStyle

  container.add newRect(box.x, box.y, box.w, box.h, style)

  for p in ins.ports:
    container.add newCircle(p.position.x, p.position.y, 40, portStyle)

template genGroup(canvas): untyped =
  var g = newGroup([])
  canvas.add g
  g

func visualize*(canvas: var XmlNode, schema: MSchematic) =
  # debugEcho schema.ports
  for p in schema.ports:
    draw canvas, p

  for ins in schema.instances:
    draw genGroup canvas, ins

  for n in schema.nets:
    draw genGroup canvas, n

