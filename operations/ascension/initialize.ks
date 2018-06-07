// initialize variables
set abort to false.
set chuteSpeed to 0.
set phase to "Initial Ascent".
set launchTime to 54752820.
set maxECdrain to 1.
set currThrottle to 1.
set logInterval to 1.
set maxQ to 0.
set MaxQLimit to 150.
set hdgHold to 45.
set pitch to 89.
set currTime to floor(time:seconds).
set obtNum to 1.

// keep track of part status
lock engineStatus to ship:partstagged("lfo")[0]:getmodule("ModuleEnginesFX"):getfield("status").
lock engineThrust to ship:partstagged("lfo")[0]:getmodule("ModuleEnginesFX"):getfield("thrust").

// get parts now so searching doesn't hold up main program execution
set engine to ship:partstagged("lfo")[0]:getmodule("ModuleEnginesFX").
set parachutes to list(
  ship:partstagged("chute")[0]:getmodule("RealChuteModule"),
  ship:partstagged("chute")[1]:getmodule("RealChuteModule")
).
set serviceTower to list(
  ship:partstagged("tower")[0]:getmodule("LaunchClamp"),
  ship:partstagged("tower")[1]:getmodule("LaunchClamp")
).

// no custom data to log
initLog().

// used for anything to be done continuously after launch
function ongoingOps {

  // log data every defined interval
  if time:seconds - currTime >= logInterval {
    set currTime to floor(time:seconds).
    logTlm(currTime - launchTime).
  }
}

output("Vessel boot up").