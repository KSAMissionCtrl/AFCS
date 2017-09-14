output("Vessel boot up").

// include needed AFCS files
runpath("0:logger.ks").

// initialize variables
set abort to false.
set landed to false.
set s2VS to false.
set s3VS to false.
set runstate to 0.
set phase to "Stage One Ascent".
set abortMsg to "undefined reasons".
set launchTime to 31670940.
set maxECdrain to 2.608695652.
set logInterval to 1.
set pitchLimit to 1.5.
set currTime to floor(time:seconds).

// monitor electric charge
list resources in resList.
for res in resList { 
  if res:name = "electriccharge" { 
    lock EClvl to res:amount. 
    break.
  } 
}

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