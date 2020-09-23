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
    s1engine:doevent("activate engine").

    // wait for chamber pressure to stabilize
    sleep("checkEngine", checkEngine@, 1, RELATIVE_TIME, PERSIST_N).

  } else if not ctrlCheckComplete setAbort(true, "Low hydraulic pressure").
  operations:remove("mes").
}

function checkEngine {

  // check to ensure nominal ignition and abort if not, continue to launch if so
  if s1engineStatus <> "Nominal" setAbort(true, "Engine ignition failure. Status: " + s1engineStatus).
  else sleep("launch", launch@, getter("launchTime"), ABSOLUTE_TIME, PERSIST_N).
  operations:remove("checkEngine").
}

function launch {

  // last check for green light
  if not launchAbort { 

    // disengage engine clamp, ignite the SRBs
    launchClamp:doevent("release clamp").
    for srb in srbs srb:doevent("activate engine").
    output("SRB ignition and launch! Flight guidance enabled, rolling to ascent heading").
    
    // enable guidance to begin rocket roll onto heading
    lock steering to heading(hdgHold,pitch).
    sleep("phase1Ascent", phase1Ascent@, 6, RELATIVE_TIME, PERSIST_N).

    // wait for SRB thrust to begin decreasing before throttling up main engine
    set operations["throttleUp"] to throttleUp@.

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
  for fin in fins fin:setfield("roll %", 0).

  // pitch over steering taken from https://www.youtube.com/watch?v=NzlM6YZ9g4w
  // https://www.wolframalpha.com/input/?i=quadratic+fit%28%28190%2C89.9%29%2C+%28346%2C88.23%29%2C+%28754%2C85.33%29%2C+%281204%2C82.98%29%2C+%281884%2C80.17%29%29
  lock pitch to 1.76094E-6 * ship:altitude^2 - 0.00926353 * ship:altitude + 91.4174.
  operations:remove("phase1Ascent").
  set operations["phase2Ascent"] to phase2Ascent@.
  output("Roll control minimized, ascent guidance Phase 1 active @ " + round(ship:altitude/1000, 3) + "km").
}

function throttleUp {
  set currentThrust to 0.
  list engines in engList.
  for eng in engList { if eng:ignition { set currentThrust to currentThrust + eng:thrust. } }

  // when the TWR reches 1.5 stabilize and hold with the main throttle
  set weight to (ship:mass * (surfaceGravity/((((ship:orbit:body:radius + ship:altitude)/1000)/(ship:orbit:body:radius/1000))^2))).
  if currentThrust / weight <= 1.5 {

    // adjust throttle to maintain TWR 
    lock throttle to (1.5 * ship:mass * (surfaceGravity/((((ship:orbit:body:radius + ship:altitude)/1000)/(ship:orbit:body:radius/1000))^2)) - srbThrust) / s1EngineAvailableThrust.
    output("Throttling up main engine to maintain TWR of 1.5 @ " + round(ship:altitude/1000, 3) + "km").

    // monitor for SRB detach
    operations:remove("throttleUp").
    set operations["beco"] to beco@.
  }
}

function phase2Ascent {
  if ship:altitude >= 1884 {

    // https://www.wolframalpha.com/input/?i=quadratic+fit%28%281884%2C80.17%29%2C+%282741%2C78.51%29%2C+%283516%2C77.22%29%2C+%284496%2C75.76%29%2C+%285393%2C74.56%29%29
    lock pitch to 1.11832E-7 * ship:altitude^2 - 0.00240533 * ship:altitude + 84.2911.
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
    for decoupler in srbDecouplers decoupler:doevent("decouple").
    output("BECO - SRBs released, main engine to full thrust @ " + round(ship:altitude/1000, 3) + "km").
    operations:remove("beco").
    set operations["meco"] to meco@.
  }
}

function phase3Ascent {
  if ship:altitude >= 5393 {

    // https://www.wolframalpha.com/input/?i=quadratic+fit%28%285393%2C74.56%29%2C+%286799%2C74.42%29%2C+%288513%2C74.28%29%2C+%2810210%2C74.15%29%2C+%2811884%2C74.04%29%29
    lock pitch to 3.03859E-9 * ship:altitude^2 - 0.000132218 * ship:altitude + 75.1828.
    operations:remove("phase3Ascent").
    set operations["phase4Ascent"] to phase4Ascent@.
    output("Ascent guidance Phase 3 active @ " + round(ship:altitude/1000, 3) + "km").
  }
}

function phase4Ascent {
  if ship:altitude >= 11884 {

    // https://www.wolframalpha.com/input/?i=quadratic+fit%28%2811884%2C74.04%29%2C+%2813394%2C72.99%29%2C+%2815116%2C71.9%29%2C+%2816802%2C70.9%29%2C+%2818383%2C70.03%29%29
    lock pitch to 1.41139E-8 * ship:altitude^2 - 0.00104317 * ship:altitude + 84.4395.
    operations:remove("phase4Ascent").
    set operations["phase5Ascent"] to phase5Ascent@.
    output("Ascent guidance Phase 4 active @ " + round(ship:altitude/1000, 3) + "km").
  }
}

function phase5Ascent {
  if ship:altitude >= 18383 {

    // https://www.wolframalpha.com/input/?i=quadratic+fit%28%2818383%2C70.03%29%2C+%2823488%2C69.41%29%2C+%2827272%2C69.01%29%2C+%2831495%2C68.61%29%2C+%2836122%2C68.22%29%29
    lock pitch to 1.4454E-9 * ship:altitude^2 - 0.000180588 * ship:altitude + 72.8591.
    operations:remove("phase5Ascent").
    set operations["phase6Ascent"] to phase6Ascent@.
    output("Ascent guidance Phase 5 active @ " + round(ship:altitude/1000, 3) + "km").
  }
}

function phase6Ascent {
  if ship:altitude >= 36122 {

    // https://www.wolframalpha.com/input/?i=quadratic+fit%28%2836122%2C68.22%29%2C+%2841512%2C61.01%29%2C+%2847558%2C53.68%29%2C+%2852993%2C47.62%29%2C+%2859058%2C41.18%29%29
    lock pitch to 7.95586E-9 * ship:altitude^2 - 0.00193257 * ship:altitude + 127.604.
    operations:remove("phase6Ascent").
    set operations["phase7Ascent"] to phase7Ascent@.
    output("Ascent guidance Phase 6 active @ " + round(ship:altitude/1000, 3) + "km").
  }
}

function meco {
  if s1engineStatus = "Flame-Out!" {
    unlock s1engineStatus.
    unlock s1EngineAvailableThrust.
    output("MECO. Stand by for staging @ " + round(ship:altitude/1000, 3) + "km").
    operations:remove("meco").
    sleep("ses1", ses1@, 1, true, false).
  }
}

function ses1 {
  for sepMotor in s1SepMotors sepMotor:getmodule("ModuleEnginesFX"):doevent("activate engine").
  wait 0.001.
  s1decoupler:doevent("decoupler staging").
  rcs on.
  s2engine:doevent("activate engine").
  wait 0.001.
  output("SES-1. Lift stage detached. Reaction Control System activated @ " + round(ship:altitude/1000, 3) + "km").
  operations:remove("ses1").
  set operations["plfDeploy"] to plfDeploy@.
  set operations["coldgasMonitor"] to coldgasMonitor@.
  set operations["abortMonitor"] to abortMonitor@.
  set operations["seco1"] to seco1@.
}

function phase7Ascent {
  if ship:altitude >= 59058 {

    // https://www.wolframalpha.com/input/?i=quadratic+fit%28%2859058%2C41.18%29%2C+%2866018%2C32.2%29%2C+%2872863%2C23.46%29%2C+%2879495%2C14.99%29%2C+%2886739%2C5.67%29%29
    lock pitch to 6.31649E-11 * ship:altitude^2 - 0.00129092 * ship:altitude + 117.182.
    operations:remove("phase7Ascent").
    set operations["phase8Ascent"] to phase8Ascent@.
    output("Ascent guidance Phase 7 active @ " + round(ship:altitude/1000, 3) + "km").
  }
}

function plfDeploy {
  if ship:altitude >= 60000 {
    for plf in fairings plf:doevent("jettison fairing").
    output("PLF detached @ 60km").
    operations:remove("plfDeploy").
  }
}

function phase8Ascent {
  if ship:altitude >= 86739 {

    // https://www.wolframalpha.com/input/?i=quadratic+fit%28%2886739%2C5.67%29%2C+%2893071%2C-2.37%29%2C+%28100020%2C-11.51%29%2C+%28106988%2C-21.18%29%2C+%28113278%2C-30.64%29%29
    lock pitch to -5.68836E-9 * ship:altitude^2 - 0.000226776 * ship:altitude + 68.0922.
    operations:remove("phase8Ascent").
    set operations["phase9Ascent"] to phase9Ascent@.
    output("Ascent guidance Phase 8 active @ " + round(ship:altitude/1000, 3) + "km").
  }
}

function phase9Ascent {
  if ship:altitude >= 113278 {

    // https://www.wolframalpha.com/input/?i=quadratic+fit%28%28113278%2C-30.64%29%2C+%28117503%2C-34.53%29%2C+%28122060%2C-39.19%29%2C+%28126504%2C-44.54%29%2C+%28130833%2C-50.94%29%29
    lock pitch to -2.09507E-8 * ship:altitude^2 + 0.00396669 * ship:altitude - 211.217.
    operations:remove("phase9Ascent").
    output("Ascent guidance Phase 9 active @ " + round(ship:altitude/1000, 3) + "km").
  }
}

function seco1 {
  if ship:apoapsis >= 210000 {
    lock steering to ship:prograde.
    set currThrottle to 0.
    output("SECO-1. Orienting prograde @ " + round(ship:altitude/1000, 3) + "km").
    operations:remove("seco1").
    operations:remove("coldgasMonitor").
    operations:remove("abortMonitor").
    set operations["sasHold"] to sasHold@.
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
    when kuniverse:canquicksave then kuniverse:quicksaveto(ship:name + " - SECO-1").
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
    when kuniverse:canquicksave then kuniverse:quicksaveto(ship:name + " - Space").
    operations:remove("space").
  }
}
function coldgasMonitor {

  // don't let the viklun stage run out of propellant to hold attitude. If needed, open crossfeed valves from Kerbin II's main tank
  if ship:coldgas-probeCG <= 0 {
    for tank in ship:partsnamed("CGTank1-2") set tank:resources[0]:enabled to true.
    operations:remove("coldgasMonitor").
    output("Cold gas flow valves open in main Kerbin II tank").
    set getter("addlLogData")["Cold Gas (u)"] to {

      // do not count the amount on the probe's sphere tanks
      return ship:coldgas-300.
    }.
  }
}
function abortMonitor {
  
  // if the viklun stage cannot maintain attitude, hold ascent to save fuel for OIB in space
  if abort {
    output("Ascent abort called by launch control @ " + round(ship:altitude/1000, 3) + "km").
    set currThrottle to 0.
    operations:remove("seco1").
    operations:remove("coldgasMonitor").
    operations:remove("abortMonitor").
    rcs off.
    unlock steering.
    when kuniverse:canquicksave then kuniverse:quicksaveto(ship:name + " - Ascent Abort").
  }
}

output("Launch/Ascent ops ready, awaiting terminal count").