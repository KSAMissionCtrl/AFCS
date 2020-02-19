// functions are in the order of flight operations

// begin check of control surfaces at T-7s
// just do a roll check both ways to make all four fins travel
function ctrlCheckStart {
  set ship:control:roll to 1.
  operations:remove("ctrlCheckStart").
  sleep("ctrlCheckRoll", ctrlCheckRoll@, 1, true, false).
}
function ctrlCheckRoll {
  set ship:control:roll to -1.
  operations:remove("ctrlCheckRoll").
  sleep("ctrlCheckFinish", ctrlCheckFinish@, 1, true, false).
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
    sleep("datalogger", logData@, 1, true, true).

    // engine alternator will now provide power
    sleepTimers:remove("monitorEcDrain").

    // ignite the engine at 10% thrust to ensure good chamber pressures
    set currThrottle to 0.10.
    output("Main engine start").
    s1engine:doevent("activate engine").

    // wait for chamber pressure to stabilize
    sleep("checkEngine", checkEngine@, 1, true, false).

  } else if not ctrlCheckComplete setAbort(true, "Low hydraulic pressure").
  operations:remove("mes").
}

function checkEngine {

  // check to ensure nominal ignition and abort if not, continue to launch if so
  if s1engineStatus <> "Nominal" setAbort(true, "Engine ignition failure. Status: " + s1engineStatus).
  else sleep("launch", launch@, getter("launchTime"), false, false).
  operations:remove("checkEngine").
}

function launch {

  // last check for green light
  if not launchAbort { 

    // disengage engine clamp, ignite and free the SRBs
    launchClamp:doevent("release clamp").
    for explosiveBolt in boltBangs explosiveBolt:doevent("kaboom!").
    for srb in srbs srb:doevent("activate engine").
    output("SRB ignition and launch! Flight guidance enabled").
    
    // enable guidance
    // pitch over steering taken from https://www.youtube.com/watch?v=NzlM6YZ9g4w
    // https://www.wolframalpha.com/input/?i=quadratic+fit%28%2885%2C89.6%29%2C+%2810000%2C64%29%2C+%2820000%2C43%29%2C+%2830000%2C27%29%2C+%2840000%2C15%29%2C+%2860000%2C5%29%29
    lock pitch to 2.2878E-8 * ship:altitude^2 - 0.00278367 * ship:altitude + 89.7046.
    lock steering to heading(hdgHold,pitch).

    // wait for SRB thrust to begin decreasing before throttling up main engine
    set operations["throttleUp"] to throttleUp@.

    // monitor the ascent up to staging
    set operations["maxQmonitor"] to maxQmonitor@.
    set operations["plfMonitor"] to plfMonitor@.
    set operations["meco"] to meco@.
    
    // setup some notification triggers
    when maxQ > ship:q then {
      output("MaxQ: " + round(ship:Q * constant:ATMtokPa, 3) + "kPa @ " + round(ship:altitude/1000, 3) + "km").
      operations:remove("maxQmonitor").
    }
    when ship:orbit:apoapsis > 70000 then {
      output("We are going to space!").
      when ship:altitude >= 70000 then output("Space reached").
    }
  } else {

    // make double sure the engine was shut down by whatever abort was thrown
    if s1engine:hasevent("shutdown engine") {
      s1engine:doevent("shutdown engine").
      output("Engine shut down").
    }
  }
  operations:remove("launch").
}

function throttleUp {

  // when the amount of solid fuel reaches 2.94t the SRBs will have begun to taper off thrust
  if ship:solidfuel * 0.0075 <= 2.94 {

    // adjust throttle to maintain TWR 
    lock throttle to 1.7 * ship:mass * (surfaceGravity/((((ship:orbit:body:radius + ship:altitude)/1000)/(ship:orbit:body:radius/1000))^2)) / getAvailableThrust().
    output("Throttling up @ " + round(ship:altitude/1000, 3) + "km to maintain TWR of 1.7").

    // monitor for SRB detach
    operations:remove("throttleUp").
    set operations["srbDetach"] to srbDetach@.
  }
}

function maxQmonitor {
  if ship:q > maxQ set maxQ to ship:q.
}

function srbDetach {

  // when the amount of fuel reaches 64kg the engines are < 3s from burning out and can be pushed away
  if ship:solidfuel * 0.0075 <= 0.064 {
    for decoupler in srbDecouplers decoupler:doevent("decouple").
    set currThrottle to 1.
    lock throttle to currThrottle.
    output("SRBs released @ " + round(ship:altitude/1000, 3) + "km, main engine to full thrust").
    operations:remove("srbDetach").
    sleep("adjustFinLimits", adjustFinLimits@, 1, true, false).
  }
}

// with the SRBs gone the fins can now actuate further
function adjustFinLimits {
  for fin in fins fin:setfield("ctrl dflct", 40).
  output("Fin steering limits increased").
  operations:remove("adjustFinLimits").
}

function plfMonitor {
  if ship:altitude >= 42000 {
    for plf in fairings plf:doevent("jettison fairing").
    output("PLF detached @ 42km").
    operations:remove("plfMonitor").
  }
}

function meco {
  if s1engineStatus = "Flame-Out!" {
    output("MECO @ " + round(ship:altitude/1000, 3) + "km. Stand by for staging").
    operations:remove("meco").
    sleep("stage", stage@, 1, true, false).
  }
}

function stage {
  s1decoupler:doevent("decoupler staging").
  rcs on.
  output("Lift stage detached. Reaction Control System activated").
  operations:remove("stage").
  sleep("ses1", ses1@, 1, true, false).
}

function ses1 {
  s2engine:doevent("activate engine").
  output("Viklun engine start @ " + round(ship:altitude/1000, 3) + "km").
  operations:remove("ses1").
  set operations["seco1"] to seco1@.
}

function seco1 {
  if ship:apoapsis >= 100000 {
    lock steering to ship:prograde.
    set currThrottle to 0.
    output("SECO-1 @ " + round(ship:altitude/1000, 3) + "km. Orienting prograde").
    operations:remove("seco1").
  }
}
      
sleep("terminalCount", terminalCount@, getter("launchTime") - 120, false, false).
output("Launch/Ascent ops ready, awaiting terminal count").