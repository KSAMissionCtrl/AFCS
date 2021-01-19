// functions are in the order of flight operations
function terminalCount {

  // set up for ignition at T-0 seconds
  if time:seconds >= getter("launchTime") {
    operations:remove("terminalCount").
    set operations["launch"] to launch@.
    sleepTimers:remove("monitorEcDrain").
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
    if stageOneMain = "Flame-Out!" or stageOneRadial = "Flame-Out!" {
      setAbort(true, "stage one booster ignition failure").
      unlock throttle.
    } else {
    
      // setup some notification triggers, nested so only a few are running at any given time
      when maxQ > ship:q then output("MaxQ: " + round(ship:Q * constant:ATMtokPa, 3) + "kPa @ " + round(ship:altitude/1000, 3) + "km").
      when ship:orbit:apoapsis > 70000 then {
        output("We are going to space!").
        when ship:altitude >= 70000 then {
          for fairing in fairings {
            fairing:doevent("decouple").
          }
          output("Payload fairing jettison").
          output("Space reached!").
        }
      }

      // begin telemetry logging with an intial entry followed by one every second
      logData().
      sleep("datalogger", logData@, 1, true, true).
      
      // wait for first stage boosts to complete
      set operations["stageOneRadialBoost"] to stageOneRadialBoost@.
      set operations["stageOneBoost"] to stageOneBoost@.
    }
  }
  operations:remove("launch").
}

function stageOneRadialBoost {

  // drop the radial boosters once they are done
  if stageOneRadial = "Flame-Out!" {
    unlock stageOneRadial.
    output("Stage one radial boost completed. Boosters released").
    stage. // for decoupler in radDecouplers { decoupler:doevent("decouple"). }
    operations:remove("stageOneRadialBoost").
  }
}

function stageOneBoost {
  if ship:Q > maxQ set maxQ to ship:Q.
  if stageOneMain = "Flame-Out!" {
    unlock stageOneMain.
    output("Stage one main boost completed, standing by to decouple. Pitch is " + round(pitch_for(ship), 3)).
    
    // setup to decouple the booster after one second
    sleep("stageOneDecouple", stageOneDecouple@, 1, true, false).
    
    // get starting value for coast monitoring and switch over
    set startPitch to pitch_for(ship).
    operations:remove("stageOneBoost").
    sleep("stageTwoIgnition", stageTwoIgnition@, 2, true, false).
  }
}

function stageOneDecouple {
  for fin in s1fins { fin:doevent("kaboom!"). }
  stage. // s1decoupler:doevent("decouple").
  output("Stage one booster decoupled").
  operations:remove("stageOneDecouple").
}

function stageTwoIgnition {
  stage. // srb2:doevent("activate engine").
  wait 0.01.
  
  // did we get booster activation?
  if stageTwo = "Flame-Out!" {
    setAbort(true, "stage two booster ignition failure").
    unlock throttle.
    runOpsFile("return").
    ascentAbort().
  } else {
    output("Stage two boost started. Pitch is " + round(pitch_for(ship), 3) + ", vertical speed is " + round(ship:verticalspeed, 3) + "m/s").
    set operations["stageTwoBoost"] to stageTwoBoost@.
  }
  operations:remove("stageTwoIgnition").
}

function stageTwoBoostWait {
  if stageTwo = "Nominal" {
    output("Stage two boost started. Pitch is " + round(pitch_for(ship), 3) + ", vertical speed is " + round(ship:verticalspeed, 3) + "m/s").
    operations:remove("stageTwoBoostWait").
    set operations["stageTwoBoost"] to stageTwoBoost@.
  }
}

function stageTwoBoost {
  if stageTwo = "Flame-Out!" {
    unlock stageTwo.
    output("Stage two boost completed, standing by to decouple").
    sleep("stageTwoDecouple", stageTwoDecouple@, 1, true, false).
    operations:remove("stageTwoBoost").
    
    // it will take a second to stage, wait a second longer to boost
    sleep("stageThreeBoost", stageThreeBoost@, 2, true, false).
  }
}

function stageTwoDecouple {
  for fin in s2fins { fin:doevent("kaboom!"). }
  stage. // s2decoupler:doevent("decouple").
  output("Stage two booster decoupled").
  operations:remove("stageTwoDecouple").
}

function stageThreeBoost {
  stage. // lfo1:doevent("activate engine").
  wait 0.01.
  
  // did we get booster activation?
  if stageThree = "Flame-Out!" and throttle > 0 {
    setAbort(true, "stage three booster ignition failure").
    unlock throttle.
    runOpsFile("return").
    ascentAbort().
  } else {
    output("Stage three boost started").
    set operations["beco"] to beco@.
  }
  operations:remove("stageThreeBoost").
}

function beco {
  if stageThree = "Flame-Out!" {
    output("Stage three boost completed").
    unlock throttle.
    operations:remove("beco").
    wait 0.1.
    when kuniverse:canquicksave then kuniverse:quicksaveto(ship:name + " - BECO").

    // begin hibernation cycle after 2s to ensure a final log entry is made
    sleep("beginHibernation", beginHibernation@, 2, true, false).
    set rdyToHibernate to true.
  }
}

function beginHibernation {
  operations:remove("beginHibernation").

  // start a bit earlier than normal since we waited a few seconds
  hibernate("space", 55, false).
}

// terminal count begins 2min prior to launch
sleep("beginTCount", beginTCount@, getter("launchTime") - 120, false, false).
output("Launch/Ascent ops ready, awaiting terminal count").