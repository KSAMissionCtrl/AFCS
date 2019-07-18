function payloadDecouple {
  decoupler:doevent("decouple").
  sleep("pushAway", pushAway@, 1, true, false).
  operations:remove("lesAbortMonitor").
  operations:remove("payloadDecouple").
  output("Capsule release @ 100km").
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
  operations:remove("endCoast").
}

output("Orbital ops loaded").