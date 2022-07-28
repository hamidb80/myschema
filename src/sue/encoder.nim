import std/[sequtils, strutils]
import ../common/[coordination]
import model, lexer

# --- options

func toToken*(p: Point): SueToken =
  toToken '{' & $p.x & ' ' & $p.y & '}'

template toOption(f, val): untyped =
  SueOption(flag: f, value: toToken val)

func `$`*(o: Orient): string =
  $o.rotation & join toseq o.flips

# --- helpers

func speardPoints(points: seq[Point]): seq[int] =
  for p in points:
    result.add p.x
    result.add p.y

# --- experssions

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


type LabelContext = enum
  lcIcon, lcSchematic

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
