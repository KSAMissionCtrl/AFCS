set burnStartUT to TBD.
set burnEndUT to TBD.

function ses2 {
  set currThrottle to 1.
  output("SES-2. Orbit is " + round(ship:apoapsis/1000, 3) + "km x " + round(ship:periapsis/1000, 3) + "km").
  operations:remove("ses2").
  set operations["peMonitor"] to peMonitor@.
  sleep("seco2", seco2@, burnEndUT, ABSOLUTE_TIME, PERSIST_N).
}

function peMonitor {
  if ship:periapsis > 0 {
    output("Perikee positive!").
    operations:remove("peMonitor").
  }
}

function seco2 {
  set currThrottle to 0.
  output("SECO-2. Orbit is " + round(ship:apoapsis/1000, 3) + "km x " + round(ship:periapsis/1000, 3) + "km").
  operations:remove("seco2").
  when kuniverse:canquicksave then kuniverse:quicksaveto(ship:name + " - Initial Orbit").
}

sleep("ses2", ses2@, burnStartUT, ABSOLUTE_TIME, PERSIST_N).
output("Orbital insertion burn configured").