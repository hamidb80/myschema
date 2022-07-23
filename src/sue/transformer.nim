import std/[tables]

import ../common/[defs, errors, seqs]

import model as sm
import ../middle/model as mm

# ------------------------------- utils

func safeAdd[K, V](lookup: var Table[K, seq[V]], k: K, v: V) {.inline.} =
  lookup.withValue k, list:
    list[].add v
  do:
    lookup[k] = @[v]

func addBoth[T](lookup: var Table[T, seq[T]], v1, v2: T) {.inline.} =
  lookup.safeAdd v1, v2
  lookup.safeAdd v2, v1

# ------------------------------- sue model -> middle model

type NetLookup = Table[Point, seq[Point]]

func collectImpl(last: var NetGraphNode, ntlkp: var NetLookup) =
  let loc = last.location

  var conns = addr ntlkp[loc]
  
  for p in conns[]:
    ntlkp[p].remove loc # remove it from other way of relation

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

func toMiddleModel*(sueIcon: sm.Icon): mm.Icon =
  discard

func toMiddleModel*(proj: sm.Project): mm.Project =
  discard

# ------------------------------- middle model -> sue model
