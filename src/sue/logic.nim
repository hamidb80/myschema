import ../common/[domain]
import model

func toArch*(sch: Schematic): Architecture =
  Architecture(kind: akSchematic, schema: sch)

func toArch*(f: MCodeFile): Architecture =
  Architecture(kind: akFile, file: f)