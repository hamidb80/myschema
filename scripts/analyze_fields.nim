import std/[os, strutils, sets, tables]
import ../src/sue/parser
import print


iterator expressions(sf: SueFile): SueExpression =
  for expr in sf.icon:
    yield expr

  for expr in sf.schematic:
    yield expr

const dir = r"C:\Users\HamidB80\Desktop\set4"

# ----------------------------------

var
  uniqValuesForFields: array[SueFlags, HashSet[string]]
  customMakeFields: Table[string, HashSet[string]]
  fieldsForCommands: array[SueCommands, HashSet[SueFlags]]

for path in walkDirRec dir:
  if path.endsWith ".sue":
    # echo ">> ", path
    let s = parseSue readfile path

    for expr in expressions s:
      for o in expr.options:
        let f = o.flag

        if f == sfCustom:
          if o.field notin customMakeFields:
            customMakeFields[o.field] = initHashSet[string]()

          customMakeFields[o.field].incl o.value

        elif f notin {sfText, sfName, sfLabel, sfOrigin}:
          uniqValuesForFields[f].incl dumpValue o

        fieldsForCommands[expr.command].incl f


print uniqValuesForFields
print customMakeFields
for c, fs in fieldsForCommands:
  echo c, ": ", fs
