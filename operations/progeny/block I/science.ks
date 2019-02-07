set payload1 to ship:partstagged("jrLow")[0]:getmodule("ModuleScienceExperiment").
set payload2 to ship:partstagged("jrHigh")[0]:getmodule("ModuleScienceExperiment").

function runScience {
  payload1:doevent("observe materials bay").
  when ship:altitude >= 350000 then { payload2:doevent("observe materials bay"). }
}
output("science instruments ready").
