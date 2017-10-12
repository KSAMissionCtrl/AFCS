// initialize variables
set abort to false.
set landed to false.
set stageCountdown to 0.
set chuteSpeed to 0.
set phase to "Stage One Ascent".
set abortMsg to "undefined reasons".
set launchTime to 34181760.
set maxECdrain to 2.608695652.
set logInterval to 1.
set pitchLimit to 1.
set maxQ to 0.
set currTime to floor(time:seconds).

// keep track of part status
lock stageOne to ship:partstagged("srb1")[0]:getmodule("ModuleEnginesFX"):getfield("status").
lock stageTwo to ship:partstagged("srb2")[0]:getmodule("ModuleEnginesFX"):getfield("status").
lock stageThree to ship:partstagged("lfo1")[0]:getmodule("ModuleEnginesFX"):getfield("status").
set chute to ship:partstagged("chute")[0]:getmodule("RealChuteModule").

// keep track of abort state
function setAbort {
  parameter doAbort, msg is "undefined reasons".
  set abort to doAbort.
  set abortMsg to msg.
}

// set the throttle to an initial TWR of 2
lock throttle to 2 * ship:mass * (surfaceGravity/((((ship:orbit:body:radius + ship:altitude)/1000)/(ship:orbit:body:radius/1000))^2)) / getAvailableThrust().

output("Vessel boot up").