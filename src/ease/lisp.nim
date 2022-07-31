import std/[strutils, macros, options]

type
  LispNodeKind* = enum
    lnkSymbol
    lnkInt
    lnkFloat
    lnkString
    lnkList

  ParserState = enum
    psInitial
    psSymbol, psNumber, psString

  LispNode* = ref object
    case kind*: LispNodeKind:
    of lnkSymbol:
      name*: string

    of lnkInt:
      vint*: int

    of lnkFloat:
      vfloat*: float

    of lnkString:
      str*: string

    of lnkList:
      children*: seq[LispNode]


func toLispNode*(s: string): LispNode =
  LispNode(kind: lnkString, str: s.unescape("", ""))

func toLispNode*(ln: LispNode): LispNode = ln

func toLispNode*(f: float): LispNode =
  LispNode(kind: lnkFloat, vfloat: f)

func toLispNode*(i: int): LispNode =
  LispNode(kind: lnkInt, vint: i)

func toLispSymbol*(s: string): LispNode =
  LispNode(kind: lnkSymbol, name: s)

func toLispNode*(s: openArray[LispNode]): LispNode =
  result = LispNode(kind: lnkList)
  result.children = @s

func toLispList*(s: varargs[LispNode]): LispNode =
  result = LispNode(kind: lnkList)
  result.children.add s


func add*(ln: var LispNode, newChild: LispNode) =
  ln.children.add newChild

func add*(ln: var LispNode, newChildren: openArray[LispNode]) =
  for nch in newChildren:
    ln.children.add nch

func parseLisp(s: ptr string, startI: int, acc: var seq[LispNode]): int =
  ## return the last index that was there
  var
    state: ParserState = psInitial
    i = startI
    temp = 0
    isScaped = false

  template reset: untyped =
    state = psInitial
  template done: untyped =
    return i
  template checkDone: untyped =
    if c == ')':
      return i

  while i <= s[].len:
    let c =
      if i == s[].len: ' '
      else: s[i]

    case state:
    of psString:
      if c == '"' and not isScaped:
        acc.add toLispNode(s[temp ..< i])
        reset()

      isScaped =
        if c == '\\': not isScaped
        else: false

    of psSymbol:
      if c in Whitespace or c == ')':
        acc.add toLispSymbol(s[temp ..< i])
        reset()
        checkDone()

    of psNumber:
      if c in Whitespace or c == ')':
        let t = s[temp ..< i]

        acc.add:
          if '.' in t:
            toLispNode parseFloat t
          else:
            toLispNode parseInt t

        reset()
        checkDone()

    of psInitial:
      case c:
      of '(':
        var node = toLispList()
        i = parseLisp(s, i+1, node.children)
        acc.add node

      of ')': done()
      of Whitespace: discard

      of {'0' .. '9', '.', '-'}:
        state = psNumber
        temp = i

      of '"':
        state = psString
        temp = i+1

      else:
        state = psSymbol
        temp = i

    i.inc

func parseLisp*(code: string): seq[LispNode] =
  discard parseLisp(unsafeAddr code, 0, result)


func `$`*(n: LispNode): string =
  case n.kind:
  of lnkInt: $n.vint
  of lnkFloat: $n.vfloat
  of lnkString: n.str.escape
  of lnkSymbol: n.name
  of lnkList: '(' & n.children.join(" ") & ')'

func pretty*(n: LispNode, indentSize = 2): string =
  case n.kind:
  of lnkList:
    if n.children.len == 0: "()"
    else:
      var acc = "(" & $n.children[0]

      for c in n.children[1..^1]:
        acc &= "\n" & pretty(c, indentSize).indent indentSize

      acc & ")\n"

  else: $n


func ident*(n: LispNode): string =
  assert n.kind == lnkList
  assert n.children.len > 0
  assert n.children[0].kind == lnkSymbol
  n.children[0].name

func args*(n: LispNode): seq[LispNode] =
  assert n.kind == lnkList
  assert n.children.len > 0
  n.children[1..^1]

func arg*(n: LispNode, i: int): LispNode =
  assert n.kind == lnkList
  n.children[i+1]

func len*(n: LispNode): Natural =
  if n.kind == lnkList: n.children.len
  else: 0

func `[]`*(n: LispNode, i: int): LispNode =
  assert n.kind == lnkList
  n.children[i]

func matchCaller*(n: LispNode, c: string): bool =
  (n.kind == lnkList) and (n.len > 0) and (n.ident == c)

func `|<`*(n: LispNode, c: string): bool {.inline.} =
  n.matchCaller c

iterator items*(n: LispNode): LispNode =
  assert n.kind == lnkList
  for i in 1 .. n.len-1:
    yield n[i]

template findNode*(node: LispNode, cond): untyped =
  var result: Option[LispNode]
  for it {.inject.} in node:
    if cond:
      result = some it
      break
  result

template assertIdent*(call: LispNode, name: string): untyped =
  doAssert call.ident == name
  call
