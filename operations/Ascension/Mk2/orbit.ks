set burnStartUT to 0.
set burnEndUT to 0.

function ses2 {
  set currThrottle to 1.
  output("SES-2 @ " + round(ship:altitude/1000, 3) + "km. Orbit is " + round(ship:apoapsis/1000, 3) + "km x " + round(ship:periapsis/1000, 3) + "km").
  when ship:periapsis > 0 then output("Perikee positive!").
  operations:remove("ses2").
  sleep("seco2", seco2@, burnEndUT, false, false).
}

function seco2 {
  set currThrottle to 0.
  output("SECO-2 @ " + round(ship:altitude/1000, 3) + "km. Orbit is " + round(ship:apoapsis/1000, 3) + "km x " + round(ship:periapsis/1000, 3) + "km").
  operations:remove("seco2").
}

sleep("ses2", ses2@, burnStartUT, false, false).
output("Orbital insertion burn configured").