// switch over to high gain antennae
function deployHGA {
  hg1:doevent("extend antenna").
  hg2:doevent("extend antenna").
  operations:remove("deployHGA").
  set operations["awaitDeployment"] to awaitDeployment@.
}
function awaitDeployment {
  if hg1Status = "Extended" and hg2Status = "Extended" {

    // switch off the low-gain antenna, open the hatch & deploy more science
    commMain:doevent("retract antenna").
    output("High gain antennae deployed. Extending mag boom, extending RPWS").
    set hatch:enabled to false.
    rpws:doaction("start: radio plasma wave scan", true).
    mag:doaction("start: magnetometer scan", true).

    operations:remove("awaitDeployment").
    set operations["highSpaceGoo"] to highSpaceGoo@.
  }
}

// swap between Goo canisters depending on altitude
// one will be exposed to normal radiaition within the magnetosphere
// one will be exposed to normal and high radiation in the belt
function highSpaceGoo {
  if ship:altitude >= 249000 {
    gooLow:doaction("stop: mystery goo™ observation", true).
    gooHigh:doaction("start: mystery goo™ observation", true).
    operations:remove("highSpaceGoo").

    // wait a few seconds so we pass 251km
    sleep("lowSpaceGoo", lowSpaceGoo@, 5, true, false).
    output("Swapping Goo canisters for high-space & belt observations").
  }
}
function lowSpaceGoo {
  if ship:altitude <= 251000 {
    gooHigh:doaction("stop: mystery goo™ observation", true).
    gooLow:doaction("start: mystery goo™ observation", true).
    operations:remove("lowSpaceGoo").
    output("Swapping Goo canisters to resume low-space observations").
  }
}

// once we enter into the radiation belt, time to seal up the capsule to test shielding
function monitorRadBeltEntry {
  if extRadLvl > nrmExtRadLvl {
    set hatch:enabled to true.
    rpws:doaction("stop: radio plasma wave scan", true).
    output("Entering radiation belt, stowing RPWS & securing hatch").
    set beltEnterUT to time:seconds.
    operations:remove("monitorRadBeltEntry").
  }
}

function apokee {
  if ship:verticalspeed <= 0 {
    output("Apokee achieved @ " + round(ship:altitude/1000, 3) + "km. Unsecuring hatch, deploying GRS").
    operations:remove("apokee").
    set operations["saveReturn"] to saveReturn@.

    // return to science operations
    set hatch:enabled to false.
    grs:doaction("start: gamma ray spectrometry", true).

    // split the time left in the belt between the two instruments
    sleep("swapBeltScience", swapBeltScience@, (floor(time:seconds)-beltEnterUT)/2, true, false).
  }
}
function swapBeltScience {
  operations:remove("swapBeltScience").
  output("Halfway back down through belt, stowing GRS, deploying RPWS").
  grs:doaction("stop: gamma ray spectrometry", true).
  rpws:doaction("start: radio plasma wave scan", true).
  set operations["monitorRadBeltExit"] to monitorRadBeltExit@.
}

// swap science one more time after exiting the belt
function monitorRadBeltExit {
  if extRadLvl <= nrmExtRadLvl {
    output("Exited the radiation belt, swapping RPWS for GRS").
    rpws:doaction("stop: radio plasma wave scan", true).
    grs:doaction("start: gamma ray spectrometry", true).

    operations:remove("monitorRadBeltExit").
    set operations["prepReentry"] to prepReentry@.
  }
}

// prepare capsule for re-entry
function prepReentry {
  if ship:altitude <= 150000 {
    output("Preparing for re-entry: retracting GRS, securing capsule hatch & Goo canister").
    set hatch:enabled to true.
    grs:doaction("stop: gamma ray spectrometry", true).
    gooLow:doaction("stop: mystery goo™ observation", true).
    commMain:doevent("extend antenna").
    commBackup:doevent("extend antenna").
    if batt:hasevent("Connect Battery") batt:doevent("Connect Battery").

    operations:remove("prepReentry").
    set operations["decoupleCapsule"] to decoupleCapsule@.
    set operations["reentry"] to reentry@.
  }
}
function decoupleCapsule {
  if commMain:hasevent("retract antenna") and commBackup:hasevent("retract antenna") {
    output("Low-gain antennae extended, decoupling from lifter stage").
    decoupler:doevent("decouple").
    sleep("pushAway", pushAway@, 1, true, false).
    operations:remove("decoupleCapsule").
    operations:remove("gasMonitor").
  }
}
function pushAway {
  rcs on.
  unlock steering.
  set ship:control:fore to 1.
  operations:remove("pushAway").
  sleep("endThrustTimer", endThrustTimer@, 15, true, false).
  set operations["endThrustFuel"] to endThrustFuel@.
}

// push away for 15 seconds or until 25u cold gas remain
// then flip around to point heat shield at atmosphere
function endThrustTimer {
  output("Capsule clear of lift stage. Orienting retrograde").
  set ship:control:fore to 0.
  lock steering to ship:retrograde.
  operations:remove("endThrustTimer").
  operations:remove("endThrustFuel").
  set operations["retropoint"] to retropoint@.
}
function endThrustFuel {
  if ship:coldgas <= 25 {
    output("Capsule clear of lift stage. Orienting retrograde").
    operations:remove("endThrustFuel").
    sleepTimers:remove("endThrustTimer").
    set ship:control:fore to 0.
    lock steering to ship:retrograde.
    set operations["retropoint"] to retropoint@.
  }
}
function retropoint {
  if pointingAt(ship:retrograde:forevector) {

    // give it 3 more seconds to stabilize
    sleep("reentryReady", reentryReady@, 3, true, false).
    operations:remove("retropoint").
  }
}
function reentryReady {
  output("Ready for atmospheric interface").
  unlock steering.
  set ship:control:roll to 1.
  operations:remove("reentryReady").
}

output("Space operations executing").

// maintain a position so dishes always point back towards KSC
// but make sure enough cold gas remains to push away from lifter & orient before re-entry
rcs on.
lock steering to heading(90, 70).
function gasMonitor {
  if ship:coldgas <= 100 {
    unlock steering.
    rcs off.
    operations:remove("gasMonitor").
    output("RCS disabled to save fuel for re-entry preparation").
  }
}
set operations["gasMonitor"] to gasMonitor@.

// get science going!
hudtext("Telemetry & Data Xmit needs to be started manually", 10, 2, 36, yellow, false).
gooLow:doaction("start: mystery goo™ observation", true).
output("Starting low-space Goo observations. Deploying high-gain antennae").

set operations["apokee"] to apokee@.
set operations["deployHGA"] to deployHGA@.
set operations["monitorRadBeltEntry"] to monitorRadBeltEntry@.