import model


func `$`*(pd: PortDir): string =
  case pd:
  of pdInput: "input"
  of pdOutput: "output"
  of pdInout: "inout"
