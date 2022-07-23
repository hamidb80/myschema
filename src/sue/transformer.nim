import std/[tables]

import ../common/[defs, errors, seqs]

import model as sm
import ../middle/model as mm


func safeAdd[K, V](lookup: var Table[K, seq[V]], k: K, v: V) {.inline.} =
  lookup.withValue k, list:
    list[].add v
  do:
    lookup[k] = @[v]

func addBoth[T](lookup: var Table[T, seq[T]], v1, v2: T) {.inline.} =
  lookup.safeAdd v1, v2
  lookup.safeAdd v2, v1


type NetLookup = Table[Point, seq[Point]]

func collectImpl(last: var NetGraphNode, ntlkp: var NetLookup) =
  let loc = last.location

  withValue ntlkp, loc, conns:
    for p in conns[]:
      # remove it from other way of relation
      withValue ntlkp, p, connsBack:
        connsBack[].remove loc

      var newNode = NetGraphNode(location: p)
      collectImpl newNode, ntlkp

      last.connections.add newNode

    clear conns[]

func collect(head: Point, ntlkp: var NetLookup): NetGraphNode =
  result = NetGraphNode(location: head)
  collectImpl result, ntlkp

func toNet(wires: seq[sm.Wire]): seq[NetGraphNode] =
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
    if leaf in netGraph:
      result.add collect(leaf, netGraph)


func toMiddleModel*(sch: sm.Schematic, lookup: sm.ModuleLookUp): mm.Schema =
  discard toNet sch.wires


