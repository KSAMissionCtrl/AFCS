//////////////////
// Initilaization
//////////////////

clearscreen.
set operations to lexicon().
set varData to lexicon().
set sleepTimers to lexicon().
set runSafe to true.

// ensure all systems ready
wait until ship:unpacked.

// get all comm parts on the ship
set commLinks to lexicon().
for part in ship:parts if part:hasmodule("ModuleRTAntenna") {
  set commLinks[part:tag] to part:getmodule("ModuleRTAntenna").
}

// get a hibernation controller?
set canHibernate to false.
if ship:partstagged("hibernationCtrl"):length {
  set hibernateCtrl to ship:partstagged("hibernationCtrl")[0]:getmodule("Timer").
  set canHibernate to true.
  if ship:partstagged(core:tag)[0]:getmodule("ModuleGenerator"):hasevent("Activate CPU") {
    ship:partstagged(core:tag)[0]:getmodule("ModuleGenerator"):doevent("Activate CPU").
  }
}

////////////
// Functions
////////////

// runs any available operations and waits for new ops
function opsRun {
  until false {
    
    // things to do if there is a connection to KSC
    if addons:rt:haskscconnection(ship) {

      // check if a new ops file is waiting to be executed
      if archive:exists(ship:name + ".ops.ks") {

        // read each line of the file and carry out the command
        set opLine to archive:open(ship:name + ".ops.ks"):readall:iterator.
        until not opLine:next  {
          set cmd to opLine:value:split(":").

          // load a command file or folder of files from KSC to the onboard disk
          if cmd[0] = "load" {

            // file?
            if not cmd[1]:endswith("/") {
              if archive:exists(cmd[1] + ".ks") {

                // if we are loading from a directory on the archive, only use the filename
                if cmd[1]:contains("/") {
                  set copyName to cmd[1]:split("/").
                  set copyName to copyName[copyName:length-1].
                } else set copyName to cmd[1].
                copypath("0:" + cmd[1] + ".ks", "/cmd/" + copyName + ".ks").
                output("Instruction onload complete for " + copyName).
              } else {
                output("Could not find file " + cmd[1]).
              }
            }

            // folder
            else {
              if archive:exists(cmd[1]:remove(cmd[1]:length-1, 1)) {
                for file in archive:open(cmd[1]:remove(cmd[1]:length-1, 1)):list:values {

                  // only copy if this is a file not a folder
                  if file:isfile copypath("0:" + cmd[1] + file:name, "/cmd/" + file:name).
                }
                output("Instruction onload complete for folder " + cmd[1]:split("/")[cmd[1]:split("/"):length-2]).
              } else {
                output("Could not find directory " + cmd[1]:remove(cmd[1]:length-1, 1)).
              }
            }
          } else

          // run a stored file that we want to remain running even after reboots
          if runSafe and cmd[0] = "run" {

            // confirm that this is an actual file. If it is not, ignore all further run commands
            // this prevents a code crash if mis-loaded file had dependencies for future files
            if not core:volume:exists("/ops/" + cmd[1] + ".ks") {

              // check if the file exists in the commands folder and copy it over if it does
              if core:volume:exists("/cmd/" + cmd[1] + ".ks") copypath("/cmd/" + cmd[1] + ".ks", "/ops/" + cmd[1] + ".ks").
              else {
                set runSafe to false.
                output("Could not find " + cmd[1] + " - further run commands ignored").
              }
            }
            if runSafe {
              set opTime to time:seconds.
              runpath("/ops/" + cmd[1] + ".ks").
              output("Instruction run complete for " + cmd[1]  + " (" + round(time:seconds - opTime,2) + "ms)").
            }
          } else 

          // run a stored file that we only want to execute this wake period
          if cmd[0] = "cmd" {
            if core:volume:exists("/cmd/" + cmd[1] + ".ks") {
              set opTime to time:seconds.
              runpath("/cmd/" + cmd[1] + ".ks").
              output("Command load complete for " + cmd[1]  + " (" + round(time:seconds - opTime,2) + "ms)").
            }
            else output("Could not find /cmd/" + cmd[1]).
          } else

          // run a file that we only want to execute once from the archive and not store to run again
          if cmd[0] = "exe" {
            if archive:exists(cmd[1] + ".ks") {
              if cmd[1]:contains("/") {
                set copyName to cmd[1]:split("/").
                set copyName to copyName[copyName:length-1].
              } else set copyName to cmd[1].
              set opTime to time:seconds.
              runpath("0:" + cmd[1] + ".ks").
              output("Instruction execution complete for " + copyName  + " (" + round(time:seconds - opTime,2) + "ms)").
            } else {
              output("Could not find " + cmd[1]).
            }
          } else

          // delete a file
          if cmd[0] = "del" {
            if core:volume:exists("/" + cmd[1] + ".ks") {
              core:volume:delete("/" + cmd[1] + ".ks").
              output("Instruction deletion complete for /" + cmd[1]).
            } else {
              output("Could not find /" + cmd[1]).
            }
          } else

          // delete all the files in a directory
          if cmd[0] = "wipe" {
            if core:volume:exists("/" + cmd[1]) {
              core:volume:delete("/" + cmd[1]).
              output("All files deleted in /" + cmd[1]).
            } else output("Could not find directory /" + cmd[1]).

            // do not let the deletion of required directories remain
            reqDirCheck().
          } else

          // print to console (not log) all files in a directory
          if cmd[0] = "list" {
            if core:volume:exists("/" + cmd[1]) print core:volume:open("/" + cmd[1]):list.
            else print "could not find directory".
          } else

          // reboot the cpu
          if cmd[0] = "reboot" {
            archive:delete(ship:name + ".ops.ks").
            reboot.
          } else

          // save all the current volatile data
          // WARNING!! Destroys delegate references. This should only be used as an option prior to reboot command
          if cmd[0] = "save" {
            writeToMemory().
          } else output("Unknown command " + cmd[0] + ":" + cmd[1]).
        }
        set runSafe to true.

        // if we have suddenly lost connection, it is because of a decoupling of vessels
        // wait until connection is re-established before allowing execution to continue
        if not addons:rt:haskscconnection(ship) wait until addons:rt:haskscconnection(ship).
        archive:delete(ship:name + ".ops.ks").
      }

      // if there is any data stored on the local drive, we need to send that to KSC
      // loop through all the data and either copy or append to what is on the archive
      if core:volume:open("/data"):size {
        for dataFile in core:volume:open("/data"):list:values {

          // do not append json files, they need to just be copied over whole
          if archive:exists(dataFile:name) and datafile:extension <> "json" {
            archive:open(dataFile:name):write(dataFile:readall).
          } else {
            copypath("/data/" + dataFile:name, "0:/" + dataFile:name).
          }
          core:volume:delete("/data/" + dataFile:name).
        }
        output("Data dump to KSC complete").
      }
    }

    // are there any sleep timers to check?
    set timerKill to list().
    if sleepTimers:length {

      // loop through all active timers
      for timer in sleepTimers:values {

        // decide if the timer has expired using time from when it was started (relative)
        // or by the current time exceeding the specified alarm time
        if 
        (timer["relative"] and time:seconds - timer["startsec"] >= timer["naptime"])
        or
        (not timer["relative"] and time:seconds >= timer["naptime"]) {

          // if the timer is up, decide how to proceed with the callback based on timer persistence
          if timer["persist"] {

            // this is a function called multiple times, so call it directly then reset the timer
            timer["callback"]().
            set timer["startsec"] to floor(time:seconds).
          } else {

            // this is a function called once, so add it to the ops queue and delete the timer        
            set operations[timer["name"]] to timer["callback"].
            timerKill:add(timer["name"]).
          }
        }
      }
    }
    for deadID in timerKill sleepTimers:remove(deadID).
    
    // run any existing ops
    if operations:length {
      for op in operations:values op().
    }

    wait 0.001.
  }
}

// serialize data we want to preserve between power sessions
function writeToMemory{

  // sanitize the lexicons to remove any delegates
  for var in varData:values if var:typename = "UserDelegate" set var to "null".
  for op in operations:values if op:typename = "UserDelegate" set op to "null".
  for timer in sleepTimers:values if timer:typename = "UserDelegate" set timer to "null".
  writejson(varData, "/mem/varData.json").
  writejson(operations, "/mem/opsData.json").
  writejson(sleepTimers, "/mem/timerData.json").
}

// create wait timers without pausing code operation
function sleep {
  parameter name.
  parameter callback.
  parameter napTime.
  parameter relative.
  parameter persist.

  set timer to lexicon(
    "persist", persist,
    "naptime", napTime,
    "relative", relative,
    "name", name,
    "callback", callback
  ).

  if persist set timer["startsec"] to floor(time:seconds).
  else set timer["startsec"] to time:seconds.
  
  set sleepTimers[name] to timer.
}

// keep a running tally of signal status
function commStatus {
  if addons:rt:haskscconnection(ship) {
    output("KSC link acquired").
    when not addons:rt:haskscconnection(ship) then commStatus().
  } else {
    output("KSC link lost").
    when addons:rt:haskscconnection(ship) then commStatus().
  }
}

// enable/disable comms
function setCommStatus {
  parameter connection.
  parameter tag is "all".

  // turning of every comm device or just a specific one?
  if tag = "all" {
    for comms in commLinks:values if comms:hasevent(connection) comms:doevent(connection).
  } else {
    if commLinks[tag]:hasevent(connection) commLinks[tag]:doevent(connection).
  }
}

// check for any active comms
function getCommStatus {
  set status to false.
  for comms in commLinks:values if comms:hasevent("Deactivate") set status to true.
  return status.
}

// see whether we are currently in range of KSC
function commCheck {
  parameter tag.
  if getter("commRanges")[tag] < (kerbin:distance-kerbin:radius) return false.
  else return true.
}

// define a variable with this value only if it doesn't already exist
function declr {
  parameter varName.
  parameter value.
  if not varData:haskey(varName) set varData[varName] to value.
}

// set or create a variable value. If no value supplied, delete the variable or just do nothing
function setter {
  parameter varName.
  parameter value is "killmeplzkthxbye".
  if value = "killmeplzkthxbye" and varData:haskey(varName) varData:remove(varName).
  else set varData[varName] to value.
}

// get the value of a variable
function getter {
  parameter varName.
  if varData:haskey(varName) return varData[varName].
  else return 0.
}

// place the command probe into a state of minimum power
function hibernate {
  parameter wakefile.
  parameter duration is 0.
  parameter comms is false.

  // only proceed if hibernation is available
  if canHibernate {

    // set comms as requested
    if not comms setCommStatus("Deactivate").

    // define the file that will run once after coming out of hibernation
    if wakefile:length setter("wakeFile", wakeFile).

    // save all the current volatile data
    writeToMemory().

    // set and activate the timer?
    if duration > 0 and duration <= 120 {
      if hibernateCtrl:hasevent("Use Seconds") hibernateCtrl:doevent("Use Seconds").
      hibernateCtrl:setfield("Seconds", duration).
      hibernateCtrl:doevent("Start Countdown").
    } else if duration > 0 {
      if hibernateCtrl:hasevent("Use Minutes") hibernateCtrl:doevent("Use Minutes").
      hibernateCtrl:setfield("Minutes", floor(duration/60)).
      hibernateCtrl:doevent("Start Countdown").
    }
    
    // switch off the cpu. Nite nite!
    output("Activating hibernation").
    ship:partstagged(core:tag)[0]:getmodule("ModuleGenerator"):doevent("Hibernate CPU").
    ship:partstagged(core:tag)[0]:getmodule("KOSProcessor"):doevent("Toggle Power").
  } else output ("Hibernation is not supported on this vessel!").
}

// these directories should always exist and never be deleted
function reqDirCheck {
  if not core:volume:exists("/data") core:volume:createdir("/data").
  if not core:volume:exists("/mem") core:volume:createdir("/mem").
  if not core:volume:exists("/ops") core:volume:createdir("/ops").
  if not core:volume:exists("/cmd") core:volume:createdir("/cmd").
  if not core:volume:exists("/includes") core:volume:createdir("/includes").
}

// loads a file from the command folder for running when the computer awakens or is reloaded
function loadOpsFile {
  parameter filename.
  if core:volume:exists("/cmd/" + filename + ".ks") {
    copypath("/cmd/" + filename + ".ks", "/ops/" + filename + ".ks").
    output(filename + " loaded for execution").
  } else output("Could not find " + filename + " to load").
}

// loads and runs a file from the command folder
function runOpsFile {
  parameter filename.
  if core:volume:exists("/cmd/" + filename + ".ks") {
    copypath("/cmd/" + filename + ".ks", "/ops/" + filename + ".ks").
    set opTime to time:seconds.
    runpath("/ops/" + filename + ".ks").
    output(filename + " loaded and executed (" + round(time:seconds - opTime,2) + "ms)").
  } else output("Could not find " + filename + " to execute").
}

// uses current signal status to determine whether data should be stashed or transmitted
// we always want to transmit data to save file space, only stash data if signal is not available
// by default, data is stashed in the vessel log
declr("jsonSizes", lexicon()).
function stashmit {
  parameter data.
  parameter filename is ship:name + ".log.np2".
  parameter filetype is "line".

  // transmit the information to KSC if we have a signal
  if addons:rt:haskscconnection(ship) {

    // append the data to the file on the archive
    if not archive:exists(filename) archive:create(filename).
    if filetype = "line" archive:open(filename):writeln(data).
    if filetype = "file" archive:open(filename):write(data).

    // compare the size of the old file to the size of the new one and store it
    if filetype = "json" {
      set filesize to archive:open(filename):size.
      writejson(data, "0:/" + filename).
      if not getter("jsonSizes"):haskey(filename) getter("jsonSizes"):add(filename, list()).
      getter("jsonSizes")[filename]:add(archive:open(filename):size - filesize).
    }

  // stash the information if we have enough space
  } else {

    // strings and filecontents can be translated directly into byte sizes, but json lists need more work
    if filetype = "json" {

      // if the json file has not yet been written, we won't know the size
      // set size to 15bytes per value to avoid disk write overrun
      if not getter("jsonSizes"):haskey(filename) {
        getter("jsonSizes"):add(filename, list()).
        set dataSize to 15 * data:length.
      } else {

        // get the average size of this json object
        set dataSize to 0.
        for filesize in getter("jsonSizes")[filename] set dataSize to dataSize + filesize.
        set dataSize to dataSize / getter("jsonSizes")[filename]:length.
      }
    } else {
      set dataSize to data:length.
    }

    if core:volume:freespace > dataSize {

      // append the data to the file locally, it will be sent to KSC next time connection is established
      if not core:volume:exists("/data/" + filename) core:volume:create("/data/" + filename).
      if filetype = "line" core:volume:open("/data/" + filename):writeln(data).
      if filetype = "file" core:volume:open("/data/" + filename):write(data).

      // compare the size of the old file to the size of the new one and store it
      if filetype = "json" {
        set filesize to core:volume:open("/data/" + filename):size.
        writejson(data, "1:/data/" + filename).
        getter("jsonSizes")[filename]:add(core:volume:open("/data/" + filename):size - filesize).
      }
    }
  }
}

////////////////////////
// Begin system boot ops
////////////////////////

// check for a new bootscript
if addons:rt:haskscconnection(ship) {
  if archive:exists(ship:name + ".boot.ks") {
    print "new system boot file received".
    movepath("0:" + ship:name + ".boot.ks", "/boot/boot.ks").
    wait 1.
    reboot.
  }
}

// if we are connected to KSC, reload the dependencies in case any were updated
if addons:rt:haskscconnection(ship) {
  if core:volume:exists("/includes") core:volume:delete("/includes").
  copypath("0:/includes", core:volume:root).
}

// run what dependencies we have stored
for includesFile in core:volume:open("/includes"):list:values runpath("/includes/" + includesFile).

// ensure required directories exist
reqDirCheck().

// load any persistent data and operations
if core:volume:exists("/mem/varData.json") set varData to readjson("/mem/varData.json").
if core:volume:exists("/mem/opsData.json") set operations to readjson("/mem/opsData.json").
if core:volume:exists("/mem/timerData.json") set sleepTimers to readjson("/mem/timerData.json").
if core:volume:open("/ops"):size {
  output("Loading onboard operations").
  for opsFile in core:volume:open("/ops"):list:values runpath("/ops/" + opsFile).
  output("Onboard operations executed").
}

// initial persistent variable definitions
declr("startupUT", time:seconds).
declr("lastDay", -1).
declr("commRanges", lexicon()).

// find and store all comm ranges if we haven't already
if not getter("commRanges"):length {
  for comm in commLinks:keys {

    // turn the antenna on if needed so we can get its range
    set deactivate to false.
    if commLinks[comm]:hasevent("Activate") {
      commLinks[comm]:doevent("Activate").
      set deactivate to true.
      wait until commLinks[comm]:hasevent("Deactivate").
    }

    // store the antenna range in meters
    if commLinks[comm]:hasfield("Dish range") set rangeInfo to commLinks[comm]:getfield("Dish range").
    if commLinks[comm]:hasfield("Omni range") set rangeInfo to commLinks[comm]:getfield("Omni range").
    if rangeInfo:contains("Km") set rangeScale to 1000.
    if rangeInfo:contains("Mm") set rangeScale to 1000000.
    if rangeInfo:contains("Gm") set rangeScale to 1000000000.
    set range to (rangeInfo:substring(0, (rangeInfo:length-2)):tonumber())*rangeScale.

    // turn the comm back off if needed
    if deactivate commLinks[comm]:doevent("Deactivate").

    // list the comm unit
    getter("commRanges"):add(comm, range).
  } 
}

// date stamp the log if this is a different day then update the day
if getter("lastDay") <> time:day stashmit("[" + time:calendar + "]").
setter("lastDay", time:day).

// are any comms active?
if getCommStatus() {
  if addons:rt:haskscconnection(ship) {
    output("KSC link acquired").
    when not addons:rt:haskscconnection(ship) then commStatus().
  }
} else when addons:rt:haskscconnection(ship) then commStatus().

output("System boot complete").

////////////////
// Begin ops run
////////////////

// if we came out of hibernation, call the file and delete the variable
if getter("wakeFile") {
  runpath("/cmd/" + getter("wakeFile") + ".ks").
  setter("wakeFile").
}
opsRun().