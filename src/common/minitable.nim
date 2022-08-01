type
  MiniTable*[K, V] = seq[tuple[key: K, value: V]]

template search(tab, k, success, fail: untyped): untyped {.dirty.} =
  for p in tab.items:
    if p.key == k:
      success

  fail

template msearch(tab, k, success, fail: untyped): untyped =
  for p {.inject.} in tab.mitems:
    if p.key == k:
      success

  fail


func contains*[K, V](tab: MiniTable[K, V], key: K): bool =
  tab.search key:
    return true
  do:
    false

func getOrDefault*[K, V](tab: MiniTable[K, V], key: K, def: V): V =
  tab.search key:
    return p.value
  do:
    return def

func `[]`*[K, V](tab: MiniTable[K, V], key: K): V =
  tab.search key:
    return p.value
  do:
    raise newException(IndexDefect, "key not found")

func `[]=`*[K, V](tab: var MiniTable[K, V], key: K, val: V) =
  tab.msearch key:
    p.value = val
    break
  do:
    tab.add (key, val)


iterator values*[_, V](tab: MiniTable[_, V]): lent V =
  for (_, v) in tab:
    yield v
