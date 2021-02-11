function powerOn {
  for battery in ship:partsnamed("ca.battery.sNR") battery:getmodule("ModuleResourceConverter"):doevent("Connect Battery").
  for battery in ship:partsnamed("z100-NR") battery:getmodule("ModuleResourceConverter"):doevent("Connect Battery").
  output("Batteries switched on, activating engine").
  probeEngine:doevent("activate engine").
  operations:remove("powerOn").
  set operations["engineOn"] to engineOn@.
}

function engineOn {
  if probeEngine:hasevent("shutdown engine") {
    set ship:partstagged("probecg")[0]:resources[0]:enabled to true.
    for tank in ship:partstagged("probelfo") for res in tank:resources set res:enabled to true.
    for thruster in ship:partstagged("oktoRCS") thruster:getmodule("modulercsfx"):setfield("rcs", true).
    output("Engine on standby, fuel valves open. RCS system check underway - fuel level @ " + round(ship:coldgas, 3) + "u").
    operations:remove("engineOn").
    set operations["thrusterChk1"] to thrusterChk1@.
  }
}

function thrusterChk1 {
  for thruster in ship:partstagged("oktoRCS") thruster:getmodule("modulercsfx"):setfield("thrust limiter", 10).
  operations:remove("thrusterChk1").
  rcs on.
  sas off.
  wait 0.001.
  set ship:control:roll to 1.
  sleep("thrusterChk2", thrusterChk2@, 1, RELATIVE_TIME, PERSIST_N).
}
function thrusterChk2 {
  output("Thruster check - fuel level @ " + round(ship:coldgas, 3) + "u").
  set ship:control:roll to -1.
  operations:remove("thrusterChk2").
  sleep("thrusterChk3", thrusterChk3@, 1, RELATIVE_TIME, PERSIST_N).
}
function thrusterChk3 {
  output("Thruster check - fuel level @ " + round(ship:coldgas, 3) + "u").
  set ship:control:roll to 0.
  set ship:control:pitch to 1.
  operations:remove("thrusterChk3").
  sleep("thrusterChk4", thrusterChk4@, 1, RELATIVE_TIME, PERSIST_N).
}
function thrusterChk4 {
  output("Thruster check - fuel level @ " + round(ship:coldgas, 3) + "u").
  set ship:control:pitch to -1.
  operations:remove("thrusterChk4").
  sleep("thrusterChk5", thrusterChk5@, 1, RELATIVE_TIME, PERSIST_N).
}
function thrusterChk5 {
  output("Thruster check - fuel level @ " + round(ship:coldgas, 3) + "u").
  set ship:control:pitch to 0.
  set ship:control:yaw to 1.
  operations:remove("thrusterChk5").
  sleep("thrusterChk6", thrusterChk6@, 1, RELATIVE_TIME, PERSIST_N).
}
function thrusterChk6 {
  output("Thruster check - fuel level @ " + round(ship:coldgas, 3) + "u").
  set ship:control:yaw to -1.
  operations:remove("thrusterChk6").
  sleep("thrusterChkEnd", thrusterChkEnd@, 1, RELATIVE_TIME, PERSIST_N).
}
function thrusterChkEnd {
  set ship:control:yaw to 0.
  unlock steering.
  rcs off.
  sas on.
  wait 0.1.
  set sasmode to "radialout".
  for thruster in ship:partstagged("oktoRCS") thruster:getmodule("modulercsfx"):setfield("thrust limiter", 100).
  operations:remove("thrusterChkEnd").
  output("Thruster check complete - fuel level @ " + round(ship:coldgas, 3) + "u. Kerbin III activation sequence ended").
}

output("Beginning Kerbin III activation sequence").
set operations["powerOn"] to powerOn@.