// track dynamic pressure during re-entry
function maxQmonitor {
  if ship:q > maxQ {
    set maxQ to ship:q.

    // restart check if Q begins to rise again
    if not operations:haskey("maxQcheck") set operations["maxQcheck"] to maxQcheck@.
  }
}
function maxQcheck {
  if maxQ > ship:q {
    output("MaxQ: " + round(ship:Q * constant:ATMtokPa, 3) + "kPa @ " + round(ship:altitude/1000, 3) + "km").
    operations:remove("maxQcheck").
  }
}

// switch over to landing state and dump the tower once LES expires
function lesTowerMonitor {
  if lesStatus = "Flame-Out!" {
    set operations["chuteDeployAbort"] to chuteDeployAbort@.
    set maxQ to 0.
    unlock lesStatus.
    unlock lesKickStatus.
    lesDecoupler:doevent("decouple").
    output("LES tower burnout & decouple. Prepped for chute deploy").
    operations:remove("lesTowerMonitor").
  }
}

// separate deployment routine from popChute since capsule may still be traveling upwards
function chuteDeployAbort {
  if ship:verticalspeed < 0 {
    chute:doevent("deploy chute").
    output("Initial chute deploy triggered @ " + round(ship:altitude/1000, 3) + "km").
    operations:remove("chuteDeployAbort").

    // only wait for speed to increase if above full chute deploy height
    if ship:altitude > chuteFullDeployAlt set operations["vsMonitor"] to vsMonitor@.
    else set operations["onFullDeploy"] to onFullDeploy@.
  }
}

// if capsule was at apogee for chute pop, we need to wait for it to pick up speed again
// before checking to see if a full chute has slowed it down
function vsMonitor {
  if abs(ship:verticalspeed) > 13 {
    set operations["onFullDeploy"] to onFullDeploy@.
    operations:remove("vsMonitor").
  }
}

// begin monitoring for re-entry
function saveReturn {
  if ship:altitude <= 75000 {
    if kuniverse:canquicksave {
      kuniverse:quicksaveto(ship:name + " - Reentry").
      operations:remove("saveReturn").
    }
  }
}
function reentry {
  if ship:altitude <= 70000 {
    output("Atmospheric interface breached").
    operations:remove("reentry").
    set operations["chuteDeploy"] to chuteDeploy@.
    set operations["maxQmonitor"] to maxQmonitor@.
    set operations["maxQcheck"] to maxQcheck@.
  }
}

// normal chute deploy upon re-entry
function chuteDeploy {

  // keep track of speed and altitude
  // release chute as soon as it's safe
  if ship:velocity:surface:mag < chuteSafeSpeed {

    if ship:partstagged("lesTower"):length {
      lesPushMotorRight:doevent("activate engine").
      lesPushMotorDw:doevent("activate engine").
      lesPushMotorUp:doevent("activate engine").
      lesPushMotorLeft:doevent("activate engine").
      wait 0.001.
      lesDecoupler:doevent("decouple").
      output("Safe speed for chute deployment reached. Discarding LES").
    } else output("Safe speed for chute deployment reached").
    chute:doevent("deploy chute").
    set operations["popChute"] to popChute@.
    operations:remove("chuteDeploy").
    rcs off.
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
    when kuniverse:canquicksave then kuniverse:quicksaveto(ship:name + " - Splashdown").
  } else set chuteSpeed to ship:verticalspeed.
}

output("Return ops loaded").