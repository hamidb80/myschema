import std/[os, strutils, sets, tables]
import ../src/sue/[lexer]
import ./utils
import print

# ----------------------------------

const dir = r"C:\Users\HamidB80\Desktop\set4"

var
  customMakeFields: Table[string, HashSet[string]]

  uniqValuesForFields: array[SueFlag, HashSet[string]]
  uniqValuesForFieldsPerCommands: array[SueCommand, array[SueFlag, HashSet[string]]]

  fieldsForCommands: array[SueCommand, set[SueFlag]]
  uniqFieldsForCommands: array[SueFlag, set[SueCommand]]


searchSueFiles dir:
  echo ">> ", path
do:
  discard
do:
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

# ---------------------------

template double(something): untyped =
  for c, fs in something:
    echo c, ": ", fs

func filterKV[Idx; T](s: array[Idx, T]): seq[(Idx, T)] =
  for k, values in s:
    if values.len != 0:
      result.add (k, values)

print customMakeFields
print "----------"
double uniqFieldsForCommands
print "----------"
for field, cmdVals in uniqValuesForFieldsPerCommands:
  echo field, ": ", cmdvals.filterKV
print "----------"
double fieldsForCommands
print "----------"
double uniqValuesForFields
