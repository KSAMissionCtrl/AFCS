function chuteDeploy {

  // keep track of speed and altitude
  // release chute as soon as it's safe, or as last-ditch attempt if below 3km
  if ship:velocity:surface:mag < chuteSafeSpeed or alt:radar < 3000 {
    parachutes:doevent("deploy chute").
    output("Initial chute deploy triggered @ " + round(ship:altitude/1000, 3) + "km").
    set phase to "initial Chute Deploy".
    when abs(ship:verticalspeed) <= 13 then {
      output("Full chute deployment @ " + round(ship:altitude, 3) + "m").
      set phase to "Full Chute Deploy".
      set operations["coastToLanding"] to coastToLanding@.
    }
    operations:remove("chuteDeploy").
  }
}

function coastToLanding {
  if ship:status = "SPLASHED" or ship:status = "LANDED" {
    output(ship:status + " @ " + round(abs(chuteSpeed), 3) + "m/s, " + round(circle_distance(launchPosition, ship:geoposition, ship:orbit:body:radius)/1000, 3) + "km downrange").
    operations:remove("coastToLanding").
    output("flight operations concluded").
  } else set chuteSpeed to ship:verticalspeed.
}

output("Return ops loaded").