import std/[tables]

type SeqTable*[K, V] = Table[K, seq[V]]

func addSafe*[K, V](t: var SeqTable[K, V], key: K, val: V) =
  t.withValue(key, wrapper):
    wrapper[].add val
  do:
    t[key] = @[val]
