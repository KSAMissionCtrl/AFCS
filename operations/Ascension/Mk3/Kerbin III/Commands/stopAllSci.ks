output("Stopping all science runs").
radSci:doaction("stop: radiation scan", true).
windSci:doaction("stop: solar wind measurement", true).
rpwsSci:doaction("stop: radio plasma wave scan", true).
magSci:doaction("stop: magnetometer report", true).
gooSci:doaction("stop: mystery goo mini observation", true).
ionSci:doaction("stop: charged particle data", true).