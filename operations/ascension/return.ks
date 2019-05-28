function chuteDeploy {

  // keep track of speed and altitude
  // release chute as soon as it's safe, or as last-ditch attempt if below 2km
  if ship:velocity:surface:mag < chuteSafeSpeed or alt:radar < 2000 {
    retroThrusterFire().
    operations:remove("chuteDeploy").
  }
}

function retroThrusterFire {

  // put on the brakes
  if ship:partstagged("lesTower"):length {
    output("Retro thrusters firing @ " + ship:velocity:surface:mag).
    lesPushMotorRight:doevent("activate engine").
    lesPushMotorDw:doevent("activate engine").
    lesPushMotorUp:doevent("activate engine").
    lesPushMotorLeft:doevent("activate engine").
    set operations["popChute"] to popChute@.
  } else {
    output("LES tower not present for retro-thrust").
    chute:doevent("deploy chute").
    output("Initial chute deploy triggered @ " + round(ship:altitude/1000, 3) + "km").
    set operations["onFullDeploy"] to onFullDeploy@.
  }
  operations:remove("retroThrusterFire").
}

function popChute {
  if lesStatus = "Flame-Out!" {
    output("Retro fire complete @ " + ship:velocity:surface:mag).
    lesDecoupler:doevent("decouple").
    chute:doevent("deploy chute").
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