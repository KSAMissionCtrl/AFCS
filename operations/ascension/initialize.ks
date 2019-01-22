// initialize variables
set abort to false.
set chuteSpeed to 0.
set chuteSafeSpeed to 490.
set phase to "Initial Ascent".
set launchTime to 74604180.
set maxECdrain to 1.
set currThrottle to 0.1.
set logInterval to 1.
set maxQ to 0.
set hdgHold to 45.
set pitch to 89.6.

// keep track of part status
lock engineStatus to ship:partstagged("lfo")[0]:getmodule("ModuleEnginesFX"):getfield("status").
lock engineThrust to ship:partstagged("lfo")[0]:getmodule("ModuleEnginesFX"):getfield("thrust").

// get parts now so searching doesn't hold up main program execution
set engine to ship:partstagged("lfo")[0]:getmodule("ModuleEnginesFX").
set decoupler to ship:partstagged("decoupler")[0]:getmodule("ModuleDecouple").
set parachutes to list(
  ship:partstagged("chute")[0]:getmodule("RealChuteModule"),
  ship:partstagged("chute")[1]:getmodule("RealChuteModule")
).
set serviceTower to list(
  ship:partstagged("tower")[0]:getmodule("LaunchClamp"),
  ship:partstagged("tower")[1]:getmodule("LaunchClamp")
).

// add any custom logging fields, then call for header write and setup log call
set addlLogData["Rad/hr"] to {
  set radlvl to ship:partstagged("science")[0]:getmodule("Sensor"):getfield("Radiation").
  if radlvl <> "nominal" {
    set radlvl to radlvl:split(" ")[0].
  }
  return radlvl.
}.
set addlLogData["Payload Internal (k)"] to {
  return ship:partstagged("payload")[0]:getmodule("HotSpotModule"):getfield("Temp [I]"):split(" / ")[0].
}.
set addlLogData["Payload Surface (k)"] to {
  return ship:partstagged("payload")[0]:getmodule("HotSpotModule"):getfield("Temp [S]"):split(" / ")[0].
}.
set addlLogData["Heat Shield Internal (k)"] to {
  return ship:partstagged("shield")[0]:getmodule("HotSpotModule"):getfield("Temp [I]"):split(" / ")[0].
}.
set addlLogData["Heat Shield Surface (k)"] to {
  return ship:partstagged("shield")[0]:getmodule("HotSpotModule"):getfield("Temp [S]"):split(" / ")[0].
}.
initLog().
function logData {
  logTlm(floor(time:seconds) - launchTime).
}

// setup some notification triggers, nested so only a few are running at any given time
when ship:orbit:apoapsis > 70000 then {
  output("We are going to space!").
  when ship:altitude >= 70000 then {
    output("Space reached!").
    unlock steering.
    when ship:verticalspeed <= 0 then {
      output("Apokee achieved @ " + round(ship:altitude/1000, 3) + "km").
      when ship:altitude <= 70000 then {
        output("Atmospheric interface breached").
        set operations["chuteDeploy"] to chuteDeploy@.
        set phase to "re-entry".
      }
    }
  }
}

lock throttle to currThrottle.
output("Vessel boot up").