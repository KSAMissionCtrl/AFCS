// initialize variables
set currThrottle to 0.
set logInterval to 1.
set maxQ to 0.
set probeCG to 861.6.
set ctrlCheckComplete to false.
lock hdgHold to 60.
lock pitch to 89.6.
declr("launchTime", 127151160).

// keep track of part status
lock s1engineStatus to ship:partstagged("s1lfo")[0]:getmodule("ModuleEnginesFX"):getfield("status").
lock s2engineStatus to ship:partstagged("s2lfo")[0]:getmodule("ModuleEnginesFX"):getfield("status").
lock srbStatus to ship:partstagged("srb")[0]:getmodule("ModuleEnginesFX"):getfield("status").
lock s1EngineAvailableThrust to ship:partstagged("s1lfo")[0]:availablethrust.
lock srbThrust to ship:partstagged("srb")[0]:thrust*4.

// get parts/resources now so searching doesn't hold up main program execution
set s1engine to ship:partstagged("s1lfo")[0]:getmodule("ModuleEnginesFX").
set s2engine to ship:partstagged("s2lfo")[0]:getmodule("ModuleEnginesFX").
set launchClamp to ship:partstagged("clamp")[0]:getmodule("launchClamp").
set s1decoupler to ship:partstagged("s2base")[0]:getmodule("moduleDecouple").
set payloadDecoupler to ship:partstagged("payloadbase")[0]:getmodule("moduleDecouple").
set oktoSAS to ship:partstagged("okto")[0]:getmodule("ModuleReactionWheel").
set probeCore to processor("okto").
set srbDecouplers to list (
  ship:partstagged("srbDecoupler")[0]:getmodule("ModuleAnchoredDecouplerBdb"),
  ship:partstagged("srbDecoupler")[1]:getmodule("ModuleAnchoredDecouplerBdb"),
  ship:partstagged("srbDecoupler")[2]:getmodule("ModuleAnchoredDecouplerBdb"),
  ship:partstagged("srbDecoupler")[3]:getmodule("ModuleAnchoredDecouplerBdb")
).  
set srbs to list(
  ship:partstagged("srb")[0]:getmodule("ModuleEnginesFX"),
  ship:partstagged("srb")[1]:getmodule("ModuleEnginesFX"),
  ship:partstagged("srb")[2]:getmodule("ModuleEnginesFX"),
  ship:partstagged("srb")[3]:getmodule("ModuleEnginesFX")
).
set fins to list(
  ship:partstagged("fin")[0]:getmodule("FARcontrollablesurface"),
  ship:partstagged("fin")[1]:getmodule("FARcontrollablesurface")
).
set fairings to list(
  ship:partstagged("plf")[0]:getmodule("proceduralfairingdecoupler"),
  ship:partstagged("plf")[1]:getmodule("proceduralfairingdecoupler")
).
set serviceTowers to list(
  ship:partstagged("tower")[0]:getmodule("LaunchClamp"),
  ship:partstagged("tower")[1]:getmodule("LaunchClamp"),
  ship:partstagged("tower")[2]:getmodule("LaunchClamp")
).
set viklunBatt to ship:partsnamed("z100-NR").
set s1SepMotors to ship:partsnamed("sepMotor1").

// enable control toggles on fins so we can adjust movement properties
for fin in fins fin:setfield("std. ctrl", true).

// set the probe's boot log, copy it over and shut it down
set probeCore:bootfilename to "boot/boot.ks".
copypath("0:/boot/boot.ks", probeCore:volume:name + ":/boot/boot.ks").
wait 0.001.
probeCore:deactivate.

// add any custom logging fields, then call for header write and setup log call
set getter("addlLogData")["Liquid Fuel Flow Rate (mT/s)"] to {
  if ship:partstagged("s1lfo"):length {
    return ship:partstagged("s1lfo")[0]:getmodule("ModuleEnginesFX"):getfield("fuel flow") * 0.005.
  } else if ship:partstagged("s2lfo"):length {
    return ship:partstagged("s2lfo")[0]:getmodule("ModuleEnginesFX"):getfield("fuel flow") * 0.005.
  } else return "N/A".
}.
set getter("addlLogData")["Solid Fuel Burn Rate (mT/s)"] to {
  if ship:partstagged("srb"):length {
    return ship:partstagged("srb")[0]:getmodule("ModuleEnginesFX"):getfield("fuel flow") * 0.0075.
  } else return "N/A".
}.
set getter("addlLogData")["Booster Rated Thrust (%)"] to {
  if ship:partstagged("srb"):length {
    return ship:partstagged("srb")[0]:getmodule("ModuleEnginesFX"):getfield("% rated thrust") * 100.
  } else return "N/A".
}.
set getter("addlLogData")["Total Fuel (u)"] to {
  return ship:liquidfuel + ship:oxidizer + ship:solidfuel.
}.
set getter("addlLogData")["Stage Fuel (u)"] to {
  if ship:partstagged("srb"):length {
    return ship:solidfuel.
  } else if ship:partstagged("s1tank"):length {
    return ship:partstagged("s1tank")[0]:resources[0]:amount + ship:partstagged("s1tank")[0]:resources[1]:amount.
  } else return ship:liquidfuel + ship:oxidizer.
}.
set getter("addlLogData")["Cold Gas (u)"] to {

  // do not count the amount on the probe
  return ship:coldgas-probeCG.
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
initLog().
function logData {
  logTlm(floor(time:seconds) - getter("launchTime")).
}

// make sure batteries are not draining, else RTG is not supplying proper power
function monitorEcDrain {
  set EClvl to ship:electriccharge.
  if getter("nonRechargeable") set ECNRlvl to ship:electricchargenonrechargeable.
  else set ECNRlvl to 0.
  if currEC - (EClvl+ECNRlvl) >= 0.1 {
    setAbort(true, "EC drain of " + currEC - (EClvl+ECNRlvl) + "ec/s detected, RTG power supply compromised").
    operations:remove("monitorEcDrain").
    sleepTimers:remove("monitorEcDrain").
  }
  set currEC to EClvl+ECNRlvl.
}

// monitor launch time for when to enter terminal count
function awaitTerminalCount {
  if time:seconds >= getter("launchTime") - 120 {
    operations:remove("awaitTerminalCount").
    set operations["enterTerminalCount"] to enterTerminalCount@.
  }
}
set operations["awaitTerminalCount"] to awaitTerminalCount@.

// retract service tower, start doing battery drain checks, ignition timing and set for control check
function enterTerminalCount {
  output("Terminal count begun, monitoring EC levels").
  for tower in serviceTowers tower:doevent("release clamp").
  // for batt in viklunBatt if batt:getmodule("ModuleResourceConverter"):hasevent("Connect Battery") batt:getmodule("ModuleResourceConverter"):doevent("Connect Battery").
  set EClvl to ship:electriccharge.
  if getter("nonRechargeable") set ECNRlvl to ship:electricchargenonrechargeable.
  else set ECNRlvl to 0.
  set currEC to EClvl+ECNRlvl.
  sleep("monitorEcDrain", monitorEcDrain@, 1, RELATIVE_TIME, PERSIST_Y).
  sleep("mes", mes@, getter("launchTime") - 3, ABSOLUTE_TIME, PERSIST_N).
  sleep("ctrlCheckStart", ctrlCheckStart@, getter("launchTime") - 7, ABSOLUTE_TIME, PERSIST_N).
  operations:remove("enterTerminalCount").
}

lock throttle to currThrottle.
output("Vessel boot up").

