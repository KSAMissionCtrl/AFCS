//////////////////
// Initilaization
//////////////////

clearscreen.
set opCode to 0.
set hasSignal to false.
set deleteOnFinish to false.
set operations to lexicon().

////////////
// Functions
////////////

// runs any available operations and waits for new ops
function opsRun {
  until false {
    
    // check if a new ops file is waiting to be executed
    if hasSignal and not archive:open(ship:name + ".ops.ks"):readall:empty {
      output("operations received, executing").
      copypath("0:" + ship:name + ".ops.ks", "/ops/operations" + opCode + ".ks").
      runpath("/ops/operations" + opCode + ".ks").
      if deleteOnFinish {
        core:volume:delete("/ops/operations" + opCode + ".ks").
        set deleteOnFinish to false.
      }
      set opCode to opCode + 1.
      output("operations execution complete").
      output("waiting to receive operations...").
      archive:open(ship:name + ".ops.ks"):clear.
    }
    
    // run any existing ops
    if operations:length {
      for op in operations:values op().
    }
    
    wait 0.001.
  }
}

///////////
// Triggers
///////////

// simulate comm loss manually by toggling action group
on ag1 {
  if hasSignal { 
    set hasSignal to false. 
    output("KSC link lost"). 
  } else { 
    set hasSignal to true. 
    output("KSC link acquired"). 
    if not archive:exists(ship:name + ".ops.ks") create("0:" + ship:name + ".ops.ks").
  }
  preserve.
}

////////////////////////
// Begin system boot ops
////////////////////////

// load dependencies - if they are not found we are on the launchpad initializing, so activate comms and load from the archive
if not core:volume:exists("/includes") {
  copypath("0:/includes", core:volume:root).
  set hasSignal to true. 
  if not archive:exists(ship:name + ".ops.ks") create("0:" + ship:name + ".ops.ks").
}
for includeFile in core:volume:open("/includes"):list:values runpath("/includes/" + includeFile).

// date stamp the log
// won't output to archive copy until first output() call
set logStr to "[" + time:calendar + "] system boot up".
log logStr to ship:name + ".log.np2".
logList:add(logStr).

// check for a new bootscript
if hasSignal and archive:exists(ship:name + ".boot.ks") {
  output("new system boot file received").
  movepath("0:" + ship:name + ".boot.ks", "boot/boot.ks").
  wait 1.
  reboot.
}

if hasSignal output("KSC link acquired, awaiting new operations").
if not hasSignal output("KSC link not acquired, onboard operations only").

// TODO - reload any operations still stored on disk

////////////////
// Begin ops run
////////////////

output("System boot complete").
opsRun().