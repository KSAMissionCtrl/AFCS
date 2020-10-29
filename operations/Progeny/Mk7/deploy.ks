output("Starting Bot probe activation sequence").
for battery in ship:partsnamed("ca.battery.sNR") battery:getmodule("ModuleResourceConverter"):doevent("Connect Battery").
rtg:doevent("deploy").
set operations["rtgDeploy"] to rtgDeploy@.

function rtgDeploy {
  if rtg:hasevent("retract") {
    output("RTG deployment confirmed, batteries activated").
    probeComms:doevent("extend antenna").
    set operations["commsDeploy"] to commsDeploy@.
    operations:remove("rtgDeploy").
  }
}

function commsDeploy {
  if probeComms:hasevent("retract antenna") {
    output("Antenna deployment confirmed, ready for deployment").
    sleep("deploy", deploy@, 1, RELATIVE_TIME, PERSIST_N).
    operations:remove("commsDeploy").
  }
}

function deploy {
  hibernateCtrl:setfield("seconds", 10).
  hibernateCtrl:doevent("Start Countdown").
  wait 0.1.
  payloadDecoupler:doevent("decoupler staging").
  wait 0.1.
  output("Bot probe deployed!").
  when kuniverse:canquicksave then kuniverse:quicksaveto(ship:name + " - Bot Probe Deployment").
  operations:remove("deploy").
}
