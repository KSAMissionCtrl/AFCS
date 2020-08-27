//////////////////
// Initilaization
//////////////////

declr("launchPositionLat", ship:geoposition:lat).
declr("launchPositionLng", ship:geoposition:lng).
declr("addlLogData", lexicon()).
declr("nonRechargeable", false).
declr("bAcc", false).
declr("fullChargeEC", ceiling(ship:electriccharge)).

// how we monitor electric charge depends on whether NR batteries are used
list resources in resList.
for res in resList { 
  if res:name = "electricchargenonrechargeable" {
    setter("nonRechargeable", true).
    setter("fullChargeEC", getter("fullChargeEC") + ceiling(ship:electricchargenonrechargeable)).
  }
}

// taken from u/nuggreat via https://github.com/nuggreat/kOS-scripts/blob/master/logging_atm.ks
LOCAL localBody IS SHIP:BODY.
LOCAL localAtm IS localBody:ATM.
LOG ("time(s),altitude(m),vel(m/s),Q(kPa),,body: " + localBody:NAME) TO logPath.


LOCAL jPerKgK IS (8314.4598/42).  //this is ideal gas constant dived by the molecular mass of the bodies atmosphere
LOCAL heatCapacityRatio IS 1.2.
IF localBody = KERBIN {
	SET jPerKgK TO (8314.4598/28.9644).
	SET heatCapacityRatio TO 1.4.
}

LOCAL preVel IS SHIP:VELOCITY:SURFACE.
LOCAL preTime IS TIME:SECONDS.
LOCAL preGravVec IS localBody:POSITION - SHIP:POSITION.
LOCAL preForeVec IS SHIP:FACING:FOREVECTOR.
LOCAL preMass IS SHIP:MASS.
LOCAL preDynamicP IS SHIP:Q * CONSTANT:ATMTOKPA.
LOCAL preAtmPressure IS MAX(localAtm:ALTITUDEPRESSURE(ALTITUDE) * CONSTANT:ATMTOKPA,0.000001).
LOCAL atmDencity IS preDynamicP / preVel:SQRMAGNITUDE.
LOCAL atmMolarMass IS atmDencity / preAtmPressure.

LOCAL burnCoeff IS 0.
IF active_engine { SET burnCoeff TO 1.}

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
  set header to "UT,MET (s),Heading,Pitch,Roll,Dynamic Pressure - Q (kPa),Pressure (kPa),Density (kg/m^3),Molar Mass (mg/J),Atmospheric Temperature (K),Mach (m/s),Mass (t),Angle of Attack,Altitude (m),Latitude,Longitude,Apoapsis (m),Periapsis (m),Inclination,Surface Velocity (m/s),Orbital Velocity (m/s),Current Thrust (kN),Available Thrust (kN),Gravity,Distance Downrange (m),Throttle,Electric Charge,EC/Capacity".

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

  // there is a small chance that in the physics ticks between when the first altitude check is made
  // and the second one at the end, the capsule is then below 70km. We don't want to do anything
  // in that second check if the first one was false
  set newVars to false.

  // taken from u/nuggreat via https://github.com/nuggreat/kOS-scripts/blob/master/logging_atm.ks
  if ship:altitude < 70000 {
    set newVars to true.
    SET newTime TO TIME:SECONDS.
    SET newAlt TO SHIP:ALTITUDE.
    SET newDynamicP TO SHIP:Q.//is in atmospheres 
    SET newVel TO SHIP:VELOCITY:SURFACE.
    SET newAtmPressure TO MAX(localAtm:ALTITUDEPRESSURE(newAlt),0.0000001).
    SET newMass TO SHIP:MASS.
    SET newForeVec TO SHIP:FACING:FOREVECTOR.
    SET newGravVec TO localBody:POSITION - SHIP:POSITION.

    SET newAtmPressure TO newAtmPressure * CONSTANT:ATMTOKPA.
    SET newDynamicP TO newDynamicP * CONSTANT:ATMTOKPA.
    //SET newMass TO newMass * 1000.

    SET avrPressure TO (newAtmPressure + preAtmPressure) / 2.
    SET avrDynamicP TO (newDynamicP + preDynamicP) / 2.
    SET avrForeVec TO ((newForeVec + preForeVec) / 2):NORMALIZED.
    SET shipISP TO isp_at(get_active_eng(),avrPressure).

    SET deltaTime TO newTime - preTime.
    SET gravVec TO average_grav(newGravVec:MAG,newGravVec:MAG) * (newGravVec:NORMALIZED + preGravVec:NORMALIZED):NORMALIZED * deltaTime.
    SET burnDV TO shipISP * 9.80665 * LN(preMass / newMass) * burnCoeff.
    SET accelVec TO avrForeVec * burnDV.
    SET dragAcc TO (newVel - (preVel + gravVec + accelVec)) / deltaTime.
    SET dragForce TO ((newMass + preMass) / 2) * VDOT(dragAcc,avrForeVec).
    SET atmDencity TO (avrDynamicP * 2) / ((newVel:SQRMAGNITUDE + preVel:SQRMAGNITUDE) / 2).//derived from q = d * v^2 / 2
    SET dragCoef TO dragForce / MAX(avrDynamicP,0.0001).
    SET atmMolarMass TO atmDencity / avrPressure.
    SET atmTemp TO avrPressure / (jPerKgK * atmDencity).
    SET mach TO SQRT(heatCapacityRatio * jPerKgK * atmTemp).
    set atmDencity to atmDencity*1000.
  } else {
    set dragForce to 0.
    set newAtmPressure to 0.
    set atmDencity to 0.
    set dragCoef to 0.
    set atmMolarMass to 0.
    set atmTemp to 0.
    set mach to 0.
  }

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

  // check for out of atmosphere
  if ship:altitude > 70000 {
    set dynpress to "N/A".
    set atmPress to "N/A".
    set atmDensity to "N/A".
    set atmMM to "N/A".
    set atmK to "N/A".
    set machVel to "N/A".
  } else {
    set dynpress to ship:Q * constant:ATMtokPa.
    set atmPress to newAtmPressure.
    set atmDensity to atmDencity.
    set atmMM to atmMolarMass.
    set atmK to atmTemp.
    set machVel to mach.
  }
  
  // log all the default data
  set datalog to floor(time:seconds) + "," +
                 met + "," +
                 compass_for(ship) + "," +
                 pitch_for(ship) + "," +
                 roll_for(ship) + "," +
                 dynPress + "," +
                 atmPress + "," +
                 atmDensity + "," +
                 atmMM + "," +
                 atmK + "," +
                 machVel + "," +
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

  // taken from u/nuggreat via https://github.com/nuggreat/kOS-scripts/blob/master/logging_atm.ks
  if ship:altitude < 70000 and newVars {
    SET preVel TO newVel.
    SET preTime TO newTime.
    SET preGravVec TO newGravVec.
    SET preForeVec TO newForeVec.
    SET preMass TO newMass.
    SET preDynamicP TO newDynamicP.
    SET preAtmPressure TO newAtmPressure.
  }
}