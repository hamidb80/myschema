import std/[os, strutils, sets, tables]
import ../src/sue/defs
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
  customMakeFields: Table[string, HashSet[string]]

  uniqValuesForFields: array[SueFlag, HashSet[string]]
  uniqValuesForFieldsPerCommands: array[SueCommand, array[SueFlag, HashSet[string]]]

  fieldsForCommands: array[SueCommand, set[SueFlag]]
  uniqFieldsForCommands: array[SueFlag, set[SueCommand]]

for path in walkDirRec dir:
  if path.endsWith ".sue":
    echo ">> ", path
    let s = parseSue readfile path

    for expr in expressions s:
      let c = expr.command

      for o in expr.options:
        let f = o.flag

        if f == sfCustom:
          if o.field notin customMakeFields:
            customMakeFields[o.field] = initHashSet[string]()

          customMakeFields[o.field].incl dumpValue o

        elif f notin {sfText, sfName, sfLabel, sfOrigin}:
          uniqValuesForFields[f].incl dumpValue o
          uniqValuesForFieldsPerCommands[c][f].incl o.dumpValue

        uniqFieldsForCommands[f].incl c
        fieldsForCommands[c].incl f


template double(something): untyped =
  for c, fs in something:
    echo c, ": ", fs

print customMakeFields
print "----------"
double uniqFieldsForCommands
print "----------"

for field, cmdVals in uniqValuesForFieldsPerCommands:
  stdout.write field, ": "
 
  for cmd, vals in cmdvals:
    if vals.len != 0:
      stdout.write (cmd, vals), " "

  stdout.write "\n"

print "----------"
double fieldsForCommands
print "----------"
double uniqValuesForFields
