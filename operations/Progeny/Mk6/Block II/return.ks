set chuteSafeSpeed to 470.
set chuteSpeed to 0.
set maxQ to 0.
when maxQ > ship:q then output("MaxQ: " + round(ship:Q * constant:ATMtokPa, 3) + "kPa @ " + round(ship:altitude/1000, 3) + "km").
set chute to ship:partstagged("chutecomms")[0]:getmodule("RealChuteFAR").

function ascentAbort {
  unlock stageOne.
  unlock stageTwo.
  
  // wait until we've reached the top of our arc then prepare to recover
  when ship:verticalspeed < 0 then {
    output("Apokee achieved @ " + round(ship:altitude/1000, 3) + "km").
    set operations["chuteDeploy"] to chuteDeploy@.
    set maxQ to 0.
  }
  if ship:orbit:apoapsis > 70000 {
    when ship:altitude > 70000 then {
      output("Space reached!").
      when ship:altitude <= 70000 then output("Atmospheric interface breached").
    }
  }
}

function chuteDeploy {
  if ship:Q > maxQ set maxQ to ship:Q.

  // keep track of speed and altitude
  // release chute as soon as it's safe
  if ship:velocity:surface:mag < chuteSafeSpeed and ship:altitude < 30000 {
    chute:doevent("deploy chute").
    when chute:hasevent("cut chute") then {
      output("Initial chute deploy triggered @ " + round(ship:altitude/1000, 3) + "km").
      when abs(ship:verticalspeed) <= 13 then {
        output("Full chute deployment @ " + round(ship:altitude, 3) + "m").
        set operations["coastToLanding"] to coastToLanding@.
      }
    }
    operations:remove("chuteDeploy").
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