// initialize variables
set chuteSpeed to 0.
set chuteSafeSpeed to 490.
set maxECdrain to 1.
set currThrottle to 0.1.
set logInterval to 1.
set maxQ to 0.
set hdgHold to 53.
lock pitch to 89.6.
declr("launchTime", 89738460).

// keep track of part status
lock engineStatus to ship:partstagged("lfo")[0]:getmodule("ModuleEnginesFX"):getfield("status").
lock engineThrust to ship:partstagged("lfo")[0]:getmodule("ModuleEnginesFX"):getfield("thrust").
lock lesStatus to ship:partstagged("lesPushUp")[0]:getmodule("ModuleEnginesFX"):getfield("status").
lock lesKickStatus to ship:partstagged("lesKick")[0]:getmodule("ModuleEnginesFX"):getfield("status").

// get parts/resources now so searching doesn't hold up main program execution
set engine to ship:partstagged("lfo")[0]:getmodule("ModuleEnginesFX").
set decoupler to ship:partstagged("decoupler")[0]:getmodule("ModuleDecouple").
set heatshield to ship:partstagged("heatshield")[0]:getmodule("ModuleDecouple").
set lesDecoupler to ship:partstagged("lesTower")[0]:getmodule("ModuleDecouple").
set lesKickMotor to ship:partstagged("lesKick")[0]:getmodule("ModuleEnginesFX").
set lesPushMotorDw to ship:partstagged("lesPushDw")[0]:getmodule("ModuleEnginesFX").
set lesPushMotorUp to ship:partstagged("lesPushUp")[0]:getmodule("ModuleEnginesFX").
set lesPushMotorLeft to ship:partstagged("lesPushLeft")[0]:getmodule("ModuleEnginesFX").
set lesPushMotorRight to ship:partstagged("lesPushRight")[0]:getmodule("ModuleEnginesFX").
set chute to ship:partstagged("chute")[0]:getmodule("RealChuteModule").
set floatCollar to ship:partstagged("float")[0]:getmodule("CL_ControlTool").
set serviceTower to ship:partstagged("tower")[0]:getmodule("LaunchClamp").

// add any custom logging fields, then call for header write and setup log call
set getter("addlLogData")["Total Fuel (u)"] to {
  return ship:liquidfuel + ship:oxidizer.
}.
set getter("addlLogData")["Cold Gas (u)"] to {
  return ship:coldgas.
}.
set getter("addlLogData")["Payload Internal (k)"] to {
  return ship:partstagged("capsule")[0]:getmodule("HotSpotModule"):getfield("Temp [I]"):split(" / ")[0].
}.
set getter("addlLogData")["Payload Surface (k)"] to {
  return ship:partstagged("capsule")[0]:getmodule("HotSpotModule"):getfield("Temp [S]"):split(" / ")[0].
}.
set getter("addlLogData")["Heat Shield Internal (k)"] to {
  if ship:partstagged("heatshield"):length {
    return ship:partstagged("heatshield")[0]:getmodule("HotSpotModule"):getfield("Temp [I]"):split(" / ")[0].
  } else return "N/A".
}.
set getter("addlLogData")["Heat Shield Surface (k)"] to {
  if ship:partstagged("heatshield"):length {
    return ship:partstagged("heatshield")[0]:getmodule("HotSpotModule"):getfield("Temp [S]"):split(" / ")[0].
  } else return "N/A".
}.
initLog().
function logData {
  logTlm(floor(time:seconds) - getter("launchTime")).
  if ship:status = "SPLASHED" or ship:status = "LANDED" sleepTimers:remove("logData").
}

// determine our max allowable EC drainage
// totalEC / mission time in seconds
set maxECdrain to getter("fullChargeEC") / 1536.

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

// retract service tower, start doing battery drain checks and launch timing
function beginTCount {
  output("Terminal count begun, monitoring EC levels").
  serviceTower:doevent("release clamp").
  set operations["terminalCount"] to terminalCount@.
  set EClvl to ship:electriccharge.
  if getter("nonRechargeable") set ECNRlvl to ship:electricchargenonrechargeable.
  else set ECNRlvl to 0.
  set currEC to EClvl+ECNRlvl.
  sleep("monitorEcDrain", monitorEcDrain@, 1, true, true).
  operations:remove("beginTCount").
}

lock throttle to currThrottle.
output("Vessel boot up").