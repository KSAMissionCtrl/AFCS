lock throttle to currThrottle.
wait 0.01.
lfo:doevent("activate engine").
wait 0.1.
if stageTwo = "Flame-Out!" and throttle > 0 {
  setAbort(true, "L/FO ignition failure").
}
else if stageTwo = "Flame-Out!" and throttle > 0 {
  setAbort(true, "L/FO ignition failure, throttle failed to open").
} else {
  output("MES-2 @ " + round(ship:altitude/1000, 3) + "km").
  for batt in batts if batt:hasevent("Disconnect Battery") batt:doevent("Disconnect Battery").
  set operations["MECO2"] to MECO2@.
}

function MECO2 {
  if stageTwo ="Flame-Out!" {
    output("MECO-2 @ " + round(ship:altitude/1000, 3) + "km").
    for batt in batts if batt:hasevent("Connect Battery") batt:doevent("Connect Battery").
    operations:remove("MECO2").
    unlock throttle.
  }
}