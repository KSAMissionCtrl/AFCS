set payload1 to ship:partstagged("iontrap")[0]:getmodule("ModuleScienceExperiment").
set payload2 to ship:partstagged("radsense")[0]:getmodule("ModuleScienceExperiment").

function runScience {
  payload1:doevent("log charged particles").
  when ship:altitude >= 400000 then { 
    payload1:doevent("log charged particles").
  }
}
output("science instruments ready").
