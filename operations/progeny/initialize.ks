// initialize variables
set abort to false.
set isLanded to false.
set stageCountdown to 0.
set chuteSafeSpeed to 490.
set phase to "Stage One Radial Ascent".
set launchTime to 55771380.
set maxECdrain to 1.
set logInterval to 1.
set pitchLimit to 1.5.
set s2AoALimit to 0.5.
set maxQ to 0.
set currTime to floor(time:seconds).

// keep track of part status
lock stageOneMain to ship:partstagged("srb1m")[0]:getmodule("ModuleEnginesFX"):getfield("status").
lock stageOneRadial to ship:partstagged("srb1r")[0]:getmodule("ModuleEnginesFX"):getfield("status").
lock stageTwo to ship:partstagged("srb2")[0]:getmodule("ModuleEnginesFX"):getfield("status").
lock stageThree to ship:partstagged("lfo1")[0]:getmodule("ModuleEnginesFX"):getfield("status").

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
set chute to ship:partstagged("chute")[0]:getmodule("RealChuteModule").

// set the throttle
lock throttle to 1.

// used for anything to be done continuously after launch
function ongoingOps {
  if ship:q > maxQ set maxQ to ship:q.
  
  if isLanded {
    operations:remove("ongoingOps").
    operations:remove("coastToLanding").
    output("flight operations concluded").
    
    // output one final log entry
    if time:seconds - currTime >= logInterval {
      set currTime to floor(time:seconds).
      logTlm(currTime - launchTime).
    } else {
      when time:seconds - currTime >= logInterval then {
        set currTime to floor(time:seconds).
        logTlm(currTime - launchTime).
      }
    }
  } else {
  
    // log data every defined interval
    if time:seconds - currTime >= logInterval {
      set currTime to floor(time:seconds).
      logTlm(currTime - launchTime).
    }
  }
}

// output the radiation levels in text or as number
function logRad {
  set radlvl to ship:partstagged("payload1")[0]:getmodule("Sensor"):getfield("Radiation").
  if radlvl <> "nominal" {
    set radlvl to radlvl:split(" ")[0].
  }
  return radlvl.
}

// add any custom logging fields, then call for header write
set addlLogData["Rad/hr"] to logRad@.
initLog().

output("Vessel boot up").