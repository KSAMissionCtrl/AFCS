set burnStartUT to 0.

function ses3 {
  set currThrottle to 1.
  output("SES-3 @ " + round(ship:altitude/1000, 3) + "km").
  when ship:periapsis <= 70000 then output("Atmospheric intercept trajectory achieved").
  operations:remove("ses3").
  set operations["seco3"] to seco3@.
}

function seco3 {
  if s2engineStatus = "Flame-Out!" {
    output("SECO-3 @ " + round(ship:altitude/1000, 3) + "km. Control disabled").
    operations:remove("seco3").
    unlock steering.
    unlock throttle.
    sas off.
    rcs off.
    when ship:altitude <= 70000 then output("Atmospheric interface breached").
  }
}

sleep("ses3", ses3@, burnStartUT, false, false).
output("Deorbit burn configured").