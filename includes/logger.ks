//////////////////
// Initilaization
//////////////////

set launchPosition to ship:geoposition.
set lastVectorPosition to ship:geoposition:altitudeposition(ship:altitude).
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

////////////
// Functions
////////////

// for logging generic operational status
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
  
  // log the new data
  stashmit("[" + hours + ":" + minutes + ":" + seconds + "." + mseconds + "] " + text).
}

// called to create log header after any additional log parameters have been set
function initLog {

  // create the default CSV headers
  set header to "UT,MET (s),Heading,Pitch,Roll,Dynamic Pressure - Q (kPa),Mass (t),Angle of Attack,AoA Test,Altitude (m),Latitude,Longitude,Apoapsis (m),Periapsis (m),Inclination,Velocity (m/s),Current Thrust (kN),Available Thrust (kN),Gravity,Distance Downrange (m),Throttle,Electric Charge,EC/Capacity".
  
  // add any additional headers?
  if addlLogData:length {
    for addlHeader in addlLogData:keys { set header to header + "," + addlHeader. }
  }
  
  // output all the headers
  stashmit(header, ship:name + ".csv").
}

// log the telemetry data each - whatever. Calling program will decide how often to log
function logTlm {
  parameter met.
  
  // log position data so an ascent path can be rendered after the launch
  geoData:add(ship:geoposition).
  altData:add(ship:altitude).
  vecData:add(ship:facing:vector).
  phaseData:add(phase).
  stashmit(pathData, ship:name + ".json", "json").
  
  // calculate the new gravity value
  set grav to surfaceGravity/((((ship:orbit:body:radius + ship:altitude)/1000)/(ship:orbit:body:radius/1000))^2).

  // get the sum of all current thrust on engines
  set currentThrust to 0.
  list engines in engList.
  for eng in engList { set currentThrust to currentThrust + eng:thrust. }

  // https://www.reddit.com/r/Kos/comments/90okvr/looking_for_aoa_relative_to_the_craft/
  Set RollFactor to -1.
  If roll < 90 {
    if roll > -90 {
      set RollFactor to 1.
    }
  }
  If Ship:Airspeed < 1 {
    Set RollFactor to 0.
  }
  Set NEW_vertical_AOA to vertical_aoa()*RollFactor.
  
  // log all the default data
  set datalog to currTime + "," +
                 met + "," +
                 compass_for(ship) + "," +
                 pitch_for(ship) + "," +
                 roll_for(ship) + "," +
                 (ship:Q * constant:ATMtokPa) + "," +
                 ship:mass + "," +
                 VANG(ship:facing:vector, ship:srfprograde:vector) + "," +
                 NEW_vertical_AOA + "," +
                 ship:altitude + "," +
                 ship:geoposition:lat + "," +
                 ship:geoposition:lng + "," +
                 ship:orbit:apoapsis + "," +
                 ship:orbit:periapsis + "," +
                 ship:orbit:inclination + "," +
                 ship:velocity:surface:mag + "," +
                 currentThrust + "," +
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
  stashmit(datalog, ship:name + ".csv").
}