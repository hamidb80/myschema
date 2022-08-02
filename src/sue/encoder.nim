import std/[os, tables, sequtils, strutils, strformat, times]
import ../common/[coordination, domain]
import model, lexer


type EncodeContext = enum
  ecIcon, ecSchematic


func quoted(s: string): string =
  '{' & s & '}'

template toOption(f, val): untyped =
  SueOption(flag: f, value: toToken val)

func toToken*(p: Point): SueToken =
  toToken "{$# $#}" % [$p.x, $p.y]

func `$`*(o: Orient): string =
  'R' & $o.rotation.int & join toseq o.flips

func `$`(pd: PortDir): string =
  case pd:
  of pdInput: "input"
  of pdOutput: "output"
  of pdInout: "inout"

func speardPoints(points: seq[Point]): seq[int] =
  for p in points:
    result.add p.x
    result.add p.y

# TODO add params

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
      toOption(sfOrient, $i.orient),
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
        toOption(sfLabel, quoted l.content)
      ]
    )

  of ecSchematic:
    SueExpression(
      command: scMakeText,
      options: @[
        toOption(sfOrigin, l.location),
        toOption(sfAnchor, $l.anchor),
        toOption(sfText, quoted l.content)
      ]
    )

func encode(p: Port): SueExpression =
  SueExpression(
    command: scMake,
    args: @[toToken $p.kind],
    options: @[
      toOption(sfName, quoted p.name),
      toOption(sfOrigin, p.location)
    ],
  )

func toSueFile(name: string, sch: sink SSchematic, ico: sink Icon): SueFile =
  result = SueFile(name: name)

  # --- icon

  for p in ico.ports:
    result.icon.add encode p
    result.icon.add encode(Label(
      content: p.name,
      location: p.location,
      anchor: c,
      size: fzStandard
    ), ecIcon)

  for l in ico.lines:
    result.icon.add encode(l, ecIcon)

  # --- schematic

  for ins in sch.instances:
    result.schematic.add encode ins

  for w in sch.wires:
    result.schematic.add encode w

  for l in sch.labels:
    result.schematic.add encode(l, ecSchematic)

  for l in sch.lines:
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

  linesAcc.add fmt"""set mtimes {timesAcc.join " "}"""
  linesAcc.join "\n"


let xxx = SSchematic(labels: @[]) # FIXME causes error in LISP!

proc writeProject*(proj: Project, dest: string) =
  for name, module in proj.modules:
    if not module.isTemporary:
      let a = module.arch

      case a.kind:
      of akSchematic:
        writeFile dest / name & ".sue", dump toSueFile(name, a.schema, module.icon)

      of akFile:
        writeFile dest / name & ".sue", dump toSueFile(name, xxx, module.icon)
        writeFile dest / name & ".v", a.file.content

  writeFile dest / "tclindex", genTclIndex proj
