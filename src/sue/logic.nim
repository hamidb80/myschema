import std/[sequtils, strutils, sets]
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


func fixErrors*(sch: var Schematic) =
  ## fixes connection errors via adding `buffer0` element
  var seen: HashSet[PortId]

  # for ins in sch.instances:
  #   for pid in
