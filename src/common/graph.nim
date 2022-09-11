## implments a non-directional graph

import std/[tables, sets]

type Graph*[N] = Table[N, HashSet[N]]

func inclImpl[N](g: var Graph[N], key, val: N) =
  g.withValue(key, wrapper):
    wrapper[].incl val
  do:
    g[key] = toHashSet @[val]

func incl*[N](g: var Graph[N], n1, n2: N) =
  g.inclImpl n1, n2
  g.inclImpl n2, n1

func exclImpl*[N](g: var Graph[N], key, val: N) =
  g.withValue(key, wrapper):
    wrapper[].excl val

func excl*[N](g: var Graph[N], n1, n2: N) =
  g.exclImpl n1, n2
  g.exclImpl n2, n1