import std/[tables, sugar, sets]

import model
import ../common/[coordination, domain, seqs, errors, graph]


func collectImpl(
  cur: Point,
  seen: var HashSet[Point],
  globalNetLookup: NetLookup,
  localNetLookup: var NetLookup) =

  if cur notin seen:
    seen.incl cur
    let g = globalNetLookup[cur]
    localNetLookup[cur] = g

    for n in g:
      collectImpl n, seen, globalNetLookup, localNetLookup

func collect(
  head: Point,
  seen: var HashSet[Point],
  ntlkp: var NetLookup): MNet =

  result = MNet(kind: mnkWire)
  collectImpl head, seen, ntlkp, result.connections

func toNets*(wires: seq[Wire]): seq[MNet] =
  ## detects wire groups by generating a 2-way connection table

  var netGraph: NetLookup
  for w in wires:
    netGraph.addBoth w.a, w.b

  let leaves = collect newseq: # the nodes that have only 1 connection
    for nn, conns in netGraph:
      if conns.len == 1:
        nn

  var seen = initHashSet[Point]()
  for leaf in leaves:
    if leaf notin seen:
      result.add collect(leaf, seen, netGraph)

func pick(nlkp: NetLookup): Point =
  for p in nlkp.keys:
    return p

template traverseNet(net, body): untyped {.dirty.} =
  var
    seen = initHashSet[Point]()
    pStack: seq[Point] = @[pick net.connections]

  while not isEmpty pStack:
    let last = pStack.pop

    if last notin seen:
      let conns = net.connections[last]
      pStack.add conns

      for next in conns:
        body

      seen.incl last

iterator segments*(net: MNet): Segment =
  traverseNet net:
    yield last .. next


func choose*(archs: seq[MArchitecture]): MArchitecture =
  result = archs[0]

  for a in archs:
    if a.kind == makSchema:
      result = a

func afterTransform*(icon: MIcon, ro: Rotation, pos: Point): Geometry =
  toGeometry(icon.size).rotate(P0, ro).placeAt(pos)


func `$`*(pd: MPortDir): string =
  case pd:
  of mpdinput: "input"
  of mpdoutput: "output"
  of mpdinout: "inout"

iterator allNets*(br: MBusRipper): MNet =
  var
    seen: seq[MNet]
    bstack = @[br]

  while not isEmpty bstack:
    let last = bstack.pop

    for n in [last.source, last.dest]:
      if n notin seen:
        yield n
        bstack.add n.busrippers
        seen.add n


func detectDir*(w: Wire): VectorDirection =
  if w.a.x == w.b.x: # horizobtal
    if w.a.y > w.b.y: vdSouth
    else: vdNorth

  elif w.a.y == w.b.y: # horizobtal
    if w.a.x > w.b.x: vdWest
    else: vdEast

  else:
    err "invalid wire"


func `==`*(mi1, mi2: MIdentifier): bool =
  if mi1.kind == mi2.kind:
    if mi1.name == mi2.name:
      case mi1.kind:
      of mikSingle: true
      of mikIndex: mi1.index == mi2.index
      of mikRange: mi1.indexes == mi2.indexes
    else: false
  else: false

func id*(n: MNet): MIdentifier =
  for p in n.ports:
    if not p.isSliced:
      return p.parent.id
