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
    rail:doevent("decouple").
    srb1:doevent("activate engine").
    output("launch!").
    
    // allow a physics tick for things to get updated
    wait 0.01.
    
    // did the booster even fire?
    if stageOne = "Flame-Out!" {
      setAbort(true, "stage one booster ignition failure").
    } else {
    
      // setup some triggers, nested so only a few are running at any given time
      when maxQ > ship:q then {
        output("MaxQ: " + round(ship:Q * constant:ATMtokPa, 3) + "kPa @ " + round(ship:altitude/1000, 3) + "km").
        operations:remove("maxQmonitor").
      }
      when ship:apoapsis > 70000 then {
        output("We are going to space!").
        when ship:altitude >= 70000 then {
          output("Space reached!").
          when ship:altitude >= 75000 then { 
            runScience().
          }
        }
      }
      when ship:verticalspeed <= 0 then {
        output("Apokee achieved @ " + round(ship:altitude/1000, 3) + "km").
        when ship:altitude <= 70000 then {
          output("Atmospheric interface breached").
          set operations["chuteDeploy"] to chuteDeploy@.
          set operations["airbrakeDeploy"] to airbrakeDeploy@.
          set operations["maxQmonitor"] to maxQmonitor@.
          set maxQ to 0.
        }
      }
      
      // begin telemetry logging with an intial entry followed by one every second
      logData().
      sleep("datalogger", logData@, 1, true, true).

      // handle certain things regardless of what ascent state we are in
      set operations["maxQmonitor"] to maxQmonitor@.
      
      // wait for first stage boost to complete
      set operations["stageOneBoost"] to stageOneBoost@.
    }
  }
  operations:remove("launch").
}

function maxQmonitor {
  if ship:q > maxQ set maxQ to ship:q.
}

function stageOneBoost {
  if stageOne = "Flame-Out!" {
    output("Stage one boost completed, standing by to decouple. Pitch is " + round(pitch_for(ship), 3)).
    
    // trigger setup to decouple the booster after one second
    set stageCountdown to time:seconds.
    when time:seconds - stageCountdown >= 1 then {
      for fin in s1fins { fin:doevent("kaboom!"). }
      s1decoupler:doevent("decouple").
      output("Stage one booster decoupled").
    }
    
    // get starting value for coast monitoring and switch over
    set startPitch to pitch_for(ship).
    operations:remove("stageOneBoost").
    set operations["stageTwoCoast"] to stageTwoCoast@.
  }
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
  if verticalAOAupdate > s2AoALimit {
    output("Angle of Attack constraint exceeded by " + round(verticalAOAupdate - s2AoALimit, 3) + " - awaiting manual staging").
    operations:remove("stageTwoCoast").
    set operations["stageTwoBoostWait"] to stageTwoBoostWait@.
  }
  
  if startPitch - pitch_for(ship) >= pitchLimit or ship:verticalspeed < 100 {
    srb2:doevent("activate engine").
    wait 0.01.
    
    // did we get booster activation?
    if stageTwo = "Flame-Out!" {
      setAbort(true, "Stage two booster ignition failure").
      operations:remove("stageTwoCoast").
      set operations["coastToLanding"] to coastToLanding@.
    } else {
      output("Stage two boost started. Pitch is " + round(pitch_for(ship), 3) + ", vertical speed is " + round(ship:verticalspeed, 3) + "m/s").
      operations:remove("stageTwoCoast").
      set operations["stageTwoBoost"] to stageTwoBoost@.
    }
  }
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
    output("Stage two boost completed, standing by to decouple").
    set stageCountdown to time:seconds.
    when time:seconds - stageCountdown >= 1 then {
      for fin in s2fins { fin:doevent("kaboom!"). }
      s2decoupler:doevent("decouple").
      output("Stage two booster decoupled").
    }
    operations:remove("stageTwoBoost").
    
    // it will take a second to stage, wait a second longer to boost
    when time:seconds - stageCountdown >= 2 then {
      set operations["stageThreeBoost"] to stageThreeBoost@.
    }
  }
}

function stageThreeBoost {
  lfo1:doevent("activate engine").
  output("Stage three boost started").
  wait 0.01.
  
  // did we get booster activation?
  if stageThree = "Flame-Out!" and throttle > 0 {
    setAbort(true, "Stage three booster ignition failure").
    operations:remove("stageThreeBoost").
    set operations["coastToLanding"] to coastToLanding@.
  } else {
    operations:remove("stageThreeBoost").
    set operations["beco"] to beco@.
  }
}

function beco {
  if stageThree = "Flame-Out!" {
    output("Stage three boost completed").
    unlock throttle.
    operations:remove("beco").
  }
}

// terminal count begins 2min prior to launch
sleep("beginTCount", beginTCount@, getter("launchTime") - 120, false, false).
output("Launch/Ascent ops ready, awaiting terminal count").