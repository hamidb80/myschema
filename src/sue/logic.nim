import std/[sequtils, sets, tables]
import ../common/[coordination, graph, errors, seqtable, domain]
import model, helpers


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


# func placeElementAt(anchor: Point, orient: Orient) =
#   result.instances.add Instance(
#     name: "hepler_" & randomHdlIdent(),
#     orient: o,
#     parent: lookup["buffer0"],
#     location: buffIn)

func toOrient(vd: VectorDirection): Orient =
  case vd:
  of vdEast: R0
  of vdWest: RXY
  of vdNorth: R270
  of vdSouth: R90
  of vdDiagonal: err "orient for diogal vectors is not defined"


func addBuffer(p: Port, schema: var Schematic) =
  ## 1. find location
  ## 2. find connected wires
  ## 3. detect direction of the port
  ## 4. place buffer before the port
  ## 5. remove intersected wires

  let
    loc = p.location
    connectedWiresNodes = toseq schema.wireNets[loc]
    nextNodeLoc = connectedWiresNodes[0]
    dir = detectDir loc .. nextNodeLoc
    vdir = toVector dir
    orient = toOrient dir
    bufferDir =
      case p.origin.dir:
      of pdInput: cdInwrad
      of pdOutput: cdOutward
      of pdInout: err "'inout' port does not need a buffer"

    # elem =
    # buffIn = loc - vdir * 20
    # newPos = loc - vdir * 200

func fixErrors*(schema: var Schematic) =
  ## fixes connection errors via adding `buffer0` element
  for pids in parts schema.connections:
    let portGroups = pids.mapit(schema.portsTable[it])
    for src, ports in groupBySource portGroups:
      for p in problematic ports:
        addBuffer p, schema
