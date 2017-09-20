// ensures that you can't divide by 0
function getAvailableThrust {
  if ship:availablethrust > 0 return ship:availablethrust.
  if ship:availablethrust = 0 return 0.000000000000000001.
}