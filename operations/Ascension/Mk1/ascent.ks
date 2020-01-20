// functions are in the order of flight operations
function lesAbortMonitor {

  // can be triggered by manual abort or no longer being able to detect the fuel tank
  if abort or not ship:partstagged("tank"):length {
    output("LES abort triggered!").

    // stop any ascent operations and remove locked variables related to lower stages
    operations:remove("maxQmonitor").
    operations:remove("ascentToPitchHold").
    operations:remove("ascentToMeco").
    unlock engineStatus.
    unlock engineThrust.
    
    // if there is still a decoupler, then detach capsule from the fuel tank
    if ship:partstagged("decoupler"):length decoupler:doevent("decouple").

    // fire the kick motor
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

function ignition {

  // ensure we have clearance to proceed with ignition
  if not launchAbort {

    // engine alternator will now provide power
    sleepTimers:remove("monitorEcDrain").

    // ignite the engine at 10% thrust to ensure good chamber pressures
    output("Ignition").
    engine:doevent("activate engine").

    // begin telemetry logging with an intial entry followed by one every second
    logData().
    sleep("datalogger", logData@, 1, true, true).
      
    // pause a sec to allow ignition
    sleep("launchThrust", launchThrust@, 1, true, false).

    // ensure the LES activates in the case of any troubles
    set operations["lesAbortMonitor"] to lesAbortMonitor@.
  }
  operations:remove("ignition").
}

function launchThrust {

  // check chamber pressures over the next two seconds if ignition was successful
  if engineStatus <> "Nominal" setAbort(true, "Engine ignition failure. Status: " + engineStatus).   

  // ensure all is still well before throttling up to launch power
  if not launchAbort and time:seconds >= getter("launchTime") - 3 {

    // throttle up to and maintain a TWR of 1.2
    // take into account the mass of the engine clamp
    output("Go for launch thrust").
    lock throttle to 1.2 * (ship:mass - 0.10) * (surfaceGravity/((((ship:orbit:body:radius + ship:altitude)/1000)/(ship:orbit:body:radius/1000))^2)) / getAvailableThrust().

    // move on to launch
    operations:remove("launchThrust").
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
      
      // adjust throttle to proper TWR now that clamp is gone
      lock throttle to 1.2 * ship:mass * (surfaceGravity/((((ship:orbit:body:radius + ship:altitude)/1000)/(ship:orbit:body:radius/1000))^2)) / getAvailableThrust().

      // wait until we've cleared the service towers
      // this is so the pad and engine clamp are not damaged by engine exhaust
      set launchHeight to alt:radar.
      set operations["throttleUp"] to throttleUp@.

      // initial pitch over
      lock steering to heading(hdgHold, pitch).

      // setup some notification triggers, nested so only a few are running at any given time
      when maxQ > ship:q then output("MaxQ: " + round(ship:Q * constant:ATMtokPa, 3) + "kPa @ " + round(ship:altitude/1000, 3) + "km").
      when ship:orbit:apoapsis > 70000 then {
        output("We are going to space!").
        when ship:altitude >= 70000 then {
          output("Space reached!").
          when ship:verticalspeed <= 0 then {
            output("Apokee achieved @ " + round(ship:altitude/1000, 3) + "km").
            when ship:altitude <= 70000 then {
              output("Atmospheric interface breached").
              set maxQ to 0.
              rcs off.
              sas off.
              set operations["chuteDeploy"] to chuteDeploy@.
              when maxQ > ship:q then {
                output("MaxQ: " + round(ship:Q * constant:ATMtokPa, 3) + "kPa @ " + round(ship:altitude/1000, 3) + "km").
                operations:remove("maxQmonitor").
              }
            }
          }
        }
      }

    // takeoff thrust failed to set
    } else {
      setAbort(true, "Engine TWR not set for launch commit. Only at " + round(engineThrust / weight, 5)).
      engine:doevent("shutdown engine").
    }
  } else {

    // make double sure the engine was shut down by whatever abort was thrown
    engine:doevent("shutdown engine").
  }
  operations:remove("launch").
}

function throttleUp {
  if alt:radar >= launchHeight + 8.1 {

    // enable guidance
    // pitch over steering taken from https://www.youtube.com/watch?v=NzlM6YZ9g4w
    // https://www.wolframalpha.com/input/?i=quadratic+fit((86,89.6),+(5000,79.75),+(10000,70.95),+(20000,57.35),+(30000,48.5),+(40000,45))
    lock pitch to 2.52971E-8 * ship:altitude^2 - 0.00213203 * ship:altitude + 89.7788.
    set hdgHold to 54.
    lock steering to heading(hdgHold,pitch).
    set lastPitch to pitch.

    // throttle up to nearly full, lock TWR and head for pitch hold
    // also enable MECO checks in case pitch hold is not reached
    lock throttle to 1.65 * ship:mass * (surfaceGravity/((((ship:orbit:body:radius + ship:altitude)/1000)/(ship:orbit:body:radius/1000))^2)) / getAvailableThrust().
    sleep("ascentToPitchHold", ascentToPitchHold@, 1, true, false). // wait so pitch value changes
    set operations["ascentToMeco"] to ascentToMeco@.
    set operations["ascentThrottleUp"] to ascentThrottleUp@.
    set operations["maxQmonitor"] to maxQmonitor@.
    output("Tower cleared, flight guidance enabled & throttle set to 1.65 TWR").
    operations:remove("throttleUp").
  }
}

function maxQmonitor {
  if ship:q > maxQ set maxQ to ship:q.
}

function ascentToPitchHold {  

  // keep track of the actual pitch and when it nears 45 hold there
  if pitch_for(ship) <= 45.2 {
    lock pitch to 45.
    output("Max pitch approaching, holding at 45 degrees").
    operations:remove("ascentToPitchHold").
    return.
  }

  // also switch to pitch hold if calculated pitch value starts to rise
  if pitch > lastPitch {
    lock pitch to 45.
    output("Pitch profile increasing at " + round(pitch, 3) + ". Switching to hold at 45 degrees").
    operations:remove("ascentToPitchHold").
  }
  set lastPitch to pitch.
}

// go to max thrust at 40km so we burn out in the atmosphere
function ascentThrottleUp {
  if ship:altitude >= 40000 {
    lock throttle to 1.
    output("Main engine throttle up").
    operations:remove("ascentThrottleUp").
  }
}

function ascentToMeco {
  if engineStatus = "Flame-Out!" {
    unlock throttle.
    output("Main engine burn complete").
    operations:remove("ascentToMeco").
    operations:remove("lesAbortMonitor").

    // decouple the capsule after 10s
    sleep("payloadDecouple", payloadDecouple@, 10, true, false).
  }
}

// begin check of control surfaces at T-15s
function ctrlCheckStart {
  set ship:control:pitch to 1.
  operations:remove("ctrlCheckStart").
  sleep("ctrlCheckPitchDown", ctrlCheckPitchDown@, 1, true, false).
}
function ctrlCheckPitchDown {
  set ship:control:pitch to -1.
  operations:remove("ctrlCheckPitchDown").
  sleep("ctrlCheckRollLeft", ctrlCheckRollLeft@, 1, true, false).
}
function ctrlCheckRollLeft {
  set ship:control:pitch to 0.
  set ship:control:roll to -1.
  operations:remove("ctrlCheckRollLeft").
  sleep("ctrlCheckRollRight", ctrlCheckRollRight@, 1, true, false).
}
function ctrlCheckRollRight {
  set ship:control:roll to 1.
  operations:remove("ctrlCheckRollRight").
  sleep("ctrlCheckYawLeft", ctrlCheckYawLeft@, 1, true, false).
}
function ctrlCheckYawLeft {
  set ship:control:roll to 0.
  set ship:control:yaw to -1.
  operations:remove("ctrlCheckYawLeft").
  sleep("ctrlCheckYawRight", ctrlCheckYawRight@, 1, true, false).
}
function ctrlCheckYawRight {
  set ship:control:yaw to 1.
  operations:remove("ctrlCheckYawRight").
  sleep("ctrlCheckFinish", ctrlCheckFinish@, 1, true, false).
}
function ctrlCheckFinish {
  set ship:control:yaw to 0.
  unlock steering.
  operations:remove("ctrlCheckFinish").
}

sleep("terminalCount", terminalCount@, getter("launchTime") - 120, false, false).
output("Launch/Ascent ops ready, awaiting terminal count").