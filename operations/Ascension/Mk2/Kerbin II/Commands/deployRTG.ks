if rtg:hasevent("deploy") {
  output("RTG deployment commanded").
  rtg:doevent("deploy").
  set operations["rtgMonitor"] to rtgMonitor@.
  function rtgMonitor {
    if rtg:hasevent("retract") {
      output("RTG deployment confirmed").
      operations:remove("rtgMonitor").
    }
  }
}
else output("Command failed - no deployment available").