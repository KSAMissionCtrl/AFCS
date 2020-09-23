// initialize variables
set currThrottle to 0.
set logInterval to 1.

// keep track of part status
lock s2engineStatus to ship:partstagged("s2lfo")[0]:getmodule("ModuleEnginesFX"):getfield("status").

// get parts/resources now so searching doesn't hold up main program execution
if ship:partstagged("okto"):length {
  set probeEngine to ship:partstagged("gasengine")[0]:getmodule("ModuleEngines").
  set probeCommMain to ship:partstagged("commsMain")[0]:getmodule("ModuleDeployableAntenna").
  set probeCommBackup to ship:partstagged("commsBackup")[0]:getmodule("ModuleDeployableAntenna").
  set oktoSAS to ship:partstagged("okto")[0]:getmodule("ModuleReactionWheel").
  set probeCore to processor("okto").
  set rtg to ship:partstagged("rtg")[0]:getmodule("ModuleAnimateGeneric").
}
set s2engine to ship:partstagged("s2lfo")[0]:getmodule("ModuleEnginesFX").
set payloadDecoupler to ship:partstagged("payloadbase")[0]:getmodule("moduleDecouple").

// simplify/reset custom logging fields
set getter("addlLogData")["Liquid Fuel Flow Rate (mT/s)"] to {
  return ship:partstagged("s2lfo")[0]:getmodule("ModuleEnginesFX"):getfield("fuel flow") * 0.005.
}.
set getter("addlLogData")["Solid Fuel Burn Rate (mT/s)"] to {
  return "N/A".
}.
set getter("addlLogData")["Booster Rated Thrust (%)"] to {
  return "N/A".
}.
set getter("addlLogData")["Total Fuel (u)"] to {
  return ship:liquidfuel + ship:oxidizer.
}.
set getter("addlLogData")["Stage Fuel (u)"] to {
  return ship:liquidfuel + ship:oxidizer.
}.
set getter("addlLogData")["Cold Gas (u)"] to {

  // do not count the amount on the probe if it is still attached
  if ship:partstagged("okto"):length return ship:coldgas-861.6.
  else return ship:coldgas.
}.
set getter("addlLogData")["PLF1 Surface (k)"] to {
  return "N/A".
}.
set getter("addlLogData")["PLF1 Internal (k)"] to {
  return "N/A".
}.
set getter("addlLogData")["PLF2 Surface (k)"] to {
  return "N/A".
}.
set getter("addlLogData")["PLF2 Internal (k)"] to {
  return "N/A".
}.
set getter("addlLogData")["RTG Surface (k)"] to {
  return "N/A".
}.
set getter("addlLogData")["RTG Internal (k)"] to {
  return "N/A".
}.
function logData {
  logTlm(floor(time:seconds) - getter("launchTime")).
}

lock throttle to currThrottle.