// begin monitoring for re-entry
function saveReturn {
  if ship:altitude <= 100000 {
    if kuniverse:canquicksave {
      kuniverse:quicksaveto(ship:name + " - Reentry").
      operations:remove("saveReturn").
    }
  }
}
function reentry {
  if ship:altitude <= 70000 {
    output("Atmospheric interface breached").
    operations:remove("reentry").
    set operations["maxQmonitor"] to maxQmonitor@.
    set operations["maxQcheck"] to maxQcheck@.
    set maxQ to 0.
  }
}

output("Return ops loaded").