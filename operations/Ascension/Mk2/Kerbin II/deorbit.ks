set chuteSafeSpeed to 450.
set prevEC to 10.

// pull down the antenna once we lose contact with DSN Central
function monitorLOS {
  if not checkCommLink() {
    operations:remove("monitorLOS").
    output("Retracting main antenna").
    probeCommMain:doevent("retract antenna").
    set operations["antennaMonitor"] to antennaMonitor@.
  }
}
function antennaMonitor {
  if probeCommMain:hasevent("extend antenna") {
    operations:remove("antennaMonitor").
    output("Main antenna retraction confirmed").
  }
}

// monitor and ensure orientation completes
function radialNormal {
  if pointingAt(vcrs(ship:velocity:orbit, -body:position)) {
    operations:remove("radialNormal").
    operations:remove("coldGasMonitor").
    unlock steering.
    if rcs {
      rcs off.
      sas on.
      output("RCS disabled, SAS enabled").
    }
    sleep("lockSAS", lockSAS@, 0.5, RELATIVE_TIME, PERSIST_N).    
  }
}
function lockSAS {
  set sasmode to "normal".
  output("Orientation locked to normal").
  operations:remove("lockSAS").
}

// if we run out of cold gas, switch to SAS
function coldGasMonitor {
  if ship:coldgas <= 1 {
    operations:remove("coldGasMonitor").
    unlock steering.
    rcs off.
    sas on.
    sleep("setSAS", setSAS@, 0.5, RELATIVE_TIME, PERSIST_N).    
  }
}
function setSAS {
  set sasmode to "normal".
  output("RCS fuel exhausted, switching to SAS. Continuing to orient normal").
  operations:remove("setSAS").
}

function decouple {
  if ship:altitude <= 100000 {
    operations:remove("decouple").
    set operations["atmoBreach"] to atmoBreach@.

    // are we still somehow trying to orient radial? If so, forget it
    if operations:haskey("radialNormal") {
      operations:remove("radialNormal").
      operations:remove("coldGasMonitor").
    }
    unlock steering.
    rcs off.
    sas on.

    // decouple the service section and prepare to begin retrograde reorientation
    unlock engineStatus.
    removeAddlLogData().
    ship:partstagged("serviceDecoupler")[0]:getmodule("ModuleDecouple"):doevent("decouple").
    output("Service module decoupled, orienting retrograde for re-entry").
    sleep("retroSet", retroSet@, 1, RELATIVE_TIME, PERSIST_N).  
  }
}

function retroSet {
  when kuniverse:canquicksave then kuniverse:quicksaveto(ship:name + " - Decoupled").
  set navmode to "surface".
  set sasmode to "retrograde".
  set operations["retroOrient"] to retroOrient@.
  set operations["atmoBreach"] to atmoBreach@.
  operations:remove("retroSet").
}
function retroOrient {
  if pointingAt(ship:retrograde:forevector) {
    operations:remove("retroOrient").
    output("Orientation locked to retrograde").
  }
}

function atmoBreach {
  if ship:altitude <= 70000 {
    operations:remove("atmoBreach").
    output("Atmospheric interface breached").
    set operations["chuteDeployCheck"] to chuteDeployCheck@.
    set operations["maxQmonitor"] to maxQmonitor@.
    set operations["maxQcheck"] to maxQcheck@.
    set operations["ecMonitor"] to ecMonitor@.
    set maxQ to 0.
  }
}

function chuteDeployCheck {
  if ship:velocity:surface:mag < chuteSafeSpeed {
    operations:remove("chuteDeployCheck").
    if ship:partstagged("rtg"):length {
      output("Safe speed for chute deployment reached, retracting RTG").
      rtg:doevent("retract").
    } else {
      output("Safe speed for chute deployment reached").
      chute:doevent("deploy chute").
      set operations["popChute"] to popChute@.
    }
    set operations["rtgMonitor"] to rtgMonitor@.
  }
}
function rtgMonitor {
  if rtg:hasevent("deploy") {
    operations:remove("rtgMonitor").
    output("RTG retraction confirmed").
    chute:doevent("deploy chute").
    set operations["popChute"] to popChute@.
  }
}

function popChute {
  if chute:hasevent("cut chute") {
    operations:remove("popChute").
    output("Initial chute deploy triggered @ " + round(ship:altitude/1000, 3) + "km").
    set operations["onFullDeploy"] to onFullDeploy@.
  }
}

function onFullDeploy {
  if abs(ship:verticalspeed) <= 9 {
    operations:remove("onFullDeploy").
    output("Full chute deployment @ " + round(ship:altitude, 3) + "m").
    set operations["coastToLanding"] to coastToLanding@.
  }
}

function coastToLanding {
  if ship:status = "SPLASHED" or ship:status = "LANDED" {
    output(ship:status + " @ " + round(abs(chuteSpeed), 3) + "m/s, " + round(circle_distance(latlng(getter("launchPositionLat"),getter("launchPositionLng")), ship:geoposition, ship:orbit:body:radius)/1000, 3) + "km downrange").
    operations:remove("coastToLanding").
    output("flight operations concluded").
    if ship:status = "SPLASHED" when kuniverse:canquicksave then kuniverse:quicksaveto(ship:name + " - Splashdown").
    else when kuniverse:canquicksave then kuniverse:quicksaveto(ship:name + " - Touchdown").
  } else set chuteSpeed to ship:verticalspeed.
}


function maxQmonitor {
  if ship:q > maxQ {
    set maxQ to ship:q.

    // restart check if Q begins to rise again
    if not operations:haskey("maxQcheck") set operations["maxQcheck"] to maxQcheck@.
  }
}
function maxQcheck {
  if maxQ > ship:q {
    output("MaxQ: " + round(ship:Q * constant:ATMtokPa, 3) + "kPa @ " + round(ship:altitude/1000, 3) + "km").
    operations:remove("maxQcheck").
  }
}
function ecMonitor {

  // if EC is draining and has dropped below 9, RTG must be gone
  if ship:electriccharge < prevEC and ship:electriccharge < 9 {
    operations:remove("ecMonitor").
    output("EC drain in progress. RTG attachment severed").
  }
  set prevEC to ship:electriccharge.
}

output("Return sequence configured").