template err*(msg: string): untyped =
  raise newException(ValueError, msg)
