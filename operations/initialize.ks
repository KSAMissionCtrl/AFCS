// initialize non-volatile variables
set abort to false.
set maxQ to 0.
set hdgHold to 45.5.
lock throttle to 1.
set currEC to 0.

// initialize volatile variables
declr("launchTime", 95779500).

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
set s2finCtrl to list(
  ship:partstagged("s2fin")[0]:getmodule("FARcontrollablesurface"),
  ship:partstagged("s2fin")[1]:getmodule("FARcontrollablesurface"),
  ship:partstagged("s2fin")[2]:getmodule("FARcontrollablesurface"),
  ship:partstagged("s2fin")[3]:getmodule("FARcontrollablesurface")
).
set lfo to ship:partstagged("ospray")[0]:getmodule("ModuleEnginesFX").
set supportArms to list(
  ship:partstagged("support")[0]:getmodule("modulewheeldeployment"),
  ship:partstagged("support")[1]:getmodule("modulewheeldeployment"),
  ship:partstagged("support")[2]:getmodule("modulewheeldeployment")
).
set shrouds to list(
  ship:partstagged("lfoshroud")[0]:getmodule("proceduralfairingdecoupler"),
  ship:partstagged("lfoshroud")[1]:getmodule("proceduralfairingdecoupler")
).
set fairings to list(
  ship:partstagged("fairing")[0]:getmodule("proceduralfairingdecoupler"),
  ship:partstagged("fairing")[1]:getmodule("proceduralfairingdecoupler")
).
set serviceTower to ship:partstagged("tower")[0]:getmodule("LaunchClamp").

// disable 2nd stage fins for initial ascent
for fin in s2finCtrl fin:setfield("std. ctrl", true).
wait 0.1.
for fin in s2finCtrl fin:setfield("ctrl dflct", 0).

// add any custom logging fields, then call for header write and setup log call
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
}

// determine our max allowable EC drainage
// totalEC / mission time in seconds
set maxECdrain to getter("fullChargeEC") / 885.

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

// retract service tower, start doing battery drain checks and launch timing
function terminalCount {
  output("Terminal count begun, monitoring EC levels").
  serviceTower:doevent("release clamp").
  set EClvl to ship:electriccharge.
  if getter("nonRechargeable") set ECNRlvl to ship:electricchargenonrechargeable.
  else set ECNRlvl to 0.
  set currEC to EClvl+ECNRlvl.
  sleep("monitorEcDrain", monitorEcDrain@, 1, true, true).
  sleep("launch", launch@, getter("launchTime"), false, false).
  sleep("retractSupportArms", retractSupportArms@, getter("launchTime") - 5, false, false).
  operations:remove("terminalCount").
}

output("Vessel boot up").