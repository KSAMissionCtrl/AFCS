// initialize variables
set logInterval to 1.
set maxQ to 0.
set logStart to 0.

// get parts/resources now so searching doesn't hold up main program execution
set botSAS to ship:partstagged("bot")[0]:getmodule("ModuleReactionWheel").

initLog().
function logData {
  logTlm(floor(time:seconds) - logStart).
}
function saveReturn {
  if ship:altitude <= 100000 {
    if kuniverse:canquicksave {
      kuniverse:quicksaveto(ship:name + " - Reentry").
      operations:remove("saveReturn").
    }
  }
}
function reentry {
  if ship:altitude <= 70000 {
    output("Atmospheric interface breached").
    operations:remove("reentry").
    set operations["maxQmonitor"] to maxQmonitor@.
    set operations["maxQcheck"] to maxQcheck@.
    set logStart to floor(time:seconds).
    logData().
    sleep("datalogger", logData@, logInterval, RELATIVE_TIME, PERSIST_Y).
  }
}
function maxQmonitor {
  if ship:q > maxQ {
    set maxQ to ship:q.

    // restart check if Q begins to rise again (unless we are falling)
    if not operations:haskey("maxQcheck") and ship:verticalspeed > 0 set operations["maxQcheck"] to maxQcheck@.
  }
}
function maxQcheck {
  if maxQ > ship:q {
    output("MaxQ: " + round(ship:Q * constant:ATMtokPa, 3) + "kPa @ " + round(ship:altitude/1000, 3) + "km").
    operations:remove("maxQcheck").
  }
}
function apokee {
  if ship:verticalSpeed <= 0 {
    output("Apokee achieved @ " + round(ship:altitude/1000, 3) + "km").
    operations:remove("apokee").
    set operations["saveReturn"] to saveReturn@.
    set operations["reentry"] to reentry@.
  }
}

set operations["apokee"] to apokee@.
output("initialization complete").