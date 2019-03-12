set payload1 to ship:partstagged("gooLow")[0]:getmodule("ModuleScienceExperiment").
set payload2 to ship:partstagged("gooHigh")[0]:getmodule("ModuleScienceExperiment").

function runScience {
  payload1:doevent("observe mystery goo").
  when ship:altitude >= 350000 then { payload2:doevent("observe mystery goo"). }
}
output("science instruments ready").
