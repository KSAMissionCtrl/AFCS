// initialize non-volatile variables
set abort to false.
set maxECdrain to 1.
set pitchLimit to 1.5.
set s2AoALimit to 0.5.
set maxQ to 0.
set rdyToHibernate to false.

// initialize volatile variables
declr("launchTime", 75210420).
declr("phase", "Stage One Radial Ascent").

// keep track of part status 
lock stageOneMain to ship:partstagged("srb1m")[0]:getmodule("ModuleEnginesFX"):getfield("status").
lock stageOneRadial to ship:partstagged("srb1r")[0]:getmodule("ModuleEnginesFX"):getfield("status").
lock stageTwo to ship:partstagged("srb2")[0]:getmodule("ModuleEnginesFX"):getfield("status").
lock stageThree to ship:partstagged("lfo1")[0]:getmodule("ModuleEnginesFX"):getfield("status").
lock radlvl to ship:partstagged("radsense")[0]:getmodule("Sensor"):getfield("Radiation").

// get parts now so searching doesn't hold up main program execution
set srb1 to ship:partstagged("srb1m")[0]:getmodule("ModuleEnginesFX").
set s1decoupler to ship:partstagged("s1decoupler")[0]:getmodule("ModuleDecouple").
set s1fins to list(
  ship:partstagged("s1fin")[0]:getmodule("Kaboom"),
  ship:partstagged("s1fin")[1]:getmodule("Kaboom"),
  ship:partstagged("s1fin")[2]:getmodule("Kaboom")
).
set radDecouplers to list(
  ship:partstagged("radDecoupler")[0]:getmodule("ModuleAnchoredDecoupler"),
  ship:partstagged("radDecoupler")[1]:getmodule("ModuleAnchoredDecoupler"),
  ship:partstagged("radDecoupler")[2]:getmodule("ModuleAnchoredDecoupler"),
  ship:partstagged("radDecoupler")[3]:getmodule("ModuleAnchoredDecoupler")
).
set srb2 to ship:partstagged("srb2")[0]:getmodule("ModuleEnginesFX").
set s2decoupler to ship:partstagged("s2decoupler")[0]:getmodule("ModuleDecouple").
set s2fins to list(
  ship:partstagged("s2fin")[0]:getmodule("Kaboom"),
  ship:partstagged("s2fin")[1]:getmodule("Kaboom"),
  ship:partstagged("s2fin")[2]:getmodule("Kaboom")
).
set lfo1 to ship:partstagged("lfo1")[0]:getmodule("ModuleEnginesFX").

// set the throttle
lock throttle to 1.

// add any custom logging fields, then call for header write and setup log call
set getter("addlLogData")["Rad/hr"] to {
  if radlvl <> "nominal" {
    set radlvl to radlvl:split(" ")[0].
  }
  return radlvl.
}.
initLog().
function logData {
  logTlm(floor(time:seconds) - getter("launchTime")).

  // remove the timer after a final log post engine shutdown on the way up
  // set reference points for future logging during hibernation cycles
  if rdyToHibernate {
    setter("lastLog", floor(time:seconds)).
    setter("lastLink", floor(time:seconds)).
    sleepTimers:remove("datalogger").
  }
}

output("Vessel boot up").