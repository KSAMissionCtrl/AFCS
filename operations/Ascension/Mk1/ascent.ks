// functions are in the order of flight operations
function ignition {

  // ensure we have clearance to proceed with ignition
  if not launchAbort and ctrlCheckComplete {

    // engine alternator will now provide power
    sleepTimers:remove("monitorEcDrain").

    // ignite the engine at 10% thrust to ensure good chamber pressures
    output("Ignition").
    engine:doevent("activate engine").

    // begin telemetry logging with an intial entry followed by one every second
    logData().
    sleep("datalogger", logData@, 1, true, true).
      
    // pause a sec to allow ignition
    sleep("launchThrust", launchThrust@, 1, true, false).
  } else if not ctrlCheckComplete setAbort(true, "Low hydraulic pressure").
  operations:remove("ignition").
}

function launchThrust {

  // check chamber pressures over the next two seconds if ignition was successful
  if engineStatus <> "Nominal" setAbort(true, "Engine ignition failure. Status: " + engineStatus).   

  // ensure all is still well before throttling up to launch power
  if not launchAbort and time:seconds >= getter("launchTime") - 3 {

    // throttle up to and maintain a TWR of 1.2
    // take into account the mass of the engine clamp
    output("Go for launch thrust").
    lock throttle to 1.2 * (ship:mass - 0.1) * (surfaceGravity/((((ship:orbit:body:radius + ship:altitude)/1000)/(ship:orbit:body:radius/1000))^2)) / getAvailableThrust().

    // move on to launch
    operations:remove("launchThrust").
    sleep("launch", launch@, getter("launchTime"), false, false).
  }
}

function launch {

  // last check for green light as this function was called after a 3s period
  if not launchAbort { 

    // ensure we are in fact at a 1.2 TWR
    set weight to ((ship:mass - 0.1) * (surfaceGravity/((((ship:orbit:body:radius + ship:altitude)/1000)/(ship:orbit:body:radius/1000))^2))).
    if engineThrust / weight >= 1.2 {

      // disengage engine clamp
      launchClamp:doevent("release clamp").
      output("Launch!").
      
      // adjust throttle to proper TWR now that clamp is gone
      lock throttle to 1.2 * ship:mass * (surfaceGravity/((((ship:orbit:body:radius + ship:altitude)/1000)/(ship:orbit:body:radius/1000))^2)) / getAvailableThrust().

      // wait until we've cleared the service towers
      // this is so the pad and engine clamp are not damaged by engine exhaust
      set operations["throttleUp"] to throttleUp@.

      // initial pitch over
      lock steering to heading(hdgHold, pitch).

      // setup some notification triggers, nested so only a few are running at any given time
      when maxQ > ship:q then output("MaxQ: " + round(ship:Q * constant:ATMtokPa, 3) + "kPa @ " + round(ship:altitude/1000, 3) + "km").
      when ship:orbit:apoapsis > 70000 then {
        output("We are going to space!").
        when ship:altitude >= 70000 then {
          when ship:verticalspeed <= 0 then {
            output("Apokee achieved @ " + round(ship:altitude/1000, 3) + "km. Payload decoupled").
            when ship:altitude <= 70000 then {
              output("Atmospheric interface breached").
              set maxQ to 0.
              rcs off.
              sas off.
              when maxQ > ship:q then {
                output("MaxQ: " + round(ship:Q * constant:ATMtokPa, 3) + "kPa @ " + round(ship:altitude/1000, 3) + "km").
                operations:remove("maxQmonitor").
              }
            }
          }
        }
      }

    // takeoff thrust failed to set
    } else {
      setAbort(true, "Engine TWR not set for launch commit. Only at " + (engineThrust / weight)).
      engine:doevent("shutdown engine").
    }
  } else {

    // make double sure the engine was shut down by whatever abort was thrown
    if engine:hasevent("shutdown engine") engine:doevent("shutdown engine").
  }
  operations:remove("launch").
}

function throttleUp {
  if ship:altitude >= 85 {

    // enable guidance
    // pitch over steering taken from https://www.youtube.com/watch?v=NzlM6YZ9g4w
    // https://www.wolframalpha.com/input/?i=quadratic+fit%28%2885%2C89.6%29%2C+%2810000%2C64%29%2C+%2820000%2C43%29%2C+%2830000%2C27%29%2C+%2840000%2C15%29%2C+%2860000%2C5%29%29
    lock pitch to 2.2878E-8 * ship:altitude^2 - 0.00278367 * ship:altitude + 89.7046.
    lock steering to heading(hdgHold,pitch).

    // setup the throttle model to adjust by altitude
    set currThrottle to 0.84228668038601.
    lock throttle to currThrottle.
    set throttleProfile to queue().
    throttleProfile:push(lexicon(500, 0.80296959995735)).
    throttleProfile:push(lexicon(1250, 0.7521563596396)).
    throttleProfile:push(lexicon(2500, 0.65224132367932)).
    throttleProfile:push(lexicon(5000, 0.61534769546699)).
    throttleProfile:push(lexicon(7500, 0.616417444269537)).
    throttleProfile:push(lexicon(10000, 0.613379442497797)).
    throttleProfile:push(lexicon(15000, 0.608442284525448)).
    throttleProfile:push(lexicon(20000, 0.604424761581035)).
    throttleProfile:push(lexicon(30000, 0.602787033402563)).
    throttleProfile:push(lexicon(35000, 0.602413141932895)).
    throttleProfile:push(lexicon(40000, 0.609706496685772)).
    throttleProfile:push(lexicon(45000, 0)).
    
    set operations["ascentToMeco"] to ascentToMeco@.
    set operations["maxQmonitor"] to maxQmonitor@.
    output("Tower cleared, flight guidance enabled & throttle set").
    operations:remove("throttleUp").
  }
}

function maxQmonitor {
  if ship:q > maxQ set maxQ to ship:q.
}

function ascentToMeco {
  if engineStatus = "Flame-Out!" {
    unlock throttle.
    output("Main engine flamed out").
    operations:remove("ascentToMeco").
  }

  // monitor altitude and compare to next throttle change point to take action when needed
  if (throttleProfile:peek():keys[0] <= ship:altitude) {

    // pop out the throttle value from the queue & set it
    set currThrottle to throttleProfile:pop():values[0].

    // if we just killed the throttle, also shut down the engine, detach payload fairings & attempt to hold prograde
    if (currThrottle <= 0) {
      engine:doevent("shutdown engine").
      lock steering to ship:prograde.
      for plf in fairings plf:doevent("jettison fairing").
      output("Main engine burn complete, PLF detached, attempting to hold prograde").
      operations:remove("ascentToMeco").
      set operations["coastToSpace"] to coastToSpace@.
    } else output("Throttle set to " + round(currThrottle*100, 3) + "% @ " + round(ship:altitude/1000, 3) + "km").
  }
}

function coastToSpace {
  if ship:altitude >= 70000 {
    output("Space reached!").
    unlock steering.
    operations:remove("coastToSpace").

    // decouple the payload at apokee
    set operations["payloadDecouple"] to payloadDecouple@.
  }
}

function payloadDecouple {
  if ship:verticalSpeed <= 0 {
    decoupler:doevent("decoupler staging").
    operations:remove("payloadDecouple").
  }
}

// begin check of control surfaces at T-10s
// just do a roll check both ways to make all four fins travel
function ctrlCheckStart {
  set ship:control:roll to 1.
  operations:remove("ctrlCheckStart").
  sleep("ctrlCheckRoll", ctrlCheckRoll@, 1, true, false).
}
function ctrlCheckRoll {
  set ship:control:roll to -1.
  operations:remove("ctrlCheckRoll").
  sleep("ctrlCheckFinish", ctrlCheckFinish@, 1, true, false).
}
function ctrlCheckFinish {
  set ship:control:roll to 0.
  unlock steering.
  set ctrlCheckComplete to true.
  operations:remove("ctrlCheckFinish").
}

sleep("terminalCount", terminalCount@, getter("launchTime") - 120, false, false).
output("Launch/Ascent ops ready, awaiting terminal count").