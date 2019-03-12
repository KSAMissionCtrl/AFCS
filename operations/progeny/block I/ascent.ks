// functions are in the order of flight operations
function TCountNotification {
  output("Terminal count begun, monitoring EC levels").
  operations:remove("TCountNotification").
}

function terminalCount {

  // terminal count begins 2min prior to launch
  if time:seconds <= launchTime - 120 {

    // until launch, ensure that EC levels are not falling faster than they should be
    set currEC to EClvl.
    if currEC - EClvl >= maxECdrain {
      setAbort(true, "EC drain is excessive at " + round(currEC - EClvl, 3) + "ec/s").
      operations:remove("terminalCount").
    }

    // set up for ignition at T-0 seconds
    when time:seconds >= launchTime then {
      operations:remove("terminalCount").
      set operations["launch"] to launch@.
    }
  }
}

function launch {

  // check if we have launch clearance
  if not abort { 
    stage.
    output("launch!").
    
    // allow a physics tick for things to get updated
    wait 0.01.
    
    // did the booster even fire?
    if stageOne = "Flame-Out!" {
      setAbort(true, "stage one booster ignition failure").
    } else {
    
      // setup some triggers, nested so only a few are running at any given time
      when maxQ > ship:q then output("MaxQ: " + round(ship:Q * constant:ATMtokPa, 3) + "kPa").
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
        set phase to "Apokee".
        when ship:altitude <= 70000 then {
          output("Atmospheric interface breached").
          set operations["chuteDeploy"] to chuteDeploy@.
          set operations["airbrakeDeploy"] to airbrakeDeploy@.
          set maxQ to 0.
        }
      }
      
      // handle certain things regardless of what ascent state we are in
      set operations["ongoingOps"] to ongoingOps@.
      
      // wait for first stage boost to complete
      set operations["stageOneBoost"] to stageOneBoost@.
    }
  }
  operations:remove("launch").
}

function stageOneBoost {
  if stageOne = "Flame-Out!" {
    output("Stage one boost completed, standing by to decouple. Pitch is " + round(pitch_for(ship), 3)).
    
    // update the phase for use when rendering the trajectory with path.ks
    set phase to "Stage Two Coast".
    
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
      set phase to "Stage Two Boost".
      operations:remove("stageTwoCoast").
      set operations["stageTwoBoost"] to stageTwoBoost@.
    }
  }
}

function stageTwoBoostWait {
  if stageTwo = "Nominal" {
    output("Stage two boost started. Pitch is " + round(pitch_for(ship), 3) + ", vertical speed is " + round(ship:verticalspeed, 3) + "m/s").
    set phase to "Stage Two Boost".
    operations:remove("stageTwoBoostWait").
    set operations["stageTwoBoost"] to stageTwoBoost@.
  }
}

function stageTwoBoost {
  if stageTwo = "Flame-Out!" {
    output("Stage two boost completed, standing by to decouple").
    set phase to "Stage Three Boost".
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
    set phase to "Stage Three Boost".
    operations:remove("stageThreeBoost").
    set operations["beco"] to beco@.
  }
}

function beco {
  if stageThree = "Flame-Out!" {
    output("Stage three boost completed").
    set phase to "Stage Three Coast".
    unlock throttle.
    operations:remove("beco").
  }
}

function airbrakeDeploy {

  // wait until dynamic pressure begins to drop before releasing airbrakes
  if maxQ > ship:q {
    for airbrake in airbrakes { airbrake:setfield("deploy", true). }
    operations:remove("airbrakeDeploy").
    output("MaxQ: " + round(ship:Q * constant:ATMtokPa, 3) + "kPa - deploying airbrakes").
  }
}

function chuteDeploy {

  // keep track of speed and altitude
  // release chute as soon as it's safe, or as last-ditch attempt if below 1.5km
  if ship:velocity:surface:mag < chuteSafeSpeed or alt:radar < 1500 {
    chute:doevent("deploy chute").
    output("Initial chute deploy triggered @ " + round(ship:altitude/1000, 3) + "km").
    set phase to "initial Chute Deploy".
    when abs(ship:verticalspeed) <= 10 then {
      output("Full chute deployment @ " + round(ship:altitude, 3) + "m").
      set phase to "Full Chute Deploy".
      set operations["coastToLanding"] to coastToLanding@.
    }
    operations:remove("chuteDeploy").
  }
}

function coastToLanding {
  if ship:status = "SPLASHED" {
    output("Splashdown @ " + round(abs(chuteSpeed), 3) + "m/s, " + round(circle_distance(latlng(getter("launchPositionLat"),getter("launchPositionLng")), ship:geoposition, ship:orbit:body:radius)/1000, 3) + "km downrange").
    operations:remove("coastToLanding").
  } else if ship:status = "LANDED" {
    output("Touchdown @ " + round(abs(chuteSpeed), 3) + "m/s, " + round(circle_distance(latlng(getter("launchPositionLat"),getter("launchPositionLng")), ship:geoposition, ship:orbit:body:radius)/1000, 3) + "km downrange").
    operations:remove("coastToLanding").
  } else if time:seconds - currTime >= logInterval { set chuteSpeed to ship:verticalspeed. }
}

set operations["terminalCount"] to terminalCount@.
sleep("TCountNotification", TCountNotification@, launchTime - 120, false, false).
output("Launch/Ascent ops ready, awaiting terminal count").