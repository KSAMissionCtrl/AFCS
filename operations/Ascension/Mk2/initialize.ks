// initialize variables
set currThrottle to 0.
set logInterval to 1.
set maxQ to 0.
set hdgHold to 45.
set finLimits to 20.
set ctrlCheckComplete to false.
lock pitch to 89.6.
declr("launchTime", 108466380).

// keep track of part status
lock s1engineStatus to ship:partstagged("s1lfo")[0]:getmodule("ModuleEnginesFX"):getfield("status").
lock s2engineStatus to ship:partstagged("s2lfo")[0]:getmodule("ModuleEnginesFX"):getfield("status").

// get parts/resources now so searching doesn't hold up main program execution
set s1engine to ship:partstagged("s1lfo")[0]:getmodule("ModuleEnginesFX").
set s2engine to ship:partstagged("s2lfo")[0]:getmodule("ModuleEnginesFX").
set probeEngine to ship:partstagged("gasengine")[0]:getmodule("ModuleEngines").
set launchClamp to ship:partstagged("clamp")[0]:getmodule("launchClamp").
set s1decoupler to ship:partstagged("s2base")[0]:getmodule("moduleDecouple").
set payloadDecoupler to ship:partstagged("payloadbase")[0]:getmodule("moduleDecouple").
set probeComm to ship:partstagged("comms")[0]:getmodule("ModuleRTAntenna").
set vesselComm to ship:partstagged("commslong")[0]:getmodule("ModuleRTAntenna").
set okto to ship:partstagged("okto")[0]:getmodule("ModuleReactionWheel").
set rtg to ship:partstagged("rtg")[0]:getmodule("ModuleAnimateGeneric").
set probe to processor("okto").
set boltBangs to list (
  ship:partstagged("srbBolt")[0]:getmodule("Kaboom"),
  ship:partstagged("srbBolt")[1]:getmodule("Kaboom"),
  ship:partstagged("srbBolt")[2]:getmodule("Kaboom"),
  ship:partstagged("srbBolt")[3]:getmodule("Kaboom")
).  
set srbDecouplers to list (
  ship:partstagged("srbDecoupler")[0]:getmodule("ModuleAnchoredDecoupler"),
  ship:partstagged("srbDecoupler")[1]:getmodule("ModuleAnchoredDecoupler"),
  ship:partstagged("srbDecoupler")[2]:getmodule("ModuleAnchoredDecoupler"),
  ship:partstagged("srbDecoupler")[3]:getmodule("ModuleAnchoredDecoupler")
).  
set srbs to list(
  ship:partstagged("srb")[0]:getmodule("ModuleEnginesFX"),
  ship:partstagged("srb")[1]:getmodule("ModuleEnginesFX"),
  ship:partstagged("srb")[2]:getmodule("ModuleEnginesFX"),
  ship:partstagged("srb")[3]:getmodule("ModuleEnginesFX")
).
set fins to list(
  ship:partstagged("fin")[0]:getmodule("FARcontrollablesurface"),
  ship:partstagged("fin")[1]:getmodule("FARcontrollablesurface"),
  ship:partstagged("fin")[2]:getmodule("FARcontrollablesurface"),
  ship:partstagged("fin")[3]:getmodule("FARcontrollablesurface")
).
set fairings to list(
  ship:partstagged("plf")[0]:getmodule("proceduralfairingdecoupler"),
  ship:partstagged("plf")[1]:getmodule("proceduralfairingdecoupler")
).
set shrouds to list(
  ship:partstagged("shroud")[0]:getmodule("proceduralfairingdecoupler"),
  ship:partstagged("shroud")[1]:getmodule("proceduralfairingdecoupler")
).
set serviceTowers to list(
  ship:partstagged("tower")[0]:getmodule("LaunchClamp"),
  ship:partstagged("tower")[1]:getmodule("LaunchClamp"),
  ship:partstagged("tower")[2]:getmodule("LaunchClamp")
).

// enable control toggles on fins so we can adjust movement limits
for fin in fins fin:setfield("std. ctrl", true).

// set the probe's boot log, copy it over and shut it down
set probe:bootfilename to "boot/boot.ks".
copypath("0:/boot/boot.ks", probe:volume:name + ":/boot/boot.ks").
probe:deactivate.

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
  return ship:coldgas-402.5.
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
set getter("addlLogData")["RTG Surface (k)"] to {
  if ship:partstagged("rtg"):length {
    return ship:partstagged("rtg")[0]:getmodule("HotSpotModule"):getfield("Temp [S]"):split(" / ")[0].
  } else return "N/A".
}.
set getter("addlLogData")["RTG Internal (k)"] to {
  if ship:partstagged("rtg"):length {
    return ship:partstagged("rtg")[0]:getmodule("HotSpotModule"):getfield("Temp [I]"):split(" / ")[0].
  } else return "N/A".
}.
initLog().
function logData {
  logTlm(floor(time:seconds) - getter("launchTime")).
}

// determine our max allowable EC drainage
// totalEC / ascent to orbit time in seconds 
// do not account for batteries on the probe
set maxECdrain to (getter("fullChargeEC") - 2680) / 500.

// track EC usage per second to ensure we have enough to last the mission at launch
function monitorEcDrain {
  set EClvl to ship:electriccharge.
  if getter("nonRechargeable") set ECNRlvl to ship:electricchargenonrechargeable.
  else set ECNRlvl to 0.
  if currEC - (EClvl+ECNRlvl) >= maxECdrain {
    setAbort(true, "EC drain is excessive at " + round(currEC - (EClvl+ECNRlvl), 3) + "ec/s. Max drain is " + round(maxECdrain, 3) + "ec/s").
    operations:remove("monitorEcDrain").
    sleepTimers:remove("monitorEcDrain").
  }
  set currEC to EClvl+ECNRlvl.
}

// retract service tower, start doing battery drain checks, ignition timing and set for control check
function terminalCount {
  output("Terminal count begun, monitoring EC levels").
  for tower in serviceTowers tower:doevent("release clamp").
  set EClvl to ship:electriccharge.
  if getter("nonRechargeable") set ECNRlvl to ship:electricchargenonrechargeable.
  else set ECNRlvl to 0.
  set currEC to EClvl+ECNRlvl.
  sleep("monitorEcDrain", monitorEcDrain@, 1, true, true).
  sleep("mes", mes@, getter("launchTime") - 3, false, false).
  sleep("ctrlCheckStart", ctrlCheckStart@, getter("launchTime") - 7, false, false).
  operations:remove("terminalCount").
}

lock throttle to currThrottle.
output("Vessel boot up").