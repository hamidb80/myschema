import std/[sequtils, strutils]
import ../common/[coordination, errors]
import model

func rotation*(orient: Orient): Rotation =
  case orient:
  of R0, RX, RY: r0
  of R90, R90X, R90Y: r90
  of RXY: r180
  of R270: r270

func flips*(orient: Orient): set[Flip] =
  case orient:
  of R0, R90, RXY, R270: {}
  of R90X, RX: {X}
  of R90Y, RY: {Y}


func instancekind*(name: string): InstanceKind =
  case name:
  of "input", "output", "inout": ikPort
  of "name_net", "name_net_s", "name_net_sw", "name_suggested_name": ikNameNet
  else: ikCustom

func dropIndexes(s: string): string =
  ## removes the bracket part from `s`
  ## "id[a:b]" => "id"
  ## "id[a]" => "id"
  ## "id" => "id"

  let i = s.find '['
  if i == -1: s
  else: s[0..<i]

iterator sepIds*(s: string): PortID =
  for w in s.split(','):
    let id = dropIndexes w
    if id.len != 0:
      yield PortID id

func `/`(s1, s2: string): string {.inline.} =
  s1 & '/' & s2

func ids*(port: Port): seq[PortID] =
  case port.parent.kind:
  of ikPort, ikNameNet: toseq sepids(port.parent.name)
  of ikCustom:
    let
      n1 = dropIndexes port.parent.name
      n2 = dropIndexes port.origin.name

    @[PortID n1/n2]


func genTransformer(geo: Geometry, pin: Point, o: Orient): Transfromer =
  let
    r = o.rotation
    f = o.flips
    rotatedGeo = rotate(geo, pin, r)
    vec = pin - topleft geo
    finalGeo = rotatedGeo.placeAt pin
    c = center finalGeo

  return func(p: Point): Point =
    (rotate(p, pin, r) + vec).flip(c, f)


func toOrient*(vd: VectorDirection): Orient =
  case vd:
  of vdEast: R0
  of vdSouth: R90
  of vdWest: RXY
  of vdNorth: R270
  of vdDiagonal: err "orient for diagonal vectors is not defined"

func location*(p: Port): Point
func geometry*(icon: Icon): Geometry =
  var acc: seq[Point]

  for p in icon.ports:
    acc.add p.location

  for l in icon.lines:
    if l.kind == straight:
      for p in l.points:
        acc.add p

  area acc

func location*(p: Port): Point =
  case p.kind:
  of pkIconTerm: p.relativeLocation
  of pkInstance:
    let
      ins = p.parent
      t = genTransformer(
        ins.module.icon.geometry,
        ins.location,
        ins.orient)

    t(p.origin.location + ins.location)
