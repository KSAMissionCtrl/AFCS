// functions are in the order of flight operations
function terminalCount {

  // until launch, ensure that EC levels are not falling faster than they should be
  set currEC to EClvl.
  if currEC - EClvl >= maxECdrain {
    setAbort(true, "EC drain is excessive at " + round(currEC - EClvl, 3) + "ec/s").
    operations:remove("terminalCount").
  }

  // set up for ignition at T-6 seconds
  when time:seconds >= launchTime - 6 then {
    operations:remove("terminalCount").
    set operations["ignition"] to ignition@.
  }
}

function ignition {

  // ensure we have clearance to proceed with ignition
  if not abort {

    // ignite the engine at 10% thrust to ensure good chamber pressures
    lock throttle to 0.1.
    output("Ignition").
    engine:doevent("activate engine").

    // pause a sec to allow ignition
    set waitTime to floor(time:seconds).
    when time:seconds - waitTime >= 1 then {

      // check chamber pressures over the next two seconds if ignition was successful
      if engineStatus = "Nominal" set operations["throttleUp"] to throttleUp@.
      else setAbort(true, "Engine ignition failure. Status: " + engineStatus).   
    }
  }
  operations:remove("ignition").
}

function throttleUp {

  // ensure all is still well before throttling up to launch power
  if not abort and time:seconds >= launchTime - 3 {

    // throttle up to and maintain a TWR of 1.2
    // take into account the mass of the engine clamp
    output("Go for launch thrust").
    lock throttle to 1.2 * (ship:mass - 0.10) * (surfaceGravity/((((ship:orbit:body:radius + ship:altitude)/1000)/(ship:orbit:body:radius/1000))^2)) / getAvailableThrust().

    // move on to launch
    operations:remove("throttleUp").
    when time:seconds >= launchTime then set operations["launch"] to launch@.
  }
}

function launch {

  // last check for green light as this function was called after a 3s period
  if not abort { 

    // ensure we are in fact at a 1.2 TWR
    set weight to ((ship:mass - 0.1) * (surfaceGravity/((((ship:orbit:body:radius + ship:altitude)/1000)/(ship:orbit:body:radius/1000))^2))).
    if engineThrust / weight >= 1.2 {

      // disengage engine clamp
      stage.
      output("Launch!").
      
      // setup some triggers, nested so only a few are running at any given time
      when ship:orbit:periapsis > 0 then output("Perikee positive").
      when ship:orbit:apoapsis > 70000 then {
        output("We are going to space!").
        when ship:altitude >= 70000 then {
          output("Space reached!").
          unlock steering.
        }
      }
        
      // handle certain things regardless of what flight state we are in
      set operations["ongoingOps"] to ongoingOps@.
      
      // wait until we've cleared the service towers (which stand 8.1m tall)
      // this is so the pad and engine clamp are not damaged by engine exhaust
      set launchHeight to alt:radar.
      when alt:radar >= launchHeight + 8.1 then {

        // enable guidance
        // pitch over steering taken from https://www.youtube.com/watch?v=NzlM6YZ9g4w
        // http://www.wolframalpha.com/input/?i=quadratic+fit((0,89),+(10000,60),+(20000,45),+(35000,15))
        lock pitch to 1.48139E-8 * alt:radar^2 - 0.00257865 * alt:radar + 87.7645.
        lock steering to heading(hdgHold,pitch).
        set waitTime to floor(time:seconds).

        // throttle up to full and head for max Q
        lock throttle to currThrottle.
        set operations["ascentToMaxQ"] to ascentToMaxQ@.
        set phase to "Tower Cleared".
        output("Tower cleared, flight guidance enabled & throttle to full").
      }

    // takeoff thrust failed to set
    } else {
      setAbort(true, "Engine TWR not set for launch commit. Only at " + (engineThrust / weight)).
      engine:doevent("shutdown engine").
    }
  }
  operations:remove("launch").
}

function ascentToMaxQ {

  // keep track of the current dynamic pressure to know when it peaks
  if ship:Q > maxQ set maxQ to ship:Q.

  // do some events once per second instead of once per tick
  if time:seconds - waitTime > 1 {
    set waitTime to floor(time:seconds).

    // if we've passed through dangerous pressure levels, throttle back continuously
    // do not throttle back past 10% cutoff
    if ship:Q * constant:ATMtokPa > MaxQLimit and currThrottle > 0.1 {
      output("High dynamic pressure detected - throttle back in progress").
      set currThrottle to currThrottle - 0.05.
      if currThrottle < 0.1 set currThrottle to 0.1.
    }
  }

  // we've reached max Q
  if maxQ > ship:Q {
    output("MaxQ: " + round(ship:Q * constant:ATMtokPa, 3) + "kPa").
    
    // reset the throttle to max in case we throttled back due to overpressure
    set currThrottle to 1.

    // if our TWR ever exceeds 2.5 during ascent, hold there
    lock weight to (ship:mass * (surfaceGravity/((((ship:orbit:body:radius + ship:altitude)/1000)/(ship:orbit:body:radius/1000))^2))).
    when engineThrust / weight >= 2.5 then {
      output("Throttle locked to TWR of 2.5").
      set weight to 1.
      lock throttle to 2.5 * ship:mass * (surfaceGravity/((((ship:orbit:body:radius + ship:altitude)/1000)/(ship:orbit:body:radius/1000))^2)) / getAvailableThrust().
    }
    set phase to "Max Q".
    operations:remove("ascentToMaxQ").
    set operations["ascentToMeco"] to ascentToMeco@.
  }
}

function ascentToMeco {

  // cut off the engine with Pe still in the atmosphere so the rocket eventually returns
  // align to prograde vector to reduce whatever drag remains during climb out of atmosphere
  if ship:orbit:periapsis > 50000 meco("MECO").

  // did we run out of fuel before attaining orbit?
  if engineStatus = "Flame-Out!" meco("Flameout").
}

function meco {
  parameter situation.
  output(situation + " with periapsis of " + round(ship:orbit:periapsis/1000, 3) + "km").
  lock steering to ship:srfprograde:vector.
  operations:remove("ascentToMeco").
  set operations["toAp"] to toAp@.
  set phase to "Orbit " + obtNum.
}

// terminal count begins 2min prior to launch
when time:seconds >= launchTime - 120 then {
  output("Terminal count begun, monitoring EC levels").
  set operations["terminalCount"] to terminalCount@.

  // retract the service towers, one at a time
  serviceTower[0]:doevent("release clamp").
  set waitTime to time:seconds.
  when time:seconds - waitTime > 1 then serviceTower[1]:doevent("release clamp").
}
output("Launch/Ascent ops ready, awaiting terminal count").