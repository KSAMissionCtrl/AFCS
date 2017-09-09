//////////////////
// Initilaization
//////////////////

clearscreen.
set opCode to 0.
set backupOps to false.
set hasSignal to false.

// date stamp the log
// won't output to archive copy until first output() call
set logList to list().
set logStr to "[" + time:calendar + "] system boot up".
log logStr to ship:name + ".log.np2".
logList:add(logStr).

////////////
// Functions
////////////

// for logging data, with various considerations
function output {
  parameter text.
  parameter toConsole is true.

  // print to console if requested
  if toConsole print text.

  // log the new data to the file if it will fit
  // otherwise delete the log to start anew
  set logStr to "[" + time:hour + ":" + time:minute + ":" + (time:second + round(time:seconds - floor(time:seconds), 2)) + "] " + text.
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

// checks if the requested file exists on the KSC disk
// checks if there is enough room to copy a file from the archive to the vessel
// will remove the log file if the space it frees will allow the transfer
// also accounts for wether the transfer file has a local copy that will be replaced
function download {
  parameter archiveFile, localFile.
  if not hasSignal return false.
  if not archive:exists(archiveFile) return false.
  if core:volume:exists(localFile) set localFileSize to core:volume:open(localFile):size.
  else set localFileSize to 0.
  set archiveFileSize to archive:open(archiveFile):size.
  if core:volume:freespace - archiveFileSize + localFileSize < 0 {
    if core:volume:freespace - archiveFileSize + localFileSize + core:volume:open(ship:name + ".log.np2"):size > 0 {
      copypath(ship:name + ".log.backup.np2", "0:").
      core:volume:delete(ship:name + ".log.np2").
      output("deleting log to free up space").
    } else {
      output("unable to copy file " + archiveFile + ". Not enough disk space").
      return false.
    }
  }
  movepath("0:" + archiveFile, localFile).
  archive:delete(archiveFile).
  if localFileSize core:volume:delete(localFile).
  return true.
}

// runs any available operations or waits for new ops
// once a run is complete, new ops are waited on
function opsRun {
  if not core:volume:exists("operations" + opCode + ".ks") and hasSignal {
    output("waiting to receive operations...").
    until download(ship:name + ".op.ks.", "operations" + opCode + ".ks") {
      if not hasSignal {
        if not core:volume:exists("backup.op.ks") {
          output("KSC connection lost, awaiting connection...").
          wait until hasSignal.
          output("KSC connection regained").
          opsRun().
        } else {
          if core:volume:exists("operations" + opCode + ".ks") core:volume:delete("operations" + opCode + ".ks").
          set opCode to opCode + 1.
          rename "backup.op.ks" to "operations" + opCode + ".ks".
          output("KSC connection lost. Stored operations file loaded").
          opsRun().
        }
      }
      wait 1.
    }
  }
  output("executing operations").
  runpath("operations" + opCode + ".ks").
  core:volume:delete("operations.ks").
  set opCode to opCode + 1.
  output("operations execution complete").
  opsRun().
}

///////////
// Triggers
///////////

// store new instructions while a current operations program is running
// if we lose connection before a new script is uploaded, this will run
// running ops should check backupOps flag and call download(ship:name + ".bop.ks.", "backup.op.ks").
when hasSignal and archive:exists(ship:name + ".bop.ks.") then {
  set backupOps to true.
  if hasSignal preserve.
}

// simulate comm loss manually by toggling action group
on AG11 {
  if hasSignal { set hasSignal to false. } 
  else { set hasSignal to true. }
  preserve.
}

////////////////////////
// Begin system boot ops
////////////////////////

// check if we have new instructions stored in event of comm loss
if core:volume:exists("backup.op.ks") and not hasSignal {
  core:volume:delete("operations.ks").
  rename "backup.op.ks" to "operations.ks".
  output("KSC connection lost. Stored operations file loaded").
} else {

  // check for connection to KSC for archive volume access if no instructions stored
  if not hasSignal {
    output("waiting for KSC link...").
    wait until hasSignal.
  }

  output("KSC link established, fetching operations...").

  // check for a new bootscript
  // destroy the log if needed to make room, but only if it'll make room
  if download(ship:name + ".boot.ks", "boot.ks") {
    output("new system boot file received").
    wait 1.
    reboot.
  }

  // check for new operations
  // destroy the log if needed to make room, but only if it'll make room
  if download(ship:name + ".op.ks", "operations" + opCode + ".ks") output("new operations file received").
}

////////////////
// Begin ops run
////////////////

output("System boot complete").
opsRun().