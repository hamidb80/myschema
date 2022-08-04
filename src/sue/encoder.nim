import std/[os, tables, sequtils, setutils, strutils, strformat, times, options]
import ../common/[coordination, domain]
import model, lexer, logic


type EncodeContext = enum
  ecIcon, ecSchematic


func quoted(s: string): string =
  if s.contains {' ', '[', ']', '{', '}'}:
    '{' & s & '}'
  else:
    s

func normalize(o: Orient): Orient =
  ## R180 is invalid rotation, you should use RXY instead

  if o.rotation == r180:
    Orient(
      rotation: r0,
      flips: complement o.flips)

  else: o

template toOption(f, val): untyped =
  SueOption(flag: f, value: toToken val)

func toToken*(p: Point): SueToken =
  toToken "{$# $#}" % [$p.x, $p.y]

func `$`*(flips: set[Flip]): string =
  join toseq flips

func `$`*(o: Orient): string =
  ## R0XY => RXY
  if o.rotation == r0:
    if o.flips.card == 0: "R0"
    else: 'R' & $o.flips
  else:
    'R' & $o.rotation.int & $o.flips

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
      args: l.points.speardPoints.map(toToken))

  of arc:
    SueExpression(
      command: scIconArc,
      args: @[l.head.x, l.head.y, l.tail.x, l.tail.y].map(toToken),
      options: @[
        toOption(sfStart, l.start),
        toOption(sfExtent, l.extent),
      ])

func encode(w: Wire): SueExpression =
  SueExpression(
    command: scMakeWire,
    args: @[w.a.x, w.a.y, w.b.x, w.b.y].map toToken,
  )

func encode(arg: Argument): SueOption =
  SueOption(flag: sfCustom,
    field: arg.name,
    value: toToken arg.value)

func encode(i: Instance): SueExpression =
  SueExpression(
    command: scMake,
    args: @[toToken i.parent.name],
    options: @[
      toOption(sfName, quoted i.name),
      toOption(sfOrigin, i.location),
      toOption(sfOrient, $i.orient.normalize),
    ] & map(i.args, encode),
  )

func encode(l: Label, ctx: EncodeContext): SueExpression =
  case ctx:
  of ecIcon:
    SueExpression(
      command: scIconProperty,
      options: @[
        toOption(sfOrigin, l.location),
        toOption(sfAnchor, $l.anchor),
        toOption(sfLabel, quoted l.content)])

  of ecSchematic:
    SueExpression(
      command: scMakeText,
      options: @[
        toOption(sfOrigin, l.location),
        toOption(sfAnchor, $l.anchor),
        toOption(sfText, quoted l.content)])

func inlineEncode(param: Parameter): string =
  if issome param.defaultValue:
    "{$# $#}" % [param.name, dump toToken param.defaultValue.get]
  else:
    "{$#}" % param.name

func encode(params: seq[Parameter], ctx: EncodeContext): SueExpression =
  SueExpression(
    command: if ctx == ecIcon: scIconSetup
      else: scCallUseKeyword,

    args: @[
      toTokenRaw "$args",
      toTokenRaw "{$#}" % params.map(inlineEncode).join " "])

func encode(p: Port): SueExpression =
  SueExpression(
    command: scIconTerm,
    options: @[
      toOption(sfType, $p.kind),
      toOption(sfName, quoted p.name),
      toOption(sfOrigin, p.location)])

func encode(p: IconProperty): SueExpression =
  result = SueExpression(
    command: scIconProperty,
    options: @[
      toOption(sfOrigin, p.location),
      toOption(sfType, $p.kind),
      toOption(sfName, p.name)])

  if issome p.defaultValue:
    result.options.add toOption(sfDefault, quoted p.defaultValue.get)

func toSueFile(m: sink Module): SueFile =
  result = SueFile(name: m.name)

  # --- icon
  result.icon.add encode(m.params, ecIcon)

  for p in m.icon.properties:
    if p.name notin ["origin", "orient"]:
      result.icon.add encode p

  for p in m.icon.ports:
    result.icon.add encode p

  for l in m.icon.labels:
    result.icon.add encode(l, ecIcon)

  for l in m.icon.lines:
    result.icon.add encode(l, ecIcon)

  # --- schematic
  result.schematic.add encode(m.params, ecSchematic)

  for ins in m.arch.schema.instances:
    result.schematic.add encode ins

  for w in m.arch.schema.wires:
    result.schematic.add encode w

  for l in m.arch.schema.labels:
    result.schematic.add encode(l, ecSchematic)

  for l in m.arch.schema.lines:
    result.schematic.add encode(l, ecSchematic)

proc genTclIndex(proj: Project): string =
  let now = $gettime().tounix()
  var
    linesAcc: seq[string]
    timesAcc: seq[string]

  for name, _ in proj.modules:
    linesAcc.add fmt"set auto_index(ICON_{name}) [list source [file join $dir {name}.sue]]"
    linesAcc.add fmt"set auto_index(SCHEMATIC_{name}) [list source [file join $dir {name}.sue]]"
    timesAcc.add "{$# $#}" % [name, now]

  linesAcc.add "set mtimes {$#}" % timesAcc.join(" ")
  linesAcc.join "\n"


const b = readfile "./elements/buffer0.sue"
proc writeProject*(proj: Project, dest: string) =

  writeFile dest / "buffer0.sue", b


  for name, module in proj.modules:
    if not module.isTemporary:
      let fname = dest / name & ".sue"
      debugEcho "writing ", fname
      writeFile fname, dump toSueFile module

      if module.arch.kind == akFile:
        writeFile dest / name, module.arch.file.content

  writeFile dest / "tclindex", genTclIndex proj
