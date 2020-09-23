// initialize variables
set currThrottle to 0.
set logInterval to 1.

// keep track of part status
lock engineStatus to ship:partstagged("gasengine")[0]:getmodule("ModuleEngines"):getfield("status").

// get parts/resources now so searching doesn't hold up main program execution
set probeEngine to ship:partstagged("gasengine")[0]:getmodule("ModuleEngines").
set probeCommMain to ship:partstagged("commsMain")[0]:getmodule("ModuleDeployableAntenna").
set probeCommBackup to ship:partstagged("commsBackup")[0]:getmodule("ModuleDeployableAntenna").
set oktoSAS to ship:partstagged("okto")[0]:getmodule("ModuleReactionWheel").
set probeCore to processor("okto").
set rtg to ship:partstagged("rtg")[0]:getmodule("ModuleAnimateGeneric").

// reset logger function delegates
set getter("addlLogData")["Cold Gas Flow Rate (mT/s)"] to {
  return ship:partstagged("gasengine")[0]:getmodule("ModuleEngines"):getfield("fuel flow") * 0.0005.
}.
set getter("addlLogData")["Cold Gas (u)"] to {
  return ship:coldgas.
}.
function logData {
  logTlm(floor(time:seconds) - getter("launchTime")).
}

lock throttle to currThrottle.