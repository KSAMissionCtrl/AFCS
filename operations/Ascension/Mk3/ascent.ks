// functions are in the order of flight operations

// begin check of control surfaces at T-7s
// just do a roll check both ways to make all four fins travel
function ctrlCheckStart {
  set ship:control:roll to 1.
  operations:remove("ctrlCheckStart").
  sleep("ctrlCheckRoll", ctrlCheckRoll@, 1, RELATIVE_TIME, PERSIST_N).
}
function ctrlCheckRoll {
  set ship:control:roll to -1.
  operations:remove("ctrlCheckRoll").
  sleep("ctrlCheckFinish", ctrlCheckFinish@, 1, RELATIVE_TIME, PERSIST_N).
}
function ctrlCheckFinish {
  set ship:control:roll to 0.
  unlock steering.
  set ctrlCheckComplete to true.
  operations:remove("ctrlCheckFinish").
}

function mes {

  // ensure we have clearance to proceed with ignition
  if not launchAbort and ctrlCheckComplete {

    // begin telemetry logging with an intial entry followed by one every second
    logData().
    sleep("datalogger", logData@, logInterval, RELATIVE_TIME, PERSIST_Y).

    // engine alternator will now provide power
    sleepTimers:remove("monitorEcDrain").

    // ignite the engine at 10% thrust to ensure good chamber pressures
    set currThrottle to 0.10.
    output("MES - Main engine start").
    stage.

    // wait for chamber pressure to stabilize
    sleep("checkEngine", checkEngine@, 1, RELATIVE_TIME, PERSIST_N).

  } else if not ctrlCheckComplete setAbort(true, "Low hydraulic pressure").
  operations:remove("mes").
}

function checkEngine {

  // check to ensure nominal ignition and abort if not, continue to launch if so
  if s1engineStatus <> "Nominal" or s1engineReliability:contains("malfunction") setAbort(true, "Engine ignition failure. Status: " + s1engineStatus).
  else sleep("launch", launch@, getter("launchTime"), ABSOLUTE_TIME, PERSIST_N).
  operations:remove("checkEngine").
}

function launch {

  // last check for green light
  if not launchAbort { 

    // disengage engine clamp, ignite the SRBs
    stage.
    output("SRB ignition and launch! Flight guidance enabled, rolling to ascent heading").
    
    // enable guidance to begin rocket roll onto heading
    lock steering to heading(hdgHold,pitch).
    sleep("phase1Ascent", phase1Ascent@, 10, RELATIVE_TIME, PERSIST_N).

    // wait for SRB thrust to begin decreasing before throttling up main engine
    set operations["throttleCtrl"] to throttleCtrl@.

    // begin to monitor various ascent milestones & status
    set operations["maxQmonitor"] to maxQmonitor@.
    set operations["maxQcheck"] to maxQcheck@.
    set operations["apSpace"] to apSpace@.

  } else {

    // make double sure the engine was shut down by whatever abort was thrown
    if s1engine:hasevent("shutdown engine") {
      s1engine:doevent("shutdown engine").
      output("Engine shut down").
    }
  }
  operations:remove("launch").
}

// roll should have completed by now, or close enough to begin pitch over
function phase1Ascent {

  // stabilize rocket by diminishing roll/yaw control
  for fin in finsHorz fin:setfield("roll %", 0).
  for fin in finsVert fin:setfield("ctrl dflct", 5).

  // pitch over steering taken from https://www.youtube.com/watch?v=NzlM6YZ9g4w
  // https://www.wolframalpha.com/input/?i=quadratic+fit%28%28326%2C89.98%29%2C+%281717%2C75.11109988%29%2C+%284089%2C60.85945619%29%29
  lock pitch to 1.24398E-6 * ship:altitude^2 - 0.0132308 * ship:altitude + 94.161.
  operations:remove("phase1Ascent").
  set operations["phase2Ascent"] to phase2Ascent@.
  output("Roll control minimized, ascent guidance Phase 1 active @ " + round(ship:altitude/1000, 3) + "km").
}

function throttleCtrl {
  set currentThrust to 0.
  list engines in engList.
  for eng in engList { if eng:ignition { set currentThrust to currentThrust + eng:thrust. } }

  // when the TWR reches 1.5 stabilize and hold with the main throttle
  set weight to (ship:mass * (surfaceGravity/((((ship:orbit:body:radius + ship:altitude)/1000)/(ship:orbit:body:radius/1000))^2))).
  if currentThrust / weight <= 1.5 {

    // adjust throttle to maintain TWR 
    lock throttle to (1.5 * ship:mass * (surfaceGravity/((((ship:orbit:body:radius + ship:altitude)/1000)/(ship:orbit:body:radius/1000))^2)) - srbThrust) / s1EngineAvailableThrust.
    output("Throttling main engine to maintain TWR of 1.5 @ " + round(ship:altitude/1000, 3) + "km").

    // monitor for SRB detach
    operations:remove("throttleCtrl").
    set operations["beco"] to beco@.
  }
}

function phase2Ascent {
  if ship:altitude >= 4089 {

    // https://www.wolframalpha.com/input/?i=quadratic+fit%28%284089%2C60.85945619%29%2C+%287168%2C+55.28068271%29%2C+%2810807%2C49.65589479%29%29
    lock pitch to 3.96223E-8 * ship:altitude^2 - 0.00225791 * ship:altitude + 69.4296.
    operations:remove("phase2Ascent").
    set operations["phase3Ascent"] to phase3Ascent@.
    output("Ascent guidance Phase 2 active @ " + round(ship:altitude/1000, 3) + "km").
  }
}

// dump the SRBs once they expire and push the throttle to full
function beco {
  if srbStatus = "Flame-Out!" {
    set currThrottle to 1.
    lock throttle to currThrottle.
    unlock srbStatus.
    unlock srbThrust.
    wait 0.001.
    for decoupler in srbDecouplers decoupler:doevent("decouple").
    output("BECO - SRBs released, main engine to full thrust @ " + round(ship:altitude/1000, 3) + "km").
    operations:remove("beco").
    set operations["meco"] to meco@.
    sleep("SRBsave", SRBsave@, 1, RELATIVE_TIME, PERSIST_N).
  }
}

function phase3Ascent {
  if abort operations:remove("phase3Ascent").
  if ship:altitude >= 10807 {

    // https://www.wolframalpha.com/input/?i=quadratic+fit%28%2810807%2C49.65589479%29%2C+%2817575%2C+43.16086332%29%2C+%2828383%2C+36.66960544%29%29
    lock pitch to 2.04296E-8 * ship:altitude^2 - 0.0015395 * ship:altitude + 63.9073.
    operations:remove("phase3Ascent").
    set operations["phase4Ascent"] to phase4Ascent@.
    output("Ascent guidance Phase 3 active @ " + round(ship:altitude/1000, 3) + "km").
  }
}

function phase4Ascent {
  if abort operations:remove("phase4Ascent").
  if ship:altitude >= 28383 {

    // https://www.wolframalpha.com/input/?i=quadratic+fit%28%2810807%2C49.65589479%29%2C+%2817575%2C+43.16086332%29%2C+%2828383%2C+36.66960544%29%29
    lock pitch to 6.95205E-9 * ship:altitude^2 - 0.00124024 * ship:altitude + 66.2709.
    operations:remove("phase4Ascent").
    set operations["phase5Ascent"] to phase5Ascent@.
    output("Ascent guidance Phase 4 active @ " + round(ship:altitude/1000, 3) + "km").
  }
}

function meco {
  if s1engineStatus = "Flame-Out!" {
    unlock s1engineStatus.
    unlock s1EngineAvailableThrust.
    output("MECO. Stand by for staging @ " + round(ship:altitude/1000, 3) + "km").
    operations:remove("meco").
    sleep("staging", staging@, 1, RELATIVE_TIME, PERSIST_N).
  }
}

function staging {
  stage.
  rcs on.
  output("Staging. Reaction Control System activated @ " + round(ship:altitude/1000, 3) + "km").
  operations:remove("staging").
  sleep("ses1", ses1@, 1, RELATIVE_TIME, PERSIST_N).
  set operations["abortMonitor"] to abortMonitor@.
}

function ses1 {
  stage.
  wait 0.001.
  if s2engineStatus = "Nominal" and not s2engineReliability:contains("malfunction") {
    output("SES-1 @ " + round(ship:altitude/1000, 3) + "km").
    set operations["plfDeploy"] to plfDeploy@.
    set operations["seco1"] to seco1@.
  } else {
    output("Engine failure! Ascent abort initiated").
    abort on.
  }
  operations:remove("ses1").
}

function plfDeploy {
  if ship:altitude >= 50000 {
    for plf in fairings plf:doevent("jettison fairing").
    output("PLF detached @ 50km").
    operations:remove("plfDeploy").
  }
}

function phase5Ascent {
  if abort operations:remove("phase5Ascent").
  if ship:altitude >= 52335 {

    // https://www.wolframalpha.com/input/?i=quadratic+fit%28%2852335%2C+20.40406307%29%2C+%2866040%2C+10.44586471%29%2C+%2880153%2C+0.447038867%29%29
    lock pitch to 6.51637E-10 * ship:altitude^2 - 0.000803748 * ship:altitude + 60.6834.
    operations:remove("phase5Ascent").
    output("Ascent guidance Phase 5 active @ " + round(ship:altitude/1000, 3) + "km").
  }
}

function seco1 {
  if ship:altitude >= 80153 {
    lock steering to ship:prograde.
    set currThrottle to 0.
    output("SECO-1. Orienting prograde @ " + round(ship:altitude/1000, 3) + "km").
    operations:remove("seco1").
    operations:remove("abortMonitor").
    set operations["sasHold"] to sasHold@.
    when kuniverse:canquicksave then kuniverse:quicksaveto(ship:name + " - SECO-1").
  }
}

// enable Kerbin II's reaction wheel system to conserve RCS fuel and hold the vessel steady
function sasHold {
  if pointingAt(ship:prograde:forevector) {
    unlock steering.
    rcs off.
    sas on.
    wait 0.1.
    set sasmode to "prograde".
    operations:remove("sasHold").
  }
}

// these functions are run parallel during ascent but roughly in the following order
function maxQmonitor {
  if ship:q > maxQ {
    set maxQ to ship:q.

    // restart check if Q begins to rise again (unless we are falling)
    if not operations:haskey("maxQcheck") and ship:verticalspeed > 0 set operations["maxQcheck"] to maxQcheck@.
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
    set operations["space"] to space@.
  }
}
function space {
  if ship:altitude >= 70000 {
    output("Space reached").
    kuniverse:quicksave().
    operations:remove("space").
  }
}
function abortMonitor {
  
  // if the viklun stage cannot maintain attitude, hold ascent to save fuel for OIB in space
  if abort {
    output("Ascent abort called by launch control @ " + round(ship:altitude/1000, 3) + "km").
    set currThrottle to 0.10.
    operations:remove("seco1").
    operations:remove("abortMonitor").
    operations:remove("plfDeploy").
    lock steering to ship:retrograde.
    kuniverse:quicksave().
    runOpsFile("abort").
  }
}
function SRBsave { 
  kuniverse:quicksave().
  operations:remove("SRBsave").
}

output("Launch/Ascent ops ready, awaiting terminal count").