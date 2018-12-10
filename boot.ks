//////////////////
// Initilaization
//////////////////

clearscreen.
set operations to lexicon().
set runSafe to true.

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
          if cmd[0] = "load" or (runSafe and cmd[0] = "run") {

            // if there is a / character at the beginning, then the file needs to be moved from the archive
            if cmd[1][0] = "/" {

              // confirm that this is an actual file. If it is not, ignore all further run commands
              // this prevents a code crash if mis-loaded file had dependencies for future files
              if not archive:exists(cmd[1] + ".ks") {
                set runSafe to false.
                output("Could not find " + cmd[1] + " - further run commands ignored").
              } else if runSafe or cmd[0] = "load" {

                // if we are loading from a directory on the archive, only use the filename
                if cmd[1]:contains("/") {
                  set copyName to cmd[1]:split("/").
                  set copyName to copyName[copyName:length-1].
                } else set copyName to cmd[1].
                set opTime to time:seconds.
                copypath("0:" + cmd[1] + ".ks", "/ops/" + copyName + ".ks").
                output("Instruction onload complete for " + copyName  + " (" + round(time:seconds - opTime,2) + "ms)").

                // if we called run instead of just load, also run the script
                if cmd[0] = "run" runpath("/ops/" + copyName + ".ks").
              }

            // if there is no / character at the beginning the file is already on the spacecraft
            } else if cmd[1][0] <> "/" {
              if core:volume:exists("/ops/" + cmd[1] + ".ks") runpath("/ops/" + cmd[1] + ".ks").
              else output("Unable to find operations file " + cmd[1] + ".ks").
            }
          } else
          if cmd[0] = "del" {
            if core:volume:exists("/" + cmd[1] + ".ks") {
              core:volume:delete("/" + cmd[1] + ".ks").
              output("Instruction deletion complete for /" + cmd[1]).
            } else {
              output("Could not find /" + cmd[1]).
            }
          } else
          if cmd[0] = "wipe" {
            if core:volume:exists("/" + cmd[1]) {
              core:volume:delete("/" + cmd[1]).
              output("All files deleted in /" + cmd[1]).
            } else output("Could not find directory /" + cmd[1]).

            // do not let the deletion of required directories remain
            if not core:volume:exists("/data") core:volume:createdir("/data").
            if not core:volume:exists("/ops") core:volume:createdir("/ops").
            if not core:volume:exists("/includes") core:volume:createdir("/includes").
          } else
          if cmd[0] = "list" {
            if core:volume:exists("/" + cmd[1]) print core:volume:open("/" + cmd[1]):list.
            else print "could not find directory".
          } else
          if cmd[0] = "reboot" {
            archive:delete(ship:name + ".ops.ks").
            reboot.
          } else output("unknown command " + cmd[0] + ":" + cmd[1]).
        }
        set runSafe to true.
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
        output("data dump to KSC complete").
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

////////////////////////
// Begin system boot ops
////////////////////////

// check for a new bootscript
if addons:rt:haskscconnection(ship) {
  if archive:exists(ship:name + ".boot.ks") {
    print "new system boot file received".
    movepath("0:" + ship:name + ".boot.ks", "boot/boot.ks").
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
for includeFile in core:volume:open("/includes"):list:values runpath("/includes/" + includeFile).

// date stamp the log if this is our first time booting up
if not core:volume:exists("/data") {
  core:volume:createdir("/data").
  core:volume:createdir("/ops").
  stashmit("[" + time:calendar + "] system boot up").
}

// get initial signal status then monitor it
if addons:rt:haskscconnection(ship) {
  output("KSC link acquired").
  when not addons:rt:haskscconnection(ship) then commStatus().
} else {
  output("KSC link not acquired").
  when addons:rt:haskscconnection(ship) then commStatus().
}

// if there are any operations stored on the local drive, run them
if core:volume:open("/ops"):size {
  output("loading onboard operations").
  for opsFile in core:volume:open("/ops"):list:values runpath("/ops/" + opsFile).
  output("onboard operations executed").
}

////////////////
// Begin ops run
////////////////

output("System boot complete").
opsRun().