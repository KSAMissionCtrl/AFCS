function airbrakeDeploy {

  // wait until dynamic pressure begins to drop before releasing airbrakes
  if maxQ > ship:q {
    for airbrake in airbrakes { airbrake:setfield("deploy", true). }
    operations:remove("airbrakeDeploy").
    output("MaxQ: " + round(ship:Q * constant:ATMtokPa, 3) + "kPa @ " + round(ship:altitude/1000, 3) + "km - deploying airbrakes").
  }
}

function chuteDeploy {

  // keep track of speed and altitude
  // release chute as soon as it's safe, or as last-ditch attempt if below 1.5km
  if ship:velocity:surface:mag < chuteSafeSpeed or alt:radar < 1500 {
    output("Safe speed for chute deployment reached @ " + round(ship:altitude/1000, 3) + "km").
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

function onFullDeploy {
  if abs(ship:verticalspeed) <= 10 {
    output("Full chute deployment @ " + round(ship:altitude, 3) + "m").
    set operations["coastToLanding"] to coastToLanding@.
    operations:remove("onFullDeploy").
  }
}

function coastToLanding {
  if ship:status = "SPLASHED" or ship:status = "LANDED" {
    output(ship:status + " @ " + round(abs(chuteSpeed), 3) + "m/s, " + round(circle_distance(latlng(getter("launchPositionLat"),getter("launchPositionLng")), ship:geoposition, ship:orbit:body:radius)/1000, 3) + "km downrange").
    operations:remove("coastToLanding").
    output("flight operations concluded").
  } else set chuteSpeed to ship:verticalspeed.
}