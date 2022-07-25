import std/[sequtils, strutils, strformat, strscans]


type Wire = array[4, int]

func toPolyLine(w: Wire): string =
    fmt"""<polyline points="{w[0]},{w[1]} {w[2]},{w[3]}"  stroke="black" stroke-width="2"/>"""

var wires: seq[Wire]

func fromWire(str: string): Wire =
    if not str.scanf("  make_wire $i $i $i $i", result[0], result[1], result[2], result[3]):
        raise newException(ValueError, "not valid")

for l in lines "grid.sue":
    wires.add:
        try: fromWire l
        except: continue

let lines = wires.map(toPolyLine)
writefile "out.svg", fmt"""
    <svg viewBox="-200 -500 800 800" xmlns="http://www.w3.org/2000/svg">
    <circle cx="0" cy="0" r="2" />
    {lines.join}
    </svg>
    """