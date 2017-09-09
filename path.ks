// render a path that was logged during an ascent - see logger.ks
clearscreen.
set pathData to readjson("path.json").
set brown to rgb(127,51,0).
set pink to rgb(255,0,110).
set colorList to list(yellow, red, cyan, green, purple, blue, white, brown, pink).
set colorListIndex to -1.
set lastPhase to "".
clearvecdraws().
from { local index is 0. } until index = pathData["geo"]:length-1 step { set index to index + 1. } do {
  if pathData["phase"][index] <> lastPhase {
    set lastPhase to pathData["phase"][index].
    set colorListIndex to colorListIndex + 1.
    if colorListIndex = colorList:length set colorListIndex to 0.
    vecdraw(latlng(pathData["geo"][index]:lat, pathData["geo"][index]:lng):altitudeposition(pathData["alt"][index]), 
            pathData["vec"][index] + (latlng(pathData["geo"][index+1]:lat, pathData["geo"][index+1]:lng):altitudeposition(pathData["alt"][index+1]) - latlng(pathData["geo"][index]:lat, pathData["geo"][index]:lng):altitudeposition(pathData["alt"][index])),
            colorList[colorListIndex],
            pathData["phase"][index],
            0.1, 
            true, 
            2).
  }
  vecdraw(latlng(pathData["geo"][index]:lat, pathData["geo"][index]:lng):altitudeposition(pathData["alt"][index]), 
          pathData["vec"][index] + (latlng(pathData["geo"][index+1]:lat, pathData["geo"][index+1]:lng):altitudeposition(pathData["alt"][index+1]) - latlng(pathData["geo"][index]:lat, pathData["geo"][index]:lng):altitudeposition(pathData["alt"][index])),
          colorList[colorListIndex],
          "",
          1.0, 
          true, 
          50).
}