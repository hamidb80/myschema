import std/[tables, strutils, strformat, sugar, sets]

import model
import ../common/[coordination, domain, seqs, errors]


# utils ---

func safeAdd[K, V](lookup: var Table[K, seq[V]], k: K, v: V) {.inline.} =
  lookup.withValue k, list:
    list[].add v
  do:
    lookup[k] = @[v]

func addBoth[T](lookup: var Table[T, seq[T]], v1, v2: T) {.inline.} =
  lookup.safeAdd v1, v2
  lookup.safeAdd v2, v1

# net extract ---

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

