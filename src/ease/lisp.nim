import std/[strutils, macros, sequtils, options, strformat]
import ../common/errors

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
  LispNode(kind: lnkString, str: s)

func toLispNode*(f: float): LispNode =
  LispNode(kind: lnkFloat, vfloat: f)

func toLispNode*(i: int): LispNode =
  LispNode(kind: lnkInt, vint: i)

func toLispSymbol*(s: string): LispNode =
  LispNode(kind: lnkSymbol, name: s)

func newLispList*(s: openArray[LispNode]): LispNode =
  result = LispNode(kind: lnkList)
  result.children.add s

func newLispList*(s: varargs[LispNode]): LispNode =
  result = LispNode(kind: lnkList)
  result.children.add s


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
        var node = newLispList()
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
  of lnkString: '"' & n.str & '"'
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

func add*(ln: var LispNode, newChildren: LispNode) =
  ln.children.add newChildren

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

# ----------------------------------------------------------

proc toLispImpl(n: NimNode): NimNode =
  case n.kind:
  of nnkTupleConstr, nnkPar: newCall("newLispList").add n.mapIt(newCall("toLisp", it)) 
  of nnkPrefix: 
    if n.kind == nnkPrefix and n[0].strVal == "!":
      newCall("toLispSymbol", newlit n[1].strval)
    else:
      newCall("toLispNode", n)
  else: newCall("toLispNode", n)

macro toLisp*(body): untyped =
  runnableExamples:
    echo toLisp ()
    echo toLisp (1)
    echo toLisp (1, (2, (3, 4)), 5)

    let a = 2
    echo toLisp (!FN, a)

  toLispImpl body
