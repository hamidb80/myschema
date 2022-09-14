import std/[unittest]

import src/common/[coordination]
import src/ease/logic


suite "icon transformer":
  test "solid":
    let
      geo = (10, 40, 20, 70)
      tr = getIconTransformer(geo, r90)

    check tr((10, 45)) == (5, 10)
    check tr((20, 60)) == (20, 0)