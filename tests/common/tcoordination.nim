import std/[unittest]
import src/common/coordination


suite "rotation":
  test "rotate0":
    let p = (-4, -3)

    check rotate0(p, r0) == p
    check rotate0(p, r90) == (3, -4)
    check rotate0(p, r180) == (4, 3)
    check rotate0(p, r270) == (-3, 4)

  test "rotate":
    let
      c1 = (10, 40)
      p1 = (10, 45)
    check p1.rotate(c1, -r90) == (15, 40)
    check p1.rotate(c1, r90) == (5, 40)

    let
      c2 = (8, -7)
      p2 = (5, 1)

    check p2.rotate(c2, r180) == (11, -15)
    check p2.rotate(c2, -r90) == (16, -4)
    check p2.rotate(c2, r90) == (0, -10)

suite "wire direction":
  test "south":
    check dirOf((0, 7) .. (0, 3)) == vdNorth

  test "north":
    check dirOf((0, 3) .. (0, 7)) == vdSouth

  test "west":
    check dirOf((7, 0) .. (3, 0)) == vdWest

  test "east":
    check dirOf((3, 0) .. (7, 0)) == vdEast

suite "flip":
  test "flip nothing":
    check flip((3, 10), (1, 5), {}) == (3, 10)

  test "flip X":
    check flip((3, 10), (1, 5), {X}) == (-1, 10)

  test "flip Y":
    check flip((3, 10), (1, 5), {Y}) == (3, 0)

  test "flip XY":
    check flip((3, 10), (1, 5), {X, Y}) == (-1, 0)
