// functions are in the order of flight operations
// retract support arms at T-5s
function retractSupportArms {
  supportArms:doevent("retract").
  output("Support arms retracting...").
  sleep("checkArmRetraction", checkArmRetraction@, getter("launchTime") - 1, false, false).
  operations:remove("retractSupportArms").
}

// retraction should be done by T-1s
function checkArmRetraction {
  if armOne <> "Retracted" or armTwo <> "Retracted" or armThree <> "Retracted" or armFour <> "Retracted" {
    setAbort(true, "support arm retraction failure").
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
    
    // did the boosters even fire?
    if stageOne = "Flame-Out!" {
      setAbort(true, "stage one booster ignition failure").
    } else {

      // pitch over to remove gimbal lock before enabling guidance
      set ship:control:pitch to -0.25.
      set operations["enableGuidance"] to enableGuidance@.  

      // begin to monitor various ascent milestones
      set operations["maxQmonitor"] to maxQmonitor@.
      set operations["maxQcheck"] to maxQcheck@.
      set operations["apSpace"] to apSpace@.

      // begin telemetry logging with an intial entry followed by one every second
      logData().
      sleep("datalogger", logData@, 1, true, true).
      
      // wait for first stage boost to complete
      set operations["stageOneBoost"] to stageOneBoost@.
    }
  } else output("Launch aborted - cause unknown").
  operations:remove("launch").
}

// begin guided ascent on heading
function enableGuidance {
  if pitch_for(ship) <= 89.9 {

    // pitch over steering taken from https://www.youtube.com/watch?v=NzlM6YZ9g4w
    // https://www.wolframalpha.com/input/?i=quadratic+fit%28%2877%2C89.9%29%2C+%285000%2C84.5%29%2C+%2815000%2C74.25%29%2C+%2825000%2C65%29%2C+%2840000%2C53%29%2C+%2855000%2C43.25%29%2C+%2870000%2C36%29%29
    set ship:control:pitch to 0.
    lock pitch to 5.10666E-9 * ship:altitude ^ 2 - 0.00112976 * ship:altitude + 90.0183.
    lock steering to heading(hdgHold, pitch).
    output("Guidance enabled").
    operations:remove("enableGuidance").
  }
}

// monitor booster until flamout
function stageOneBoost {
  if stageOne = "Flame-Out!" {
    output("Stage one main boost completed, coasting to 25km").
    operations:remove("stageOneBoost").
    unlock stageOne.
    set operations["stageOneCoast"] to stageOneCoast@.
  }
}

// coast until 25km then detach S1 & fire S2
function stageOneCoast {
  if ship:altitude >= 25000 {

    // make sure the fins are straight on decouple
    output("Disabling guidance, arming booster parachute").
    unlock steering.
    s1chute:doevent("arm parachute").
    wait 0.5.
    decoupler:doevent("decoupler staging").
    output("Stage one booster decoupled").
    kuniverse:quicksave().

    lfo:doevent("activate engine").
    wait 0.01.

    // did we get booster activation?
    if stageTwo = "Flame-Out!" and throttle > 0 {
      setAbort(true, "L/FO ignition failure").
    } else {
      output("Stage two boost started").
      for batt in batts if batt:hasevent("Disconnect Battery") batt:doevent("Disconnect Battery").
      set operations["boostMECO1"] to boostMECO1@.
      lock pitch to 5.10666E-9 * ship:altitude ^ 2 - 0.00112976 * ship:altitude + 90.0183.
      lock steering to heading(hdgHold, pitch).
    }
    operations:remove("stageOneCoast").
  }
}

// powered flight up to space
function boostMECO1 {
  if ship:altitude >= 70000 {
    output("MECO-1, space reached").
    for batt in batts if batt:hasevent("Connect Battery") batt:doevent("Connect Battery").
    wait 0.01.
    lfo:doevent("shutdown engine").
    unlock throttle.
    unlock steering.
    set operations["apokee"] to apokee@.
    operations:remove("boostMECO1").
    operations:remove("maxQmonitor").
    operations:remove("maxQcheck").
    operations:remove("boostCutOff").
    when kuniverse:canquicksave then kuniverse:quicksaveto(ship:name + " - Space").
    ship:partstagged("gyro")[0]:getmodule("ModuleReactionWheel"):setfield("reaction wheel authority", 100).
    sas on.
    wait 0.01.
    set sasmode to "prograde".
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
    set operations["boostCutOff"] to boostCutOff@.
  }
}
function boostCutOff {

  // if we're running low on fuel but will exit the atmo, shut down
  if ship:liquidfuel < 5 and ship:orbit:apoapsis > 80000 {
    output("MECO-1, fuel almost too low for restart").
    for batt in batts if batt:hasevent("Connect Battery") batt:doevent("Connect Battery").
    wait 0.01.
    lfo:doevent("shutdown engine").
    unlock throttle.
    unlock steering.
    set operations["apokee"] to apokee@.
    set operations["space"] to space@.
    operations:remove("boostMECO1").
    operations:remove("boostCutOff").
    operations:remove("maxQmonitor").
    operations:remove("maxQcheck").
    ship:partstagged("gyro")[0]:getmodule("ModuleReactionWheel"):setfield("reaction wheel authority", 100).
    sas on.
    set sasmode to "prograde".
  }
}
function space {
  if ship:altitude >= 70000 {
    output("Space reached").
    when kuniverse:canquicksave then kuniverse:quicksaveto(ship:name + " - Space").
    operations:remove("space").
  }
}
function apokee {
  if ship:verticalSpeed <= 0 {
    output("Apokee achieved @ " + round(ship:altitude/1000, 3) + "km").
    operations:remove("apokee").
  }
}

// terminal count begins 2min prior to launch
sleep("terminalCount", terminalCount@, getter("launchTime") - 120, false, false).
sleep("launch", launch@, getter("launchTime"), false, false).
output("Launch/Ascent ops ready, awaiting terminal count").