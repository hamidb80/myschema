import std/tables

type Graph*[N] = Table[N, seq[N]]

func safeAdd*[N](lookup: var Graph[N], k, v: N) =
  lookup.withValue k, list:
    list[].add v
  do:
    lookup[k] = @[v]

func addBoth*[N](lookup: var Graph[N], v1, v2: N) =
  lookup.safeAdd v1, v2
  lookup.safeAdd v2, v1

func removeBoth*[N](lookup: var Graph[N], v1, v2: N) =
  del lookup[v1], find(lookup[v1], v2)
  del lookup[v2], find(lookup[v2], v1)
