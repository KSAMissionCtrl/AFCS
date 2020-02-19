function powerOn {
  for battery in ship:partstitled("ca-100i battery") set battery:resources[0]:enabled to true.
  for battery in ship:partstitled("z-1k rechargeable battery bank") set battery:resources[0]:enabled to true.
  rtg:doevent("deploy").
  output("Batteries switched on, RTG deploying").
  operations:remove("powerOn").
  set operations["rtgDeploy"] to rtgDeploy@.
}

function rtgDeploy {
  if rtg:getfield("status") = "Locked" {
    output("RTG deployed & locked, activating comms").
    probeComm:doevent("activate").
    operations:remove("rtgDeploy").
    set operations["commOn"] to commOn@.
  }
}

function commOn {
  if probeComm:getfield("status") = "Connected" {
    okto:setfield("reaction wheel authority", 100).
    output("Communications active, reaction wheels active").
    probeEngine:doevent("activate engine").
    operations:remove("commOn").
    set operations["engineOn"] to engineOn@.
  }
}

function engineOn {
  if probeEngine:hasevent("shutdown engine") {
    for tank in ship:partstitled("cg-r1 cold gas fuel tank") set tank:resources[0]:enabled to true.
    for tank in ship:partstitled("rc-14 gas container") set tank:resources[0]:enabled to true.
    output("Engine on standby, fuel valves open. Kerbin I ready for deployment!").
    operations:remove("engineOn").
  }
}

output("Beginning Kerbin I activation sequence").
set operations["powerOn"] to powerOn@.