function awaitTerminalCount {

  // terminal count begins 2min prior to launch
  if time:seconds >= launchTime - 120 {
    output("Terminal count begun, monitoring EC levels").
    operations:remove("awaitTerminalCount").
    set operations["terminalCount"] to terminalCount@.
  }
}
set operations["awaitTerminalCount"] to awaitTerminalCount@.

function terminalCount {

  // until launch, ensure that EC levels are not falling too fast
  // anything greater than the max drain means not enough EC will remain to finish the mission
  // drain limit currently set for a 10-min mission
  set currEC to EClvl.
  if time:seconds < launchTime {
    if not abort and currEC - EClvl >= maxECdrain {
      output("[WARNING] EC drain is " + round(currEC - EClvl, 3) + "ec/s, vessel will run out of EC early").
      setAbort(true, "excessive EC drain").
    }
    if abort and currEC - EClvl < maxECdrain {
      output("EC drain is nominal @ " + round(currEC - EClvl, 3) + "ec/s").
      setAbort(false).
    }  
    set currEC to EClvl.
  } else {
  
    // move into the launch state
    operations:remove("terminalCount").
    set operations["launch"] to launch@.
  }
}

function ongoingOps {
  if ship:q > maxQ set maxQ to ship:q.
  
  // log data every defined interval
  if time:seconds - currTime >= logInterval {
    set currTime to floor(time:seconds).
    logTlm(currTime - launchTime).
  }
  
  if ship:status = "SPLASHED" or ship:status = "LANDED" {
    operations:remove("ongoingOps").
    operations:remove("coastToLanding").
    output("flight operations concluded").
    log profileresult() to ship:name + "kos.csv".
  }
}

function launch {

  // if we are in an abort state, do not continue
  if abort { 
    output("launch aborted due to " + abortMsg). 
    operations:remove("launch").
  } else {

    // launch the rocket
    srb1:doevent("activate engine").
    output("launch!").
    
    // allow a physics tick then setup some triggers, nested so only a few are running at any given time
    wait 0.01.
    when maxQ > ship:q then output("MaxQ: " + round(ship:Q * constant:ATMtokPa, 3) + "kPa").
    when ship:verticalspeed <= 0 then {
      output("Apokee achieved @ " + round(ship:altitude/1000, 3) + "km").
      set phase to "Apokee".
      when ship:altitude <= 4000 then {
        chute:doevent("deploy chute").
        output("Initial chute deploy triggered @ " + round(ship:altitude/1000, 3) + "km").
        set phase to "initial Chute Deploy".
        when abs(ship:verticalspeed) <= 10 then {
          output("Full chute deployment @ " + round(ship:altitude, 3) + "m").
          set phase to "Full Chute Deploy".
          set operations["coastToLanding"] to coastToLanding@.
        }
      }
    }
    when ship:altitude >= 60000 then {
      for fin in s3fins { fin:doevent("kaboom!"). }
      output("Stage three fin shred @ " + round(ship:altitude/1000, 3) + "km").
    }
    when ship:apoapsis > 70000 then {
      output("We are going to space!").
      when ship:altitude >= 70000 then {
        output("Space reached!").
        when ship:altitude >= 75000 then { 
          runScience().
        }
        when ship:altitude <= 70000 then output("Atmospheric interface breached").
      }
    }
    
    // handle certain things regardless of what ascent state we are in
    set operations["ongoingOps"] to ongoingOps@.
    
    // wait for first stage boost to complete
    operations:remove("launch").
    set operations["stageOneBoost"] to stageOneBoost@.
  }
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
  if startPitch - pitch_for(ship) >= pitchLimit or ship:verticalspeed < 100 {
    srb2:doevent("activate engine").
    output("Stage two boost started. Pitch is " + round(pitch_for(ship), 3) + ", vertical speed is " + round(ship:verticalspeed, 3) + "m/s").
    set phase to "Stage Two Boost".
    operations:remove("stageTwoCoast").
    set operations["stageTwoBoost"] to stageTwoBoost@.
  }
}

function stageTwoBoost {
  if stageTwo = "Flame-Out!" {
    output("Stage two boost completed, standing by to decouple. Pitch is " + round(pitch_for(ship), 3)).
    set phase to "Stage Three Coast".
    set stageCountdown to time:seconds.
    when time:seconds - stageCountdown >= 1 then {
      for fin in s2fins { fin:doevent("kaboom!"). }
      s2decoupler:doevent("decouple").
      output("Stage two booster decoupled").
    }
    set startPitch to pitch_for(ship).
    operations:remove("stageTwoBoost").
    set operations["stageThreeCoast"] to stageThreeCoast@.
  }
}

function stageThreeCoast {
  if startPitch - pitch_for(ship) >= pitchLimit or ship:verticalspeed < 100 {
    lfo1:doevent("activate engine").
    output("Stage three boost started. Pitch is " + round(pitch_for(ship), 3) + ", vertical speed is " + round(ship:verticalspeed, 3) + "m/s").
    set phase to "Stage Three Boost".
    
    // wait a second before moving to the next state to give time for craft to accelerate and reset the maxQ
    set stageCountdown to time:seconds.
    when time:seconds - stageCountdown >= 1 then {
      set operations["stageThreeBoostToMaxQ"] to stageThreeBoostToMaxQ@.
      set maxQ to ship:q.
    }
    operations:remove("stageThreeCoast").
  }
}

function stageThreeBoostToMaxQ {
  if maxQ > ship:q {
    output("Go for throttle up @ " + round(maxQ * constant:ATMtokPa, 3) + "kPa and falling, " + round(ship:altitude/1000, 3) + "km").
    operations:remove("stageThreeBoostToMaxQ").
    set operations["stageThreeThrottleUp"] to stageThreeThrottleUp@.
    set maxQ to ship:q.
  }
}

function stageThreeThrottleUp {
  if throttle >= 1 {
    set throttle to 1.
    operations:remove("stageThreeThrottleUp").
    set operations["meco"] to meco@.
  } else {
    if maxQ > ship:q set throttle to throttle + 0.001.
    if maxQ < ship:q set throttle to throttle - 0.001.
    set maxQ to ship:q.
  }
}

function meco {
  if stageThree = "Flame-Out!" {
    output("Stage three boost completed").
    set phase to "Stage Three Coast".
    unlock throttle.
    operations:remove("meco").
  }
}

function coastToLanding {
  if ship:status = "SPLASHED" {
    output("Splashdown @ " + round(abs(chuteSpeed), 3) + "m/s, " + round(circle_distance(launchPosition, ship:geoposition, ship:orbit:body:radius)/1000, 3) + "km downrange").
  } else if ship:status = "LANDED" {
    output("Touchdown @ " + round(abs(chuteSpeed), 3) + "m/s, " + round(circle_distance(launchPosition, ship:geoposition, ship:orbit:body:radius)/1000, 3) + "km downrange").
  } else if time:seconds - currTime >= logInterval { set chuteSpeed to ship:verticalspeed. }
}

output("Launch/Ascent ops ready, awaiting terminal count").