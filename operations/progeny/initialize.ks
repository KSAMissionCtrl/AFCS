// initialize non-volatile variables
set abort to false.
set rdyToHibernate to false.
set isLanded to false.
set chuteSafeSpeed to 450.
set chuteSpeed to 0.
set maxQ to 0.
set hdgHold to 54.
lock pitch to 89.
lock throttle to 1.
set currEC to 0.

// initialize volatile variables
declr("launchTime", 87661800).

// keep track of part status 
lock stageOne to ship:partstagged("srmxl")[0]:getmodule("ModuleEnginesFX"):getfield("status").
lock stageTwo to ship:partstagged("srml")[0]:getmodule("ModuleEnginesFX"):getfield("status").
lock stageThree to ship:partstagged("ospray")[0]:getmodule("ModuleEnginesFX"):getfield("status").
lock armOne to ship:partstagged("support")[0]:getmodule("modulewheeldeployment"):getfield("state").
lock armTwo to ship:partstagged("support")[1]:getmodule("modulewheeldeployment"):getfield("state").
lock armThree to ship:partstagged("support")[2]:getmodule("modulewheeldeployment"):getfield("state").

// get parts now so searching doesn't hold up main program execution
set srb1 to ship:partstagged("srmxl")[0]:getmodule("ModuleEnginesFX").
set s1decoupler to ship:partstagged("s1decoupler")[0]:getmodule("ModuleDecouple").
set s1fins to list(
  ship:partstagged("s1fin")[0]:getmodule("Kaboom"),
  ship:partstagged("s1fin")[1]:getmodule("Kaboom"),
  ship:partstagged("s1fin")[2]:getmodule("Kaboom"),
  ship:partstagged("s1fin")[3]:getmodule("Kaboom")
).
set srb2 to ship:partstagged("srml")[0]:getmodule("ModuleEnginesFX").
set s2decoupler to ship:partstagged("s2decoupler")[0]:getmodule("ModuleDecouple").
set s2fins to list(
  ship:partstagged("s2fin")[0]:getmodule("Kaboom"),
  ship:partstagged("s2fin")[1]:getmodule("Kaboom"),
  ship:partstagged("s2fin")[2]:getmodule("Kaboom"),
  ship:partstagged("s2fin")[3]:getmodule("Kaboom")
).
set lfo to ship:partstagged("ospray")[0]:getmodule("ModuleEnginesFX").
set chute to ship:partstagged("chute")[0]:getmodule("RealChuteModule").
set airbrakes to list(
  ship:partstagged("airbrake")[0]:getmodule("ModuleAeroSurface"),
  ship:partstagged("airbrake")[1]:getmodule("ModuleAeroSurface"),
  ship:partstagged("airbrake")[2]:getmodule("ModuleAeroSurface")
).
set supportArms to list(
  ship:partstagged("support")[0]:getmodule("modulewheeldeployment"),
  ship:partstagged("support")[1]:getmodule("modulewheeldeployment"),
  ship:partstagged("support")[2]:getmodule("modulewheeldeployment")
).
set shrouds to list(
  ship:partstagged("lfoshroud")[0]:getmodule("proceduralfairingdecoupler"),
  ship:partstagged("lfoshroud")[1]:getmodule("proceduralfairingdecoupler")
).
set serviceTower to ship:partstagged("tower")[0]:getmodule("LaunchClamp").

// add any custom logging fields, then call for header write and setup log call
set getter("addlLogData")["Pitch Target"] to {
  return 1.14452E-8 * ship:altitude ^ 2 - 0.00181906 * ship:altitude + 88.6057.
}.
initLog().
function logData {
  logTlm(floor(time:seconds) - getter("launchTime")).
  if ship:status = "SPLASHED" or ship:status = "LANDED" sleepTimers:remove("logData").
}

// determine our max allowable EC drainage
// totalEC / mission time in seconds
set maxECdrain to fullChargeEC / 1500.

// track EC usage per second to ensure we have enough to last the mission at launch
function monitorEcDrain {
  set EClvl to ship:electriccharge.
  if nonRechargeable set ECNRlvl to ship:electricchargenonrechargeable.
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
  set operations["terminalCount"] to terminalCount@.
  set operations["retractSupportArms"] to retractSupportArms@.
  serviceTower:doevent("release clamp").
  set EClvl to ship:electriccharge.
  if nonRechargeable set ECNRlvl to ship:electricchargenonrechargeable.
  else set ECNRlvl to 0.
  set currEC to EClvl+ECNRlvl.
  sleep("monitorEcDrain", monitorEcDrain@, 1, true, true).
  operations:remove("beginTCount").
}

output("Vessel boot up").