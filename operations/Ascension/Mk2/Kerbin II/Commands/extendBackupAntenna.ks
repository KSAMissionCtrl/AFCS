if probeCommBackup:hasevent("extend antenna") {
  output("Backup antenna extension commanded").
  probeCommBackup:doevent("extend antenna").
  set operations["antennaMonitor"] to antennaMonitor@.
  function antennaMonitor {
    if probeCommBackup:hasevent("retract antenna") {
      output("Backup antenna extension confirmed").
      operations:remove("antennaMonitor").
    }
  }
}
else output("Command failed - no extension available").