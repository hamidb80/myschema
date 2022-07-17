based on `Ease 8.0 rev4` and `SUE MMI 4.4.0`


note that some `.sue` files have some problems like invalid white-space

TODO: list broken files with fixes

we first convert both to SVG as middle format

the following modules are not available:
```nim

usedModeles - availableModules=[
  "shift",
  "memaddrmux",
  "pcc",
  "pcl",
  "inv_s",
  "inv",
  "count_buf",
  "PMOS",
  "pl3",
  "forwardmux",
  "local_buf",
  "shift_driver",
  "rwmux_driver",
  "memarray",
  "immmux",
  "clock_driver",
  "SheetSmall",
  "wmux_driver",
  "onebit",
  "count_mux2",
  "zdetector2",
  "forwardmux_driver",
  "immmux_driver",
  "alu_driver",
  "name_net",
  "endriver",
  "NMOS",
  "lfsr14",
  "ci_min",
  "SheetMed",
  "memaddrmux_driver",
  "name_net_sw",
  "Sheet",
  "wmux",
  "tgate",
  "anaSupply",
  "pl2",
  "rwmux",
  "memarray_decoder",
  "pcmux",
  "srcV"
]

```

obids:
- `proj`: project (PROJECT_FILE)
- `pack`: package (PROJECT_FILE->PACKAGE | PACKAGE_FILE)
- `lib`: library (DESIGN_FILE)
- `ent`: entity (ENTITY_FILE->ENTITY)
- `Arch`/`arch`: architecture (ARCH_DEFINITION)

- `eprt`: entity port (ENTITY->PORT)
- `cprt`: component port (COMPONENT->PORT)
- `aprt`: architecture port (ARCH_DEFINITION->PORT)
- `nprt`: net port (NET->PART->PORT)
- `pprt`: process port (PROCESS->PORT)
- `gprt`: generate port (GENERATE->PORT)

- `proc`: process (PROCESS)
- `genb`: generate block

- `ttab`: truth table (TABLE)
- `thdr`: table header (HEADER)
- `trow`: table row (ROW)
- `cell`: cell (CELL)

- `Comp`/`comp`: component [instance of a block] (COMPONENT)
- `ncon`: node connection (CONNECTION)
- `net`: net (NET)

- `hook`: bus ripper (BUS_RIPPER)
- `cbn`: connect by name (CBN)

- `igen`: instance generic (GENERIC)
- `egen`: entity generic (GENERIC)

- `file`: file content (VHDL_FILE)
- `itxt`: included text (FSM_DIAGRAM->INCLUDED_TEXT)
- `extf`: external file

- `fsm`: (STATE_MACHINE_V2 | TRANS_LINE/TRANS_SPLINE->[FROM_CONN, TO_CONN] | GLOBAL)
- `diag`: diagram (SCHEMATIC | FSM_DIAGRAM)
- `tran`: transition (TRANS_LINE | TRANS_SPLINE)
- `decl`: (FSM_DIAGRAM->DECLARATION)
- `lab`: ??? (ACTION | CONDITION)
- `stat`: state (STATE)
- `lab`: (ACTION | CONDITION)
- `act`: action (ACTION)
