function reentry {

  // keep tabs on our pitch angle - if we manage to make it to horizontal, pitch up 15 degrees and hold
  if abs(pitch_for(ship)) < 1 {
    set pitch to 15.
    operations:remove("reentry").
    output("Level glide achieved").
  }
}

function coastToLanding {
  if ship:status = "SPLASHED" {
    output("Splashdown @ " + round(abs(chuteSpeed), 3) + "m/s, " + round(circle_distance(launchPosition, ship:geoposition, ship:orbit:body:radius)/1000, 3) + "km downrange").
    landed().
  } else if ship:status = "LANDED" {
    output("Touchdown @ " + round(abs(chuteSpeed), 3) + "m/s, " + round(circle_distance(launchPosition, ship:geoposition, ship:orbit:body:radius)/1000, 3) + "km downrange").
    landed().
  } else if time:seconds - currTime >= logInterval { set chuteSpeed to ship:verticalspeed. }
}

function landed {
  operations:remove("ongoingOps").
  operations:remove("coastToLanding").
  output("flight operations concluded").
  
  // output one final log entry
  if time:seconds - currTime >= logInterval {
    set currTime to floor(time:seconds).
    logTlm(currTime - launchTime).
  } else {
    when time:seconds - currTime >= logInterval then {
      set currTime to floor(time:seconds).
      logTlm(currTime - launchTime).
    }
  }
}

output("Return ops loaded").