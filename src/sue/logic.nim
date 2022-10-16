import std/[sequtils, strutils, sets, tables]

import ../common/[coordination, graph, errors, seqtable, domain, rand,
    collections, minitable]

import model

# import print

func rotation*(orient: Orient): Rotation =
  case orient:
  of R0, RX, RY: r0
  of R90, R90X, R90Y: r90
  of RXY: r180
  of R270: r270

func flips*(orient: Orient): set[Axis] =
  case orient:
  of R0, R90, RXY, R270: {}
  of R90X, RX: {X}
  of R90Y, RY: {Y}

func toOrient*(vd: VectorDirection): Orient =
  case vd:
  of vdEast: R0
  of vdSouth: R90
  of vdWest: RXY
  of vdNorth: R270
  of vdDiagonal: err "orient for diagonal vectors is not defined"

func tag*(m: Module): ModuleTag =
  case m.name:
  of "input", "output", "inout": mtPort
  of "name_net", "name_net_s", "name_net_sw", "name_suggested_name": mtNameNet
  else: mtCustom

func normalizeModuleName(name: string): string =
  case name:
  of "name_net", "name_net_s", "name_net_sw", "name_suggested_name": "name_net"
  else: name

func instantiate(o: Port, i: Instance): Port =
  Port(kind: pkInstance, parent: i, origin: o)

func `not`(pd: PortDir): PortDir =
  case pd
  of pdInput: pdOutput
  of pdOutput: pdInput
  of pdInout: pdInout

func dropIndexes(s: string): string =
  ## removes the bracket part from `s`
  ## "id[a:b]" => "id"
  ## "id[a]" => "id"
  ## "id" => "id"

  let i = s.find '['
  if i == -1: s
  else: s[0..<i]

iterator sepIds*(s: string): PortID =
  for w in s.split(','):
    let id = dropIndexes w
    if id.len != 0:
      yield PortID id

func `--`(s1, s2: string): string =
  s1 & '/' & s2

func ids*(port: Port): seq[PortID] =
  case port.parent.module.tag:
  of mtPort, mtNameNet: toseq sepids(port.parent.name)
  of mtCustom:
    let
      n1 = dropIndexes port.parent.name
      n2 = dropIndexes port.origin.name

    @[PortID n1--n2]


func genTransformer(geo: Geometry, pin: Point, o: Orient): Transformer =
  let
    r = o.rotation
    f = o.flips

  return func(p: Point): Point =
    rotate(p, pin, r)
    .flip(pin, f)

func location*(p: Port): Point

iterator points*(icon: Icon): Point =
  for p in icon.ports:
    yield p.location

  for l in icon.lines:
    if l.kind == straight:
      for p in l.points:
        yield p

func geometry*(icon: Icon): Geometry =
  area toseq points icon

func size*(i: Icon): Size =
  i.geometry.size

func location*(p: Port): Point =
  case p.kind:
  of pkIconTerm: p.relativeLocation
  of pkInstance:
    let
      ins = p.parent
      t = genTransformer(
        ins.module.icon.geometry + ins.location,
        ins.location,
        ins.orient)

    t(p.origin.location + ins.location)

func geometry*(ins: Instance): Geometry =
  let
    pin = ins.location
    geo =
      ins.module.icon.geometry
      .rotate(P0, rotation ins.orient)
      .flip(P0, flips ins.orient)

  geo + pin

iterator wires*(wiredNodes: Graph[Point]): Wire =
  var my: Graph[Point]

  for n1, conns in wiredNodes:
    for n2 in conns:
      if not isConnected(my, n1, n2):
        let w = n1..n2
        my.incl w
        yield w

iterator ports*(schema: Schematic): Port =
  for ports in values schema.portsPlot:
    for p in ports:
      yield p


func `*`(i: range[-1..1], vd: VectorDirection): VectorDirection =
  case i:
  of +1: vd
  of -1: -vd
  else: err "coefficient is not in {-1, +1}"

template `||`(s1, s2): untyped =
  if s1.len == 0: s2
  else: s1

proc addNameNet*(loc: Point, schema: Schematic,
    nameNetModule: Module,
    name: string = ""): Instance =

  result = Instance(
    name: name || ("net_" & randomIdent()),
    module: nameNetModule,
    location: loc)

  schema.instances.add result

  if loc in schema.wiredNodes:
    discard
  else:
    discard

proc addNameNet*(p: Port, schema: Schematic,
    nameNetModule: Module,
    name: string = ""): Instance =

  result = addNameNet(p.location, schema, nameNetModule, name)

func `{}`*(sp: seq[Port], dir: PortDir): Port =
  for p in sp:
    if p.origin.dir == dir:
      return p

  err "not found"

const notFound = -1
func netKind*(name: string): NetWireKind =
  let
    bClose = name.rfind "]"
    bSlice = name.find ":"

  if bClose == notFound: nwkSingle
  elif bSlice == notFound: nwkSelect
  else: nwkBus

func busRange*(name: string): string = 
  for ch in name:
    case ch:
    of '['
    of ']'
    of ':'

func buildNetList(schema: Schematic): Table[Point, string] =
  for p in schema.ports:
    let t = p.parent.module.tag

    if p.origin.dir == pdInput and t == mtPort:
      discard

    elif p.origin.dir == pdOutput and t != mtPort:
      discard


proc addBuffer(p: Port, schema: Schematic, bufferModule: Module): Instance =
  ## 1. find location
  ## 2. find connected wires
  ## 3. detect direction of the port
  ## 4. place buffer before the port
  ## 5. remove intersected wires

  # FIXME buffer array ... like [2:0] according to the netlist

  let
    loc = p.location
    nextNodeLoc = schema.wiredNodes[loc].pick

    dir_coeff =
      case p.origin.dir:
      of pdInput: +1
      of pdOutput: -1
      else: err "inout is not valid"

    kind_coeff =
      case p.parent.module.tag:
      of mtPort: +1
      else: -1

    coeff = dir_coeff * kind_coeff
    dir = coeff * (dirOf loc .. nextNodeLoc)
    orient = toOrient dir

    buffer = Instance(
      name: "buffer_" & randomIdent(),
      module: bufferModule,
      orient: orient)


  for ip in bufferModule.icon.ports:
    buffer.ports.add instantiate(ip, buffer)

  let
    which =
      case coeff:
      of -1: pdOutput
      of +1: pdInput
      else: pdInout

    pin = buffer.ports{which}.location
    move = pin - loc

  buffer.location = buffer.location - move

  schema.wiredNodes.excl loc, nextNodeLoc
  schema.wiredNodes.incl buffer.ports{not which}.location, nextNodeLoc
  schema.instances.add buffer

  buffer

func problematic(ports: seq[Port]): seq[Port] =
  ## returns input ports if there were both input ports and output ports
  var groups: array[PortDir, seq[Port]]

  for p in ports:
    groups[p.origin.dir].add p

  if groups[pdInput].len != 0 and groups[pdOutput].len != 0:
    groups[pdInput]
  else:
    @[]

func toPorts(schema: Schematic, pids: seq[PortID]): seq[Port] =
  for pid in pids:
    result.add schema.portsTable[pid]

proc fixErrors(schema: Schematic, modules: ModuleLookup) =
  let
    bufferModule = modules["buffer0"]
    nameNetModule = modules["name_net"]

  var instancesList = schema.instances # contains a copy

  for ins in instancesList:
    var tt: MiniTable[string, string]

    for p in ins.ports:
      if p.origin.hasSiblings:
        let
          b = addBuffer(p, schema, bufferModule)
          n = addNameNet(b.ports{not p.origin.dir}, schema, nameNetModule)

        tt[p.origin.name] = n.name
        p.origin.dir = pdInout

      elif p.origin.isGhost:
        let b = addBuffer(p, schema, bufferModule)
        discard addNameNet(b.ports{not p.origin.dir}, schema, nameNetModule, tt[p.origin.name])

  for pids in parts schema.connections:
    let connectedSchemaPorts =
      toPorts(schema, pids)
      .filterit(it.parent.module.tag == mtPort)

    for p in problematic connectedSchemaPorts:
      discard addBuffer(p, schema, bufferModule)

proc fixErrors*(project: Project) =
  for _, m in mpairs project.modules:
    if not m.isTemp:
      fixErrors m.schema, project.modules


func extractConnections(sch: Schematic): Graph[PortId] =
  for loc, ports in sch.portsPlot:
    var acc: seq[Port]

    for l in walk(sch.wiredNodes, loc):
      if l in sch.portsPlot:
        for cp in sch.portsPlot[l]:
          acc.add cp

    for p1 in acc:
      for pid1 in ids p1:
        for p2 in ports:
          for pid2 in ids p2:
            result.incl pid1, pid2

proc resolve*(proj: Project) =
  ## add meta data for instances, resolve modules
  for _, module in mpairs proj.modules:
    reset module.schema.portsPlot
    reset module.schema.portsTable

    for ins in mitems module.schema.instances:
      let mref = proj.modules[normalizeModuleName ins.module.name]
      ins.module = mref
      reset ins.ports

      if ins.module.tag != mtNameNet and (ins.name.len == 0 or ins.name[0] ==
          '['): # an array, like [2:0]
        ins.name = randomIdent(10) & ins.name

      for p in mref.icon.ports:
        let
          insPort = instantiate(p, ins)
          loc = insPort.location

        ins.ports.add insPort
        module.schema.portsPlot.add loc, insPort

        for pid in insPort.ids:
          module.schema.portsTable.add pid, insPort

    module.schema.netList = buildNetList module.schema
    module.schema.connections = extractConnections module.schema
