// functions are in the order of flight operations
function terminalCount {

  // until launch, ensure that EC levels are not falling faster than they should be
  set currEC to EClvl.
  if currEC - EClvl >= maxECdrain {
    setAbort(true, "EC drain is excessive at " + round(currEC - EClvl, 3) + "ec/s").
    operations:remove("terminalCount").
  }

  // set up for ignition at T-0 seconds
  if time:seconds >= getter("launchTime") {
    operations:remove("terminalCount").
    set operations["launch"] to launch@.
  }
}

function launch {

  // check if we have launch clearance
  if not abort { 
    stage.
    output("Launch!").
    
    // allow a physics tick for things to get updated
    wait 0.01.
    
    // did the boosters even fire?
    if stageOneMain = "Flame-Out!" or stageOneRadial = "Flame-Out!" {
      setAbort(true, "stage one booster ignition failure").
    } else {
    
      // setup some notification triggers, nested so only a few are running at any given time
      when maxQ > ship:q then output("MaxQ: " + round(ship:Q * constant:ATMtokPa, 3) + "kPa @ " + round(ship:altitude/1000, 3) + "km").
      when ship:orbit:apoapsis > 70000 then {
        output("We are going to space!").
        setter("phase", "Apokee Spaced").
        when ship:altitude >= 70000 then {
          output("Space reached!").
          setter("phase", "Space").
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
    set stageOneRadial to 0.
    output("Stage one radial boost completed. Boosters released").
    setter("phase", "Stage One Main Boost").
    for decoupler in radDecouplers { decoupler:doevent("decouple"). }
    operations:remove("stageOneRadialBoost").
  }
}

function stageOneBoost {
  if ship:Q > maxQ set maxQ to ship:Q.
  if stageOneMain = "Flame-Out!" {
    set stageOneMain to 0.
    output("Stage one main boost completed, standing by to decouple. Pitch is " + round(pitch_for(ship), 3)).
    
    // update the phase for use when rendering the trajectory with path.ks
    setter("phase", "Stage Two Coast").
    
    // setup to decouple the booster after one second
    sleep("stageOneDecouple", stageOneDecouple@, 1, true, false).
    
    // get starting value for coast monitoring and switch over
    set startPitch to pitch_for(ship).
    operations:remove("stageOneBoost").
    set operations["stageTwoCoast"] to stageTwoCoast@.
  }
}

function stageOneDecouple {
  for fin in s1fins { fin:doevent("kaboom!"). }
  s1decoupler:doevent("decouple").
  output("Stage one booster decoupled").
  operations:remove("stageOneDecouple").
}

function stageTwoCoast {
  
  // check for anomalous AoA
  Set RollFactor to -1.
  If roll < 90 {
    if roll > -90 {
      set RollFactor to 1.
    }
  }
  If Ship:Airspeed < 1 {
    Set RollFactor to 0.
  }
  Set verticalAOAupdate to vertical_aoa()*RollFactor.
  if abs(verticalAOAupdate) > s2AoALimit {
    output("Angle of Attack constraint exceeded by " + round(VANG(ship:facing:vector, ship:srfprograde:vector) - s2AoALimit, 3) + " - awaiting manual staging @ " + round(startPitch-pitchLimit, 3)).
    operations:remove("stageTwoCoast").
    set operations["stageTwoBoostWait"] to stageTwoBoostWait@.
  }
  
  if startPitch - pitch_for(ship) >= pitchLimit or ship:verticalspeed < 100 {
    srb2:doevent("activate engine").
    wait 0.01.
    
    // did we get booster activation?
    if stageTwo = "Flame-Out!" {
      setAbort(true, "stage two booster ignition failure").
      operations:remove("stageTwoCoast").
      unlock throttle.
      when ship:verticalspeed < 0 then {
        output("Apokee achieved @ " + round(ship:altitude/1000, 3) + "km").
        setter("phase", "Apokee").
        runOpsFile("return").
        when ship:altitude < 70000 then {
          output("Atmospheric interface breached").
          setter("phase", "Re-Entry").
          set operations["chuteDeploy"] to chuteDeploy@.
        }
      }
    } else {
      output("Stage two boost started. Pitch is " + round(pitch_for(ship), 3) + ", vertical speed is " + round(ship:verticalspeed, 3) + "m/s").
      setter("phase", "Stage Two Boost").
      operations:remove("stageTwoCoast").
      set operations["stageTwoBoost"] to stageTwoBoost@.
    }
  }
}

function stageTwoBoostWait {
  if stageTwo = "Nominal" {
    output("Stage two boost started. Pitch is " + round(pitch_for(ship), 3) + ", vertical speed is " + round(ship:verticalspeed, 3) + "m/s").
    setter("phase", "Stage Two Boost").
    operations:remove("stageTwoBoostWait").
    set operations["stageTwoBoost"] to stageTwoBoost@.
  }
}

function stageTwoBoost {
  if stageTwo = "Flame-Out!" {
    set stageTwo to 0.
    output("Stage two boost completed, standing by to decouple").
    setter("phase", "Stage Three Boost").
    sleep("stageTwoDecouple", stageTwoDecouple@, 1, true, false).
    operations:remove("stageTwoBoost").
    
    // it will take a second to stage, wait a second longer to boost
    sleep("stageThreeBoost", stageThreeBoost@, 2, true, false).
  }
}

function stageTwoDecouple {
  for fin in s2fins { fin:doevent("kaboom!"). }
  s2decoupler:doevent("decouple").
  output("Stage two booster decoupled").
  operations:remove("stageTwoDecouple").
}

function stageThreeBoost {
  lfo1:doevent("activate engine").
  output("Stage three boost started").
  wait 0.01.
  
  // did we get booster activation?
  if stageThree = "Flame-Out!" and throttle > 0 {
    setAbort(true, "stage three booster ignition failure").
    unlock throttle.
    when ship:verticalspeed < 0 then {
      output("Apokee achieved @ " + round(ship:altitude/1000, 3) + "km").
      setter("phase", "Apokee").
      runOpsFile("return").
      when ship:altitude < 70000 then {
        output("Atmospheric interface breached").
        setter("phase", "Re-Entry").
        set operations["chuteDeploy"] to chuteDeploy@.
      }
    }
  } else {
    setter("phase", "Stage Three Boost").
    set operations["beco"] to beco@.
  }
  operations:remove("stageThreeBoost").
}

function beco {
  if stageThree = "Flame-Out!" {
    output("Stage three boost completed").
    setter("phase", "Stage Three Coast").
    unlock throttle.
    operations:remove("beco").

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
when time:seconds >= getter("launchTime") - 120 then {
  output("Terminal count begun, monitoring EC levels").
  set operations["terminalCount"] to terminalCount@.
}
output("Launch/Ascent ops ready, awaiting terminal count").