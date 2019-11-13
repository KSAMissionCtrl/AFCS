// initialize
set rdyToHibernate to false.
lock radlvl to ship:partstagged("radsense")[0]:getmodule("Sensor"):getfield("Radiation").
set getter("addlLogData")["Rad/hr"] to {
  if radlvl <> "nominal" {
    set outputLvl to radlvl:split(" ")[0].
  } else set outputLvl to radlvl.
  return outputLvl.
}.
set getter("addlLogData")["Total Fuel (u)"] to {
  return 0.
}.
set getter("addlLogData")["Stage Fuel (u)"] to {
  return 0.
}.
function logData {
  logTlm(floor(time:seconds) - getter("launchTime")).
  if ship:status = "SPLASHED" or ship:status = "LANDED" sleepTimers:remove("logData").
  if rdyToHibernate {
    setter("lastLog", floor(time:seconds)).
    setter("lastLink", floor(time:seconds)).
    sleepTimers:remove("datalogger").
  }
}
function beginHibernation {
  operations:remove("beginHibernation").
  hibernate("space", 25, false).
}

function apokee {
  if ship:verticalspeed <= 0 {
    operations:remove("apokee").
    output("Apokee achieved @ " + round(ship:altitude/1000, 3) + "km").
    logTlm(floor(time:seconds) - getter("launchTime")).
    setter("lastLog", floor(time:seconds)).
    setter("lastLink", floor(time:seconds)).
    hibernate("space", 27).
  }
}

function reentry {
  if ship:altitude <= 70000 {
    operations:remove("reentry").
    if not addons:rt:haskscconnection(ship) setCommStatus("Deactivate").
    output("Atmospheric interface breached").
    runOpsFile("return").
    set operations["chuteDeploy"] to chuteDeploy@.
  }
}

function radMonitor {
  if radlvl:split(" ")[0]:tonumber <= 0.010 {
    operations:remove("radMonitor").

    // if we are in belt 1 or 2 save the altitude
    if getter("radBelt") = 1 {
      setter("innerAlt", ship:altitude).
      output("Exited inner radiation belt").
    } else
    if getter("radBelt") = 2 {
      setter("outerAlt", ship:altitude).
      output("Exited outer radiation belt").
    } else

    // belt 3 & 4 is on the way down, make sure we can't call again by lowering altitude below 0
    if getter("radBelt") = 3 {
      setter("outerAlt", -50000).
      output("Exited outer radiation belt").
    } else
    if getter("radBelt") = 4 {
      setter("outerAlt", -50000).
      output("Exited inner radiation belt").
    }

    // give the logger time to do one last entry then return to hibernation
    sleep("beginHibernation", beginHibernation@, 2, true, false).
    set rdyToHibernate to true.
  }
}

function datalog {
  if time:seconds - getter("lastLog") >= 30 {
    operations:remove("datalog").
    logTlm(floor(time:seconds) - getter("launchTime")).
    setter("lastLog", floor(time:seconds)).
    if addons:rt:haskscconnection(ship) setter("lastLink", floor(time:seconds)).
    hibernate("space", 27).
  }
}

// if we are less than a 30s to apokee, stay awake through it
if eta:apoapsis < 30 {
  if commCheck("chutecomms") setCommStatus("Activate").
  set operations["apokee"] to apokee@.
} else

// if we will be near the atmosphere in the next 30s, stay on and go back to 1s logging
// aim for 90km because we will continue to speed up as we fall if waiting another 30s
if ship:altitude + (ship:verticalspeed*30) < 90000 {
  setCommStatus("Activate").
  logData().
  sleep("datalogger", logData@, 1, true, true).
  set operations["reentry"] to reentry@.
} else

// if we are headed down, check if we will reach the upper radiation belt in the next 30s
// use a 10km buffer zone
if ship:verticalspeed < 0 and ship:altitude + (ship:verticalspeed*30) < getter("outerAlt") + 10000 {
  if commCheck("chutecomms") setCommStatus("Activate").
  logData().
  sleep("datalogger", logData@, 1, true, true).
  set operations["radMonitor"] to radMonitor@.
  output("Entered outer radiation belt").
  setter("radBelt", getter("radBelt") + 1).
} else

// if we are headed down, check if we will reach the inner radiation belt in the next 30s
// use a 30km buffer zone since we're moving faster by now
if ship:verticalspeed < 0 and ship:altitude + (ship:verticalspeed*30) < getter("outerAlt") + 30000 {
  if commCheck("chutecomms") setCommStatus("Activate").
  logData().
  sleep("datalogger", logData@, 1, true, true).
  set operations["radMonitor"] to radMonitor@.
  output("Entered outer radiation belt").
  setter("radBelt", getter("radBelt") + 1).
} else

// if we are in a high radiation region, stay on until we exit it
if radlvl:split(" ")[0]:tonumber > 0.010 {
  if commCheck("chutecomms") setCommStatus("Activate").
  logData().
  sleep("datalogger", logData@, 1, true, true).
  set operations["radMonitor"] to radMonitor@.

  // which belt are we in?
  setter("radBelt", getter("radBelt") + 1).
  if getter("radBelt") = 1 output("Entered inner radiation belt").
  if getter("radBelt") = 2 output("Entered outer radiation belt").
}

// otherwise log data and downlink it every 1min
else {
  if commCheck("chutecomms") setCommStatus("Activate").
  set operations["datalog"] to datalog@.
}