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