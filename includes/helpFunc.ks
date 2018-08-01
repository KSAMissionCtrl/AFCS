// easier to remember
set surfaceGravity to (ship:orbit:body:mass * constant:G)/(ship:orbit:body:radius^2).

// ensures that you can't divide by 0
function getAvailableThrust {
  if ship:availablethrust > 0 return ship:availablethrust.
  if ship:availablethrust = 0 return 0.000000000000000001.
}

// keep track of abort state
function setAbort {
  parameter doAbort, msg is "undefined reasons".
  set abort to doAbort.
  output("Launch abort thrown: " + msg).
}

// from the KSLib
// https://github.com/KSP-KOS/KSLib/blob/master/library/lib_circle_nav.ks
function circle_distance {
 parameter
  p1,     //...this point...
  p2,     //...to this point...
  radius. //...around a body of this radius. (note: if you are flying you may want to use ship:body:radius + altitude).
 local A is sin((p1:lat-p2:lat)/2)^2 + cos(p1:lat)*cos(p2:lat)*sin((p1:lng-p2:lng)/2)^2.

 return radius*constant():PI*arctan2(sqrt(A),sqrt(1-A))/90.
}

// from the KSLib
// https://github.com/KSP-KOS/KSLib/blob/master/library/lib_navball.ks
function east_for {
  parameter ves.

  return vcrs(ves:up:vector, ves:north:vector).
}
function compass_for {
  parameter ves.

  local pointing is ves:facing:forevector.
  local east is east_for(ves).

  local trig_x is vdot(ves:north:vector, pointing).
  local trig_y is vdot(east, pointing).

  local result is arctan2(trig_y, trig_x).

  if result < 0 {
    return 360 + result.
  } else {
    return result.
  }
}
function pitch_for {
  parameter ves.

  return 90 - vang(ves:up:vector, ves:facing:forevector).
}
function roll_for {
  parameter ves.

  if vang(ship:facing:vector,ship:up:vector) < 0.2 { //this is the dead zone for roll when the ship is vertical
    return 0.
  } else {
    local raw is vang(vxcl(ship:facing:vector,ship:up:vector), ves:facing:starvector).
    if vang(ves:up:vector, ves:facing:topvector) > 90 {
      if raw > 90 {
        return 270 - raw.
      } else {
        return -90 - raw.
      }
    } else {
      return raw - 90.
    }
  }
}

// https://www.reddit.com/r/Kos/comments/90okvr/looking_for_aoa_relative_to_the_craft/
FUNCTION vertical_aoa {
  LOCAL srfVel IS VXCL(SHIP:FACING:STARVECTOR,SHIP:VELOCITY:SURFACE). //surface velocity excluding any yaw component 
  RETURN VANG(SHIP:FACING:FOREVECTOR,srfVel).
}
LOCK roll TO ARCTAN2(-VDOT(FACING:STARVECTOR, UP:FOREVECTOR), VDOT(FACING:TOPVECTOR, UP:FOREVECTOR)).