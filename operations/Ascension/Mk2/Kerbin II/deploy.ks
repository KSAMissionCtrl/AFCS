output("Deploying Kerbin II").
hibernateCtrl:setfield("seconds", 10).
hibernateCtrl:doevent("Start Countdown").
wait 0.1.
payloadDecoupler:doevent("decoupler staging").
wait 0.1.
when kuniverse:canquicksave then kuniverse:quicksaveto(ship:name + " - Kerbin II Deployment").