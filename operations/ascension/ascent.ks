// functions are in the order of flight operations
function terminalCount {

  // until launch, ensure that EC levels are not falling faster than they should be
  set currEC to EClvl.
  if currEC - EClvl >= maxECdrain {
    setAbort(true, "EC drain is excessive at " + round(currEC - EClvl, 3) + "ec/s").
    operations:remove("terminalCount").
  }

  // set up for ignition at T-6 seconds
  if time:seconds >= launchTime - 6 {
    operations:remove("terminalCount").
    set operations["ignition"] to ignition@.
  }
}

function ignition {

  // ensure we have clearance to proceed with ignition
  if not abort {

    // ignite the engine at 10% thrust to ensure good chamber pressures
    output("Ignition").
    engine:doevent("activate engine").

    // pause a sec to allow ignition
    sleep("throttleUp", throttleUp@, 1, true, false).
  }
  operations:remove("ignition").
}

function throttleUp {

  // check chamber pressures over the next two seconds if ignition was successful
  if engineStatus <> "Nominal" setAbort(true, "Engine ignition failure. Status: " + engineStatus).   

  // ensure all is still well before throttling up to launch power
  if not abort and time:seconds >= launchTime - 3 {

    // throttle up to and maintain a TWR of 1.2
    // take into account the mass of the engine clamp
    output("Go for launch thrust").
    lock throttle to 1.2 * (ship:mass - 0.10) * (surfaceGravity/((((ship:orbit:body:radius + ship:altitude)/1000)/(ship:orbit:body:radius/1000))^2)) / getAvailableThrust().

    // move on to launch
    operations:remove("throttleUp").
    sleep("launch", launch@, launchTime, false, false).
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
      
      // begin telemetry logging with an intial entry followed by one every second
      logData().
      sleep("datalogger", logData@, 1, true, true).
      
      // wait until we've cleared the service towers (which stand 8.1m tall)
      // this is so the pad and engine clamp are not damaged by engine exhaust
      set launchHeight to alt:radar.
      when alt:radar >= launchHeight + 8.1 then {

        // enable guidance
        // pitch over steering taken from https://www.youtube.com/watch?v=NzlM6YZ9g4w
        // https://www.wolframalpha.com/input/?i=quadratic+fit((87,89.6),+(10000,70),+(20000,55),+(30000,43))
        lock pitch to 1.94586E-8 * alt:radar^2 - 0.00213732 * alt:radar + 89.6957.
        lock steering to heading(hdgHold,pitch).

        // throttle up to full and head for max Q
        set currThrottle to 1.
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

  // we've reached max Q
  if maxQ > ship:Q {
    output("MaxQ: " + round(ship:Q * constant:ATMtokPa, 3) + "kPa").
    
    // gradually decrease throttle amount as we climb to not overspeed & heat up
    sleep("throttleBack", throttleBack@, 1, true, true).

    set phase to "Max Q".
    operations:remove("ascentToMaxQ").
    set operations["ascentToPitchHold"] to ascentToPitchHold@.
  }
}

function throttleBack {
  set currThrottle to currThrottle - 0.005.
}

function ascentToPitchHold {

  // hold pitch at 43° and press to MECO
  if pitch <= 43 {
    set pitch to 43.
    operations:remove("ascentToPitchHold").
    set operations["ascentToMeco"] to ascentToMeco@.
  }
}

function ascentToMeco {
  if engineStatus = "Flame-Out!" {
    output("Main engine burn complete").
    sleepTimers:remove("throttleBack").
    operations:remove("ascentToMeco").
    set phase to "Coast to Apokee".
    set operations["payloadDecouple"] to payloadDecouple@.
  }
}

// terminal count begins 2min prior to launch
when time:seconds >= launchTime - 120 then {
  output("Terminal count begun, monitoring EC levels").
  set operations["terminalCount"] to terminalCount@.

  // retract the service towers
  for tower in serviceTower tower:doevent("release clamp").
}

output("Launch/Ascent ops ready, awaiting terminal count").