// initialize non-volatile variables
set launchAbort to false.
set maxQ to 0.
set hdgHold to 34.
lock currthrottle to 1.
lock pitch to 89.8.
set currEC to 0.
set currStage to 1.
set logInterval to 1.

// initialize volatile variables
declr("launchTime", 130254300).

// keep track of part status 
lock stageOne to ship:partstagged("btron2")[0]:getmodule("ModuleEnginesFX"):getfield("status").
lock stageTwo to ship:partstagged("ospray")[0]:getmodule("ModuleEnginesFX"):getfield("status").
lock armOne to ship:partstagged("support")[0]:getmodule("modulewheeldeployment"):getfield("state").
lock armTwo to ship:partstagged("support")[1]:getmodule("modulewheeldeployment"):getfield("state").
lock armThree to ship:partstagged("support")[2]:getmodule("modulewheeldeployment"):getfield("state").
lock armFour to ship:partstagged("support")[3]:getmodule("modulewheeldeployment"):getfield("state").

// get parts now so searching doesn't hold up main program execution
set srb to ship:partstagged("btron2")[0]:getmodule("ModuleEnginesFX").
set decoupler to ship:partstagged("decoupler")[0]:getmodule("ModuleDecouple").
set lfo to ship:partstagged("ospray")[0]:getmodule("ModuleEnginesFX").
set supportArms to ship:partstagged("support")[0]:getmodule("modulewheeldeployment").
set serviceTower to ship:partstagged("tower")[0]:getmodule("LaunchClamp").
set launchClamp to ship:partstagged("clamp")[0]:getmodule("LaunchClamp").
set s1Chute to ship:partstagged("s1chute")[0]:getmodule("RealChuteModule").
set probeCore to processor("bot").
set payloadDecoupler to ship:partstagged("payloadbase")[0]:getmodule("moduleDecouple").
set probeComms to ship:partstagged("probeComm")[0]:getmodule("ModuleDeployableAntenna").
set rtg to ship:partstagged("rtg")[0]:getmodule("ModuleAnimateGeneric").
set batts to list(
  ship:partstagged("batt")[0]:getmodule("ModuleResourceConverter"),
  ship:partstagged("batt")[1]:getmodule("ModuleResourceConverter")
).
set shrouds to list(
  ship:partstagged("lfoshroud")[0]:getmodule("ProceduralFairingDecoupler"),
  ship:partstagged("lfoshroud")[1]:getmodule("ProceduralFairingDecoupler")
).
set fairings to list(
  ship:partstagged("plf")[0]:getmodule("ProceduralFairingDecoupler"),
  ship:partstagged("plf")[1]:getmodule("ProceduralFairingDecoupler")
).

// set the probe's boot & init files, copy them over and shut it down
set probeCore:bootfilename to "boot/boot.ks".
copypath("0:/boot/boot.ks", probeCore:volume:name + ":/boot/boot.ks").
copypath("0:/ops/Progeny Mk7-B Flight 4/probeInit.ks", probeCore:volume:name + ":/ops/probeInit.ks").
wait 0.001.
probeCore:deactivate.

// add any custom logging fields, then call for header write and setup log call
set getter("addlLogData")["Total Fuel (u)"] to {
  return ship:solidfuel + ship:liquidfuel + ship:oxidizer.
}.
set getter("addlLogData")["Stage Fuel (u)"] to {
  if currStage = 1 return ship:solidfuel.
  else return ship:liquidfuel + ship:oxidizer.
}.
initLog().
function logData {
  logTlm(floor(time:seconds) - getter("launchTime")).
  if ship:status = "SPLASHED" or ship:status = "LANDED" sleepTimers:remove("datalogger").
}

// determine our max allowable EC drainage
// totalEC / mission time in seconds
set maxECdrain to getter("fullChargeEC") / 855.

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

// monitor launch time for when to enter terminal count
function awaitTerminalCount {
  if time:seconds >= getter("launchTime") - 120 {
    operations:remove("awaitTerminalCount").
    set operations["terminalCount"] to terminalCount@.
  }
}
set operations["awaitTerminalCount"] to awaitTerminalCount@.

// retract service tower, switch to internal power, start doing battery drain checks, ignition timing and set for support arm retract
function terminalCount {
  output("Terminal count begun, monitoring EC levels").
  if ship:partstagged("tower"):length serviceTower:doevent("release clamp").
  for batt in batts if batt:hasevent("Connect Battery") batt:doevent("Connect Battery").
  set EClvl to ship:electriccharge.
  if getter("nonRechargeable") set ECNRlvl to ship:electricchargenonrechargeable.
  else set ECNRlvl to 0.
  set currEC to EClvl+ECNRlvl.
  sleep("monitorEcDrain", monitorEcDrain@, 1, RELATIVE_TIME, PERSIST_Y).
  sleep("retractSupportArms", retractSupportArms@, getter("launchTime") - 5, ABSOLUTE_TIME, PERSIST_N).
  operations:remove("terminalCount").
}

lock throttle to currThrottle.
output("Vessel boot up").