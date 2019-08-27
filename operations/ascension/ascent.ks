// functions are in the order of flight operations
function lesAbortMonitor {

  // can be triggered by manual abort or no longer being able to detect the fuel tank
  if abort or not ship:partstagged("tank"):length {
    output("LES abort triggered!").

    // stop any ascent operations and remove locked variables related to lower stages
    operations:remove("maxQmonitor").
    operations:remove("TWRmonitor").
    operations:remove("ascentToPitchHold").
    operations:remove("ascentToMeco").
    unlock engineStatus.
    unlock engineThrust.
    
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

function terminalCount {

  // monitor for ignition at T-6 seconds
  if time:seconds >= getter("launchTime") - 6 {
    operations:remove("terminalCount").
    set operations["ignition"] to ignition@.
    sleepTimers:remove("monitorEcDrain").
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

      // wait until we've cleared the service towers (which stand 8.1m tall)
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
          unlock steering.
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
              }
            }
          }
        }
      }

    // takeoff thrust failed to set
    } else {
      setAbort(true, "Engine TWR not set for launch commit. Only at " + (engineThrust / weight)).
      engine:doevent("shutdown engine").
    }
  }
  operations:remove("launch").
}

function throttleUp {
  if alt:radar >= launchHeight + 8.1 {

    // enable guidance
    // pitch over steering taken from https://www.youtube.com/watch?v=NzlM6YZ9g4w
    // https://www.wolframalpha.com/input/?i=quadratic+fit((76,89.6),+(5000,82),+(10000,75),+(20000,62),+(30000,51.5),+(40000,44))
    lock pitch to 1.21101E-8 * ship:altitude^2 - 0.001634 * ship:altitude + 89.8602.
    set hdgHold to 53.
    lock steering to heading(hdgHold,pitch).
    set lastPitch to pitch.

    // throttle up to full
    // also enable MECO checks in case pitch hold is not reached
    lock throttle to 1.
    sleep("ascentToPitchHold", ascentToPitchHold@, 1, true, false). // wait so pitch value changes
    set operations["ascentToMeco"] to ascentToMeco@.
    set operations["maxQmonitor"] to maxQmonitor@.
    set operations["TWRmonitor"] to TWRmonitor@.
    output("Tower cleared, flight guidance enabled & throttle to full").
    operations:remove("throttleUp").
  }
}

function maxQmonitor {
  if ship:q > maxQ set maxQ to ship:q.
  else operations:remove("maxQmonitor").
}

function TWRmonitor {
  set weight to ((ship:mass - 0.1) * (surfaceGravity/((((ship:orbit:body:radius + ship:altitude)/1000)/(ship:orbit:body:radius/1000))^2))).
  if engineThrust / weight >= 2.5 {
    lock throttle to 2.5 * ship:mass * (surfaceGravity/((((ship:orbit:body:radius + ship:altitude)/1000)/(ship:orbit:body:radius/1000))^2)) / getAvailableThrust().
    output("Thrust locked to 2.5").
    operations:remove("TWRmonitor").
  }
}

function ascentToPitchHold {  

  // keep track of the actual pitch and when it reaches 44° hold there
  if pitch_for(ship) <= 44 {
    lock pitch to 44.
    output("Max pitch reached, holding at 44 degrees").
    operations:remove("ascentToPitchHold").
    return.
  }

  // also switch to pitch hold if calculated pitch value starts to rise
  if pitch > lastPitch {
    lock pitch to 44.
    output("Pitch profile increasing at " + round(pitch, 3) + ". Switching to hold at 44 degrees").
    operations:remove("ascentToPitchHold").
  }
  set lastPitch to pitch.
}

function ascentToMeco {
  if engineStatus = "Flame-Out!" {
    unlock throttle.
    unlock steering.
    output("Main engine burn complete").
    operations:remove("ascentToMeco").
    operations:remove("lesAbortMonitor").
  }
}

// begin check of control surfaces at T-15s
function ctrlCheckStart {
  if time:seconds >= getter("launchTime") - 15 {
    set ship:control:pitch to 1.
    operations:remove("ctrlCheckStart").
    sleep("ctrlCheckPitchDown", ctrlCheckPitchDown@, 1, true, false).
  }
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

sleep("beginTCount", beginTCount@, getter("launchTime") - 120, false, false).
output("Launch/Ascent ops ready, awaiting terminal count").