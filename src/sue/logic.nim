import ../common/domain
import model



func `$`*(pd: PortDir): string =
  case pd:
  of pdInput: "input"
  of pdOutput: "output"
  of pdInout: "inout"


func toArch*(sch: SSchematic): Architecture =
  Architecture(kind: akSchematic, schema: sch)

func toArch*(f: MCodeFile): Architecture =
  Architecture(kind: akFile, schema: SSchematic(), file: f)
