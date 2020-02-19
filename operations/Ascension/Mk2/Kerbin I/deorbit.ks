set burnStartUT to 0.

function beginBurn {
  set currThrottle to 1.
  output("Burn commencing").
  when ship:periapsis <= 70000 then output("Atmospheric intercept trajectory achieved").
  operations:remove("beginBurn").
  set operations["endBurn"] to endBurn@.
}

function endBurn {
  if engineStatus = "Flame-Out!" {
    output("Burn complete, fuel expired. Control disabled").
    operations:remove("endBurn").
    unlock steering.
    unlock throttle.
    sas off.
    rcs off.
    when ship:altitude <= 70000 then output("Atmospheric interface breached").
  }
}

sleep("beginBurn", beginBurn@, burnStartUT, false, false).
output("Deorbit burn configured").