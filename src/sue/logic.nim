import ../common/[domain]
import model

func toArch*(sch: SSchematic): Architecture =
  Architecture(kind: akSchematic, schema: sch)

func toArch*(f: MCodeFile): Architecture =
  Architecture(kind: akFile, schema: SSchematic(), file: f)