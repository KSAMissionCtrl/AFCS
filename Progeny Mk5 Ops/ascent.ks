output("Launch/Ascent ops ready, awaiting terminal count").

// terminal count begins 2min prior to launch
wait until time:seconds >= launchTime - 120.
output("Terminal count begun, monitoring EC levels").

// until launch, ensure that EC levels are not falling too fast
// anything greater than the max drain means not enough EC will remain to finish the mission
// drain limit currently set for a 10-min mission
set currEC to EClvl.
until time:seconds >= launchTime {
  if not abort and currEC - EClvl >= maxECdrain {
    output("[WARNING] EC drain is " + round(currEC - EClvl, 3) + "ec/s, vessel will run out of EC early").
    setAbort(true, "excessive EC drain").
  }
  if abort and currEC - EClvl < maxECdrain {
    output("EC drain is nominal @ " + round(currEC - EClvl, 3) + "ec/s").
    setAbort(false).
  }  
  set currEC to EClvl.
  wait 0.01.
}

// if we are in an abort state, do not continue
if abort { output("launch aborted due to " + abortMsg). }
else {

  // launch the rocket
  output("launch!").
  stage.
  
  // allow a physics tick then setup some triggers
  wait 0.01.
  when ship:altitude >= 70000 then {
    output("Space reached!").
    when ship:altitude >= 75000 then runScience().
    when ship:altitude <= 70000 then output("Atmospheric interface breached").
    when ship:verticalspeed <= 0 then {
      output("Apokee achieved @ " + round(ship:altitude/1000, 3) + "km").
      set phase to "Apokee".
    }
  }
  when maxQ > ship:q then output("MaxQ: " + (ship:Q * constant:ATMtokPa) + "kPa").
  when ship:apoapsis > 70000 then output("We are going to space!").
  
  // enter ascent runtime
  until landed {
  
    // stage 1 boost
    if runstate = 0 and stageOne = "Flame-Out!" {
      output("Stage one boost completed, standing by to decouple. Pitch is " + round(pitch_for(ship), 3)).
      set phase to "Stage Two Coast".
      set stageCountdown to time:seconds.
      set runState to 1.1.
      set startPitch to pitch_for(ship).
    }
    
    // stage 1 decouple after 1 second wait
    else if runState = 1.1 and time:seconds - stageCountdown >= 1 {
      output("Stage one booster decoupled").
      AG6 on.
      set runState to 2.
    }
    
    // stage 2 coast to ignition after pitch delta
    else if runState = 2 and (startPitch - pitch_for(ship) >= pitchLimit or ship:verticalspeed < 100) {
      output("Stage two boost started. Pitch is " + round(pitch_for(ship), 3) + ", vertical speed is " + round(ship:verticalspeed, 3) + "m/s").
      stage.
      set phase to "Stage Two Boost".
      set runState to 3.
    }
    
    // stage 2 boost
    else if runstate = 3 and stageTwo = "Flame-Out!" {
      output("Stage two boost completed, standing by to decouple. Pitch is " + round(pitch_for(ship), 3)).
      set phase to "Stage Three Coast".
      AG5 on.
      set stageCountdown to time:seconds.
      set runState to 4.
      set startPitch to pitch_for(ship).
    }
    
    // stage 2 decouple after 1 second wait
    else if runState = 4 and time:seconds - stageCountdown >= 1 {
      output("Stage two booster decoupled").
      AG5 on.
      set runState to 5.
    }
    
    // stage 3 coast to ignition after pitch delta
    else if runState = 5 and (startPitch - pitch_for(ship) >= pitchLimit or ship:verticalspeed < 100) {
      output("Stage three boost started. Pitch is " + round(pitch_for(ship), 3) + ", vertical speed is " + round(ship:verticalspeed, 3) + "m/s").
      stage.
      set phase to "Stage Three Boost".
      set runState to 6.
    }

    // stage 3 boost
    else if runstate = 6 and stageThree = "Flame-Out!" {
      output("Stage three boost completed").
      set phase to "Stage Three Coast".
      set runState to 7.
    }
    
    // stage 3 coast to fin shred
    else if runstate = 7 and ship:altitude >= 60000 {
      AG4 on.
      output("Stage three fin shred @ " + round(ship:altitude/1000, 3) + "km").
      set runState to 9.
    }
    
    // coast to chute deploy
    // atmosphere sensor on chute is now backup
    else if runstate = 9 and ship:altitude <= 4000 {
      chute:doevent("deploy chute").
      output("Initial chute deploy triggered @ " + round(ship:altitude/1000, 3) + "km").
      set phase to "initial Chute Deploy".
      set runState to 10.
    }
    
    // coast to full chute deploy
    else if runstate = 10 and abs(ship:verticalspeed) <= 10 {
      output("Full chute deployment @ " + round(ship:altitude, 3) + "m").
      set phase to "Full Chute Deploy".
      set runState to 11.
    }
    
    // coast to landing
    else if runstate = 11 { 
      if ship:status = "SPLASHED" {
        output("Splashdown @ " + round(abs(chuteSpeed), 3) + "m/s, " + round(circle_distance(launchPosition, ship:geoposition, ship:orbit:body:radius)/1000, 3) + "km downrange").
        set landed to true.
      } else if ship:status = "LANDED" {
        output("Touchdown @ " + round(abs(chuteSpeed), 3) + "m/s, " + round(circle_distance(launchPosition, ship:geoposition, ship:orbit:body:radius)/1000, 3) + "km downrange").
        set landed to true.
      } else if time:seconds - currTime >= logInterval { set chuteSpeed to ship:verticalspeed. }
    }
    
    // log data every defined interval
    if time:seconds - currTime >= logInterval {
      set currTime to floor(time:seconds).
      logTlm(currTime - launchTime).
    }
    
    wait 0.01.
  }
}