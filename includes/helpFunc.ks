// easier to remember
set surfaceGravity to (ship:orbit:body:mass * constant:G)/(ship:orbit:body:radius^2).

// ensures that you can't divide by 0
function getAvailableThrust {
  if ship:availablethrust > 0 return ship:availablethrust.
  if ship:availablethrust = 0 return 0.000000000000000001.
}

// keep track of abort state
set launchAbort to false.
function setAbort {
  parameter doAbort, msg is "undefined reasons".
  set launchAbort to doAbort.
  if (doAbort) {
    output("Launch abort thrown: " + msg).
    unlock throttle.
    unlock steering.
  }
}

// from https://forum.kerbalspaceprogram.com/index.php?/topic/149514-kos-wait-until-facing-prograde/&do=findComment&comment=2793759
// used to determine when the vessel is pointing in a given direction
function pointingAt {
  parameter vector.
  return vang(ship:facing:forevector,vector) <2.
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

// taken from u/nuggreat via https://github.com/nuggreat/kOS-scripts/blob/master/logging_atm.ks
FUNCTION average_grav {
	PARAMETER rad1 IS SHIP:ALTITUDE,rad2 IS 0, localBody IS SHIP:BODY.
	IF rad1 > rad2 {
		RETURN ((localBody:MU / rad2) - (localBody:MU / rad1))/(rad1 - rad2).
	} ELSE IF rad2 > rad1 {
		RETURN ((localBody:MU / rad1) - (localBody:MU / rad2))/(rad2 - rad1).
	} ELSE {
		RETURN localBody:MU / rad1^2.
	}
}

FUNCTION get_active_eng {
	LOCAL engList IS LIST().
	LIST ENGINES IN engList.
	LOCAL returnList IS LIST().
	FOR eng IN engList {
		IF eng:IGNITION AND NOT eng:FLAMEOUT {
			returnList:ADD(eng).
		}
	}
	RETURN returnList.
}

FUNCTION isp_at {
	PARAMETER engineList,curentPressure.  //curentPressure should be in KpA
	SET curentPressure TO curentPressure * CONSTANT:KPATOATM.
	LOCAL totalFlow IS 0.
	LOCAL totalThrust IS 0.
	FOR engine IN engineList {
		LOCAL engThrust IS engine:AVAILABLETHRUSTAT(curentPressure).
		SET totalFlow TO totalFlow + (engThrust / (engine:ISPAT(curentPressure) * 9.80665)).
		SET totalThrust TO totalThrust + engThrust.
	}
	IF totalThrust = 0 {
		RETURN 1.
	}
	RETURN (totalThrust / (totalFlow * 9.80665)).
}

FUNCTION active_engine {  // check for a active engine on ship
	LOCAL engineList IS LIST().
	LIST ENGINES IN engineList.
	LOCAL haveEngine IS FALSE.
	FOR engine IN engineList {
		IF engine:IGNITION AND NOT engine:FLAMEOUT {
			SET haveEngine TO TRUE.
			BREAK.
		}
	}
	RETURN haveEngine.
}