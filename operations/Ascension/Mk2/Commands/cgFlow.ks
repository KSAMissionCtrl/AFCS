for tank in ship:partstitled("cg-r1 cold gas fuel tank") set tank:resources[0]:enabled to true.
output("Cold gas flow valves open in main Kerbin I tanks").
set getter("addlLogData")["Cold Gas (u)"] to {
  // do not count the amount on the probe's sphere tanks
  return ship:coldgas-240.
}.
