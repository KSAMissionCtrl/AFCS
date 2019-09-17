// functions are in the order of flight operations
function terminalCount {

  // set up for ignition at T-0 seconds
  if time:seconds >= getter("launchTime") {
    operations:remove("terminalCount").
    set operations["launch"] to launch@.
    sleepTimers:remove("monitorEcDrain").
  }
}

// retract support arms at T-5s
function retractSupportArms {
  if time:seconds >= getter("launchTime") - 5 {
    for arm in supportArms arm:doevent("retract").
    set operations["checkArmRetraction"] to checkArmRetraction@.
    operations:remove("retractSupportArms").
  } 
}

// retraction should be done by T-1s
function checkArmRetraction {
  if time:seconds >= getter("launchTime") - 1 {
    if armOne <> "Retracted" or armTwo <> "Retracted" or armThree <> "Retracted" {
      setAbort(true, "support arm retraction failure").
    } else {
      unlock armOne.
      unlock armTwo.
      unlock armThree.
    }
    operations:remove("checkArmRetraction").
  }
}

function launch {

  // check if we have launch clearance
  if not launchAbort { 
    stage.
    output("Launch!").
    
    // allow a physics tick for things to get updated
    wait 0.01.
    
    // did the boosters even fire?
    if stageOne = "Flame-Out!" {
      setAbort(true, "stage one booster ignition failure").
    } else {

      // roll to heading in first ~400m and then start pitch over
      // pitch over steering taken from https://www.youtube.com/watch?v=NzlM6YZ9g4w
      // https://www.wolframalpha.com/input/?i=quadratic+fit((500,+89),+(5000,80),+(10000,70),+(20000,55),+(30500,45),+(40500,35),+(60000,20))
      lock steering to heading(hdgHold, pitch).
      set operations["endRoll"] to endRoll@.

      // setup some notification triggers, nested so only a few are running at any given time
      when maxQ > ship:q then output("MaxQ: " + round(ship:Q * constant:ATMtokPa, 3) + "kPa @ " + round(ship:altitude/1000, 3) + "km").
      when ship:orbit:apoapsis > 70000 then {
        output("We are going to space!").
        when ship:altitude >= 70000 then {
          output("Space reached!").
          when ship:verticalspeed <= 0 then {
            output("Apokee achieved @ " + round(ship:altitude/1000, 3) + "km").
            when ship:altitude <= 100000 then {

              // failsafe for proper re-entry position
              if not addons:rt:haskscconnection(ship) {
                sas on.
                set sasmode to "retrograde".
              }
              when ship:altitude <= 70000 then {
                output("Atmospheric interface breached").
                set maxQ to 0.
                when maxQ > ship:q then output("MaxQ: " + round(ship:Q * constant:ATMtokPa, 3) + "kPa @ " + round(ship:altitude/1000, 3) + "km").
                set operations["chuteDeploy"] to chuteDeploy@.
              }
            } 
          }
        }
      }

      // begin telemetry logging with an intial entry followed by one every second
      logData().
      sleep("datalogger", logData@, 1, true, true).
      
      // wait for first stage boosts to complete
      set operations["stageOneBoost"] to stageOneBoost@.
    }
  }
  operations:remove("launch").
}

// begin pitch over
function endRoll {
  if ship:altitude > 500 {
    lock pitch to 1.14452E-8 * ship:altitude ^ 2 - 0.00181906 * ship:altitude + 88.6057.
    operations:remove("endRoll").
  }
}

function stageOneBoost {
  if ship:Q > maxQ set maxQ to ship:Q.
  if ship:partstagged("srmxl"):length and stageOne = "Flame-Out!" {
    output("Stage one main boost completed, standing by to decouple").
    
    // setup to decouple the booster after one second
    sleep("stageOneDecouple", stageOneDecouple@, 1, true, false).
    operations:remove("stageOneBoost").
    unlock stageOne.
  } else if not ship:partstagged("srmxl"):length {
    ascentAbort().
    operations:remove("stageOneBoost").
  }
}

function stageOneDecouple {
  for fin in s1fins fin:doevent("kaboom!"). 
  s1decoupler:doevent("decouple").
  output("Stage one booster decoupled").
  operations:remove("stageOneDecouple").

  // ignite stage two booster
  srb2:doevent("activate engine").
  wait 0.01.
  
  // did we get booster activation?
  if stageTwo = "Flame-Out!" {
    setAbort(true, "stage two booster ignition failure").
    ascentAbort().
  } else {
    output("Stage two boost started").
    set operations["stageTwoBoost"] to stageTwoBoost@.
  }
}

function stageTwoBoost {
  if ship:partstagged("srml"):length and stageTwo = "Flame-Out!" {
    output("Stage two boost completed, standing by to decouple").
    sleep("stageTwoDecouple", stageTwoDecouple@, 1, true, false).
    operations:remove("stageTwoBoost").
    unlock stageTwo.
  } else if not ship:partstagged("srml"):length {
    setAbort(true, "Structural/explosive failure on stage 2").
    ascentAbort().
    operations:remove("stageTwoBoost").
  }
}

function stageTwoDecouple {
  for fin in s2fins fin:doevent("kaboom!").
  s2decoupler:doevent("decoupler staging").
  output("Stage two booster decoupled").
  operations:remove("stageTwoDecouple").

  lfo:doevent("activate engine").
  wait 0.01.

  // did we get booster activation?
  if stageThree = "Flame-Out!" and throttle > 0 {
    setAbort(true, "stage three booster ignition failure").
    ascentAbort().
  } else {
    output("Stage three boost started").
    set operations["stageThreeBoost"] to stageThreeBoost@.
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
    ascentAbort().
    operations:remove("stageThreeBoost").
  }
}

// terminal count begins 2min prior to launch
sleep("beginTCount", beginTCount@, getter("launchTime") - 120, false, false).
output("Launch/Ascent ops ready, awaiting terminal count").