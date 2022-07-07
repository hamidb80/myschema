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


template err*(msg: string): untyped =
  raise newException(ValueError, msg)

template impossible*: untyped =
  err "impossible"
