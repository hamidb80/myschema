import std/[os, tables, sequtils, strutils, strformat, times, options, macros]
import ../common/[coordination, domain]
import model, lexer, logic


type
  EncodeContext = enum
    ecIcon, ecSchematic

  KeyValueNimPair = tuple
    k, v: NimNode


func `$`*(pd: PortDir): string =
  case pd:
  of pdInput: "input"
  of pdOutput: "output"
  of pdInout: "inout"


func newObjConstr(objIdent: NimNode,
  keyValuePairs: seq[KeyValueNimPair]): NimNode = # TODO add to macroplus

  result = newTree(nnkObjConstr, objIdent)

  for (k, v) in keyValuePairs:
    result.add newTree(nnkExprColonExpr, k, v)

func extractSueOption(n: NimNode): KeyValueNimPair =
  expectKind n, nnkPrefix
  (n[1][0], n[1][1])

func toSueOption(p: KeyValueNimPair): NimNode =
  newCall(ident "toOption", ident "sf" & p.k.strVal, p.v)

func seqLit(s: seq[NimNode]): NimNode = # TODO add to macroplus
  prefix(newTree(nnkBracket).add s, "@")

macro genSueExpr(fnName, body: untyped): untyped =
  var
    options: seq[NimNode]
    args: seq[NimNode]

  for e in body:
    case e.kind:
    of nnkPrefix:
      options.add toSueOption extractSueOption e
    else:
      args.add newCall(bindSym"toToken", e)

  result = newObjConstr bindSym "SueExpression":
    @[(ident "command", ident "sc" & fnName.strVal),
    (ident "args", seqLit args),
    (ident "options", seqLit options)]


func quoted(s: string): string =
  if s.contains {' ', '[', ']', '{', '}'}:
    '{' & s & '}'
  else:
    s

template `|>`(list, fn): untyped =
  list.map fn

template toOption(f, val): untyped =
  SueOption(flag: f, value: toToken val)

func toToken*(p: Point): SueToken =
  toToken "{$# $#}" % [$p.x, $p.y]

func `$`*(flips: set[Flip]): string =
  join toseq flips

func speardPoints(points: seq[Point]): seq[int] =
  for p in points:
    result.add p.x
    result.add p.y


func encode(l: Line, ctx: EncodeContext): SueExpression =
  case l.kind:
  of straight:
    let cmd = case ctx:
      of ecIcon: scIconLine
      of ecSchematic: scMakeLine

    SueExpression(
      command: cmd,
      args: l.points.speardPoints |> toToken)

  of arc:
    genSueExpr icon_arc:
      l.head.x
      l.head.y
      l.tail.x
      l.tail.y
      -start l.start
      -extent l.extent

func encode(w: Wire): SueExpression =
  genSueExpr make_wire:
    w.a.x
    w.a.y
    w.b.x
    w.b.y

func encode(arg: Argument): SueOption =
  SueOption(flag: sfCustom,
    field: arg.name,
    value: toToken arg.value)

func encode(i: Instance): SueExpression =
  result = genSueExpr make:
    i.module.name
    -name quoted i.name
    -origin i.location
    -orient $i.orient

  result.options.add (i.args |> encode)

func encode(l: Label, ctx: EncodeContext): SueExpression =
  case ctx:
  of ecIcon:
    genSueExpr icon_property:
      -origin l.location
      -anchor $l.anchor
      -label quoted l.content

  of ecSchematic:
    genSueExpr make_text:
      -origin l.location
      -anchor $l.anchor
      -text quoted l.content

func encode(p: Port): SueExpression =
  genSueExpr icon_term:
    -type $p.dir
    -name quoted p.name
    -origin p.location

func encode(p: IconProperty): SueExpression =
  result = genSueExpr icon_property:
    -origin p.location
    -type $p.kind
    -name p.name

  if issome p.defaultValue:
    result.options.add toOption(sfDefault, quoted p.defaultValue.get)

func toSueFile(m: sink Module): SueFile =
  result = SueFile(name: m.name)

  # --- icon

  var acc: seq[string]

  for (name, value) in m.params:
    acc.add:
      if isSome value:
        "{$# $#}" % [name, value.get]
      else:
        "{$#}" % name


  result.icon.add SueExpression(
    command: scIconSetup,
    args: @[toRawToken "$args", toRawToken "{$#}" % acc.join" "])


  for p in m.icon.properties:
    if p.name notin ["origin", "orient"]:
      result.icon.add encode p

  for p in m.icon.ports:
    result.icon.add encode p

  for l in m.icon.labels:
    result.icon.add encode(l, ecIcon)

  for l in m.icon.lines:
    result.icon.add encode(l, ecIcon)


  for ins in m.schema.instances:
    result.schematic.add encode ins

  for w in wires m.schema.wiredNodes:
    result.schematic.add encode w

  for l in m.schema.labels:
    result.schematic.add encode(l, ecSchematic)

  for l in m.schema.lines:
    result.schematic.add encode(l, ecSchematic)

proc tclIndex(proj: Project): string =
  let now = $gettime().tounix()
  var
    linesAcc: seq[string]
    timesAcc: seq[string]

  for name, _ in proj.modules:
    linesAcc.add fmt"set auto_index(ICON_{name}) [list source [file join $dir {name}.sue]]"
    linesAcc.add fmt"set auto_index(SCHEMATIC_{name}) [list source [file join $dir {name}.sue]]"
    timesAcc.add "{$# $#}" % [name, now]

  linesAcc.add "set mtimes {$#}" % timesAcc.join(" ")
  linesAcc.join "n"


proc writeProject*(proj: Project, dest: string) =
  if not dirExists dest:
    createDir dest

  for name, module in proj.modules:
    if not module.isTemp:
      let fname = dest / name & ".sue"
      # debugEcho "writing ", fname
      writeFile fname, dump toSueFile module

      # if module.kind == akFile:
      #   writeFile dest / name, module.file.content

  writeFile dest / "tclIndex", tclIndex proj
