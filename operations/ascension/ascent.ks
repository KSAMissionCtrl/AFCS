// functions are in the order of flight operations
function lesAbortMonitor {

  // can be triggered by manual abort or no longer being able to detect the fuel tank
  if abort or not ship:partstagged("tank"):length {
    output("LES abort triggered!").

    // stop any ascent operations and remove locked variables related to lower stages
    operations:remove("maxQmonitor").
    operations:remove("ascentToPitchHold").
    operations:remove("ascentToMeco").
    set engineStatus to 0.
    set engineThrust to 0.
    
    // if there is still a decoupler, then detach it
    if ship:partstagged("decoupler"):length decoupler:doevent("decouple").

    // fire all LES rocket motors
    lesKickMotor:doevent("activate engine").
    wait 0.005.

    // if kick motor did not fire, we need to light off one of the push motors first to angle the capsule away
    // make sure not to light off the motor whose status we are tracking
    if lesKickStatus <> "Nominal" {
      lesPushMotorRight:doevent("activate engine").
      wait 0.02.
      lesPushMotorDw:doevent("activate engine").
      lesPushMotorUp:doevent("activate engine").
      lesPushMotorLeft:doevent("activate engine").
    } else {
      lesPushMotorRight:doevent("activate engine").
      lesPushMotorDw:doevent("activate engine").
      lesPushMotorUp:doevent("activate engine").
      lesPushMotorLeft:doevent("activate engine").
    }

    // switch over to landing state and dump the tower once LES expires
    when lesStatus = "Flame-Out!" then {
      lesDecoupler:doevent("decouple").
      set operations["chuteDeployAbort"] to chuteDeployAbort@.
      set maxQ to 0.
      output("LES tower burnout. Prepped for chute deploy").
    }
    operations:remove("lesAbortMonitor").
  }
}

function onTerminalCount {
  output("Terminal count begun, monitoring EC levels").
  set operations["terminalCountMonitor"] to terminalCountMonitor@.
  operations:remove("onTerminalCount").

  // retract the service towers
  for tower in serviceTower tower:doevent("release clamp").
}

function terminalCountMonitor {

  // until launch, ensure that EC levels are not falling faster than they should be
  set currEC to ship:electriccharge.
  if currEC - ship:electriccharge >= maxECdrain {
    setAbort(true, "EC drain is excessive at " + round(currEC - ship:electriccharge, 3) + "ec/s").
    operations:remove("terminalCountMonitor").
  }

  // set up for ignition at T-6 seconds
  if time:seconds >= getter("launchTime") - 6 {
    operations:remove("terminalCountMonitor").
    set operations["ignition"] to ignition@.
  }
}

function ignition {

  // ensure we have clearance to proceed with ignition
  if not launchAbort {

    // ignite the engine at 10% thrust to ensure good chamber pressures
    output("Ignition").
    engine:doevent("activate engine").

    // begin telemetry logging with an intial entry followed by one every second
    logData().
    sleep("datalogger", logData@, 1, true, true).
      
    // pause a sec to allow ignition
    sleep("throttleUp", throttleUp@, 1, true, false).
  }
  operations:remove("ignition").
}

function throttleUp {

  // check chamber pressures over the next two seconds if ignition was successful
  if engineStatus <> "Nominal" setAbort(true, "Engine ignition failure. Status: " + engineStatus).   

  // ensure all is still well before throttling up to launch power
  if not launchAbort and time:seconds >= getter("launchTime") - 3 {

    // throttle up to and maintain a TWR of 1.2
    // take into account the mass of the engine clamp
    output("Go for launch thrust").
    lock throttle to 1.2 * (ship:mass - 0.10) * (surfaceGravity/((((ship:orbit:body:radius + ship:altitude)/1000)/(ship:orbit:body:radius/1000))^2)) / getAvailableThrust().

    // move on to launch
    operations:remove("throttleUp").
    sleep("launch", launch@, getter("launchTime"), false, false).
  }
}

function launch {

  // last check for green light as this function was called after a 3s period
  if not launchAbort { 

    // ensure we are in fact at a 1.2 TWR
    set weight to ((ship:mass - 0.1) * (surfaceGravity/((((ship:orbit:body:radius + ship:altitude)/1000)/(ship:orbit:body:radius/1000))^2))).
    if engineThrust / weight >= 1.2 {

      // disengage engine clamp
      stage.
      output("Launch!").
      
      // wait until we've cleared the service towers (which stand 8.1m tall)
      // this is so the pad and engine clamp are not damaged by engine exhaust
      set launchHeight to alt:radar.
      when alt:radar >= launchHeight + 8.1 then {

        // enable guidance
        // pitch over steering taken from https://www.youtube.com/watch?v=NzlM6YZ9g4w
        // https://www.wolframalpha.com/input/?i=quadratic+fit((82,89.85),+(5000,81),+(10000,72),+(20000,59),+(30000,51),+(40000,48))
        lock pitch to 2.51091E-8 * ship:altitude^2 - 0.00206121 * ship:altitude + 90.2484.
        lock steering to heading(hdgHold,pitch).

        // throttle up to full and head for pitch hold
        // also enable MECO checks in case pitch hold is not reached
        set currThrottle to 1.
        lock throttle to currThrottle.
        set operations["ascentToPitchHold"] to ascentToPitchHold@.
        set operations["ascentToMeco"] to ascentToMeco@.
        set operations["maxQmonitor"] to maxQmonitor@.
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

function maxQmonitor {
  if ship:q > maxQ set maxQ to ship:q.
}

function ascentToPitchHold {

  // keep track of the pitch and when it reaches 49° hold there
  if pitch <= 48 {
    set pitch to 48.
    output("Max pitch reached, holding at 48 degrees").
    operations:remove("ascentToPitchHold").
  }
}

function ascentToMeco {
  if engineStatus = "Flame-Out!" {
    set currThrottle to 0.
    unlock steering.
    output("Main engine burn complete").
    operations:remove("ascentToMeco").
    set operations["payloadDecouple"] to payloadDecouple@.
  }
}

set operations["lesAbortMonitor"] to lesAbortMonitor@.
sleep("onTerminalCount", onTerminalCount@, getter("launchTime") - 120, false, false).
output("Launch/Ascent ops ready, awaiting terminal count").