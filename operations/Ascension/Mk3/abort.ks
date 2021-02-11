set chuteSafeSpeed to 450.

// slow down as quickly as possible, then leave engine on to drain fuel
function ascentAbort {
  if ship:velocity:surface:mag < 600 {
    output("Safe velocity reached, payload fairings jettisoned @ " + round(ship:altitude/1000, 3) + "km").
    for plf in fairings plf:doevent("jettison fairing").
    set currThrottle to 0.10.
    operations:remove("ascentAbort").
  }
  if pointingAt(ship:retrograde:forevector, 20) set currThrottle to 1.
  if not pointingAt(ship:retrograde:forevector, 20) set currThrottle to 0.5.
}

function chuteDeployCheck {
  if ship:velocity:surface:mag < chuteSafeSpeed {
    operations:remove("chuteDeployCheck").
    output("Safe speed for chute deployment reached").
    rcs off.
    unlock steering.
    chute1:doevent("deploy chute").
    chute2:doevent("deploy chute").
    set operations["popChute"] to popChute@.
  }
}

function popChute {
  if chute1:hasevent("cut chute") {
    operations:remove("popChute").
    output("Initial chute deploy triggered @ " + round(ship:altitude/1000, 3) + "km").
    set operations["onFullDeploy"] to onFullDeploy@.
  }
}

function onFullDeploy {
  if abs(ship:verticalspeed) <= 25 {
    operations:remove("onFullDeploy").
    output("Full chute deployment @ " + round(ship:altitude, 3) + "m").
    set operations["coastToLanding"] to coastToLanding@.
  }
}

function coastToLanding {
  if ship:status = "SPLASHED" or ship:status = "LANDED" {
    output(ship:status + " @ " + round(abs(chuteSpeed), 3) + "m/s, " + round(circle_distance(latlng(getter("launchPositionLat"),getter("launchPositionLng")), ship:geoposition, ship:orbit:body:radius)/1000, 3) + "km downrange").
    operations:remove("coastToLanding").
    output("flight operations concluded").
    if ship:status = "SPLASHED" when kuniverse:canquicksave then kuniverse:quicksaveto(ship:name + " - Splashdown").
    else when kuniverse:canquicksave then kuniverse:quicksaveto(ship:name + " - Touchdown").
  } else set chuteSpeed to ship:verticalspeed.
}

// give the stage time to re-orient
sleep("ascentAbort", ascentAbort@, 15, RELATIVE_TIME, PERSIST_N).
set operations["chuteDeployCheck"] to chuteDeployCheck@.