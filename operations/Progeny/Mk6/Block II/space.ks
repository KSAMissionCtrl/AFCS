// initialize
set rdyToHibernate to false.
lock radlvl to ship:partstagged("radsense")[0]:getmodule("Sensor"):getfield("Radiation").
set getter("addlLogData")["mrad/hr"] to {
  set data to "N/A".
  if radlvl = "nominal" set data to 0.
  else {
    
    // convert from rad/h to mrad/h if needed
    if radlvl:split(" ")[1] = "mrad/h" set data to radlvl:split(" ")[0].
    else set data to radlvl:split(" ")[0]:tonumber() * 1000.
  }
  return data.
}.
set getter("addlLogData")["Total Fuel (u)"] to {
  return 0.
}.
set getter("addlLogData")["Stage Fuel (u)"] to {
  return 0.
}.
function logData {
  parameter met is getter("launchTime").
  logTlm(floor(time:seconds) - met).
  if ship:status = "SPLASHED" or ship:status = "LANDED" sleepTimers:remove("logData").
  if rdyToHibernate {
    setter("lastLog", floor(time:seconds)).
    setter("lastLink", floor(time:seconds)).
    sleepTimers:remove("datalogger").
  }
}
function beginHibernation {
  operations:remove("beginHibernation").
  hibernate("space", 50).
}

function apokee {
  if ship:verticalspeed <= 0 {
    operations:remove("apokee").
    output("Apokee achieved @ " + round(ship:altitude/1000, 3) + "km").
    logTlm(floor(time:seconds) - getter("launchTime")).
    setter("lastLog", floor(time:seconds)).
    setter("lastLink", floor(time:seconds)).
    
    // if we didn't make the outer belt, skip the count
    if getter("radBelt") = 1 setter("radBelt", 3).
    hibernate("space", 50).
  }
}

function reentry {
  if ship:altitude <= 70000 {
    operations:remove("reentry").
    output("Atmospheric interface breached").
    runOpsFile("return").
    set operations["chuteDeploy"] to chuteDeploy@.
  }
}

function radApokee {
  // check if we pass through apokee while in a belt
  if ship:verticalspeed <= 0 {
    operations:remove("radApokee").
    output("Apokee achieved @ " + round(ship:altitude/1000, 3) + "km").
  }
}

function radMonitor {
  if (radlvl:split(" ")[1] = "rad/h" and radlvl:split(" ")[0]:tonumber <= 0.014) or (radlvl:split(" ")[1] = "mrad/h" and radlvl:split(" ")[0]:tonumber < 4) {
    operations:remove("radMonitor").

    // if we are in belt 1 or 2 save the altitude
    if getter("radBelt") = 1 {
      setter("innerAlt", ship:altitude).
      output("Exited inner radiation belt @ " + round(ship:altitude/1000, 3) + "km").
    } else
    if getter("radBelt") = 2 {
      setter("outerAlt", ship:altitude).
      output("Exited outer radiation belt @ " + round(ship:altitude/1000, 3) + "km").
    } else

    // belt 3 & 4 is on the way down, make sure we can't call again by lowering altitude below 0
    if getter("radBelt") = 3 {
      setter("outerAlt", -50000).
      output("Exited outer radiation belt @ " + round(ship:altitude/1000, 3) + "km").
    } else
    if getter("radBelt") = 4 {
      setter("innerAlt", -50000).
      output("Exited inner radiation belt @ " + round(ship:altitude/1000, 3) + "km").
    }

    // give the logger time to do one last entry then return to hibernation
    sleep("beginHibernation", beginHibernation@, 2, true, false).
    set rdyToHibernate to true.
  }
}

function datalog {
  if time:seconds - getter("lastLog") >= 60 {
    operations:remove("datalog").
    logTlm(floor(time:seconds) - getter("launchTime")).
    setter("lastLog", floor(time:seconds)).
    if checkCommLink() setter("lastLink", floor(time:seconds)).
    hibernate("space", 50).
  }
}

// if we are less than 60s to apokee, stay awake through it
if eta:apoapsis < 60 {
  set operations["apokee"] to apokee@.
} else

// if we will be near the atmosphere in the next 60s, stay on and go back to 1s logging
// aim for 100km because we will continue to speed up as we fall if waiting another 60s
if ship:altitude + (ship:verticalspeed*60) < 100000 {
  logData(floor(time:seconds)).
  sleep("datalogger", logData@, 1, true, true).
  set operations["reentry"] to reentry@.
  output("Preparing for re-entry").
} else

// if we are headed down, check if we will reach the upper radiation belt in the next 60s
// use a 10km buffer zone
if ship:verticalspeed < 0 and getter("radBelt") > 1 and ship:altitude + (ship:verticalspeed*60) < getter("outerAlt") + 10000 {
  logData().
  sleep("datalogger", logData@, 1, true, true).
  set operations["radMonitor"] to radMonitor@.
  output("Preparing to enter outer radiation belt @ " + round(ship:altitude/1000, 3) + "km").
  setter("radBelt", getter("radBelt") + 1).
} else

// if we are headed down, check if we will reach the inner radiation belt in the next 60s
// use a 30km buffer zone since we're moving faster by now
if ship:verticalspeed < 0 and ship:altitude + (ship:verticalspeed*60) < getter("innerAlt") + 30000 {
  logData().
  sleep("datalogger", logData@, 1, true, true).
  set operations["radMonitor"] to radMonitor@.
  output("Preparing to enter inner radiation belt @ " + round(ship:altitude/1000, 3) + "km").
  setter("radBelt", getter("radBelt") + 1).
} else

// if we are in a high radiation region, stay on until we exit it
if radlvl:split(" ")[1] = "rad/h" and radlvl:split(" ")[0]:tonumber > 0.014 {
  logData().
  sleep("datalogger", logData@, 1, true, true).
  set operations["radMonitor"] to radMonitor@.

  // which belt are we in?
  setter("radBelt", getter("radBelt") + 1).
  if getter("radBelt") = 1 output("Entered inner radiation belt @ " + round(ship:altitude/1000, 3) + "km").
  if getter("radBelt") = 2 output("Entered outer radiation belt @ " + round(ship:altitude/1000, 3) + "km").
}

// otherwise log data and downlink it every 1min
else {
  set operations["datalog"] to datalog@.
}