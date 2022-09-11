## implments a non-directional graph

import std/[tables, sets]
import seqs

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

func areConnected*[N](conns: Graph[N], n1, n2: N): bool =
  n2 in conns[n2]


iterator walk*[N](g: Graph[N], start: N, seen: var HashSet[N]): N =  
  var stack = @[start]

  while not isempty stack:
    let head = stack.pop
    yield head

    if head notin seen:
      seen.incl head

      for p in g[head]:
        stack.add p


iterator walk*[N](g: Graph[N], start: N): N =
  var seen: HashSet[N]
  for n in walk(g, start, seen):
    yield n