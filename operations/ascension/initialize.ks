// initialize variables
set chuteSpeed to 0.
set chuteSafeSpeed to 490.
set launchTime to 84304080.
set maxECdrain to 1.
set currThrottle to 0.1.
set logInterval to 1.
set maxQ to 0.
set hdgHold to 45.
set pitch to 89.99.

// keep track of part status
lock engineStatus to ship:partstagged("lfo")[0]:getmodule("ModuleEnginesFX"):getfield("status").
lock engineThrust to ship:partstagged("lfo")[0]:getmodule("ModuleEnginesFX"):getfield("thrust").
lock lesStatus to ship:partstagged("lesPushUp")[0]:getmodule("ModuleEnginesFX"):getfield("status").
lock lesKickStatus to ship:partstagged("lesKick")[0]:getmodule("ModuleEnginesFX"):getfield("status").

// get parts/resources now so searching doesn't hold up main program execution
set engine to ship:partstagged("lfo")[0]:getmodule("ModuleEnginesFX").
set decoupler to ship:partstagged("decoupler")[0]:getmodule("ModuleDecouple").
set heatshield to ship:partstagged("heatshield")[0]:getmodule("ModuleDecouple").
set lesDecoupler to ship:partstagged("lesTower")[0]:getmodule("ModuleDecouple").
set lesKickMotor to ship:partstagged("lesKick")[0]:getmodule("ModuleEnginesFX").
set lesPushMotorDw to ship:partstagged("lesPushDw")[0]:getmodule("ModuleEnginesFX").
set lesPushMotorUp to ship:partstagged("lesPushUp")[0]:getmodule("ModuleEnginesFX").
set lesPushMotorLeft to ship:partstagged("lesPushLeft")[0]:getmodule("ModuleEnginesFX").
set lesPushMotorRight to ship:partstagged("lesPushRight")[0]:getmodule("ModuleEnginesFX").
set chute to ship:partstagged("chute")[0]:getmodule("RealChuteModule").
set floatCollar to ship:partstagged("float")[0]:getmodule("CL_ControlTool").
set serviceTower to list(
  ship:partstagged("tower")[0]:getmodule("LaunchClamp"),
  ship:partstagged("tower")[1]:getmodule("LaunchClamp")
).

// add any custom logging fields, then call for header write and setup log call
initLog().
function logData {
  logTlm(floor(time:seconds) - launchTime).
}

// setup some notification triggers, nested so only a few are running at any given time
when maxQ > ship:q then output("MaxQ: " + round(ship:Q * constant:ATMtokPa, 3) + "kPa @ " + round(ship:altitude/1000, 3) + "km").
when ship:altitude > 18500 then abort on.
when ship:orbit:apoapsis > 70000 then {
  output("We are going to space!").
  when ship:altitude >= 70000 then {
    output("Space reached!").
    unlock steering.
    when ship:verticalspeed <= 0 then {
      output("Apokee achieved @ " + round(ship:altitude/1000, 3) + "km").
      when ship:altitude <= 70000 then {
        output("Atmospheric interface breached").
        set maxQ to 0.
        rcs off.
        sas off.
        when maxQ > ship:q then {
          output("MaxQ: " + round(ship:Q * constant:ATMtokPa, 3) + "kPa @ " + round(ship:altitude/1000, 3) + "km").
          retroThrusterFire().
        }
      }
    }
  }
}

lock throttle to currThrottle.
output("Vessel boot up").