import std/[tables, sequtils, strutils, options, sugar, macros]
import ../common/[coordination, collections, minitable, domain]
import ../ease/model as em
import ../sue/model as sm

func toSue*(proj: em.Project): sm.Project = 
  discard  