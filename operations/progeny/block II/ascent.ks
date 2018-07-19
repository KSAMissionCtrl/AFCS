// functions are in the order of flight operations
function terminalCount {

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

function launch {

  // check if we have launch clearance
  if not abort { 
    stage.
    output("launch!").
    
    // allow a physics tick for things to get updated
    wait 0.01.
    
    // did the boosters even fire?
    if stageOneMain = "Flame-Out!" or stageOneRadial = "Flame-Out!" {
      setAbort(true, "stage one booster ignition failure").
    } else {
    
      // setup some triggers, nested so only a few are running at any given time
      when maxQ > ship:q then output("MaxQ: " + round(ship:Q * constant:ATMtokPa, 3) + "kPa").
      when ship:apoapsis > 70000 then {
        output("We are going to space!").
        when ship:altitude >= 70000 then {
          output("Space reached!").
        }
      }
      when ship:verticalspeed <= 0 then {
        output("Apokee achieved @ " + round(ship:altitude/1000, 3) + "km").
        set phase to "Apokee".
        when ship:altitude <= 70000 then {
          output("Atmospheric interface breached").
          set operations["chuteDeploy"] to chuteDeploy@.
        }
      }
      
      // handle certain things regardless of what ascent state we are in
      set operations["ongoingOps"] to ongoingOps@.
      
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
    output("Stage one radial boost completed. Boosters released").
    set phase to "Stage One Main Boost".
    for decoupler in radDecouplers { decoupler:doevent("decouple"). }
    operations:remove("stageOneRadialBoost").
  }
}

function stageOneBoost {
  if stageOneMain = "Flame-Out!" {
    output("Stage one main boost completed, standing by to decouple. Pitch is " + round(pitch_for(ship), 3)).
    
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
  if VANG(ship:facing:vector, ship:srfprograde:vector) > s2AoALimit {
    output("Angle of Attack constraint exceeded by " + round(VANG(ship:facing:vector, ship:srfprograde:vector) - s2AoALimit, 3) + " - awaiting manual staging").
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
    setAbort(true, "stage three booster ignition failure").
    set operations["coastToLanding"] to coastToLanding@.
  } else {
    set phase to "Stage Three Boost".
    set operations["beco"] to beco@.
  }
  operations:remove("stageThreeBoost").
}

function beco {
  if stageThree = "Flame-Out!" {
    output("Stage three boost completed").
    set phase to "Stage Three Coast".
    unlock throttle.
    operations:remove("beco").
  }

  // do not let the spacecraft fly beyond 1Mm radio range
  // account for distance from KSC not just height over Kerbin
  if ship:apoapsis > 900000 {
    lfo1:doevent("shutdown engine").
    output("Stage three shutdown due to excessive apokee").
    set phase to "Stage Three Coast".
    unlock throttle.
    operations:remove("beco").
  }
}

function chuteDeploy {

  // force deployment below 800m as a failsafe - might as well just try at that point!
  if ship:velocity:surface:mag < chuteSafeSpeed or ship:altitude <= 800 {
    chute:doevent("deploy chute").
    output("Initial chute deploy triggered @ " + round(ship:altitude/1000, 3) + "km").
    set phase to "initial Chute Deploy".
    operations:remove("chuteDeploy").
    when abs(ship:verticalspeed) <= 10 then {
      output("Full chute deployment @ " + round(ship:altitude, 3) + "m").
      set phase to "Full Chute Deploy".
      set operations["coastToLanding"] to coastToLanding@.
    }
  }
}

function coastToLanding {
  if ship:status = "SPLASHED" {
    output("Splashdown @ " + round(abs(chuteSpeed), 3) + "m/s, " + round(circle_distance(launchPosition, ship:geoposition, ship:orbit:body:radius)/1000, 3) + "km downrange").
    set isLanded to true.
  } else if ship:status = "LANDED" {
    output("Touchdown @ " + round(abs(chuteSpeed), 3) + "m/s, " + round(circle_distance(launchPosition, ship:geoposition, ship:orbit:body:radius)/1000, 3) + "km downrange").
    set isLanded to true.
  } else if time:seconds - currTime >= logInterval { set chuteSpeed to ship:verticalspeed. }
}

// terminal count begins 2min prior to launch
when time:seconds >= launchTime - 120 then {
  output("Terminal count begun, monitoring EC levels").
  set operations["terminalCount"] to terminalCount@.
}
output("Launch/Ascent ops ready, awaiting terminal count").