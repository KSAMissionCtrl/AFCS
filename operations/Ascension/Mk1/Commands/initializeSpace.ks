// initialize variables
set chuteSpeed to 0.
set chuteSafeSpeed to 490.
set chuteFullDeployAlt to 700.
set logInterval to 1.
set maxQ to 0.
set extRadLvl to 0.
set nrmExtRadLvl to 0.
set beltEnterUT to 0.
declr("launchTime", 119208600).

// keep track of part status
lock hg1Status to ship:partstagged("hg1")[0]:getmodule("ModuleDeployableAntenna"):getfield("status").
lock hg2Status to ship:partstagged("hg2")[0]:getmodule("ModuleDeployableAntenna"):getfield("status").

// get parts/resources now so searching doesn't hold up main program execution
set decoupler to ship:partstagged("decoupler")[0]:getmodule("ModuleDecouple").
set heatshield to ship:partstagged("shield")[0]:getmodule("ModuleDecouple").
set chute to ship:partstagged("chute")[0]:getmodule("RealChuteModule").
set floatCollar to ship:partstagged("float")[0]:getmodule("CL_ControlTool").
set hg1 to ship:partstagged("hg1")[0]:getmodule("ModuleDeployableAntenna").
set hg2 to ship:partstagged("hg2")[0]:getmodule("ModuleDeployableAntenna").
set commMain to ship:partstagged("commMain")[0]:getmodule("ModuleDeployableAntenna").
set commBackup to ship:partstagged("commBackup")[0]:getmodule("ModuleDeployableAntenna").
set backupCore to processor("backup").
set mainCore to processor("capsule").
set hatch to ship:partstagged("capsule")[0]:resources[8].
set rpws to ship:partstagged("rpws")[0]:getmodule("Experiment").
set mag to ship:partstagged("mag")[0]:getmodule("Experiment").
set grs to ship:partstagged("grs")[0]:getmodule("Experiment").
set tlm to ship:partstagged("backup")[0]:getmodule("Experiment").
set gooLow to ship:partstagged("gooLow")[0]:getmodule("Experiment").
set gooHigh to ship:partstagged("gooHigh")[0]:getmodule("Experiment").
set batt to ship:partstagged("batt")[0]:getmodule("ModuleResourceConverter").

// reset ship position to launch coordinates
setter("launchPositionLat", -0.097185401179765).
setter("launchPositionLng", -74.557677161204).

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
      set extRadLvl to data.

      // set the normal space level if it's not already
      if not nrmExtRadLvl set nrmExtRadLvl to data.
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
sleep("datalogger", logData@, logInterval, true, true).

// set the backup CPU's boot log, copy it over and shut it down
set backupCore:bootfilename to "boot/boot.ks".
copypath("0:/boot/boot.ks", backupCore:volume:name + ":/boot/boot.ks").
backupCore:deactivate.

// activate additional battery banks
for battery in ship:partstitled("ca-100i battery") set battery:resources[0]:enabled to true.

// make sure we switch back to capsule power if needed
function monitorEC {
  if ship:electriccharge < 25 {
    if batt:hasevent("Connect Battery") batt:doevent("Connect Battery").
    operations:remove("monitorEC").
  }
}
set operations["monitorEC"] to monitorEC@.

// ensure hatch is secure
set hatch:enabled to true.

output("Space operations initialized").