import std/[tables, xmltree, os]
import ../common/[coordination]
import svg, model, logic
import expr

const
  moduleInstanceStyle = ShapeStyle(
    fill: initColor(225, 225, 225, 1.0),
    corner: 10,
    width: 10,
    border: initColor(100, 100, 100, 1.0))

  processInstanceStyle = ShapeStyle(
    fill: initColor(79, 195, 247, 1.0),
    corner: 40)

  generatorBlockStyle = ShapeStyle(
    fill: initColor(40, 190, 110, 1.0), )

  mainPortStyle = ShapeStyle(
    fill: initColor(100, 200, 100, 1.0), )

  insportStyle = ShapeStyle(
    fill: initColor(200, 100, 100, 1.0), )

  tagStyle = ShapeStyle(
    fill: initColor(170, 90, 200, 0.4), )

  wireStyle = ShapeStyle(
    width: 10,
    border: initColor(30, 30, 30, 1.0), )

  darkBlue = initColor(30, 80, 200, 1.0)

  busRipperStyle = ShapeStyle(
    width: 10,
    border: darkBlue,
    fill: darkBlue)

  verySmall = FontStyle(
    family: "tahoma",
    size: 80,
    anchor: taStart)

  small = FontStyle(
    family: "tahoma",
    size: 120,
    anchor: taStart)

  large = FontStyle(
    family: "tahoma",
    size: 200,
    anchor: taMiddle)


func draw(container: var XmlNode, p: MPort, style: ShapeStyle) =
  container.add newCircle(p.position.x, p.position.y, 40, style)

func draw(container: var XmlNode, net: MNet) =
  for sg in net.segments:
    container.add newLine(sg.a, sg.b, wireStyle)

func draw(container: var XmlNode, label: MText) =
  container.add newTextBox(
    label.position.x, label.position.y,
    label.texts, FontStyle(size: 120))

func draw(container: var XmlNode, ins: MInstance) =
  let
    box = toRect ins.geometry
    style =
      case ins.parent.kind:
      of mekModule: moduleInstanceStyle
      of mekGenerator: generatorBlockStyle
      else: processInstanceStyle

    c = center ins.geometry
    tl = topleft ins.geometry

  container.add newRect(box.x, box.y, box.w, box.h, style)
  container.add newTextBox(tl.x, tl.y, @[ins.name], small)
  container.add newTextBox(c.x, c.y, @[ins.parent.name], large)

  for p in ins.ports:
    container.draw p, insportStyle

func draw(container: var XmlNode, bp: MBusRipper) =
  container.add newTextBox(bp.position.x, bp.position.y, @[dump bp.source.ports[0].parent.id], verySmall)
  container.add newCircle(bp.position.x, bp.position.y, 20, busRipperStyle)
  
  container.add newTextBox(bp.connection.x, bp.connection.y, @[dump bp.select], verySmall)
  container.add newCircle(bp.connection.x, bp.connection.y, 10, busRipperStyle)

  container.add newLine(bp.position, bp.connection, busRipperStyle)

template genGroup(canvas): untyped =
  var g = newGroup([])
  canvas.add g
  g

func visualize(canvas: var XmlNode, schema: MSchematic) =
  for n in schema.nets:
    case n.kind:
    of mnkWire:
      draw genGroup canvas, n
    of mnkTag:
      var c = genGroup canvas
      for p in n.ports:
        let (x, y) = p.position
        c.add newRect(x-50, y-50, 100, 100, tagStyle)

  for bp in schema.busRippers:
    canvas.draw bp

  for p in schema.ports:
    draw canvas, p, mainPortStyle

  for ins in schema.instances:
    draw genGroup canvas, ins

  for lbl in schema.texts:
    canvas.draw lbl

proc toSVG*(proj: MProject, dest: string) =
  for name, el in proj.modules:
    case el.kind:
    of mekModule:
      let a = el.arch

      case el.arch.kind:
      of makSchema:
        let (w, h) = a.schema.size
        var c = newCanvas(-400, -400, w, h)
        c.visualize a.schema
        writeFile dest / name & ".svg", $c

      else: discard
    else: discard
