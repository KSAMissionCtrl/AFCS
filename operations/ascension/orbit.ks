function toAp {

  // once we've stopped going up, we've reached apokee
  if ship:verticalspeed <= 0 {
    output("Apokee achieved @ " + round(ship:altitude/1000, 3) + "km").
    operations:remove("toAp").
    when ship:altitude <= 70000 then {
      output("Atmospheric interface breached").
      set operations["aerobrake"] to aerobrake@.
      set phase to "Aerobrake".
      lock steering to ship:srfprograde:vector.
    }
  }
}

function aerobrake {
  when ship:verticalspeed >= 0 then output("Perikee achieved @ " + round(ship:altitude/1000, 3) + "km").

  // keep an eye on the apoapsis to see if we are returning
  // a negative perikee means we never reached orbit to begin with
  if ship:orbit:apoapsis < 70000 or ship:orbit:periapsis < 0 {
    output("Return to Kerbin imminent").
    operations:remove("aerobrake").
    set phase to "Re-Entry".
    when ship:altitude <= 35000 then {
      set operations["reentry"] to reentry@.

      // we should now be low enough for our control surfaces to work
      // hold whatever heading we are at and attempt to pitch level
      set hdgHold to compass_for(ship).
      set pitch to 0.
      lock steering to heading(hdgHold,pitch).
      output("Attempting to pitch level").

      // prepare for chute deployment
      // altitude is AGL
      when alt:radar <= 2000 then {
        for chute in parachutes { chute:doevent("deploy chute"). } 
        output("Initial chute deploy triggered @ " + round(ship:altitude/1000, 3) + "km").
        set phase to "initial Chute Deploy".
        unlock steering.
        when abs(ship:verticalspeed) <= 10 then {
          output("Full chute deployment @ " + round(ship:altitude, 3) + "m").
          set phase to "Full Chute Deploy".
          set operations["coastToLanding"] to coastToLanding@.
        }
      }
    }
  }

  // if we climbed back out of the atmosphere it's time for another go 'round
  if ship:altitude >= 70000 {
    set obtNum to obtNum + 1.
    operations:remove("aerobrake").
    set operations["toAp"] to toAp@.
    set phase to "Orbit " + obtNum.
    output("Begin orbit #" + obtNum).
  }
}

output("Orbital ops loaded").