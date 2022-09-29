TODO find why does not compile with 1.6.8

note that some `.sue` files have some problems like invalid white-space or 5 argument for make_wire/make_line

TODO: list broken files with fixes

the following modules are not available:

-  shift
-  memaddrmux
-  pcc
-  pcl
-  inv_s
-  inv
-  count_buf
-  PMOS
-  pl3
-  forwardmux
-  local_buf
-  shift_driver
-  rwmux_driver
-  memarray
-  immmux
-  clock_driver
-  SheetSmall
-  wmux_driver
-  onebit
-  count_mux2
-  zdetector2
-  forwardmux_driver
-  immmux_driver
-  alu_driver
-  name_net
-  endriver
-  NMOS
-  lfsr14
-  ci_min
-  SheetMed
-  memaddrmux_driver
-  name_net_sw
-  Sheet
-  wmux
-  tgate
-  anaSupply
-  pl2
-  rwmux
-  memarray_decoder
-  pcmux
-  srcV


# Ease OBID meaning

| prefix | meaning | element |
| -------|---------|---------|
| `proj` | project | PROJECT_FILE |
| `conf` | config | CONFIGURATION |
| `decl` | declaration | DECLARATION |
| `pack` | package | PACKAGE | PACKAGE_FILE | 
| `lib` | library | DESIGN_FILE |
| `ent` | entity | ENTITY |
| `daig` | diagram | SCHEMATIC, SCHEMATIC, FSM_DIAGRAM |
| `eprt` | entity port | PORT |
| `cprt` | component port | PORT |
| `aprt` | architecture port | PORT |
| `pprt` | process port | PORT |
| `gprt` | generate port | PORT |
| `proc` | process | PROCESS |
| `genb` | generate block | GENERATE |
| `ttab` | truth table | TABLE |
| `thdr` | table header | HEADER |
| `trow` | table row | ROW |
| `cell` | cell | CELL |
| `comp` | component | COMPONENT |
| `ncon` | node connection | CONNECTION |
| `net` | net| NET |
| `nprt` | net part | PART |
| `hook` | Bus ripper| BUS_RIPPER |
| `cbn` | Connect by name | CBN |
| `igen` | instance generic | GENERIC |
| `egen` | entity generic | GENERIC |
| `txt` | File content | FILE, VERILOG_FILE |
| `itxt` | included text	| INCLUDED_TEXT |
| `extf` | External file | - |
| `fsmx` | state machine | STATE_MACHINE_V2 |
| `fsmc` | fsm connections | TO_CONN, FROM_CONN |
| `fsmp` | ? | GLOBAL |
| `fsm` | finiate state machine | FSM |
| `tran` | transition | TRANS_LINE, TRANS_SPLINE |
| `lab` | ? | ACTION, CONDITION |
| `stat` | state | STATE |
| `act` | action | ACTION |
