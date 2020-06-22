// initialize variables
set currThrottle to 0.1.
set logInterval to 1.
set maxQ to 0.
set hdgHold to 90.
lock pitch to 87.
set ctrlCheckComplete to false.
declr("launchTime", 119208600).

// keep track of part status
lock engineStatus to ship:partstagged("lfo")[0]:getmodule("ModuleEnginesFX"):getfield("status").
lock engineThrust to ship:partstagged("lfo")[0]:getmodule("ModuleEnginesFX"):getfield("thrust").
lock lesStatus to ship:partstagged("lesPushUp")[0]:getmodule("ModuleEnginesFX"):getfield("status").
lock lesKickStatus to ship:partstagged("lesKick")[0]:getmodule("ModuleEnginesFX"):getfield("status").

// get parts/resources now so searching doesn't hold up main program execution
set engine to ship:partstagged("lfo")[0]:getmodule("ModuleEnginesFX").
set decoupler to ship:partstagged("decoupler")[0]:getmodule("ModuleDecouple").
set heatshield to ship:partstagged("shield")[0]:getmodule("ModuleDecouple").
set lesDecoupler to ship:partstagged("lesTower")[0]:getmodule("ModuleDecouple").
set lesKickMotor to ship:partstagged("lesKick")[0]:getmodule("ModuleEnginesFX").
set lesPushMotorDw to ship:partstagged("lesPushDw")[0]:getmodule("ModuleEnginesFX").
set lesPushMotorUp to ship:partstagged("lesPushUp")[0]:getmodule("ModuleEnginesFX").
set lesPushMotorLeft to ship:partstagged("lesPushLeft")[0]:getmodule("ModuleEnginesFX").
set lesPushMotorRight to ship:partstagged("lesPushRight")[0]:getmodule("ModuleEnginesFX").
set chute to ship:partstagged("chute")[0]:getmodule("RealChuteModule").
set floatCollar to ship:partstagged("float")[0]:getmodule("CL_ControlTool").
set serviceTower to ship:partstagged("tower")[0]:getmodule("LaunchClamp").
set launchClamp to ship:partstagged("clamp")[0]:getmodule("LaunchClamp").
set batt to ship:partstagged("batt")[0]:getmodule("ModuleResourceConverter").
set backupCore to processor("backup").
set mainCore to processor("capsule").
set hatch to ship:partstagged("capsule")[0]:resources[8].

// add any custom logging fields, then call for header write and setup log call
set getter("addlLogData")["Total Fuel (u)"] to {
  return ship:liquidfuel + ship:oxidizer.
}.
set getter("addlLogData")["Cold Gas (u)"] to {
  return ship:coldgas.
}.
set getter("addlLogData")["Capsule Internal (k)"] to {
  return ship:rootpart:getmodule("HotSpotModule"):getfield("Temp [I]"):split(" / ")[0].
}.
set getter("addlLogData")["Capsule Surface (k)"] to {
  return ship:rootpart:getmodule("HotSpotModule"):getfield("Temp [S]"):split(" / ")[0].
}.
set getter("addlLogData")["Heat Shield Internal (k)"] to {
  if ship:partstagged("shield"):length {
    return ship:partstagged("shield")[0]:getmodule("HotSpotModule"):getfield("Temp [I]"):split(" / ")[0].
  } else return "N/A".
}.
set getter("addlLogData")["Heat Shield Surface (k)"] to {
  if ship:partstagged("shield"):length {
    return ship:partstagged("shield")[0]:getmodule("HotSpotModule"):getfield("Temp [S]"):split(" / ")[0].
  } else return "N/A".
}.
set getter("addlLogData")["Fuel Flow Rate (mT/s)"] to {
  if ship:partstagged("lfo"):length {
    return ship:partstagged("lfo")[0]:getmodule("ModuleEnginesFX"):getfield("fuel flow") * 0.005.
  } else return "N/A".
}.
set getter("addlLogData")["Temp (k)"] to {
  set data to "N/A".
  set mods to ship:rootpart:allmodules.
  from {local index is 0.} until index >= mods:length step {set index to index+1.} do {
    if ship:rootpart:getmodulebyindex(index):hasfield("temperature") {
      set data to ship:rootpart:getmodulebyindex(index):getfield("temperature"):split(" ")[0].
    }
  }
  return data.
}.
set getter("addlLogData")["Rads External (mrad/h)"] to {
  set data to "N/A".
  set mods to ship:rootpart:allmodules.
  from {local index is 0.} until index >= mods:length step {set index to index+1.} do {
    if ship:rootpart:getmodulebyindex(index):hasfield("radiation") {
      set radStr to ship:rootpart:getmodulebyindex(index):getfield("radiation").

      // convert from rad/h to mrad/h if needed
      if radStr:split(" ")[1] = "mrad/h" set data to radStr:split(" ")[0]:tonumber().
      else set data to radStr:split(" ")[0]:tonumber() * 1000.
    }
  }
  return data.
}.
set getter("addlLogData")["Rads Internal (mrad/h)"] to {
  set data to "N/A".
  set mods to ship:rootpart:allmodules.
  from {local index is 0.} until index >= mods:length step {set index to index+1.} do {
    if ship:rootpart:getmodulebyindex(index):hasfield("habitat radiation") {
      set radStr to ship:rootpart:getmodulebyindex(index):getfield("habitat radiation").

      // can be "nominal" if shielding is active in atmosphere
      if radStr = "nominal" set data to 0.
      else {
        if radStr:split(" ")[1] = "mrad/h" set data to radStr:split(" ")[0].
        else set data to radStr:split(" ")[0]:tonumber() * 1000.
      }
    }
  }
  return data.
}.
initLog().
function logData {
  logTlm(floor(time:seconds) - getter("launchTime")).
  if ship:status = "SPLASHED" or ship:status = "LANDED" sleepTimers:remove("datalogger").
}

// set the backup CPU's boot log, copy it over and shut it down
set backupCore:bootfilename to "boot/boot.ks".
copypath("0:/boot/boot.ks", backupCore:volume:name + ":/boot/boot.ks").
backupCore:deactivate.

// ensure hatch is secure
set hatch:enabled to true.

// determine our max allowable EC drainage
// totalEC / mission time in seconds
set maxECdrain to getter("fullChargeEC") / 1092.

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

// retract service tower, switch to internal power, start doing battery drain checks, ignition timing and set for control check
function terminalCount {
  output("Terminal count begun, monitoring EC levels").
  if ship:partstagged("tower"):length serviceTower:doevent("release clamp").
  if batt:hasevent("Connect Battery") batt:doevent("Connect Battery").
  set EClvl to ship:electriccharge.
  if getter("nonRechargeable") set ECNRlvl to ship:electricchargenonrechargeable.
  else set ECNRlvl to 0.
  set currEC to EClvl+ECNRlvl.
  sleep("monitorEcDrain", monitorEcDrain@, 1, true, true).
  sleep("ignition", ignition@, getter("launchTime") - 6, false, false).
  sleep("ctrlCheckStart", ctrlCheckStart@, getter("launchTime") - 12, false, false).
  set operations["lesAbortMonitor"] to lesAbortMonitor@.
  operations:remove("terminalCount").
}

lock throttle to currThrottle.
output("Vessel boot up").