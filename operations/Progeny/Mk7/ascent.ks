// functions are in the order of flight operations
// retract support arms at T-5s
function retractSupportArms {
  for arm in supportArms arm:doevent("retract").
  sleep("checkArmRetraction", checkArmRetraction@, getter("launchTime") - 1, false, false).
  operations:remove("retractSupportArms").
}

// retraction should be done by T-1s
function checkArmRetraction {
  if armOne <> "Retracted" or armTwo <> "Retracted" or armThree <> "Retracted" {
    setAbort(true, "support arm retraction failure").
  } else {
    unlock armOne.
    unlock armTwo.
    unlock armThree.
  }
}

function launch {

  // check if we have launch clearance
  if not launchAbort { 
    stage.
    output("Launch!").
    sleepTimers:remove("monitorEcDrain").
    
    // allow a physics tick for things to get updated
    wait 0.01.
    
    // did the boosters even fire?
    if stageOne = "Flame-Out!" {
      setAbort(true, "stage one booster ignition failure").
    } else {

      // pitch over to remove gimbal lock before enabling guidance
      set ship:control:pitch to -1.
      set operations["enableGuidance"] to enableGuidance@.  

      // setup some notification triggers, nested so only a few are running at any given time
      when maxQ > ship:q then {
        output("MaxQ: " + round(ship:Q * constant:ATMtokPa, 3) + "kPa @ " + round(ship:altitude/1000, 3) + "km").
        operations:remove("monitorMaxQ").
      }
      when ship:orbit:apoapsis > 70000 then {
        output("We are going to space!").
        when ship:altitude >= 70000 then {
          output("Space reached!").
          when ship:verticalspeed <= 0 then {
            output("Apokee achieved @ " + round(ship:altitude/1000, 3) + "km").
            when ship:altitude <= 70000 then {
              output("Atmospheric interface breached").
              set maxQ to 0.
              set operations["monitorMaxQ"] to monitorMaxQ@.
              when maxQ > ship:q then {
                output("MaxQ: " + round(ship:Q * constant:ATMtokPa, 3) + "kPa @ " + round(ship:altitude/1000, 3) + "km").
                operations:remove("monitorMaxQ").
              }
            } 
          }
        }
      }

      // begin telemetry logging with an intial entry followed by one every second
      logData().
      sleep("datalogger", logData@, 1, true, true).
      
      // wait for first stage boost to complete
      set operations["stageOneBoost"] to stageOneBoost@.
      set operations["monitorMaxQ"] to monitorMaxQ@.
      set operations["fairingDetach"] to fairingDetach@.
    }
  }
  operations:remove("launch").
}

function monitorMaxQ {
  if ship:Q > maxQ set maxQ to ship:Q.
}

// begin guided ascent on heading
function enableGuidance {
  if pitch_for(ship) <= 89.5 {

    // pitch over steering taken from https://www.youtube.com/watch?v=NzlM6YZ9g4w
    // https://www.wolframalpha.com/input/?i=quadratic+fit((77,90),+(5000,84),+(15000,74),+(25000,63.5),+(35000,53.8),+(45000,46),+(70000,27))
    set ship:control:pitch to 0.
    for fin in s2finCtrl fin:setfield("ctrl dflct", 40).
    lock pitch to 3.46637E-9 * ship:altitude ^ 2 - 0.00114115 * ship:altitude + 89.9469.
    lock steering to heading(hdgHold, pitch).
    output("Guidance lock enabled").
    operations:remove("enableGuidance").
  }
}

function fairingDetach {
  if ship:altitude >= 45000 {
    for fairing in fairings fairing:doevent("jettison fairing").
    output("Payload fairings detached").
    operations:remove("fairingDetach").
  }
}

function stageOneBoost {
  
  if ship:partstagged("srmxl"):length and stageOne = "Flame-Out!" {
    output("Stage one main boost completed, standing by to decouple").
    
    // setup to decouple the booster after one second
    sleep("stageOneDecouple", stageOneDecouple@, 1, true, false).
    operations:remove("stageOneBoost").
    unlock stageOne.
  } else if not ship:partstagged("srmxl"):length {
    operations:remove("stageOneBoost").
  }
}

function stageOneDecouple {
  for fin in s1fins fin:doevent("kaboom!"). 
  s1decoupler:doevent("decouple").
  output("Stage one booster decoupled, coasting to stage two ignition").
  operations:remove("stageOneDecouple").

  // wait for stage two ignition
  set operations["stageTwoCoast"] to stageTwoCoast@.
}

function stageTwoCoast {
  if ship:altitude >= 15000 {
    srb2:doevent("activate engine").
    wait 0.01.
    
    // did we get booster activation?
    if stageTwo = "Flame-Out!" {
      setAbort(true, "stage two booster ignition failure").
    } else {
      output("Stage two boost started").
      set operations["stageTwoBoost"] to stageTwoBoost@.
    }
    operations:remove("stageTwoCoast").
  }
}

function stageTwoBoost {
  if ship:partstagged("srml"):length and stageTwo = "Flame-Out!" {
    output("Stage two boost completed, coasting to stage three ignition").
    set operations["stageThreeCoast"] to stageThreeCoast@.
    operations:remove("stageTwoBoost").
    unlock stageTwo.
  } else if not ship:partstagged("srml"):length {
    setAbort(true, "Structural/explosive failure on stage 2").
    operations:remove("stageTwoBoost").
  }
}

function stageThreeCoast {
  if ship:altitude >= 25000 {

    // dump the second stage, needed until now for its fins
    for fin in s2fins fin:doevent("kaboom!").
    s2decoupler:doevent("decoupler staging").

    lfo:doevent("activate engine").
    wait 0.01.

    // did we get booster activation?
    if stageThree = "Flame-Out!" and throttle > 0 {
      setAbort(true, "Stage two booster decoupled, stage three booster ignition failure").
    } else {
      output("Stage two booster decoupled, stage three boost started").
      set operations["stageThreeBoost"] to stageThreeBoost@.
    }
    operations:remove("stageThreeCoast").
  }
}

function stageThreeBoost {
  if ship:partstagged("ospray"):length and stageThree = "Flame-Out!" {
    output("Stage three boost completed").
    unlock throttle.
    unlock steering.
    operations:remove("stageThreeBoost").
  } else if not ship:partstagged("ospray"):length {
    setAbort(true, "Structural/explosive failure on stage 3").
    operations:remove("stageThreeBoost").
  }
}

// terminal count begins 2min prior to launch
sleep("terminalCount", terminalCount@, getter("launchTime") - 120, false, false).
output("Launch/Ascent ops ready, awaiting terminal count").