import std/[tables, sequtils, strutils, options, sugar, macros]
import ../common/[coordination, collections, domain, errors]
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


func toSue*(entity: em.Entity): sm.Module =
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
        result.instances.add Instance(
          kind: ikCustom,
          name: c.hdlIdent.name,
          module: sm.Module(kind: mkRef, name: $c.parent.obid),
          location: topleft c.geometry,
          orient: _)

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

      result.modules[$obid] = toSue e

  # for name, mmdl in mpairs proj.modules:
  #   var m = result.modules[name]
  #   debugEcho "finalizing module sue: ", name
  #   m.arch = toSue(mmdl.arch, m.icon, result.modules, m)


when false:
  template flipCase(f: set[Flip], bxy, bx, by, b0: untyped): untyped =
    if f == {X, Y}: bxy
    elif f == {X}: bx
    elif f == {Y}: by
    else: b0

  func toSue(tr: Transform): Orient =
    let fs = tr.flips

    case tr.rotation:
    of r0: flipCase(fs, RXY, RX, RY, R0)
    of r90: flipCase(fs, R270, R90X, R90Y, R90)
    of r180: flipCase(fs, R0, RY, RX, RXY)
    of r270: flipCase(fs, R90, R90Y, R90X, R270)

  func buildIcon(name: string, ico: MIcon, params: seq[Parameter]): Icon =
    defaultLabel = Label(
      content: name,
      location: ico.size.toGeometry.center,
      anchor: c,
      size: fzLarge)

    Icon(
      properties: params.map(toProperty),
      labels: @[defaultLabel] & myPorts.map(toLabel))

  proc toSue(sch: MSchematic, lookup: ModuleLookUp): SSchematic =

    for br in sch.busRippers:
      let anotherId = br.source.ports.search((p) => not p.isSliced).parent.id

      result.instances.add [
        Instance(
          name: dump(anotherId, true),
          parent: lookup["name_net"],
          location: br.position),

        Instance(
          name: dump(br.select, true),
          parent: lookup["name_net"],
          location: br.connection)]
