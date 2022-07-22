template err*(msg: string): untyped =
  raise newException(ValueError, msg)

template impossible*: untyped =
  err "impossible"
