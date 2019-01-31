lock radlvl to ship:partstagged("radsense")[0]:getmodule("Sensor"):getfield("Radiation").
set getter("addlLogData")["Rad/hr"] to {
  if radlvl <> "nominal" {
    set radlvl to radlvl:split(" ")[0].
  }
  return radlvl.
}.
function logData {
  logTlm(floor(time:seconds) - getter("launchTime")).
}

// if we are less than a minute to apokee, stay awake through it
if eta:apoapsis < 60 {
  if commCheck("chutecomms") setCommStatus("Activate").
  when ship:verticalspeed <= 0 then {
    output("Apokee achieved @ " + round(ship:altitude/1000, 3) + "km").
    setter("phase", "Apokee").
    logTlm(floor(time:seconds) - getter("launchTime")).
    setter("lastLog", floor(time:seconds)).
    setter("lastLink", floor(time:seconds)).
    hibernate("space", 57).
  }
} else

// if we will be near the atmosphere in the next minute, stay on and go back to 1s logging
// aim for 90km because we will continue to speed up as we fall if waiting another minute
if ship:altitude + (ship:verticalspeed*60) < 90000 {
  setCommStatus("Activate").
  logData().
  sleep("datalogger", logData@, 1, true, true).
  when ship:altitude <= 70000 then {
    if not addons:rt:haskscconnection(ship) setCommStatus("Deactivate").
    output("Atmospheric interface breached").
    runOpsFile("return").
    set operations["chuteDeploy"] to chuteDeploy@.
    setter("phase", "Re-Entry").
  }
}

// otherwise log data and downlink it every 1min
else {
  if commCheck("chutecomms") setCommStatus("Activate").
  when time:seconds - getter("lastLog") >= 60 then {
    logTlm(floor(time:seconds) - getter("launchTime")).
    setter("lastLog", floor(time:seconds)).
    if addons:rt:haskscconnection(ship) setter("lastLink", floor(time:seconds)).
    hibernate("space", 57).
  }
}