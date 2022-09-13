import std/[tables, sequtils, strutils, options, sugar, macros]
import ../common/[coordination, collections, minitable, domain]
import model, logic

# ------------------------------- middle model -> sue model

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
  let
    myPorts = ico.ports.map(iconPort)
    defaultLabel = Label(
      content: name,
      location: ico.size.toGeometry.center,
      anchor: c,
      size: fzLarge)

  Icon(
    ports: myPorts,
    properties: params.map(toProperty),
    size: ico.size,
    labels: @[defaultLabel] & myPorts.map(toLabel),
    lines: @[toLine toGeometry ico.size])

func addIconPorts(s: var SSchematic, ico: Icon, lookup: ModuleLookUp)
func findDriectInputs(br: MBusRipper): seq[tuple[port: MPort, net: MNet]]

proc toSue(sch: MSchematic, lookup: ModuleLookUp): SSchematic =

  var seenPorts: seq[MPort]
  for br in sch.busRippers:
    let anotherId = br.source.ports.search((p) => not p.isSliced).parent.id

    block convert_busRipper_to_2_nameNets:
      result.instances.add [
        Instance(
          name: dump(anotherId, true),
          parent: lookup["name_net"],
          location: br.position),

        Instance(
          name: dump(br.select, true),
          parent: lookup["name_net"],
          location: br.connection)]
      
func inoutModule(n: string): Module =
  Module(
    name: n,
    kind: mkCtx,
    isTemporary: true,
    icon: Icon(
      ports: @[
        Port(
          kind: pdInout,
          location: (0, 0))],
      size: (1, 1)))

proc toSue*(proj: mm.MProject): sm.Project =
  result = new Project
  result.modules = toTable {
    "input": inoutModule("input"),
    "inout": inoutModule("inout"),
    "output": inoutModule("output"),
    "name_net": inoutModule("name_net"),
    "buffer0": inoutModule("buffer0")}

  for name, mmdl in proj.modules:
    var
      myParams = @[
        Parameter(name: "name", defaultValue: some "{}"),
        Parameter(name: "origin", defaultValue: some "{0 0}"),
        Parameter(name: "orient", defaultValue: some "R0")]

    for p in values mmdl.parameters:
      myParams.add Parameter(
        name: p.name,
        defaultValue: map(p.defaultValue, toSue))

    result.modules[name] = Module(
      kind: mkCtx,
      name: name,
      params: myParams,
      icon: buildIcon(name, mmdl.icon, myParams))

  for name, mmdl in mpairs proj.modules:
    var m = result.modules[name]
    debugEcho "finalizing module sue: ", name
    m.arch = toSue(mmdl.arch, m.icon, result.modules, m)
