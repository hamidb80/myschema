import std/[xmltree] # , browser

import ../common/[coordination]

import svg, model, logic

const
  moduleInstanceStyle = ShapeStyle(
    fill: initColor(225, 225, 225, 1.0),
    corner: 10,
    width: 10,
    border: initColor(100, 100, 100, 1.0)
  )
  processInstanceStyle = ShapeStyle(
    fill: initColor(79, 195, 247, 1.0),
    corner: 40
  )
  generatorBlockStyle = ShapeStyle(
    fill: initColor(40, 190, 110, 1.0),
  )
  wireStyle = ShapeStyle(
    width: 10,
    border: initColor(30, 30, 30, 1.0),
  )
  mainPortStyle = ShapeStyle(
    fill: initColor(100, 200, 100, 1.0),
  )
  insportStyle = ShapeStyle(
    fill: initColor(200, 100, 100, 1.0),
  )
  tagStyle = ShapeStyle(
    fill: initColor(170, 90, 200, 0.4),
  )


func draw*(container: var XmlNode, p: MPort, style: ShapeStyle) =
  container.add newCircle(p.position.x, p.position.y, 40, style)

func draw*(container: var XmlNode, net: MNet) =
  for sg in net.segments:
    container.add newLine(sg.a, sg.b, wireStyle)

func draw*(container: var XmlNode, label: MLabel) =
  container.add newTextBox(
    label.position.x, label.position.y,
    label.texts, FontStyle(size: 120))

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
    container.draw p, insportStyle

template genGroup(canvas): untyped =
  var g = newGroup([])
  canvas.add g
  g

func visualize*(canvas: var XmlNode, schema: MSchematic) =
  for lbl in schema.lables:
    canvas.draw lbl

  for n in schema.nets:
    case n.kind:
    of mnkWire:
      draw genGroup canvas, n
    of mnkTag:
      var c = genGroup canvas
      for p in n.ports:
        let (x, y) = p.position
        c.add newRect(x-50, y-50, 100, 100, tagStyle)

  for p in schema.ports:
    draw canvas, p, mainPortStyle

  for ins in schema.instances:
    draw genGroup canvas, ins
