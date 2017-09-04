// render a path that was logged during an ascent
clearscreen.
set pathData to readjson("path.json").
set colorList to list(green, red, cyan, purple, yellow, blue).
set colorListIndex to -1.
set lastPhase to "".
clearvecdraws().
from { local index is 0. } until index = pathData["geo"]:length-1 step { set index to index + 1. } do {
  if pathData["phase"][index] <> lastPhase {
    set lastPhase to pathData["phase"][index].
    set colorListIndex to colorListIndex + 1.
    if colorListIndex = colorList:length set colorListIndex to 0.
  }
  vecdraw(latlng(pathData["geo"][index]:lat, pathData["geo"][index]:lng):altitudeposition(pathData["alt"][index]), 
              pathData["vec"][index] + (latlng(pathData["geo"][index+1]:lat, pathData["geo"][index+1]:lng):altitudeposition(pathData["alt"][index+1]) - latlng(pathData["geo"][index]:lat, pathData["geo"][index]:lng):altitudeposition(pathData["alt"][index])),
              colorList[colorListIndex],
              "",
              1.0, 
              true, 
              100).
}.