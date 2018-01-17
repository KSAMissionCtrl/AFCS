//////////////////
// Initilaization
//////////////////

set loggingAllowed to true.
set launchPosition to ship:geoposition.
set lastVectorPosition to ship:geoposition:altitudeposition(ship:altitude).
set surfaceGravity to (ship:orbit:body:mass * constant:G)/(ship:orbit:body:radius^2).
set pathData to lexicon().
set addlLogData to lexicon().
set altData to list().
set geoData to list().
set vecData to list().
set phaseData to list().
set logList to list().
pathData:add("alt", altData).
pathData:add("geo", geoData).
pathData:add("vec", vecData).
pathData:add("phase", phaseData).

// monitor electric charge
list resources in resList.
for res in resList { 
  if res:name = "electriccharge" { 
    lock EClvl to res:amount. 
    set fullChargeEC to res:capacity.
    break.
  } 
}

// ensure any previous data is overwritten
if archive:exists(ship:name + ".csv") archive:delete(ship:name + ".csv").

////////////
// Functions
////////////

// for logging generic operational status, with various considerations
function output {
  parameter text.
  parameter toConsole is true.

  // print to console if requested
  if toConsole print text.
  
  // format the timestamp
  set hours to time:hour.
  set minutes to time:minute.
  set seconds to time:second.
  set mseconds to round(time:seconds - floor(time:seconds), 2) * 100.
  if hours < 10 set hours to "0" + hours.
  if minutes < 10 set minutes to "0" + minutes.
  if seconds < 10 set seconds to "0" + seconds.
  if mseconds < 10 set mseconds to "0" + mseconds.
  
  // log the new data to the file if it will fit
  // otherwise delete the log to start anew
  set logStr to "[" + hours + ":" + minutes + ":" + seconds + "." + mseconds + "] " + text.
  if core:volume:freespace > logStr:length {
    log logStr to ship:name + ".log.np2".
  } else {
    core:volume:delete(ship:name + ".log.np2").
    log "[" + time:calendar + "] new file" to ship:name + ".log.np2".
    log logStr to ship:name + ".log.np2".
  }

  // store a copy on KSC hard drives if we are in contact
  // otherwise save and copy over as soon as we are back in contact
  if hasSignal {
    if not archive:exists(ship:name + ".log.np2") archive:create(ship:name + ".log.np2").
    if logList:length {
      for entry in logList archive:open(ship:name + ".log.np2"):writeln(entry).
      set logList to list().
    }
    archive:open(ship:name + ".log.np2"):writeln(logStr).
  } else {
    if core:volume:freespace > logStr:length {
      logList:add(logStr).
    } else {
      core:volume:delete(ship:name + ".log.np2").
      logList:add("[" + time:calendar + "] new file").
      logList:add(logStr).
    }
  }
}

// called to create log header after any additional log parameters have been set
function initLog {

  // create the default CSV headers
  set header to "UT,MET (s),Heading,Pitch,Roll,Dynamic Pressure - Q (kPa),Mass (t),Angle of Attack,Altitude (m),Latitude,Longitude,Apoapsis (m),Periapsis (m),Inclination,Velocity (m/s),Thrust (kN),Gravity,Distance Downrange (m),Throttle,Electric Charge,EC/Capacity".
  
  // add any additional headers?
  if addlLogData:length {
    for addlHeader in addlLogData:keys { set header to header + "," + addlHeader. }
  }
  
  // output all the headers
  log header to "0:" + ship:name + ".csv".
}

// log the telemetry data each - whatever. Calling program will decide how often to log
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
  
  // log all the default data
  set datalog to currTime + "," +
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
                 round(EClvl, 2) + "," + 
                 round(100 * EClvl / fullChargeEC, 2) + "%".
                 
  // add any additional data?
  if addlLogData:length {
    for data in addlLogData:values { set datalog to datalog + "," + data(). }
  }

  // push the new data to the log
  log datalog to logVol + ship:name + ".csv".
}