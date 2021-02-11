// initialize variables
set currThrottle to 0.
set logInterval to 1.

// keep track of part status
lock engineStatus to ship:partstagged("enginelfo")[0]:getmodule("ModuleEngines"):getfield("status").
lock radlvl to ship:partstagged("okto")[0]:getmodule("Sensor"):getfield("Radiation").

// get parts/resources now so searching doesn't hold up main program execution
set probeEngine to ship:partstagged("enginelfo")[0]:getmodule("ModuleEngines").
set probeCommMain to ship:partstagged("commsMain")[0]:getmodule("ModuleDeployableAntenna").
set probeCommBackup to ship:partstagged("commsBackup")[0]:getmodule("ModuleDeployableAntenna").
set oktoSAS to ship:partstagged("okto")[0]:getmodule("ModuleReactionWheel").
set probeCore to processor("okto").
set rtg to ship:partstagged("rtg")[0]:getmodule("ModuleAnimateGeneric").
set windSci to ship:partstagged("swis")[0]:getmodule("Experiment").
set rpwsSci to ship:partstagged("rpws")[0]:getmodule("Experiment").
set magSci to ship:partstagged("mag")[0]:getmodule("Experiment").
set gooSci to ship:partstagged("goo")[0]:getmodule("Experiment").
set ionSci to ship:partstagged("ion")[0]:getmodule("Experiment").

set mods to ship:partstagged("okto")[0]:allmodules.
from {local index is 0.} until index >= mods:length step {set index to index+1.} do {
  if ship:partstagged("okto")[0]:getmodulebyindex(index):hasaction("start: radiation scan") {
    set radSci to ship:partstagged("okto")[0]:getmodulebyindex(index).
  }
}

// reset logger function delegates
set getter("addlLogData")["mrad/hr"] to {
  set data to "N/A".
  if radlvl = "nominal" set data to 0.
  else {
    
    // convert from rad/h to mrad/h if needed
    if radlvl:split(" ")[1] = "mrad/h" set data to radlvl:split(" ")[0].
    else set data to radlvl:split(" ")[0]:tonumber() * 1000.
  }
  return data.
}.
set getter("addlLogData")["Cold Gas Flow Rate (mT/s)"] to {
  return ship:partstagged("gasengine")[0]:getmodule("ModuleEngines"):getfield("fuel flow") * 0.0005.
}.
set getter("addlLogData")["Cold Gas (u)"] to {
  return ship:coldgas.
}.
function logData {
  logTlm(floor(time:seconds) - getter("launchTime")).
}

hudtext("Open and pin probe core PAW!", 10, 2, 25, red, false).

lock throttle to currThrottle.