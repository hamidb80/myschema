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
    discard
