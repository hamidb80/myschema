import std/[sequtils, strutils, sets, tables]
import ../common/[coordination, graph, errors, seqtable, domain, rand]
import model


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

func instancekind*(name: string): InstanceKind =
  case name:
  of "input", "output", "inout": ikPort
  of "name_net", "name_net_s", "name_net_sw", "name_suggested_name": ikNameNet
  else: ikCustom


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
  case port.parent.kind:
  of ikPort, ikNameNet: toseq sepids(port.parent.name)
  of ikCustom:
    let
      n1 = dropIndexes port.parent.name
      n2 = dropIndexes port.origin.name

    @[PortID n1--n2]


func genTransformer(geo: Geometry, pin: Point, o: Orient): Transformer =
  let
    r = o.rotation
    f = o.flips
    rotatedGeo = rotate(geo, pin, r)
    vec = pin - topleft geo
    finalGeo = rotatedGeo.placeAt pin
    c = center finalGeo

  return func(p: Point): Point =
    (rotate(p, pin, r) + vec).flip(c, f)

func toOrient*(vd: VectorDirection): Orient =
  case vd:
  of vdEast: R0
  of vdSouth: R90
  of vdWest: RXY
  of vdNorth: R270
  of vdDiagonal: err "orient for diagonal vectors is not defined"

func location*(p: Port): Point
func geometry*(icon: Icon): Geometry =
  var acc: seq[Point]

  for p in icon.ports:
    acc.add p.location

  for l in icon.lines:
    if l.kind == straight:
      for p in l.points:
        acc.add p

  area acc

func location*(p: Port): Point =
  case p.kind:
  of pkIconTerm: p.relativeLocation
  of pkInstance:
    let
      ins = p.parent
      t = genTransformer(
        ins.module.icon.geometry,
        ins.location,
        ins.orient)

    t(p.origin.location + ins.location)


iterator wires*(schema: Schematic): Wire =
  var my: Graph[Point]

  for n1, conns in schema.wireNets:
    for n2 in conns:
      if not connected(my, n1, n2):
        let w = n1..n2
        my.incl w
        yield w


type
  SourceKind = enum
    skSchema
    skElement

  Source = object
    case kind*: SourceKind
    of skSchema: discard
    of skElement:
      name: string

func source(p: Port): Source =
  case p.parent.kind:
  of ikPort: Source(kind: skSchema)
  of ikCustom: Source(kind: skElement, name: p.parent.name)
  of ikNameNet: err "cannot find source of a name-net"

func `==`(s1, s2: Source): bool =
  if s1.kind == s2.kind:
    case s1.kind:
    of skSchema: true
    of skElement: s1.name == s2.name

  else: false

func groupBySource(portGroups: seq[seq[Port]]): Table[Source, seq[Port]] =
  for ports in portGroups:
    for p in ports:
      if p.origin.dir in {pdInput, pdOutput}:
        result.add p.source, p

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

proc addBuffer(p: Port, schema: var Schematic, module: Module) =
  ## 1. find location
  ## 2. find connected wires
  ## 3. detect direction of the port
  ## 4. place buffer before the port
  ## 5. remove intersected wires
  ##
  ## you need to draw every 2*4 cases to reach this conclusion
  ## when the input is from input element, head of buffer is `loc`
  ## when input is from a custom element, tail of the buffer is `loc`

  assert p.origin.dir == pdInput

  let
    loc = p.location
    connectedWiresNodes = toseq schema.wireNets[loc]
    nextNodeLoc = connectedWiresNodes[0]
    dir = dirOf loc .. nextNodeLoc
    vdir = toVector dir
    coeff =
      case p.parent.kind:
      of ikPort: +1
      else: -1

    orient = toOrient coeff*dir
    width = module.icon.geometry.size.w
    loc2 = loc + coeff*vdir*width
    buffIn =
      case p.parent.kind:
      of ikPort: loc
      else: loc2

    buffer = Instance(
      kind: ikCustom,
      name: "buffer_" & randomIdent(),
      module: module,
      location: buffIn,
      orient: orient)

  schema.wireNets.excl loc, nextNodeLoc
  schema.wireNets.incl loc2, nextNodeLoc
  schema.instances.add buffer

proc fixErrors(schema: var Schematic, modules: ModuleLookup) =
  ## fixes connection errors via adding `buffer0` element
  for pids in parts schema.connections:
    let portGroups = pids.mapit(schema.portsTable[it])
    for src, ports in groupBySource portGroups:
      for p in problematic ports:
        addBuffer p, schema, modules["buffer0"]

proc fixErrors*(project: var Project) =
  for _, m in mpairs project.modules:
    fixErrors m.schema, project.modules


func instantiate(o: Port, p: Instance): Port =
  Port(kind: pkInstance, parent: p, origin: o)

func extractConnection(
  sch: Schematic,
  portsPlot: Table[Point, seq[Port]]
  ): Graph[PortId] =

  var seen: Hashset[Point]

  for loc, ports in portsPlot:
    var acc: seq[Port]

    for l in walk(sch.wireNets, loc, seen):
      if l in portsPlot:
        for cp in portsPlot[l]:
          acc.add cp

    for p1 in acc:
      for pid1 in ids p1:
        for p2 in ports:
          for pid2 in ids p2:
            result.incl pid1, pid2

proc resolve*(proj: var Project) =
  ## add meta data for instances, resolve modules
  for _, module in mpairs proj.modules:
    var portsPlot: Table[Point, seq[Port]]

    for ins in mitems module.schema.instances:
      let mref = proj.modules[ins.module.name]
      ins.module = mref

      if ins.name[0] == '[': # an array, like [2:0]
        ins.name = randomIdent(10) & ins.name

      for p in mref.icon.ports:
        let
          insPort = instantiate(p, ins)
          loc = insPort.location

        portsPlot.add loc, insPort

        for pid in p.ids:
          module.schema.portsTable.add pid, insPort

    module.schema.connections =
      extractConnection(module.schema, portsPlot)
