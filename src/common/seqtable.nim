import std/tables

type SeqTable*[K, V] = Table[K, seq[V]]

func safeAdd*[K, V](t: var SeqTable[K, V], key: K, value: V) =
  t.withValue(key, wrapper):
    wrapper[].add value
  do:
    t[key] = @[value]