import macros

macro toTuple*(list: untyped, n: static[int]): untyped =
  let tempId = gensym()
  var tupleDef = newTree nnkTupleConstr

  for i in 0..(n-1):
    tupleDef.add newTree(nnkBracketExpr, tempid, newlit i)

  quote:
    block:
      let `tempId` = `list`
      `tupleDef`

macro pickTuple*(list: untyped, indexes: static[openArray[int]]): untyped =
  let tempId = gensym()
  var tupleDef = newTree nnkTupleConstr

  for i in indexes:
    tupleDef.add newTree(nnkBracketExpr, tempid, newlit i)

  quote:
    block:
      let `tempId` = `list`
      `tupleDef`
