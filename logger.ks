TODO: sourced from older R&D projects - cleanup into a single logging component that can be referenced by ops scripts

clearscreen.
set currTime to ceiling(time:seconds).
set phase to "Booster Ascent".
lock srb to ship:partstagged("srb")[0]:getmodule("moduleengines"):getfield("status").
set pathData to lexicon().
set altData to list().
set geoData to list().
set vecData to list().
set phaseData to list().
pathData:add("alt", altData).
pathData:add("geo", geoData).
pathData:add("vec", vecData).
pathData:add("phase", phaseData).

when srb = "flame-out!" then {
  set phase to "Main Engine Ascent".
  stage.
}.

when ship:obt:apoapsis > 75000 then {
  set phase to "Coast to OIB".
  lock throttle to 0.
  lock steering to prograde.
}.

when ship:altitude > 74000 then {
  set phase to "Orbital Insertion Burn".
  lock throttle to 1.
}.

when ship:obt:periapsis > 70500 then {
  set phase to "Orbit Achieved".
  lock throttle to 0.
}.

print "logging data...".
until 0 {
  wait until time:seconds - currTime > 1.
  set currTime to floor(time:seconds).

  if ship:velocity:surface:mag > 1 {
    geoData:add(ship:geoposition).
    altData:add(ship:altitude).
    vecData:add(ship:facing:vector).
    phaseData:add(phase).
    writejson(pathData, "path.json").
  }
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
}.

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
}.

on AG13 {
  set running to false.
}.

//when stage:number < 2 then { set fuelOffset to 180. }

set TotalFuelIndex to 1.
set StageFuelIndex to 0.
set bTotalFuel to true.
set bStageFuel to true.
set dstTraveled to 0.
set logInterval to 1.
set TotalFuel to 1.
set StageFuel to 1.
//set fuelOffset to 0.
set running to true.
set currTime to ceiling(time:seconds).
set launchTime to currTime+30.
set startStage to stage:number.
set initialVelocity to ship:velocity:surface:mag.
set launchPosition to ship:geoposition.
set surfaceGravity to (ship:orbit:body:mass * constant:G)/(ship:orbit:body:radius^2).

// print out the initial information for us to update as we go along
clearscreen.
print "Time to Launch: ".
print "Compass: " + round(compass_for(ship), 1) + "°".
print "Pitch: " + round(pitch_for(ship), 1) + "°".
print "Roll: " + round(roll_for(ship), 1)  + "°".
print "StageFuel: 100%".
print "TotalFuel: 100%".
print "Distance Traveled: 0m".
print "".

list files in fileList.
for fil in fileList {
  if fil:name = "TelemetryLog.ks" { delete TelemetryLog. }.
}

// create the CSV headers
log "ID,Heading,Pitch,Roll,DstTraveled,StageFuel,TotalFuel,Q,Mass,AoA,Altitude,Lat,Lon,Apoapsis,Periapsis,Inclination,Velocity,Thrust,Gravity,DstDownrange,Throttle,AoAWarn,Video,Camera,CommLost,Event,Image,Tweet" to TelemetryLog.

when launchTime - currTime = 0 then stage.

// loop until program exit is triggered by action group
until not running {
  wait until time:seconds - currTime > logInterval.
  set currTime to floor(time:seconds).

  if launchTime - currTime = 8 {
    stage.
    wait 0.1.
    set TFName to ship:resources[TotalFuelIndex]:name.
    set SFName to stage:resources[StageFuelIndex]:name.
  }.

  // only log the data when staged
  if stage:number < startStage {
    if currTime > launchTime {
      // update our distance traveled every second based on our speed (which is in m/s)
      // https://answers.yahoo.com/question/index?qid=20100423120148AADAkZ2
      // this should be set to ship:velocity:orbital:mag if launching into orbit
      set a to (initialVelocity - ship:velocity:surface:mag)/logInterval.
      set d to (initialVelocity * logInterval) + 0.5 * ((a * logInterval)^2).
      set dstTraveled to dstTraveled + d.
      set initialVelocity to ship:velocity:surface:mag.
    }

    set thrust to 0.
    list engines in allEngines.
    for eng in allEngines {
      if eng:ignition { set thrust to thrust + eng:thrust. }.
    }.

    if currTime >= launchTime {
    if ship:resources:length <= TotalFuelIndex and bTotalFuel {
      set index to 0.
      set bTotalFuel to false.
      for res in ship:resources {
        if res:name = TFName {
          set TotalFuelIndex to index.
          set bTotalFuel to true.
        }
        set index to index+1.
      }.
      if bTotalFuel {
        set TotalFuel to ship:resources[TotalFuelIndex]:amount/(ship:resources[TotalFuelIndex]:capacity).
      } else {
        set TotalFuel to 0.
      }.
    } else if bTotalFuel {
      if TFName <> ship:resources[TotalFuelIndex]:name {
        set index to 0.
        set bTotalFuel to false.
        for res in ship:resources {
          if res:name = TFName {
            set TotalFuelIndex to index.
            set bTotalFuel to true.
          }
          set index to index+1.
        }.
        if bTotalFuel {
          set TotalFuel to ship:resources[TotalFuelIndex]:amount/(ship:resources[TotalFuelIndex]:capacity).
        } else {
          set TotalFuel to 0.
        }.
      } else {
        set TotalFuel to ship:resources[TotalFuelIndex]:amount/(ship:resources[TotalFuelIndex]:capacity).
      }.
    }.
    if stage:resources:length <= StageFuelIndex and bStageFuel {
      set index to 0.
      set bStageFuel to false.
      for res in stage:resources {
        if res:name = SFName {
          set StageFuelIndex to index.
          set bStageFuel to true.
        }
        set index to index+1.
      }.
      if bStageFuel {
        set StageFuel to stage:resources[StageFuelIndex]:amount/(stage:resources[StageFuelIndex]:capacity).
      } else {
        set StageFuel to 0.
      }.
    } else if bStageFuel {
      if SFName <> stage:resources[StageFuelIndex]:name {
        wait 0.5.
        set index to 0.
        set bStageFuel to false.
        for res in stage:resources {
          if res:name = SFName {
            set StageFuelIndex to index.
            set bStageFuel to true.
          }
          set index to index+1.
        }.
        if bStageFuel {
          set StageFuel to stage:resources[StageFuelIndex]:amount/(stage:resources[StageFuelIndex]:capacity).
        } else {
          set StageFuel to 0.
        }.
      } else {
        set StageFuel to stage:resources[StageFuelIndex]:amount/(stage:resources[StageFuelIndex]:capacity).
      }.
    }.
    }.

    // update information text with new data
    if currTime > launchTime {
    print "Mission Elapsed Time: " + (currTime - launchTime) + "s         " at (0,0).
    print "Compass: " + round(compass_for(ship), 1) + "°" + "             " at (0,1).
    print "Pitch: " + round(pitch_for(ship), 1) + "°" + "       " at (0,2).
    print "Roll: " + round(roll_for(ship), 1)  + "°" + "        " at (0,3).
    print "TotalFuel: " + 100*TotalFuel + "%        " at (0,4).
    print "StageFuel: " + 100*StageFuel + "%        " at (0,5).
    print "Distance Traveled: " + dstTraveled + "m        " at (0,6).
    }.

    // log all the data
    log currTime + "," +
        compass_for(ship) + "," +
        pitch_for(ship) + "," +
        roll_for(ship) + "," +
        dstTraveled + "," +
        StageFuel + "," +
        TotalFuel + "," +
        ship:Q + "," +
        ship:mass + "," +
        VANG(ship:facing:vector, ship:srfprograde:vector) + "," +
        ship:altitude + "," +
        ship:geoposition:lat + "," +
        ship:geoposition:lng + "," +
        ship:orbit:apoapsis + "," +
        ship:orbit:periapsis + "," +
        ship:orbit:inclination + "," +
        ship:velocity:surface:mag + "," +
        thrust + "," +
        surfaceGravity/((((ship:orbit:body:radius + ship:altitude)/1000)/(ship:orbit:body:radius/1000))^2) + "," +
        circle_distance(launchPosition, ship:geoposition, ship:orbit:body:radius) + "," +
        ship:control:pilotmainthrottle
    to TelemetryLog.
  }.
  if launchTime - currTime >= 0 { print "Time to Launch: " + (launchTime - currTime)  + "s   " at (0,0). }.
}.
