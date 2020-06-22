// functions are in the order of flight operations
function lesAbortMonitor {
  if not ship:partstagged("lesTower"):length {
    unlock lesStatus.
    unlock lesKickStatus.
    operations:remove("lesAbortMonitor").
  }

  // can be triggered by manual abort or no longer being able to detect the fuel tank
  if abort or not ship:partstagged("tank"):length {
    output("LES abort triggered!").

    // stop any ascent operations and remove locked variables related to lower stages
    operations:remove("maxQmonitor").
    operations:remove("ascentToMeco").
    unlock engineStatus.
    unlock engineThrust.
    unlock hg1Status.
    unlock hg2Status.
    
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

    // monitor tower burn
    set operations["lesTowerMonitor"] to lesTowerMonitor@.
    operations:remove("lesAbortMonitor").
  }
}

// begin check of control surfaces at T-12s
function ctrlCheckStart {
  set ship:control:roll to 1.
  operations:remove("ctrlCheckStart").
  sleep("ctrlCheckRoll", ctrlCheckRoll@, 1, true, false).
}
function ctrlCheckRoll {
  set ship:control:roll to -1.
  operations:remove("ctrlCheckRoll").
  sleep("ctrlCheckPitchUp", ctrlCheckPitchUp@, 1, true, false).
}
function ctrlCheckPitchUp {
  set ship:control:roll to 0.
  set ship:control:pitch to 1.
  operations:remove("ctrlCheckPitchUp").
  sleep("ctrlCheckPitchDw", ctrlCheckPitchDw@, 1, true, false).
}
function ctrlCheckPitchDw {
  set ship:control:pitch to -1.
  operations:remove("ctrlCheckPitchDw").
  sleep("ctrlCheckFinish", ctrlCheckFinish@, 1, true, false).
}
function ctrlCheckFinish {
  set ship:control:pitch to 0.
  unlock steering.
  set ctrlCheckComplete to true.
  operations:remove("ctrlCheckFinish").
}

function ignition {

  // ensure we have clearance to proceed with ignition
  if not launchAbort and ctrlCheckComplete {

    // engine alternator will now provide power
    sleepTimers:remove("monitorEcDrain").

    // ignite the engine at 10% thrust to ensure good chamber pressures
    output("Ignition").
    engine:doevent("activate engine").

    // begin telemetry logging with an intial entry followed by one every second
    logData().
    sleep("datalogger", logData@, 1, true, true).
      
    // pause a sec to allow ignition
    sleep("launchThrust", launchThrust@, logInterval, true, false).
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
    lock throttle to 1.2 * (ship:mass - 0.1) * (surfaceGravity/((((ship:orbit:body:radius + ship:altitude)/1000)/(ship:orbit:body:radius/1000))^2)) / getAvailableThrust().

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
    if round(engineThrust / weight,3) >= 1.2 {

      // disengage engine clamp
      launchClamp:doevent("release clamp").
      output("Launch!").
      wait 0.01.
      
      // use engine alternator
      batt:doevent("Disconnect Battery").

      // adjust throttle to proper TWR now that clamp is gone
      lock throttle to 1.2 * ship:mass * (surfaceGravity/((((ship:orbit:body:radius + ship:altitude)/1000)/(ship:orbit:body:radius/1000))^2)) / getAvailableThrust().

      // wait until we've cleared the service towers
      // this is so the pad and engine clamp are not damaged by engine exhaust
      set launchHeight to alt:radar.
      set operations["throttleUp"] to throttleUp@.

      // initial pitch over
      lock steering to heading(hdgHold, pitch).

      // begin to monitor various ascent milestones
      set operations["maxQmonitor"] to maxQmonitor@.
      set operations["maxQcheck"] to maxQcheck@.
      set operations["apSpace"] to apSpace@.
      
    // takeoff thrust failed to set
    } else {
      setAbort(true, "Engine TWR not set for launch commit. Only at " + (engineThrust / weight)).
      if (engine:hasevent("shutdown engine")) {
        engine:doevent("shutdown engine").
        batt:doevent("Connect Battery").
        output("Engine shut down").
      }
    }
  } else {

    // make double sure the engine was shut down by whatever abort was thrown
    if (engine:hasevent("shutdown engine")) {
      engine:doevent("shutdown engine").
      batt:doevent("Connect Battery").
      output("Engine shut down").
    }
  }
  operations:remove("launch").
}

function throttleUp {
  if alt:radar >= launchHeight + 9 {

    // enable guidance for initial pitchover
    // pitch over steering taken from https://www.youtube.com/watch?v=NzlM6YZ9g4w
    // https://www.wolframalpha.com/input/?i=quadratic+fit%28%2887%2C87%29%2C+%285000%2C83.40%29%2C+%2810000%2C82.11%29%29
    lock pitch to 4.78916E-8 * ship:altitude^2 - 0.000976375 * ship:altitude + 87.0846.
    lock throttle to 1.
    set operations["ascentToGuidanceUpdate"] to ascentToGuidanceUpdate@.
    output("Tower cleared, phase 1 flight guidance enabled & throttle to full").
    operations:remove("throttleUp").
  }
}

function ascentToGuidanceUpdate {
  if ship:altitude >= 10000 {

    // switch guidance for second phase of ascent
    // https://www.wolframalpha.com/input/?i=quadratic+fit%28%2810000%2C82.11%29%2C+%2816500%2C80.965%29%2C+%2825000%2C79.84%29%2C+%2835000%2C78.81%29%2C+%2847500%2C77.76%29%2C+%2860000%2C76.89%29%2C+%2873767%2C76.08%29%29
    lock pitch to 8.87714E-10 * ship:altitude^2 - 0.000165715 * ship:altitude + 83.5466.
    set operations["ascentToMeco"] to ascentToMeco@.
    output("Phase 2 flight guidance enabled").
    operations:remove("ascentToGuidanceUpdate").
  }
}

function ascentToMeco {
  if engineStatus = "Flame-Out!" {
    unlock throttle.
    unlock steering.
    output("Main engine burn complete").
    operations:remove("ascentToMeco").
    operations:remove("lesAbortMonitor").
    batt:doevent("Connect Battery").
  }
}



// these functions are run parallel during ascent but in the following order
// the first two are run both during ascent and re-entry
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
function apSpace {
  if ship:orbit:apoapsis > 70000 {
    output("We are going to space!").
    operations:remove("apSpace").
    set operations["inSpace"] to inSpace@.
  }
}
function inSpace {
  if ship:altitude >= 70000 {
    output("Space reached!").
    operations:remove("inSpace").
    operations:remove("maxQmonitor").
    operations:remove("maxQcheck").
    when kuniverse:canquicksave then kuniverse:quicksaveto(ship:name + " - Space").
  }
}

output("Launch/Ascent ops ready, awaiting terminal count").