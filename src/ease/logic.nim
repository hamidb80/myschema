import std/[options, tables, strutils, strformat]

import ../common/[coordination, errors, minitable]
import model

# basics ---

func toRotation*(s: Side): Rotation =
  case s:
  of sTopToBottom: r0
  of sRightToLeft: r90
  of sBottomToTop: r180
  of sLeftToRight: r270

func rotation*[T: Thing](c: T): Rotation =
  toRotation c.side

func position*(p: Port): Point =
  center p.geometry

func flips*[T: Thing](element: T): set[Axis] =
  # vertical = 1
  # horizontal = 2
  # both = 3

  let f = element.properties.getOrDefault("Flip", "0").parseInt
  case f:
  of 0: {}
  of 1: {Y}
  of 2: {X}
  of 3: {X, Y}
  else: err fmt"invalid Flip code: '{f}'"

func identifier*[T](p: T): Identifier =
  let cn = p.hdlident.attributes.constraint

  if isSome cn:
    case cn.get.kind:
    of ckIndex:
      result = Identifier(kind: ikIndex, index: cn.get.index)

    of ckRange:
      result = Identifier(kind: ikRange,
        indexes: cn.get.`range`.indexes,
        direction: cn.get.`range`.direction)

  else:
    result = Identifier(kind: ikSingle)

  result.name = p.hdlident.name

func mode*(p: Port): PortMode =
  PortMode p.hdlident.attributes.mode.get

func getIfCond*(gb: GenerateBlock): string =
  gb.properties["IF_CONDITION"]

func getForInfo*(gb: GenerateBlock): tuple[ident: string, `range`: Range] =
  (gb.properties["FOR_LOOP_VAR"], gb.constraint.get.`range`)

func translationAfter*(geo: Geometry, ro: Rotation): Vector =
  ## returns a vector that if added to the result,
  ## it will keep the whole shape at the original top left
  geo.placeAt(P0).rotate(P0, ro).topleft

func getIconTransformer*(iconGeo: Geometry,
    rotated: Rotation): Transformer =

  let
    pin = topLeft iconGeo
    translate = -translationAfter(iconGeo, -rotated)

  proc transformer(p: Point): Point =
    let
      t1 = p.rotate(pin, -rotated)
      t2 = t1 + translate - pin

    t2

  transformer

func getNetSlice*(p: Port): Option[NetSlice] =
  # FIXME "(8*i)+7 downto i*8" from `mc8051`

  let ns = p.properties.get("NET_SLICE")

  if ns.isSome:
    result = some NetSlice(kind: nskIndex, index: ns.get)


iterator allPorts(s: Schematic): Port =
  for p in s.ports:
    yield p

  for pr in s.processes:
    for p in pr.ports:
      yield p

  for c in s.components:
    for p in c.ports:
      yield p

func resolve*(proj: Project) =
  ## links obids to refrencers

  var
    portMap: Table[Obid, Port]
    netMap: Table[Obid, Net]

  template walkEntities(body): untyped {.dirty.} =
    for d in mitems proj.designs:
      for _, e in mpairs d.entities:
        body

  template withSchema(e, code): untyped {.dirty.} =
    for a in e.archs:
      if a.body.kind == bkSchematic:
        let schema = a.body.schematic
        code

  walkEntities:
    for p in e.ports:
      portMap[p.obid] = p

    withSchema e:
      for p in allPorts schema:
        portMap[p.obid] = p

      for n in schema.nets:
        netMap[n.obid] = n

  walkEntities:
    withSchema e:
      for p in schema.ports:
        p.parent = portMap[p.parent.obid]

      for c in schema.components:
        for p in c.ports:
          p.parent = portMap[p.parent.obid]

      for n in schema.nets:
        for part in n.parts:
          if part.kind == pkWire:
            for b in part.busRippers:
              b.destNet = netMap[b.destNet.obid]

          for p in mitems part.ports:
            p = portMap[p.obid]
