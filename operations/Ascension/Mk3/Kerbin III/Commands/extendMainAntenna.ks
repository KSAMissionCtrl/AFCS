if probeCommMain:hasevent("extend antenna") {
  output("Main antenna extension commanded").
  probeCommMain:doevent("extend antenna").
  set operations["antennaMonitor"] to antennaMonitor@.
  function antennaMonitor {
    if probeCommMain:hasevent("retract antenna") {
      output("Main antenna extension confirmed").
      operations:remove("antennaMonitor").
    }
  }
}
else output("Command failed - no extension available").