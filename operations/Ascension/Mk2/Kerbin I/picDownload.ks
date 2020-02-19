set picStartUT to 0.
set picEndUT to 0.
set cameraCount to 2.

// 1 photo per minute from each camera @ 5s per photo to xmit
set xmitTime to ((floor((picEndUT - picStartUT)/60))*cameraCount)*5.

function xmitComplete {
  output("Photo download completed").
  ship:partstagged("cam")[0]:getmodule("moduleGenerator"):doevent("End Transmission").
  operations:remove("xmitComplete").
}

output("Downloading photos").
ship:partstagged("cam")[0]:getmodule("moduleGenerator"):doevent("Download Photos").
sleep("xmitComplete", xmitComplete@, xmitTime, true, false).