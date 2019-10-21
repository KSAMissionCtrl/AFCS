function payloadDecouple {
  decoupler:doevent("decouple").
  sleep("pushAway", pushAway@, 1, true, false).
  operations:remove("payloadDecouple").
  output("Capsule release @ " + round(ship:altitude, 3) + "km").
}

// maneuver straight away from the tank for 10 seconds
function pushAway {
  rcs on.
  set ship:control:fore to 1.
  sleep("endCoast", endCoast@, 10, true, false).
  operations:remove("pushAway").
}
function endCoast {
  set ship:control:fore to 0.
  unlock steering.
  wait 0.001.
  operations:remove("endCoast").
}

output("Orbital ops loaded").