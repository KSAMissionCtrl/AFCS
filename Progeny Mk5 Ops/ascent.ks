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
    set abort to true.
    set abortMsg to "excessive EC drain".
  }
  if abort and currEC - EClvl < maxECdrain {
    output("EC drain is nominal @ " + round(currEC - EClvl, 3) + "ec/s").
    set abort to false.
  }  
  set currEC to EClvl.
  wait 0.01.
}

// setup triggers to know when to change our run state based on external commands
on AG6 {
  output("Stage one separation commanded").
  set runState to 2.
}
on AG5 {
  output("Stage two separation commanded").
  set runState to 5.
}
on AG4 {
  output("Stage three fin shred commanded @ " + round(ship:altitude/1000, 3) + "km").
  set runState to 8.
}

// if we are in an abort state, do not continue
if abort { output("launch aborted due to " + abortMsg). }
else {

  // launch the rocket
  output("launch!").
  stage.
  
  // enter ascent runtime
  until splashdown {
  
    // stage 1 boost
    if runstate = 0 and stageOne = "Flame-Out!" {
      output("Stage one boost completed").
      set phase to "Stage Two Coast".
      set runState to 1.
    }
    
    // stage 2 coast to ignition
    else if runState = 2 and stageTwo = "Nominal" {
      output("Stage two boost started").
      set phase to "Stage Two Boost".
      set runState to 3.
    }
    
    // stage 2 boost
    else if runstate = 3 and stageTwo = "Flame-Out!" {
      output("Stage two boost completed").
      set phase to "Stage Three Coast".
      set runState to 4.
    }
    
    // stage 3 coast to ignition
    else if runState = 5 and stageThree = "Nominal" {
      output("Stage three boost started").
      set phase to "Stage Three Boost".
      set runState to 6.
    }

    // stage 3 boost
    else if runstate = 6 and stageThree = "Flame-Out!" {
      output("Stage three boost completed").
      set phase to "Stage Three Coast".
      set runState to 7.
    }
    
    // stage 3 coast to apokee
    else if runstate = 8 and ship:verticalspeed <= 0 {
      output("Apokee achieved @ " + round(ship:altitude/1000, 3) + "km").
      set phase to "Apokee".
      set runState to 9.
    }
    
    // coast to chute deploy
    else if runstate = 9 and chute:hasevent("Cut chute") {
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
    
    // coast to splashdown
    else if runstate = 11 { 
      if ship:altitude <= 0 or abs(ship:verticalspeed) < 1 {
        output("Splashdown @ " + round(abs(chuteSpeed), 3) + "m/s").
        set splashdown to true.
      } else if time:seconds - currTime >= logInterval { set chuteSpeed to ship:verticalspeed. }
    }
    
    // log data every defined interval
    if time:seconds - currTime >= logInterval {
      set currTime to floor(time:seconds).
      logTlm().
    }
  }
}