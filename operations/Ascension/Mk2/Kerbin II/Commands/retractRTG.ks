if rtg:hasevent("retract") {
  output("RTG retraction commanded").
  rtg:doevent("retract").
  set operations["rtgMonitor"] to rtgMonitor@.
  function rtgMonitor {
    if rtg:hasevent("deploy") {
      output("RTG retraction confirmed").
      operations:remove("rtgMonitor").
    }
  }
}
else output("Command failed - no retraction available").