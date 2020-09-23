if probeCommBackup:hasevent("retract antenna") {
  output("Backup antenna retraction commanded").
  probeCommBackup:doevent("retract antenna").
  set operations["antennaMonitor"] to antennaMonitor@.
  function antennaMonitor {
    if probeCommBackup:hasevent("extend antenna") {
      output("Backup antenna retraction confirmed").
      operations:remove("antennaMonitor").
    }
  }
}
else output("Command failed - no retraction available").