//////////////////
// Initilaization
//////////////////

set loggingAllowed to true.
set launchPosition to ship:geoposition.
set lastVectorPosition to ship:geoposition:altitudeposition(ship:altitude).
set surfaceGravity to (ship:orbit:body:mass * constant:G)/(ship:orbit:body:radius^2).
set pathData to lexicon().
set altData to list().
set geoData to list().
set vecData to list().
set phaseData to list().
pathData:add("alt", altData).
pathData:add("geo", geoData).
pathData:add("vec", vecData).
pathData:add("phase", phaseData).

// ensure any previous data is overwritten
if archive:exists(ship:name + ".csv") archive:delete(ship:name + ".csv").

// create the CSV headers
log "UT,MET (s)Heading,Pitch,Roll,Dynamic Pressure - Q (kPa),Mass (t),Angle of Attack,Altitude (m),Lat,Lon,Apoapsis (m),Periapsis (m),Inclination,Velocity (m/s),Thrust (kN),Gravity,Distance Downrange (m), Actual Throttle, Calculated Throttle" to "0:" + ship:name + ".csv".

output("logger ready").

////////////
// Functions
////////////

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

// log the data each - whatever. Calling program will decide how often to log
function logTlm {
  parameter met.
  
  // if free space has fallen below a certain limit, cease logging
  if core:volume:freespace < 500 set loggingAllowed to false.
  if not loggingAllowed return.
  
  // logging destination determined by signal status
  if hasSignal set logVol to "0:".
  if not hasSignal set logVol to "1:".
  
  // log position data so an ascent path can be rendered after the launch
  geoData:add(ship:geoposition).
  altData:add(ship:altitude).
  vecData:add(ship:facing:vector).
  phaseData:add(phase).
  writejson(pathData, logVol + ship:name + ".json").
  
  // calculate the new gravity value
  set grav to surfaceGravity/((((ship:orbit:body:radius + ship:altitude)/1000)/(ship:orbit:body:radius/1000))^2).
  
  // ensure we have thrust so there is no division by zero
  if ship:availablethrust set twrThrottle to (3 * ship:mass * grav / ship:availablethrust) * 100.
  if not ship:availablethrust set twrThrottle to 0.

  // log all the data
  log currTime + "," +
    met + "," +
    compass_for(ship) + "," +
    pitch_for(ship) + "," +
    roll_for(ship) + "," +
    (ship:Q * constant:ATMtokPa) + "," +
    ship:mass + "," +
    VANG(ship:facing:vector, ship:srfprograde:vector) + "," +
    ship:altitude + "," +
    ship:geoposition:lat + "," +
    ship:geoposition:lng + "," +
    ship:orbit:apoapsis + "," +
    ship:orbit:periapsis + "," +
    ship:orbit:inclination + "," +
    ship:velocity:surface:mag + "," +
    ship:availablethrust + "," +
    grav + "," +
    circle_distance(launchPosition, ship:geoposition, ship:orbit:body:radius) + "," +
    ship:control:mainthrottle + "%," + 
    twrThrottle + "%"
  to logVol + ship:name + ".csv".
}