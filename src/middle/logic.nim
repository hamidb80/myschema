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

iterator segments*(net: MNet): Segment =
  ## returns segmented net :: a single Wire

func detectDir*(w: Wire): VectorDirection =
  if w.a.x == w.b.x: # horizobtal
    if w.a.y > w.b.y: vdSouth
    else: vdNorth

  elif w.a.y == w.b.y: # horizobtal
    if w.a.x > w.b.x: vdWest
    else: vdEast

  else:
    err "invalid wire"
