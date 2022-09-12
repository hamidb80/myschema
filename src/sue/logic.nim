import std/[sequtils, strutils, sets, tables]
import ../common/[coordination, graph]
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

iterator sepIds*(s: string): PortId =
  for w in s.split(','):
    let id = dropIndexes w
    if id.len != 0:
      yield PortId id

func `/`(s1, s2: string): string {.inline.} =
  s1 & '/' & s2

func ids*(port: Port): seq[PortId] =
  case port.parent.kind:
  of ikPort, ikNameNet: toseq sepids(port.parent.name)
  of ikCustom:
    let
      n1 = dropIndexes port.parent.name
      n2 = dropIndexes port.origin.name

    @[PortId n1/n2]


type Transfromer = proc(p: Point): Point {.noSideEffect.}

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

func location*(p: Port): Point =
  case p.kind:
  of pkIconTerm: p.relativeLocation
  of pkInstance:
    let
      ins = p.parent
      t = genTransformer(
        toGeometry ins.module.icon.size,
        ins.location,
        ins.orient)

    t(p.origin.location + ins.location)


func fixErrors*(schema: var Schematic) =
  ## fixes connection errors via adding `buffer0` element
  var seen: HashSet[PortId]

  for pid1 in keys schema.connections:

    if pid1 notin seen:

      var 
        hasInput = false
        hasOutput = false

      for pid2 in walk(schema.connections, pid1):


        seen.incl pid2
