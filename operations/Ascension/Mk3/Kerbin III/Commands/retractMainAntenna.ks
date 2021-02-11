if probeCommMain:hasevent("retract antenna") {
  output("Main antenna retraction commanded").
  probeCommMain:doevent("retract antenna").
  set operations["antennaMonitor"] to antennaMonitor@.
  function antennaMonitor {
    if probeCommMain:hasevent("extend antenna") {
      output("Main antenna retraction confirmed").
      operations:remove("antennaMonitor").
    }
  }
}
else output("Command failed - no retraction available").