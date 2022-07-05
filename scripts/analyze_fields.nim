import std/[os, strutils, sets, tables]
import ../src/sue/parser
import print


var 
  uniqValuesForFields: array[SueFlags, HashSet[string]]
  customs: Table[string, HashSet[string]]
  fieldsForCommands: array[SueCommands, HashSet[SueFlags]]

iterator expressions(sf: SueFile): SueExpression =
  for expr in sf.icon:
    yield expr

  for expr in sf.schematic:
    yield expr

const
  me = r"C:\Users\HamidB80\Desktop\set4\2-cpu\file\sue\"
  full = r"C:\Users\HamidB80\Desktop\set4"

for path in walkDirRec full:
  if path.endsWith ".sue":
    # echo "\n\n>> ", path, "\n\n"
    let s = parseSue readfile path

    for expr in expressions s:
      for o in expr.options:
        let f = o.flag

        if f == sfCustom:
          if o.field notin customs:
            customs[o.field] = initHashSet[string]()

          customs[o.field].incl o.value

        elif f notin {sfText, sfName, sfLabel, sfOrigin}:
          uniqValuesForFields[f].incl dumpValue o

        fieldsForCommands[expr.command].incl f


# ----------------------------------

print uniqValuesForFields
print customs

for c, fs in fieldsForCommands:
  echo c, ": ", fs
