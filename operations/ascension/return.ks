function chuteDeploy {

  // keep track of speed and altitude
  // release chute as soon as it's safe
  if ship:velocity:surface:mag < chuteSafeSpeed {
    lesPushMotorRight:doevent("activate engine").
    lesPushMotorDw:doevent("activate engine").
    lesPushMotorUp:doevent("activate engine").
    lesPushMotorLeft:doevent("activate engine").
    wait 0.001.
    lesDecoupler:doevent("decouple").
    output("Safe speed for chute deployment reached. Discarding LES").
    chute:doevent("deploy chute").
    set operations["popChute"] to popChute@.
    operations:remove("chuteDeploy").
  }
}

function popChute {
  if chute:hasevent("cut chute") {
    output("Initial chute deploy triggered @ " + round(ship:altitude/1000, 3) + "km").
    set operations["onFullDeploy"] to onFullDeploy@.
    operations:remove("popChute").
  }
}

function chuteDeployAbort {

  if ship:verticalspeed < 0 {
    chute:doevent("deploy chute").
    output("Initial chute deploy triggered @ " + round(ship:altitude/1000, 3) + "km").
    when abs(ship:verticalspeed) > 13 then set operations["onFullDeploy"] to onFullDeploy@.
    operations:remove("chuteDeployAbort").
  }
}

function onFullDeploy {
  if abs(ship:verticalspeed) <= 13 {
    output("Full chute deployment @ " + round(ship:altitude, 3) + "m").
    set operations["coastToLanding"] to coastToLanding@.
    operations:remove("onFullDeploy").

    // if the AGL and ASL match up, we are landing over water
    // prep to drop the shield just before touchdown and arm the floats
    if round(alt:radar, 3) = round(ship:altitude, 3) {
      output("Preparing for splashdown").
      when alt:radar < 2 then heatshield:doevent("jettison heat shield").
      floatCollar:doevent("activate pre-landing mode").
    }
  }
}

function coastToLanding {
  if ship:status = "SPLASHED" or ship:status = "LANDED" {
    output(ship:status + " @ " + round(abs(chuteSpeed), 3) + "m/s, " + round(circle_distance(latlng(getter("launchPositionLat"),getter("launchPositionLng")), ship:geoposition, ship:orbit:body:radius)/1000, 3) + "km downrange").
    operations:remove("coastToLanding").
    output("flight operations concluded").
  } else set chuteSpeed to ship:verticalspeed.
}

output("Return ops loaded").