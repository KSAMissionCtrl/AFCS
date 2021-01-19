// initialize non-volatile variables
set abort to false.
set pitchLimit to 1.5.
set s2AoALimit to 0.5.
set maxQ to 0.
set rdyToHibernate to false.
lock throttle to 1.

// initialize volatile variables
declr("launchTime", 137427000).
declr("radBelt", 0).
declr("innerAlt", 0).
declr("outerAlt", 0).

// keep track of part status 
lock stageOneMain to ship:partstagged("srb1m")[0]:getmodule("ModuleEnginesFX"):getfield("status").
lock stageOneRadial to ship:partstagged("srb1r")[0]:getmodule("ModuleEnginesFX"):getfield("status").
lock stageTwo to ship:partstagged("srb2")[0]:getmodule("ModuleEnginesFX"):getfield("status").
lock stageThree to ship:partstagged("lfo1")[0]:getmodule("ModuleEnginesFX"):getfield("status").
lock radlvl to ship:partstagged("radsense")[0]:getmodule("Sensor"):getfield("Radiation").

// get parts now so searching doesn't hold up main program execution
set s1fins to list(
  ship:partstagged("s1fin")[0]:getmodule("ModuleKaboom"),
  ship:partstagged("s1fin")[1]:getmodule("ModuleKaboom"),
  ship:partstagged("s1fin")[2]:getmodule("ModuleKaboom")
).
set s2fins to list(
  ship:partstagged("s2fin")[0]:getmodule("ModuleKaboom"),
  ship:partstagged("s2fin")[1]:getmodule("ModuleKaboom"),
  ship:partstagged("s2fin")[2]:getmodule("ModuleKaboom")
).
set fairings to list(
  ship:partstagged("fairing")[0]:getmodule("ModuleAnimatedDecoupler"),
  ship:partstagged("fairing")[1]:getmodule("ModuleAnimatedDecoupler")
).

// add any custom logging fields, then call for header write and setup log call
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
  return ship:solidfuel + ship:liquidfuel + ship:oxidizer.
}.
set getter("addlLogData")["Stage Fuel (u)"] to {
  return stage:solidfuel + stage:liquidfuel + stage:oxidizer.
}.
initLog().
function logData {
  logTlm(floor(time:seconds) - getter("launchTime")).
  if ship:status = "SPLASHED" or ship:status = "LANDED" sleepTimers:remove("logData").

  // remove the timer after a final log post engine shutdown on the way up
  // set reference points for future logging during hibernation cycles
  if rdyToHibernate {
    setter("lastLog", floor(time:seconds)).
    setter("lastLink", floor(time:seconds)).
    sleepTimers:remove("datalogger").
  }
}

// determine our max allowable EC drainage
// set to a constant based on previous mission profile
set maxECdrain to 0.2.

// track EC usage per second to ensure we have enough to last the mission at launch
function monitorEcDrain {
  set EClvl to ship:electriccharge.
  if getter("nonRechargeable") set ECNRlvl to ship:electricchargenonrechargeable.
  else set ECNRlvl to 0.
  if currEC - (EClvl+ECNRlvl) >= maxECdrain {
    setAbort(true, "EC drain is excessive at " + round(currEC - (EClvl+ECNRlvl), 3) + "ec/s. Max drain is " + round(maxECdrain, 3) + "ec/s").
    operations:remove("terminalCount").
    operations:remove("monitorEcDrain").
  }
  set currEC to EClvl+ECNRlvl.
}

// start doing battery drain checks and launch timing
function beginTCount {
  output("Terminal count begun, monitoring EC levels").
  set operations["terminalCount"] to terminalCount@.
  set EClvl to ship:electriccharge.
  if getter("nonRechargeable") set ECNRlvl to ship:electricchargenonrechargeable.
  else set ECNRlvl to 0.
  set currEC to EClvl+ECNRlvl.
  sleep("monitorEcDrain", monitorEcDrain@, 1, true, true).
  operations:remove("beginTCount").
}

output("Vessel boot up").