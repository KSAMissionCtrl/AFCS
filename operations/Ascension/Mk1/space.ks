function payloadDecouple {
  decoupler:doevent("decouple").
  sleep("pushAway", pushAway@, 1, true, false).
  operations:remove("payloadDecouple").
  output("Capsule released @ " + round(ship:altitude/1000, 3) + "km").
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
  wait 0.01.
  operations:remove("endCoast").
  output("RCS push complete, control unlocked").
  when kuniverse:canquicksave then kuniverse:quicksaveto(ship:name + " - Capsule Sep").
  set operations["monitorApokee"] to monitorApokee@.
}

// monitor for apokee and set for re-entry
function monitorApokee {
  if ship:verticalSpeed <= 0 {
    output("Apokee achieved @ " + round(ship:altitude/1000, 3) + "km").
    set operations["saveReturn"] to saveReturn@.
    set operations["reentry"] to reentry@.
    operations:remove("monitorApokee").
  }
}

output("Space ops loaded").