import std/[tables, strutils, options, macros]
import ../common/[coordination, domain, errors, graph, rand]
import ../ease/model as em, ../sue/model as sm
import ../ease/logic as el, ../sue/logic as sl
import ../sue/parser as sp


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


func `[]`(proj: em.Project, obid: em.Obid): Entity =
  for l in proj.designs:
    if obid in l.entities:
      return l.entities[obid]

  err "cannot find"


proc makeModule(prc: em.Process): sm.Module =
  result = sm.newModule("proc_" & randomIdent(6))
  let pin = topLeft prc.geometry

  for p in prc.ports:
    result.icon.ports.add sm.Port(
      kind: sm.pkIconTerm,
      dir: toSue p.mode,
      name: p.identifier.format) # FIXME input and output cannot have the same name

  result.icon.lines.add toLine(prc.geometry - pin)


proc toSue*(
  entity: em.Entity,
  proj: em.Project,
  modules: var ModuleLookup
  ): sm.Module =

  result = sm.newModule(entity.identifier.name)
  result.icon.lines.add toLine entity.geometry

  # result.icon.labels.add sm.Label(
  #   content: entity.name,
  #   location: topleft entity.geometry,
  #   anchor: c,
  #   fnsize: fzLarge)

  # TODO add arguments and params
  # TODO generator block

  for p in entity.ports:
    result.icon.ports.add sm.Port(
      kind: sm.pkIconTerm,
      dir: toSue p.mode,
      name: format(p.identifier),
      relativeLocation: p.geometry.center)

    result.icon.labels.add sm.Label(
      content: p.identifier.format,
      location: p.geometry.center,
      anchor: s,
      fnsize: fzStandard)

  let nameNet = modules["name_net"]
  for a in entity.archs:
    case a.kind:
    of amBlockDiagram:
      let schema = a.body.schematic

      template drawDiffWire(p: em.Port): untyped =
        result.schema.wiredNodes.incl:
          p.geometry.center .. p.connection.position

      for c in schema.components:
        let
          geo = c.geometry
          pin = topleft geo
          r = c.rotation
          dv = pin - topleft(rotate(geo, pin, -r))

        result.schema.instances.add Instance(
          kind: ikCustom,
          name: c.hdlIdent.name,
          location: dv + topleft(geo),
          orient: toSue(c.rotation, c.flips),
          module: refModule(proj[c.parent.obid].identifier.name))

        for p in c.ports:
          drawDiffWire p

      ## since `process`es and `generate block`s are not resusable,
      ## we can simply *ignore* the rotation and flip properties

      for pr in schema.processes:
        let newModule = makeModule pr
        modules[newModule.name] = newModule
        result.schema.instances.add sm.Instance(
          kind: sm.ikCustom,
          name: randomIdent(10),
          module: newModule,
          location: topleft pr.geometry)

        for p in pr.ports:
          drawDiffWire p

      for sourceNet in schema.nets:
        for part in sourceNet.parts:
          if part.kind == pkWire:
            for w in part.wires:
              result.schema.wiredNodes.incl w

            for br in part.busRippers:
              let
                conn = toWire br
                srcIdent =
                  sourceNet
                  .parts[1]
                  .ports[0]
                  .parent.identifier

              template makeNet(id, pos): untyped =
                Instance(
                  kind: ikNameNet,
                  name: id,
                  module: nameNet,
                  location: pos)

              result.schema.instances.add [
                makeNet(format(srcIdent, false), conn.a),
                makeNet(format(br.identifier, false), conn.b)]

              result.schema.wiredNodes.incl conn

      for p in schema.ports:
        let loc = center p.geometry

        result.schema.instances.add sm.Instance(
          kind: ikPort,
          name: format p.identifier,
          module: modules[$(toSue p.mode)],
          location: loc,
          # TODO orient*: Orient
        )

        result.schema.wiredNodes.incl p.connection.position .. loc


    of amTableDiagram, amStateDiagram, amExternalHDLFIle, amHDLFile:
      discard # FIXME "is not supported yet"

proc toSue*(proj: em.Project, basicModules: sm.ModuleLookUp): sm.Project =
  ## fonverts a EWS project to SUE project
  result = sm.Project(modules: basicModules)

  for d in proj.designs:
    for obid, e in d.entities:
      let m = toSue(e, proj, result.modules)
      result.modules[m.name] = m

proc toSue*(proj: em.Project): sm.Project =
  result = toSue(proj, sp.basicModules)
  resolve result
