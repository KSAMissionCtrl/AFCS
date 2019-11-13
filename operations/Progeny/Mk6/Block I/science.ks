set payload1 to ship:partstagged("ksp1")[0]:getmodule("ModuleScienceExperiment").
set payload2 to ship:partstagged("ksp2")[0]:getmodule("ModuleScienceExperiment").

function runScience {
  payload1:doevent("record test data").
  when ship:altitude >= 250000 then { 
    payload1:doevent("record test data").
  }
}
output("science instruments ready").
