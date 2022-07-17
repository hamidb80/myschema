import std/[strutils, macros, sugar, sequtils, options]
import ../utils

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
  (n.kind == lnkList) and (n.len > 0) and (n.ident.name == c)


iterator items*(n: LispNode): LispNode =
  if n.kind == lnkList:
    for ch in n.children:
      yield ch

iterator args*(n: LispNode): LispNode =
  assert n.kind == lnkList
  for i in 1 .. n.len-1:
    yield n[i]


func findNode*(node: LispNode, fn: proc(l: LispNode): bool): Option[LispNode] =
  for ch in node:
    if fn ch:
      return some ch

template assertIdent*(call: LispNode, name: string): untyped =
  assert call.ident == name
  call

# ----------------------------------------------------------

let
  toLispNodeIdent {.compileTime.} = ident "toLispNode"
  toLispSymbolIdent {.compileTime.} = ident "toLispSymbol"
  newLispListIdent {.compileTime.} = ident "newLispList"

proc toLispImpl(nodes: seq[NimNode]): NimNode =
  result = newCall(newLispListIdent)

  for n in nodes:
    result.add:
      case n.kind:
      of nnkIdent:
        newCall(toLispSymbolIdent, newlit n.strVal)

      of nnkTupleConstr:
        toLispImpl n.toseq

      of nnkPar:
        newCall(newLispListIdent, n[0])

      else:
        newCall(toLispNodeIdent, n)

macro toLisp*(body): untyped =
  result = case body.kind:
  of nnkTupleConstr:
    toLispImpl body.toseq

  of nnkStmtList:
    newTree(nnkBracket).add collect do:
      for n in body:
        expectKind n, nnkTupleConstr
        toLispImpl n.toseq

  else:
    raise newException(ValueError, "expected tupleConstr or stmtList. got: " & $body.kind)
