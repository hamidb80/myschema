import std/[tables]

import model
import ../common/[coordination, domain, seqs]


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

type NetLookup = Table[Point, seq[Point]]

func collectImpl(last: WireGraphNode, ntlkp: var NetLookup) =
  let loc = last.location
  var conns = addr ntlkp[loc]

  for p in conns[]:
    ntlkp[p].remove loc # remove it from other way of relation

    var newNode = WireGraphNode(location: p)
    collectImpl newNode, ntlkp
    last.connections.add newNode

  clear conns[]

func collect(head: Point, ntlkp: var NetLookup): MNet =
  var head = WireGraphNode(location: head)
  result = MNet(kind: mnkWire, start: head)
  collectImpl head, ntlkp

func toNets*(wires: seq[Wire]): seq[MNet] =
  ## detects wire groups by generating a 2-way connection table

  var netGraph: NetLookup

  for w in wires:
    netGraph.addBoth w.a, w.b

  # ---

  var leaves: seq[Point]

  for nn, conns in netGraph:
    if conns.len == 1:
      leaves.add nn

  # ---

  for leaf in leaves:
    if netGraph[leaf].len > 0:
      result.add collect(leaf, netGraph)

# traversal ---

template traverseNet(net, body): untyped {.dirty.} =
  var nstack: seq[tuple[node: WireGraphNode, connIndex: int]] = @[(net.start, 0)]

  while not isEmpty nstack:
    let (lastNode, i) = nstack.last

    if i == lastNode.connections.len:
      shoot nstack

    else:
      let nextNode = lastNode.connections[i]
      body

      inc nstack.last.connIndex
      nstack.add (nextNode, 0)

type Segment* = Slice[Point]

iterator segments*(net: MNet): Segment =
  traverseNet net:
    yield lastNode.location .. nextNode.location

iterator points*(net: MNet): Point =
  yield net.start.location

  traverseNet net:
    yield nextNode.location


func afterTransform*(ins: MInstance): Geometry =
  toGeometry(ins.parent.icon.size)
  .rotate((0, 0), ins.transform.rotation)
  .placeAt(ins.position)
