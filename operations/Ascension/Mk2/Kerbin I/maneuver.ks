set burnStartUT to 0.
set burnEndUT to 0.

function beginBurn {
  set currThrottle to 1.
  output("Burn starting. Current orbit " + round(ship:apoapsis/1000, 3) + "km x " + round(ship:periapsis/1000, 3) + "km").
  operations:remove("beginBurn").
  sleep("endBurn", endBurn@, burnEndUT, false, false).
}

function endBurn {
  set currThrottle to 0.
  output("Burn complete. New orbit " + round(ship:apoapsis/1000, 3) + "km x " + round(ship:periapsis/1000, 3) + "km").
  operations:remove("endBurn").
}

sleep("beginBurn", beginBurn@, burnStartUT, false, false).
output("Maneuver burn configured").