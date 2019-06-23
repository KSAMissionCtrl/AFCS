//////////////////
// Initilaization
//////////////////

declr("launchPositionLat", ship:geoposition:lat).
declr("launchPositionLng", ship:geoposition:lng).
declr("addlLogData", lexicon()).
declr("nonRechargeable", false).
declr("bAcc", false).
declr("fullChargeEC", ship:electriccharge).

// how we monitor electric charge depends on whether NR batteries are used
list resources in resList.
for res in resList { 
  if res:name = "electricchargenonrechargeable" {
    setter("nonRechargeable", true).
    setter("fullChargeEC", getter("fullChargeEC") + ship:electricchargenonrechargeable).
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
  set header to "UT,MET (s),Heading,Pitch,Roll,Dynamic Pressure - Q (kPa),Mass (t),Angle of Attack,Altitude (m),Latitude,Longitude,Apoapsis (m),Periapsis (m),Inclination,Surface Velocity (m/s),Orbital Velocity (m/s),Current Thrust (kN),Available Thrust (kN),Gravity,Distance Downrange (m),Throttle,Electric Charge,EC/Capacity".

  // add GForce if sensor is installed
  list sensors in senselist.
  for sensor in senselist {
    if sensor:type = "ACC" {
      lock acc to sensor.
      setter("bAcc", true).
      if not sensor:active sensor:toggle().
    }
  }
  if (getter("bAcc")) set header to header + ",G Force".
  
  // add any additional headers?
  if getter("addlLogData"):length {
    for addlHeader in getter("addlLogData"):keys { set header to header + "," + addlHeader. }
  }
  
  // output all the headers
  stashmit(header, ship:name + ".csv").
}

// log the telemetry data each - whatever. Calling program will decide how often to log
function logTlm {
  parameter met.
  
  // calculate the new gravity value
  set grav to surfaceGravity/((((ship:orbit:body:radius + ship:altitude)/1000)/(ship:orbit:body:radius/1000))^2).

  // get the sum of all current thrust on active engines
  set currentThrust to 0.
  list engines in engList.
  for eng in engList { if eng:ignition { set currentThrust to currentThrust + eng:thrust. } }

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

  // get current EC values
  set EClvl to ship:electriccharge.
  if getter("nonRechargeable") set ECNRlvl to ship:electricchargenonrechargeable.
  else set ECNRlvl to 0.
  
  // log all the default data
  set datalog to floor(time:seconds) + "," +
                 met + "," +
                 compass_for(ship) + "," +
                 pitch_for(ship) + "," +
                 roll_for(ship) + "," +
                 (ship:Q * constant:ATMtokPa) + "," +
                 ship:mass + "," +
                 NEW_vertical_AOA*-1 + "," +
                 ship:altitude + "," +
                 ship:geoposition:lat + "," +
                 ship:geoposition:lng + "," +
                 ship:orbit:apoapsis + "," +
                 ship:orbit:periapsis + "," +
                 ship:orbit:inclination + "," +
                 ship:velocity:surface:mag + "," +
                 ship:velocity:orbit:mag + "," +
                 currentThrust + "," +
                 ship:availablethrust + "," +
                 grav + "," +
                 circle_distance(latlng(getter("launchPositionLat"),getter("launchPositionLng")), ship:geoposition, ship:orbit:body:radius) + "," +
                 (throttle*100) + "%," +
                 round(EClvl+ECNRlvl, 2) + "," + 
                 round(100 * (EClvl + ECNRlvl) / getter("fullChargeEC"), 2) + "%".
  
  // add G's?
  if (getter("bAcc")) set datalog to datalog + "," + acc:display:split(" ")[0].

  // add any additional data?
  if getter("addlLogData"):length {
    for data in getter("addlLogData"):values { set datalog to datalog + "," + data(). }
  }

  // push the new data to the log
  stashmit(datalog, ship:name + ".csv").
}