import std/[strutils, strformat]

type
  SueCommand* = enum
    scMake = "make"
    scMakeWire = "make_wire"
    scMakeLine = "make_line"
    scMakeText = "make_text"
    scIconSetup = "icon_setup"
    scIconTerm = "icon_term"
    scIconProperty = "icon_property"
    scIconLine = "icon_line"
    scIconArc = "icon_arc"

  SueFlag* = enum
    sfLabel = "label"
    sfText = "text"
    sfName = "name"
    sfOrigin = "origin"
    sfOrient = "orient"
    sfRotate = "rotate"
    sfSize = "size"
    sfType = "type"
    sfAnchor = "anchor"
    sfStart = "start"
    sfExtent = "extent"
    sfCustom = "<CUSTOM_FIELD>"

  SueType* = enum
    spInput = "input"
    spOutput = "output"
    spInOut = "inout"
    spUser = "user"

  SueSize* = enum
    ssSmall = "small"
    ssLarge = "large"


  SuePoint* = tuple[x, y: int]

  SueOption* = object # TODO merge commom fields by types
    case flag*: SueFlag
    of sfText, sfName, sfLabel, sfOrient:
      strval*: string

    of sfOrigin:
      position*: SuePoint

    of sfType:
      portType*: SueType

    of sfSize:
      size*: SueSize

    of sfAnchor:
      anchor*: string

    of sfRotate:
      rotation*: int

    of sfStart, sfExtent:
      degree*: int

    of sfCustom:
      field*, value*: string

  SueExpression* = object
    case command*: SueCommand
    of scMake:
      ident*: string

    of scMakeWire, scMakeLine, scIconArc:
      head*, tail*: SuePoint

    of scIconSetup:
      discard # TODO

    of scIconTerm, scIconProperty, scMakeText:
      discard

    of scIconLine:
      points*: seq[SuePoint]

    options*: seq[SueOption]

  SueFile* = object
    name*: string
    schematic*, icon*: seq[SueExpression]


func expand*(points: seq[SuePoint]): seq[int] =
  for p in points:
    result.add [p.x, p.y]

func isPure*(s: string): bool =
  for ch in s:
    if ch notin IdentChars:
      return false

  true

func wrap*(s: string): string =
  if isPure s: s
  else: '{' & s & '}'

const SueVersion = "MMI_SUE4.4"

func dumpValue*(o: SueOption): string = 
  case o.flag:
  of sfLabel, sfText, sfName, sfOrient: wrap o.strval
  of sfOrigin: ["{", $o.position.x, " ", $o.position.y, "}"].join
  of sfRotate: $o.rotation
  of sfSize: $o.size
  of sfType: $o.portType
  of sfAnchor: o.anchor
  of sfStart, sfExtent: $o.degree
  of sfCustom: o.value

func dumpFlag*(o: SueOption): string = 
  case o.flag:
  of sfcustom: o.field
  else: $o.flag

func dumpArgs(expr: SueExpression): string = 
  case expr.command:
  of scMake: expr.ident
  of scMakeText, scIconTerm, scIconProperty: ""
  of scIconSetup: ""
  of scIconLine: expr.points.expand.join " "
  of scMakeWire, scMakeLine, scIconArc:
    @[expr.head.x, expr.head.y, expr.tail.x, expr.tail.y].join " "

func dump*(expr: SueExpression): string =
  result = fmt"  {expr.command} "
  result.add dumpArgs expr
  result = result.strip(leading = false)

  for op in expr.options:
    result.add fmt" -{op.dumpFlag} {dumpValue op}"

func dump*(sf: SueFile): string =
  var lines = @[fmt "# SUE version {SueVersion}\n"]

  template addLinesFor(exprWrapper): untyped =
    for expr in exprWrapper:
      lines.add dump expr

  lines.add "proc SCHEMATIC_" & sf.name & " {} {"
  addLinesFor sf.schematic
  lines.add "}\n"

  if sf.icon.len != 0:
    lines.add "proc ICON_" & sf.name & " args {"
    addLinesFor sf.icon
    lines.add "}"

  lines.join "\n"
