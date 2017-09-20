output("Vessel boot up").

// include needed AFCS files
runpath("0:logger.ks").
runpath("0:helpFunc.ks").

// initialize variables
set abort to false.
set landed to false.
set runstate to 0.
set stageCountdown to 0.
set phase to "Stage One Ascent".
set abortMsg to "undefined reasons".
set launchTime to 32190540.
set maxECdrain to 2.608695652.
set logInterval to 1.
set pitchLimit to 1.5.
set maxQ to 0.
set desiredTWR to 3.
set currTime to floor(time:seconds).

// keep track of part status
lock stageOne to ship:partstagged("srb1")[0]:getmodule("ModuleEnginesFX"):getfield("status").
lock stageTwo to ship:partstagged("srb2")[0]:getmodule("ModuleEnginesFX"):getfield("status").
lock stageThree to ship:partstagged("lfo1")[0]:getmodule("ModuleEnginesFX"):getfield("status").
lock chute to ship:partstagged("chute")[0]:getmodule("RealChuteModule").

// keep track of abort state
function setAbort {
  parameter doAbort, msg is "undefined reasons".
  set abort to doAbort.
  set abortMsg to msg.
}