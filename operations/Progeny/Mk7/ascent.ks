// functions are in the order of flight operations
// retract support arms at T-5s
function retractSupportArms {
  supportArms:doevent("retract").
  output("Support arms retracting...").
  sleep("checkArmRetraction", checkArmRetraction@, getter("launchTime") - 1, ABSOLUTE_TIME, PERSIST_N).
  operations:remove("retractSupportArms").
}

// retraction should be done by T-1s
function checkArmRetraction {
  if armOne <> "Retracted" or armTwo <> "Retracted" or armThree <> "Retracted" or armFour <> "Retracted" {
    setAbort(true, "Support arm retraction failure").
  } else {
    output("Support arms retract successful").
    unlock armOne.
    unlock armTwo.
    unlock armThree.
    unlock armFour.
  }
  operations:remove("checkArmRetraction").
}

function launch {

  // check if we have launch clearance
  if not launchAbort { 
    launchClamp:doevent("release clamp").
    srb:doevent("activate engine").
    output("Launch!").
    sleepTimers:remove("monitorEcDrain").
    
    // allow a physics tick for things to get updated
    wait 0.01.
    
    // did the booster even fire?
    if stageOne = "Flame-Out!" {
      setAbort(true, "Stage one booster ignition failure").
    } else {

      // pitch over to remove gimbal lock and roll to heading before enabling guidance
      lock steering to heading(hdgHold, pitch).
      set operations["enableGuidance"] to enableGuidance@.  

      // begin to monitor various ascent milestones
      set operations["maxQmonitor"] to maxQmonitor@.
      set operations["maxQcheck"] to maxQcheck@.
      set operations["apSpace"] to apSpace@.

      // begin telemetry logging with an intial entry followed by one every set period
      logData().
      sleep("datalogger", logData@, logInterval, RELATIVE_TIME, PERSIST_Y).
      
      // wait for first stage boost to complete
      set operations["ascentBECO"] to ascentBECO@.
    }
  }
  operations:remove("launch").
}

// begin guided ascent on heading
function enableGuidance {
  if pitch_for(ship) <= 89.9 and compass_for(ship) < 40 {

    // pitch over steering taken from https://www.youtube.com/watch?v=NzlM6YZ9g4w
    // https://www.wolframalpha.com/input/?i=quadratic+fit%28%2877%2C89.9%29%2C+%2823721%2C62.68%29%2C+%2868234%2C34.93%29%29
    lock pitch to 7.74433E-9 * ship:altitude ^ 2 - 0.00133554 * ship:altitude + 90.0028.
    output("Guidance enabled @ " + round(ship:altitude/1000, 3) + "km").
    operations:remove("enableGuidance").
  }
}

// monitor booster until flameout
function ascentBECO {
  if stageOne = "Flame-Out!" {
    output("BECO @ " + round(ship:altitude/1000, 3) + "km").
    operations:remove("ascentBECO").
    unlock stageOne.
    s1chute:doevent("arm parachute").
    set operations["shroudSplit"] to shroudSplit@.
  }
}

function shroudSplit {
  if ship:altitude >= 25000 {
    for shroud in shrouds shroud:doevent("jettison fairing").
    operations:remove("shroudSplit").
    sleep("staging", staging@, 0.1, RELATIVE_TIME, PERSIST_N).
  }
}

function staging {
  operations:remove("staging").
  decoupler:doevent("decoupler staging").
  set currStage to 2.
  lfo:doevent("activate engine").
  wait 0.01.

  // did we get engine activation?
  if stageTwo = "Flame-Out!" and throttle > 0 {
    setAbort(true, "LF/O ignition failure").
  } else {
    output("Stage one booster decoupled, MES @ " + round(ship:altitude/1000, 3) + "km").
    for batt in batts if batt:hasevent("Disconnect Battery") batt:doevent("Disconnect Battery").
    set operations["ascentMECO"] to ascentMECO@.
    set operations["plfDetach"] to plfDetach@.
    kuniverse:quicksave().
  }
}

function plfDetach {
  if ship:altitude >= 50000 {
    for plf in fairings plf:doevent("jettison fairing").
    output("PLF detached @ 50km").
    operations:remove("plfDetach").
  }
}

// powered flight up to space
function ascentMECO {
  if stageTwo = "Flame-Out!" {
    output("MECO @ " + round(ship:altitude/1000, 3) + "km").
    for batt in batts if batt:hasevent("Connect Battery") batt:doevent("Connect Battery").
    unlock throttle.
    unlock steering.
    set operations["apokee"] to apokee@.
    operations:remove("ascentMECO").
    operations:remove("maxQmonitor").
    operations:remove("maxQcheck").
    when kuniverse:canquicksave then kuniverse:quicksaveto(ship:name + " - MECO").
  }
}


// these functions are run parallel during ascent but in the following order
// the first two are run both during ascent and re-entry
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
    set operations["spaceReached"] to spaceReached@.
  }
}
function spaceReached {
  if ship:altitude >= 70000 {
    output("Space reached").
    operations:remove("spaceReached").
    if stageTwo = "Flame-Out!" {
      when kuniverse:canquicksave then kuniverse:quicksaveto(ship:name + " - Space").
    } else kuniverse:quicksave().
  }
}
function apokee {
  if ship:verticalSpeed <= 0 {
    output("Apokee achieved @ " + round(ship:altitude/1000, 3) + "km").
    operations:remove("apokee").
    set operations["saveReturn"] to saveReturn@.
    set operations["reentry"] to reentry@.
  }
}

// terminal count begins 2min prior to launch
sleep("terminalCount", terminalCount@, getter("launchTime") - 120, ABSOLUTE_TIME, PERSIST_N).
sleep("launch", launch@, getter("launchTime"), ABSOLUTE_TIME, PERSIST_N).
output("Launch/Ascent ops ready, awaiting terminal count").