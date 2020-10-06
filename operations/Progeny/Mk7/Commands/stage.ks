// make sure the fins are straight on decouple
output("Staging commanded. Disabling guidance, arming booster parachute").
unlock steering.
s1chute:doevent("arm parachute").
wait 0.5.
for shroud in shrouds shroud:doevent("jettison fairing").
wait 0.1.
decoupler:doevent("decoupler staging").
output("Stage one booster decoupled").
kuniverse:quicksave().
set currStage to 2.