output("Deploying Kerbin I").
rcs off.
sas off.
hibernateCtrl:setfield("seconds", 10).
hibernateCtrl:doevent("Start Countdown").
payloadDecoupler:doevent("decoupler staging").