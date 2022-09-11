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


func normalizeModuleName(originalName: string): string = 
  case originalName:
  of "name-net", "name-net_s", "name-net_sw", "name-suggested_name": "name-net"
  else: originalName

func absoluteName(s: string): string = 
  ## "id[]" => "id"

func id*(p: Port): PortId = 
  # TODO consider multi ident, like: `a,b[0],c[2:0]`
  PortId(
    ident: absoluteName p.origin.name, 
    elem: normalizeModuleName p.parent.name)