import std/[tables, sugar, sets]

import model
import ../common/[coordination, domain, collections, errors, graph]

func toNets*(wires: seq[Wire]): seq[MNet]
iterator segments*(net: MNet): Segment =
  ## returns segmented net :: a single Wire

func detectDir*(w: Wire): VectorDirection =
  if w.a.x == w.b.x: # horizobtal
    if w.a.y > w.b.y: vdSouth
    else: vdNorth

  elif w.a.y == w.b.y: # horizobtal
    if w.a.x > w.b.x: vdWest
    else: vdEast

  else:
    err "invalid direction"
