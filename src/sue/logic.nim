import std/[sequtils, strutils, sets, tables]
import ../common/[coordination, graph, errors, seqtable, domain, rand, collections]
import model

# import print

func rotation*(orient: Orient): Rotation =
  case orient:
  of R0, RX, RY: r0
  of R90, R90X, R90Y: r90
  of RXY: r180
  of R270: r270

func flips*(orient: Orient): set[Flip] =
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

func moduleTag*(name: string): ModuleTag =
  case name:
  of "input", "output", "inout": mtPort
  of "name_net", "name_net_s", "name_net_sw", "name_suggested_name": mtNameNet
  else: mtCustom

func normalizeModuleName(name: string): string =
  case name:
  of "name_net", "name_net_s", "name_net_sw", "name_suggested_name": "name_net"
  else: name


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
      if not connected(my, n1, n2):
        let w = n1..n2
        my.incl w
        yield w

iterator ports*(schema: Schematic): Port =
  for ports in values schema.portsPlot:
    for p in ports:
      yield p


func problematic(ports: seq[Port]): seq[Port] =
  ## returns input ports if there were both input ports and output ports
  var groups: array[PortDir, seq[Port]]

  for p in ports:
    groups[p.origin.dir].add p

  if groups[pdInput].len != 0 and groups[pdOutput].len != 0:
    groups[pdInput]
  else:
    @[]

func `*`(i: range[-1..1], vd: VectorDirection): VectorDirection =
  case i:
  of +1: vd
  of -1: -vd
  else: err "coefficient is not in {-1, +1}"

proc addBuffer(p: Port, schema: Schematic, bufferModule: Module) =
  ## 1. find location
  ## 2. find connected wires
  ## 3. detect direction of the port
  ## 4. place buffer before the port
  ## 5. remove intersected wires
  ##
  ## you need to draw every 2*4 cases to reach this conclusion
  ## when the input is from input element, head of buffer is `loc`
  ## when input is from a custom element, tail of the buffer is `loc`

  let
    loc = p.location
    connectedWiresNodes = toseq schema.wiredNodes[loc]
    nextNodeLoc = connectedWiresNodes[0]
    dir = dirOf loc .. nextNodeLoc
    vdir = toVector dir
    dir_coeff =
      case p.origin.dir:
      of pdInput: +1
      of pdOutput: -1
      else: err "invalid"

    kind_coeff =
      case p.parent.module.tag:
      of mtPort: +1
      else: -1

    coeff = dir_coeff * kind_coeff

    orient = toOrient coeff*dir
    width = bufferModule.icon.geometry.size.w
    loc2 = loc + coeff*vdir*width
    buffIn =
      case p.parent.module.tag:
      of mtPort: loc
      else: loc2

    buffer = Instance(
      name: "buffer_" & randomIdent(),
      module: bufferModule,
      location: buffIn,
      orient: orient)

  schema.wiredNodes.excl loc, nextNodeLoc
  schema.wiredNodes.incl loc2, nextNodeLoc
  schema.instances.add buffer

func toPorts(schema: Schematic, pids: seq[PortID]): seq[Port] =
  for pid in pids:
    result.add schema.portsTable[pid]

proc fixErrors(schema: Schematic, modules: ModuleLookup) =
  ## fixes connection errors via adding `buffer0` element
  let
    bufferModule = modules["buffer0"]
    nameNet = modules["name_net"]

  for pids in parts schema.connections:
    let connectedSchemaPorts =
      toPorts(schema, pids)
      .filterit(it.parent.module.tag == mtPort)

    for p in problematic connectedSchemaPorts:
      addBuffer p, schema, bufferModule

  # var instancesList = schema.instances # contains a copy
  # for ins in instancesList:
  #   for p in ins.ports:
  #     if p.origin.hasSiblings:
  #       addBuffer p, schema, bufferModule
  #       p.origin.dir = pdInout

  #     elif p.origin.isGhost:
  #       # FIXME add the first element changes the wire node position
  #       addBuffer p, schema, nameNet
  #       addBuffer p, schema, bufferModule

proc fixErrors*(project: Project) =
  for _, m in mpairs project.modules:
    if not m.isTemp:
      fixErrors m.schema, project.modules


func instantiate(o: Port, i: Instance): Port =
  Port(kind: pkInstance, parent: i, origin: o)

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
    for ins in mitems module.schema.instances:
      let mref = proj.modules[normalizeModuleName ins.module.name]
      ins.module = mref

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

    module.schema.connections = extractConnections(module.schema)
