import std/[macros, tables, sets]
import seqtable

macro toTuple*(list: untyped, n: static[int]): untyped =
  ## converts first `n` elements of `list` to tuple
  ## toTuple(list, 3) => (list[0], list[1], list[2])

  let tempId = gensym()
  var tupleDef = newTree nnkTupleConstr

  for i in 0 ..< n:
    tupleDef.add newTree(nnkBracketExpr, tempid, newlit i)

  quote:
    block:
      let `tempId` = `list`
      `tupleDef`

macro pickTuple*(list: untyped, indexes: static[openArray[int]]): untyped =
  ## convert a desired indexes from list to tuple
  ## pickTuple(list, [4, 1]) => (list[4], list[1])

  let tempId = gensym()
  var tupleDef = newTree nnkTupleConstr

  for i in indexes:
    tupleDef.add newTree(nnkBracketExpr, tempid, newlit i)

  quote:
    block:
      let `tempId` = `list`
      `tupleDef`


template toSlice*(a): untyped =
  a[0] .. a[1]

func sorted*[T](r: Slice[T]): Slice[T] =
  if r.a < r.b: r
  else: r.b .. r.a


func reversed*[T](s: Slice[T]): Slice[T] =
  s.b .. s.a

## this modules contains utility functionalities to work woth
## `seq`s

func remove*[T](s: var seq[T], v: T) =
  let i = s.find(v)

  if i != -1:
    s.del i

func clear*(s: var seq) =
  s.setlen 0

func isEmpty*(s: seq): bool {.inline.} =
  s.len == 0

template first*(s): untyped = s[0]
template last*(s): untyped = s[^1]

func shoot*(s: var seq) =
  s.del s.high

func search*[T](s: openArray[T], check: proc(item: T): bool): T =
  for i in s:
    if check i:
      return i

  raise newException(ValueError, "not found")

# proc add[T](s: var HashSet[T], v: T) =
#   s.incl v

template toTableBy*[Key, Value](s, keyExtractor): untyped =
  var result: Table[Key, seq[Value]]

  for it{.inject.} in s:
    let key = keyExtractor
    withValue result, key, wrapper:
      wrapper[].add it
    do:
      result[key] = @[it]

  result

template findOne*[V](s, cond): untyped =
  var
    result: V
    found = false

  for it{.inject.} in s:
    if cond:
      result = it
      found = true
      break

  assert found, "not found"
  result
