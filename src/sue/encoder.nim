import std/[os, tables, sequtils, strutils, strformat, times, sugar]
import ../common/[coordination, domain]
import model, lexer


type LabelContext = enum
  lcIcon, lcSchematic


func toToken*(p: Point): SueToken =
  toToken '{' & $p.x & ' ' & $p.y & '}'

template toOption(f, val): untyped =
  SueOption(flag: f, value: toToken val)

func `$`*(o: Orient): string =
  $o.rotation & join toseq o.flips

func `$`(pd: PortDir): string =
  case pd:
  of pdInput: "input"
  of pdOutput: "output"
  of pdInout: "inout"

func speardPoints(points: seq[Point]): seq[int] =
  for p in points:
    result.add p.x
    result.add p.y


func encode(l: Line): SueExpression =
  case l.kind:
  of straight:
    SueExpression(
      command: scMakeLine,
      args: l.points.speardPoints.map(toToken))

  of arc:
    SueExpression(
      command: scMakeLine,
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

func encode(i: Instance): SueExpression =
  SueExpression(
    command: scMake,
    args: @[totoken i.parent.name],
    options: @[
      toOption(sfName, i.name),
      toOption(sfOrigin, i.location),
      toOption(sfOrient, $i.orient)
    ],
  )


func encode(l: Label, ctx: LabelContext): SueExpression =
  case ctx:
  of lcIcon:
    SueExpression(
      command: scIconProperty,
      options: @[
        toOption(sfOrigin, l.location),
        toOption(sfAnchor, $l.anchor),
        toOption(sfLabel, l.content)
      ]
    )

  of lcSchematic:
    SueExpression(
      command: scMakeText,
      options: @[
        toOption(sfOrigin, l.location),
        toOption(sfAnchor, $l.anchor),
        toOption(sfText, l.content)
      ]
    )

func encode(p: Port): SueExpression =
  SueExpression(
    command: scMake,
    args: @[toToken $p.kind],
    options: @[
      toOption(sfName, p.name),
      toOption(sfOrigin, p.location)
    ],
  )

func dump(a: Architecture): string =
  case a.kind:
  of akFile: a.file.content
  of akSchematic:

    ""

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

proc writeProject*(proj: Project, dest: string) =
  for name, module in proj.modules:
    let
      a = module.arch
      fname =
        case a.kind:
        of akSchematic: name & ".sue"
        of akFile: name

    writeFile dest / fname, dump a
    writeFile dest / "tclindex", genTclIndex proj
