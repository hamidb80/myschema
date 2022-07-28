import std/[options, strtabs, strutils]

import model
import ../common/[coordination, errors, domain]

func identifier*(p: Port): Identifier =
  let cn = p.ident.attributes.constraint
  
  if isSome cn:
    case cn.get.kind:
    of ckIndex: 
      result = Identifier(kind: ikIndex,
        index: cn.get.index)
      
    of ckRange: 
      result = Identifier(kind: ikRange,
        indexes: cn.get.`range`.indexes,
        direction: cn.get.`range`.direction)

  else: 
    result = Identifier(kind: ikSingle)

  result.name = p.ident.name
  

func position*(p: Port): Point =
  result.x = (p.geometry.x1 + p.geometry.x2) div 2
  result.y = (p.geometry.y1 + p.geometry.y2) div 2

func mode*(p: Port): PortMode =
  PortMode p.ident.attributes.mode.get

func rotation*(c: Component): Rotation =
  Rotation (int c.side) * 90

type Element = Component or Process or GenerateBlock

func flips*[T: Element](element: T): set[Flip] =
  # vertical = 1
  # horizontal = 2
  # both = 3

  let f = element.properties.getOrDefault("Flip", "0").parseInt
  case f:
  of 0: {}
  of 1: {Y}
  of 2: {X}
  of 3: {X, Y}
  else: err fmt"invalid Flip code: '{f}'"
