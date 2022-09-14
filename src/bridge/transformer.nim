import std/[tables, strutils, options, macros]
import ../common/[coordination, domain, errors, graph]
import ../ease/model as em, ../sue/model as sm
import ../ease/logic as el, ../sue/logic as sl

# template param(n, d): untyped =
#   Parameter(name: n, defaultValue: some d)

func toLine(geo: Geometry): sm.Line =
  sm.Line(
    kind: sm.straight,
    points: geo.points(closed = true))

func toSue(portMode: em.PortMode): sm.PortDir =
  case portMode:
  of pmInput: pdInput
  of pmOutput: pdOutput
  of pmInout, pmBuffer: pdInout
  of pmVirtual: err "invalid port mode"

template flipCase(f: set[Flip], bxy, bx, by, b0: untyped): untyped =
  if f == {X, Y}: bxy
  elif f == {X}: bx
  elif f == {Y}: by
  else: b0

func toSue(ro: Rotation, fs: set[Flip]): Orient =
  case ro:
  of r0: flipCase(fs, RXY, RX, RY, R0)
  of r90: flipCase(fs, R270, R90X, R90Y, R90)
  of r180: flipCase(fs, R0, RY, RX, RXY)
  of r270: flipCase(fs, R90, R90Y, R90X, R270)

func head(b: BusRipper): Point =
  center b.geometry

func tail(b: BusRipper): Point =
  case b.side:
  of brsTopLeft: topLeft b.geometry
  of brsTopRight: topRight b.geometry
  of brsBottomRight: bottomRight b.geometry
  of brsBottomLeft: bottomLeft b.geometry

func toWire(b: BusRipper): Wire =
  b.head .. b.tail


func toSue*(entity: em.Entity, modules: ModuleLookup): sm.Module =
  result = sm.newModule()
  result.icon.lines.add toLine entity.geometry

  ## TODO add icon labels
  ## TODO add icon properties

  for p in entity.ports:
    result.icon.ports.add sm.Port(
      kind: sm.pkIconTerm,
      dir: toSue p.mode,
      name: $p.identifier,
      relativeLocation: p.geometry.center)

  for a in entity.archs:
    case a.kind:
    of amBlockDiagram:
      let schema = a.body.schematic

      for c in schema.components:
        let
          geo = c.geometry
          pin = topleft geo
          r = c.rotation
          dv = pin - topleft(rotate(geo, pin, -r))

        result.schema.instances.add Instance(
          kind: ikCustom,
          name: c.hdlIdent.name,
          module: sm.Module(kind: mkRef, name: $c.parent.obid),
          location: dv - topleft(geo),
          orient: toSue(c.rotation, c.flips))

      for sourceNet in schema.nets:
        for part in sourceNet.parts:
          if part.kind == pkWire:
            for br in part.busRippers:
              let
                nameNet = modules["name_net"]
                conn = toWire br
                srcIdent =
                  sourceNet.parts[1]
                  .ports[0]
                  .parent.identifier

              template makeNet(id, pos): untyped =
                Instance(
                  kind: ikNameNet,
                  name: id,
                  module: nameNet,
                  location: pos)

              result.schema.instances.add [
                makeNet($srcIdent, conn.a),
                makeNet($br.identifier, conn.b)]

              result.schema.wireNets.incl conn

      # TODO process, generator block

    of amTableDiagram, amStateDiagram, amExternalHDLFIle, amHDLFile:
      err "is not supported yet"

proc toSue*(proj: em.Project, basicModules: sm.ModuleLookUp): sm.Project =
  ## fonverts a EWS project to SUE project
  result = sm.Project(modules: basicModules)

  for d in proj.designs:
    for obid, e in d.entities:
      # var
      #   myParams = @[
      #     param("name", "{}"),
      #     param("origin", "{0 0}"),
      #     param("orient", "R0")]

      result.modules[$obid] = toSue(e, basicModules)

when false:
  func buildIcon(name: string, ico: MIcon, params: seq[Parameter]): Icon =
    defaultLabel = Label(
      content: name,
      location: ico.size.toGeometry.center,
      anchor: c,
      size: fzLarge)

    Icon(
      properties: params.map(toProperty),
      labels: @[defaultLabel] & myPorts.map(toLabel))
