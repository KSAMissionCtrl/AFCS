// initialize variables
set currThrottle to 0.1.
set logInterval to 1.
set maxQ to 0.
set hdgHold to 45.
lock pitch to 89.6.
set ctrlCheckComplete to false.
declr("launchTime", 105889020).

// keep track of part status
lock engineStatus to ship:partstagged("lfo")[0]:getmodule("ModuleEnginesFX"):getfield("status").
lock engineThrust to ship:partstagged("lfo")[0]:getmodule("ModuleEnginesFX"):getfield("thrust").

// get parts/resources now so searching doesn't hold up main program execution
set engine to ship:partstagged("lfo")[0]:getmodule("ModuleEnginesFX").
set serviceTower to ship:partstagged("tower")[0]:getmodule("LaunchClamp").
set launchClamp to ship:partstagged("clamp")[0]:getmodule("launchClamp").
set decoupler to ship:partstagged("plfbase")[0]:getmodule("moduleDecouple").
set fairings to list(
  ship:partstagged("plf")[0]:getmodule("proceduralfairingdecoupler"),
  ship:partstagged("plf")[1]:getmodule("proceduralfairingdecoupler")
).

// add any custom logging fields, then call for header write and setup log call
set getter("addlLogData")["Total Fuel (u)"] to {
  return ship:liquidfuel + ship:oxidizer.
}.
set getter("addlLogData")["PLF1 Surface (k)"] to {
  if ship:partstagged("plf"):length {
    return ship:partstagged("plf")[0]:getmodule("HotSpotModule"):getfield("Temp [S]"):split(" / ")[0].
  } else return "N/A".
}.
set getter("addlLogData")["PLF1 Internal (k)"] to {
  if ship:partstagged("plf"):length {
    return ship:partstagged("plf")[0]:getmodule("HotSpotModule"):getfield("Temp [I]"):split(" / ")[0].
  } else return "N/A".
}.
set getter("addlLogData")["PLF2 Surface (k)"] to {
  if ship:partstagged("plf"):length {
    return ship:partstagged("plf")[1]:getmodule("HotSpotModule"):getfield("Temp [S]"):split(" / ")[0].
  } else return "N/A".
}.
set getter("addlLogData")["PLF2 Internal (k)"] to {
  if ship:partstagged("plf"):length {
    return ship:partstagged("plf")[1]:getmodule("HotSpotModule"):getfield("Temp [I]"):split(" / ")[0].
  } else return "N/A".
}.
set getter("addlLogData")["RTG Internal (k)"] to {
  if ship:partstagged("rtg"):length {
    return ship:partstagged("rtg")[0]:getmodule("HotSpotModule"):getfield("Temp [I]"):split(" / ")[0].
  } else return "N/A".
}.
set getter("addlLogData")["RTG Surface (k)"] to {
  if ship:partstagged("rtg"):length {
    return ship:partstagged("rtg")[0]:getmodule("HotSpotModule"):getfield("Temp [S]"):split(" / ")[0].
  } else return "N/A".
}.
set getter("addlLogData")["Fuel Flow Rate (mT/s)"] to {
  if ship:partstagged("lfo"):length {
    return ship:partstagged("lfo")[0]:getmodule("ModuleEnginesFX"):getfield("fuel flow") * 0.005.
  } else return "N/A".
}.
initLog().
function logData {
  logTlm(floor(time:seconds) - getter("launchTime")).
  if ship:status = "SPLASHED" or ship:status = "LANDED" sleepTimers:remove("logData").
}

// determine our max allowable EC drainage
// totalEC / mission time in seconds
set maxECdrain to getter("fullChargeEC") / 500.

// track EC usage per second to ensure we have enough to last the mission at launch
function monitorEcDrain {
  set EClvl to ship:electriccharge.
  if getter("nonRechargeable") set ECNRlvl to ship:electricchargenonrechargeable.
  else set ECNRlvl to 0.
  if currEC - (EClvl+ECNRlvl) >= maxECdrain {
    setAbort(true, "EC drain is excessive at " + round(currEC - (EClvl+ECNRlvl), 3) + "ec/s. Max drain is " + round(maxECdrain, 3) + "ec/s").
    operations:remove("monitorEcDrain").
  }
  set currEC to EClvl+ECNRlvl.
}

// retract service tower, start doing battery drain checks, ignition timing and set for control check
function terminalCount {
  output("Terminal count begun, monitoring EC levels").
  serviceTower:doevent("release clamp").
  set EClvl to ship:electriccharge.
  if getter("nonRechargeable") set ECNRlvl to ship:electricchargenonrechargeable.
  else set ECNRlvl to 0.
  set currEC to EClvl+ECNRlvl.
  sleep("monitorEcDrain", monitorEcDrain@, 1, true, true).
  sleep("ignition", ignition@, getter("launchTime") - 6, false, false).
  sleep("ctrlCheckStart", ctrlCheckStart@, getter("launchTime") - 10, false, false).
  operations:remove("terminalCount").
}

lock throttle to currThrottle.
output("Vessel boot up").