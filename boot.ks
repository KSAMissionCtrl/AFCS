TODO: adapt to new kOS v1.0.0. directory structure (copy depricated)
TODO: handle signal gain/loss since RemoteTech is no longer used

clearscreen.
set deleteOnFinish to false.
set backupOps to false.
log "" to ship:name + ".log.np2".

// checks if the requested file exists on the KSC disk
// checks if there is enough room to copy a file from the archive to the vessel
// will remove the log file if the space it frees will allow the transfer
// also accounts for wether the transfer file has a local copy that will be replaced
function download {
  parameter archiveFile, localFile.
  if not addons:rt:haskscconnection(ship) return false.
  if not archive:exists(archiveFile) return false.
  if core:volume:exists(localFile) set localFileSize to core:volume:open(localFile):size.
  else set localFileSize to 0.
  set archiveFileSize to archive:open(archiveFile):size.
  if core:volume:freespace - archiveFileSize + localFileSize < 0 {
    if core:volume:freespace - archiveFileSize + localFileSize + core:volume:open(ship:name + ".log.np2"):size > 0 {
      copy ship:name + ".log.backup.np2" to 0.
      core:volume:delete(ship:name + ".log.np2").
      print "deleting log to free up space".
    } else {
      print "unable to copy file " + archiveFile + ". Not enough disk space".
      return false.
    }
  }
  copy archiveFile from 0.
  archive:delete(archiveFile).
  if localFileSize core:volume:delete(localFile).
  rename archiveFile to localFile.
  return true.
}

// check if we have new instructions stored in event of comm loss
if core:volume:exists("backup.op.ks") and not addons:rt:haskscconnection(ship) {
  core:volume:delete("operations.ks").
  rename "backup.op.ks" to "operations.ks".
  print "KSC connection lost. Stored operations file loaded".
} else {

  // check for connection to KSC for archive volume access if no instructions stored
  if not addons:rt:haskscconnection(ship) {
    print "waiting for KSC link...".
    wait until addons:rt:haskscconnection(ship).
  }

  print "KSC link established, fetching operations...".
  wait addons:rt:kscdelay(ship).

  // check for a new bootscript
  // destroy the log if needed to make room, but only if it'll make room
  if download(ship:name + ".boot.ks", "boot.ks") {
    print "new boot file received".
    wait 2.
    reboot.
  }

  // check for new operations
  // destroy the log if needed to make room, but only if it'll make room
  if download(ship:name + ".op.ks", "operations.ks") print "new operations file received".
}


/////////////////////
// do any boot stuff
/////////////////////
set ship:control:pilotmainthrottle to 0.

// date stamp the log
// won't output to archive copy until first ouput() call
set logList to list().
set logStr to "[" + time:calendar + "] boot up".
log logStr to ship:name + ".log.np2".
logList:add(logStr).

// for logging data, with various considerations
function output {
  parameter text.
  parameter toConsole is false.

  // print to console if requested
  if toConsole print text.

  // log the new data to the file if it will fit
  // otherwise delete the log to start anew
  set logStr to "[" + time:hour + ":" + time:minute + ":" + floor(time:second) + "] " + text.
  if core:volume:freespace > logStr:length {
    log logStr to ship:name + ".log.np2".
  } else {
    core:volume:delete(ship:name + ".log.np2").
    log "[" + time:calendar + "] new file" to ship:name + ".log.np2".
    log logStr to ship:name + ".log.np2".
  }

  // store a copy on KSC hard drives if we are in contact
  // otherwise save and copy over as soon as we are back in contact
  if addons:rt:haskscconnection(ship) {
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

// store new instructions while a current operations program is running
// if we lose connection before a new script is uploaded, this will run
// running ops should check backupOps flag and call download(ship:name + ".bop.ks.", "backup.op.ks").
when addons:rt:haskscconnection(ship) and archive:exists(ship:name + ".bop.ks.") then {
  set backupOps to true.
  if addons:rt:haskscconnection(ship) preserve.
}

// run operations?
if not core:volume:exists("operations.ks") and addons:rt:haskscconnection(ship) {
  print "waiting to receive operations...".
  until download(ship:name + ".op.ks.", "operations.ks") {
    if not addons:rt:haskscconnection(ship) {
      if not core:volume:exists("backup.op.ks") {
        print "KSC connection lost, awaiting connection...".
        wait until addons:rt:haskscconnection(ship).
        reboot.
      } else {
        if core:volume:exists("operations.ks") core:volume:delete("operations.ks").
        rename "backup.op.ks" to "operations.ks".
        print "KSC connection lost. Stored operations file loaded".
        break.
      }
    }
    wait 1.
  }
}
output("executing operations", true).
wait 2.
run operations.
if deleteOnFinish delete operations.
output("operations execution complete", true).
wait 2.
reboot.