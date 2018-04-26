set payload1 to ship:partstagged("payload1")[0]:getmodule("ModuleScienceExperiment").
// set payload2 to ship:partstagged("payload2")[0]:getmodule("ModuleScienceExperiment").
set probecore to ship:partstagged("probecore")[0]:getmodule("ModuleScienceExperiment").

function runScience {
  payload1:doevent("log radiation data").
  // payload2:doevent("log gravity data").
  probecore:doevent("analyse telemetry").
}
runScience().
output("science instruments ready").
