import std/[sequtils, strutils]
import ../common/[coordination]
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


const nameNet = "name_net"

func normalizeModuleName(originalName: string): string =
  case originalName:
  of "name_net", "name_net_s", "name_net_sw", "name_suggested_name": nameNet
  else: originalName

func pureName(s: string): string =
  ## removes the bracket part from `s`
  ## "id[a:b]" => "id"
  ## "id[a]" => "id"
  ## "id" => "id"

  let i = s.find '['
  if i == -1: s
  else: s[0..<i]

func id*(p: Port): PortId =
  PortId(
    ident: pureName p.origin.name,
    elem: normalizeModuleName p.parent.name)

func id(p: string): PortId =
  PortId(ident: p, elem: nameNet)

func ids*(s: string): seq[PortId] =
  s.split(',').mapit(id pureName it)
