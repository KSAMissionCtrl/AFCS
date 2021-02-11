set burnStartUT to TBD.

function startLogging {
  logData().
  sleep("datalogger", logData@, logInterval, RELATIVE_TIME, PERSIST_Y).
  operations:remove("startLogging").
}

function ses3 {
  set currThrottle to 1.
  output("SES-3 @ " + round(ship:altitude/1000, 3) + "km").
  operations:remove("ses3").
  set operations["seco3"] to seco3@.
  set operations["peMonitor"] to peMonitor@.
}

function peMonitor {
  if ship:periapsis <= 70000 {
    output("Atmospheric intercept trajectory achieved").
    operations:remove("peMonitor").
  }
}

function seco3 {
  if s2engineStatus = "Flame-Out!" {
    output("SECO-3 @ " + round(ship:altitude/1000, 3) + "km. Control disabled").
    operations:remove("seco3").
    unlock steering.
    unlock throttle.
    sas off.
    rcs off.
    set operations["atmoMonitor"] to atmoMonitor@.
    when kuniverse:canquicksave then kuniverse:quicksaveto(ship:name + " - Deorbit").
  }
}

function atmoMonitor {
  if ship:altitude <= 70000 {
    output("Atmospheric interface breached").
    operations:remove("atmoMonitor").
  }
}

sleep("ses3", ses3@, burnStartUT, ABSOLUTE_TIME, PERSIST_N).
sleep("startLogging", startLogging@, burnStartUT-1, ABSOLUTE_TIME, PERSIST_N).
output("Deorbit burn configured").