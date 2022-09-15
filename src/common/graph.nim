## implments a non-directional graph

import std/[tables, sets, sequtils]
import collections

type Graph*[N] = Table[N, HashSet[N]]

func inclImpl[N](g: var Graph[N], key, val: N) =
  g.withValue(key, wrapper):
    wrapper[].incl val
  do:
    g[key] = toHashSet @[val]

func incl*[N](g: var Graph[N], n1, n2: N) =
  g.inclImpl n1, n2
  g.inclImpl n2, n1

func incl*[N](g: var Graph[N], ns: Slice[N]) =
  g.incl ns.a, ns.b

func exclImpl*[N](g: var Graph[N], key, val: N) =
  g.withValue(key, wrapper):
    wrapper[].excl val

func excl*[N](g: var Graph[N], n1, n2: N) =
  g.exclImpl n1, n2
  g.exclImpl n2, n1

func connected*[N](conns: Graph[N], n1, n2: N): bool =
  if n1 in conns:
    n2 in conns[n1]
  else: 
    false

iterator walk*[N](g: Graph[N], start: N, seen: var HashSet[N]): N =
  var stack = @[start]

  if start in g:
    while not isempty stack:
      let head = stack.pop

      if head notin seen:
        yield head
        seen.incl head

        for p in g[head]:
          stack.add p

iterator walk*[N](g: Graph[N], start: N): N =
  var seen: HashSet[N]
  for n in walk(g, start, seen):
    yield n

iterator parts*[N](g: Graph[N]): seq[N] =
  ## converts a disconnected graph to series of connected graphs
  var seen: HashSet[N]

  for node in keys g:
    let part = toseq walk(g, node, seen)
    if not isEmpty part:
      yield part
