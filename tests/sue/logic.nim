import std/[unittest]
import src/sue/logic {.all.}
import src/sue/model


test "dropIndexes":
  check:
    dropIndexes("id[a:b]") == "id"
    dropIndexes("id[a]") == "id"
    dropIndexes("id") == "id"

