set burnStartUT to 134481644.521455-51.37137.
set burnEndUT to 134481644.521455+49.12993.
set startTime to 0.

function startTlm {
  initLog().
  set startTime to floor(time:seconds).
  tlmLog().
  sleep("datalogger", tlmLog@, logInterval, RELATIVE_TIME, PERSIST_Y).
  operations:remove("startTlm").
}
function tlmLog {
  logTlm(floor(time:seconds) - startTime).
}

function beginBurn {
  set currThrottle to 1.
  output("Maneuver started. Current orbit " + round(ship:apoapsis/1000) + "km x " + round(ship:periapsis/1000) + "km").
  operations:remove("beginBurn").
  sleep("endBurn", endBurn@, burnEndUT, ABSOLUTE_TIME, PERSIST_N).
}

function endBurn {
  set currThrottle to 0.
  output("Maneuver complete. New orbit " + round(ship:apoapsis/1000) + "km x " + round(ship:periapsis/1000) + "km").
  when kuniverse:canquicksave then kuniverse:quicksaveto(ship:name + " - De-Orbit Burn").
  operations:remove("endBurn").
  sas off.
  rcs on.
  lock steering to vcrs(ship:velocity:orbit, -body:position).
  output("RCS enabled, orienting normal").
  set operations["radialNormal"] to radialNormal@.
  set operations["coldGasMonitor"] to coldGasMonitor@.
  set operations["decouple"] to decouple@.
  set operations["monitorLOS"] to monitorLOS@.
}

sleep("beginBurn", beginBurn@, burnStartUT, ABSOLUTE_TIME, PERSIST_N).
sleep("startTlm", startTlm@, burnStartUT-5, ABSOLUTE_TIME, PERSIST_N).
output("Maneuver burn configured").