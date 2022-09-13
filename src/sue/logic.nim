import std/[sequtils, sets, tables, os]
import ../common/[coordination, graph, errors, seqtable, domain, rand]
import model, helpers, parser, lexer


type
  SourceKind = enum
    skSchema
    skElement

  Source = object
    case kind*: SourceKind
    of skSchema: discard
    of skElement:
      name: string


var basicModules: ModuleLookUp

for path in walkFiles "./elements/*.sue":
  let (_, name, _) = splitFile path
  basicModules[name] = parseSue lexSue readfile path



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

proc addBuffer(p: Port, schema: var Schematic, module: Module) =
  ## 1. find location
  ## 2. find connected wires
  ## 3. detect direction of the port
  ## 4. place buffer before the port
  ## 5. remove intersected wires

  let
    loc = p.location
    connectedWiresNodes = toseq schema.wireNets[loc]
    nextNodeLoc = connectedWiresNodes[0]
    dir = dirOf loc .. nextNodeLoc
    vdir = toVector dir
    orient = toOrient dir
    buffIn = loc
    buffOut = loc + -vdir*(module.icon.geometry.size.w)

    buffer = Instance(
      kind: ikCustom,
      name: "fix_" & randomIdent(),
      module: module,
      location: buffIn,
      orient: orient)

  schema.wireNets.excl loc, nextNodeLoc
  schema.wireNets.incl buffOut, nextNodeLoc
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
