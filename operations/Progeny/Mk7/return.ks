// begin monitoring for re-entry
function saveReturn {
  if ship:altitude <= 100000 {
    if kuniverse:canquicksave {
      kuniverse:quicksaveto(ship:name + " - Reentry").
      operations:remove("saveReturn").
    }
    set operations["reentry"] to reentry@.
  }
}
function reentry {
  if ship:altitude <= 70000 {
    output("Atmospheric interface breached").
    operations:remove("reentry").
    set operations["chuteDeploy"] to chuteDeploy@.
    set operations["airbrakeDeploy"] to airbrakeDeploy@.
    set operations["maxQmonitor"] to maxQmonitor@.
    set operations["maxQcheck"] to maxQcheck@.
    set maxQ to 0.
    ship:partstagged("gyro")[0]:getmodule("ModuleReactionWheel"):setfield("reaction wheel authority", 0).
    sas off.
  }
}

function airbrakeDeploy {

  // wait until dynamic pressure begins to drop before releasing airbrakes
  if maxQ > ship:q {
    for airbrake in airbrakes airbrake:doaction("extend", true).
    operations:remove("airbrakeDeploy").
    output("Deploying airbrakes").
  }
}

function chuteDeploy {

  // keep track of speed and altitude
  // release chute as soon as it's safe, or as last-ditch attempt if below 1.5km
  if ship:velocity:surface:mag < chuteSafeSpeed or alt:radar < 1500 {
    output("Safe speed for chute deployment reached @ " + round(ship:altitude/1000, 3) + "km").
    s2chute:doevent("deploy chute").
    set operations["popChute"] to popChute@.
    operations:remove("chuteDeploy").
  }
}

function popChute {
  if s2chute:hasevent("cut chute") {
    output("Initial chute deploy triggered @ " + round(ship:altitude/1000, 3) + "km").
    set operations["onFullDeploy"] to onFullDeploy@.
    operations:remove("popChute").
  }
}

function onFullDeploy {
  if abs(ship:verticalspeed) <= 12 {
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

set operations["saveReturn"] to saveReturn@.
output("Return ops loaded").