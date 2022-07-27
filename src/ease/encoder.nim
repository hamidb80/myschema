import std/[tables, macros, options, sequtils]
import model, lisp
import ../common/[coordination, errors]

# --- building blocks

func add(ln: var LispNode, v: Option[LispNode]) =
  if isSome v:
    ln.add v.get

template toLispNode(v: Option[LispNode]): untyped =
  v


type LispGroup = distinct LispNode

template toLispNode(v: LispGroup): untyped = v

func toLispGroup(sl: seq[LispNode]): LispGroup =
  var tmp = toLispList()
  tmp.add sl
  tmp.LispGroup

func add(ln: var LispNode, gl: LispGroup) =
  ln.add gl.LispNode.children


type LispMacroMode = enum
  lmmInital, lmmAsIs, lmmFnCall

proc toLispImpl(nn: NimNode, mode = lmmInital): NimNode =
  template norm(val): untyped =
    newCall("toLispNode", val)

  result =
    case nn.kind:
    of nnkStmtList:
      raise newException(ValueError, "not")

    of nnkAccQuoted:
      newCall("toLispSymbol", newLit nn.repr[1..^2])

    of nnkTupleConstr, nnkPar:
      doAssert nn.len > 0

      case mode:
      of lmmInital:
        case nn[0].kind:
        of nnkIdent:
          toLispImpl(nn, lmmFnCall)

        of nnkAccQuoted:
          toLispImpl(nn, lmmAsIs)

        else:
          raise newException(ValueError, "invalid")

      of lmmAsIs:
        let id = ident "temp"
        var res = newStmtList()

        for i, n in nn:
          res.add newCall("add", id) do:
            if i == 0:
              newCall("toLispSymbol", newlit n.repr[1..^2])
            else:
              newCall("toLisp", n)

        quote:
          block:
            var `id` = toLispList()
            `res`
            `id`


      of lmmFnCall:
        var res: NimNode

        for i, n in nn:
          if i == 0:
            res = newCall("encode" & n.strval)
          else:
            res.add n

        res

    of nnkCommand, nnkCall:
      case nn[0].strval:
      of "_": # spread
        newCall "toLispGroup", nn[1]
      else:
        norm nn

    else:
      norm nn

  # debugEcho "------------------"
  # debugEcho repr result

macro toLisp*(body): untyped =
  ## converts paranterized nim code to lisp nodes
  runnableExamples:
    toLisp (`END_OF_FILE`) # scaped => ("END_OF_FILE")
    toLisp (GEOMETRY, 1, 2, 3, 4) # call => encodeGEOMETRY(1, 2, 3, 4)
    toLisp (`TEXT`, _["t1", "t2"]) # spread => ("TEXT", "t1", "t2")

  toLispImpl body

# --- basics

func encodeObid*(o: Obid): LispNode =
  toLisp (`OBID`, o.string)

func encodeHdlIdent*(id: HdlIdent): LispNode =
  err "not implemented"

func encodeGeometry*(g: Geometry): LispNode =
  toLisp (`GEOMETRY`, g.x1, g.y1, g.x2, g.y2)

func encodeWire*(w: Wire): LispNode =
  toLisp (`WIRE`, w.a.x, w.a.y, w.b.x, w.b.y)

func encodeSide*(s: Side): LispNode =
  toLisp (`SIDE`, s.int)

func encodeAlignment*(a: Alignment): LispNode =
  toLisp (`ALIGNMENT`, a.int)

func encodeDirection*(d: NumberDirection): LispNode =
  toLisp (`DIRECTION`, d.int)

func encodeProperties*(prs: Properties): LispNode =
  result = toLisp (`PROPERTIES`)
  for k, v in prs:
    result.add toLisp (`PROPERTY`, k, v)

func encodeMode*(i: int): LispNode =
  toLisp (`MODE`, i)

func encodeFormat*(f: int): LispNode =
  toLisp (`FORMAT`, f)

func encodeType*(t: int): LispNode =
  toLisp (`TYPE`, t)

func encodeColorFill*(c: EaseColor): LispNode =
  toLisp (`COLOR_FILL`, c.int)

func encodeColorLine*(c: EaseColor): LispNode =
  toLisp (`COLOR_LINE`, c.int)

func encodeObjStamp*(username: string, created, modified: int): LispNode =
  toLisp (`OBJSTAMP`,
    (`DESIGNER`, username),
    (`CREATED`, created, "..."),
    (`MODIFIED`, modified, "..."),
  )

func encodePosition*(pos: Point): LispNode =
  toLisp (`POSITION`, pos.x, pos.y)

func encodeScale*(s: int): LispNode =
  toLisp (`SCALE`, s)

func encodeText*(ss: seq[string]): Option[LispNode] =
  if ss.len != 0:
    let t = ss.map(toLispNode)
    some toLisp (`TEXT`, _ t)
  else:
    none LispNode

# --- compound

func encodeLabel*(lbl: Label): LispNode =
  toLisp (`LABEL`,
    (POSITION, lbl.position),
    (SCALE, lbl.scale),
    (COLOR_LINE, lbl.colorLine),
    (SIDE, lbl.side),
    (ALIGNMENT, lbl.alignment),
    (FORMAT, lbl.format),
    (TEXT, lbl.texts),
  )

func encodeFreePlacedText*(fpt: FreePlacedText): LispNode =
  toLisp (`FREE_PLACED_TEXT`,
    (LABEL, fpt.Label)
  )

func encodeCBN*(cbn: ConnectByName): LispNode =
  err "not implemented"

  toLisp (`CBN`,
    (OBID, cbn.obid),
    # (HDL_IDENT, cbn.ident),
    (GEOMETRY, cbn.geometry),
    # (SIDE, 2),
    # (TYPE, 1),
    (LABEL, cbn.label),
  )



when isMainModule:
  echo encodeGeometry (1, 2, 3, 4)
  echo encodeWire ((1, 3) .. (2, 4))
  echo encodeLabel Label(texts: @["hye", "wow"])
