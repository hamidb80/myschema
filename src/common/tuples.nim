import macros

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
