// initialize variables
set currThrottle to 0.
set logInterval to 1.

// keep track of part status
lock engineStatus to ship:partstagged("gasengine")[0]:getmodule("ModuleEngines"):getfield("status").

// get parts/resources now so searching doesn't hold up main program execution
set engine to ship:partstagged("gasengine")[0]:getmodule("ModuleEngines").
set comms to ship:partstagged("comms")[0]:getmodule("ModuleRTAntenna").
set okto to ship:partstagged("okto")[0]:getmodule("ModuleReactionWheel").
set rtg to ship:partstagged("rtg")[0]:getmodule("ModuleAnimateGeneric").

// add any custom logging fields, then call for header write and setup log call
set getter("addlLogData")["Cold Gas Flow Rate (mT/s)"] to {
  return ship:partstagged("gasengine")[0]:getmodule("ModuleEngines"):getfield("fuel flow") * 0.0005.
}.
set getter("addlLogData")["Cold Gas (u)"] to {
  return ship:coldgas.
}.
initLog().
function logData {
  logTlm(floor(time:seconds) - getter("launchTime")).
}

logData().
sleep("datalogger", logData@, 1, true, true).
lock throttle to currThrottle.
output("First run initialization complete").