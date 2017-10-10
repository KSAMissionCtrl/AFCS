# AFCS
Automated Flight Control System for vessels in Kerbal Space Program using kOS

## Systems
**Logger** - monitors and stores various flight parameters, outputs generic status updates   
**Boot** - sets up the environment and runs operations uploaded to the probe core

## Known Issues

- When saving changes to the operations file, a file-sharing access error can crash the boot script. It tends to happen more often with small instruction sizes of only a few lines, and can be avoided more often than not if additional empty lines are added

## Change Log

**Boot upgrade** (10/10/17)

AFCS:
  - [boot.ks] Can now run multiple continuous operations through the use of function delegates assigned to the `operations` lexicon by any loaded instructions
  - [boot.ks] An operations file is created in the root archive that controllers can paste code into and save, which will then be read by the spacecraft and the file cleared to await additional instructions
  - [boot.ks] The `deleteOnFinish` flag has been brought back to tell the spacecraft not to save an operations file after it has been uploaded
  - [boot.ks] AFCS dependencies are now loaded by the boot script rather than an operations script, and generically loads any files found in the /includes directory on the archive
  - [boot.ks] Removed the `download` function as there is no longer a need to load operations files of non-specific names, only look for a new boot file or changes to the operations file
  - [boot.ks] If a new bootscript is found it is now loaded into the proper location in the /boot directory of the spacecraft volume
  - [logger.ks] The `output` function has been moved into here

**Progeny Mk5 Flight 5** (9/22/17)

Operations:
  - [ascent.ks] Fixed the code monitoring for decrease in dynamic pressure so it does not run until a second after ignition to allow dynamic pressure to begin to increase first

**Progeny Mk5 Flight 4** (9/20/17)

AFCS:
  - [helpFunc.ks] New script containing general functions that can be useful in a variety of situations
  - [helpFunc.ks] `getAvailableThrust` ensures that a value of 0 is never returned so that division operations always work okay
  - [logger.ks] New data fields for Electric Charge levels in both units and percentage, still allows operations code to use `EClvl` to monitor
  - [logger.ks] Fixed missing comma seperator between MET and Heading fields
  
Operations:
  - [ascent.ks] Fixed `maxQ` to update each loop so script knows when it occurs and logs it properly
  - [ascent.ks] New automation to control throttle to a set TWR
  - [ascent.ks] New automation to throttle up to full once dynamic pressure begins to drop
  - [ascent.ks] Removed errant command to decouple second stage booster immediately after flame-out
  - [initialize.ks] Added `helperFunc.ks` to includes
  - [initialize.ks] New variable `desiredTWR` to control third stage burn

**Progeny Mk5 Flight 3** (9/18/17)

AFCS:
  - [boot.ks] Operations log output now uses uniform timestamps with leading zeros for single-digit numbers and 00.00 for whole minutes
  - [logger.ks] Distance traveled measurement removed until a better solution can be worked up
  - [logger.ks] Mission Elapsed Time added to log output (passed along via operational script as logger would not otherwise know the time of launch)
  - [logger.ks] Calculate Throttle percentage added to log output to determine whether equation to calculate the throttle needed for a set TWR is good
  - [logger.ks] Dynamic Pressure is now logged in kilopascals (kPa) rather than units of standard atmospheric pressure
  - [logger.ks] CSV header is now outputted to archive copy rather than local copy of the log file
  
Operations:
  - [ascent.ks] Additional triggers set for new operations log outputs for MaxQ, Apokee reaching 70km, rocket reaching 70km, rocket falling back through 70km
  - [ascent.ks] run state to monitor reaching apokee is now a trigger
  - [ascent.ks] Solid boosters are now staged 1 second after flame-out instead of immediately to prevent them from bumping into the upper stages
  - [ascent.ks] Engines are ignited after 1.5° of pitch change or if vertical speed drops below 100m/s
  - [ascent.ks] Pitch value output to the operations log is constrained to 3 decimal places
  - [ascent.ks] Chute deployment is triggered via altitude rather than built-in pressure sensor (now used as backup)
  - [initialize.ks] Test flags for vertical speed monitoring removed
  - [science.ks] New routine for handling of payload instruments. Nothing complex yet
  
**Progeny Mk5 Flight 2** (9/13/17)

AFCS:
  - [logger.ks] Replaced the inaccurate distance traveled measuring code with a new method to try out
  - [logger.ks] Log straight to the archive at KSC if comm connection is established, otherwise write to disk
  - [logger.ks] Stop logging if we fill up almost all the disk space so the running code does not terminate
  - [logger.ks] Specify thrust measured in kilonewtons (kN) in log output header
  - [logger.ks] Change throttle readout variable to get proper value & display it as a percentage
  
Operations:
  - [ascent.ks] Wrapped abort setting into a function for more flexibility in enabling/disabling the abort state and setting the reasons for the abort
  - [ascent.ks] Ascent monitoring loop interrupt now more generically named to `landed` from `splashdown`
  - [ascent.ks] Boosters are automatically decoupled immediately after flame-out is detected
  - [ascent.ks] Pitch monitoring readouts in the log will test to see how accurate the code is at reporting pitch change from separation and will signal booster ignition point but not automatically stage boosters
  - [ascent.ks] Flags added to detect if vertical speed has fallen below 100m/s, the backup stage ignition point (no automatic action taken just monitoring)
  - [ascent.ks] 3rd stage fins are automatically shredded at 60km
  - [ascent.ks] Landing state monitored from environment sensor to detect & note in log landing on land or in water
  - [ascent.ks] `wait 0.01.` was a critical peice of missing code in the ascent runtime loop
  - [initialize.ks] Holds the function that sets the abort state

**Progeny Mk5 Flight 1** (9/7/17)

AFCS:
  - [boot.ks] Updated to work with new kOS directory file system features
  - [boot.ks] Signal loss handling configured for KSC comm prototcols
  - [boot.ks] `output` routine now prints to the log file and console by default
  - [boot.ks] `opsRun` routine allows for running multiple instruction sets without needing to reboot
  - [boot.ks] Without rebooting, each new instruction set now requires an `opCode` added to them so the same instruction set isn't constantly run under the same internal name
  - [boot.ks] Instructions are always deleted after they are executed, although they remain in memory
  - [boot.ks] `output` now logs time with milliseconds included up to 2 decimal places
  - [logger.ks] Cleaned up & wrapped into a function that can be called by the operations code
  - [path.ks] Can now output the names of the phases to the screen as well

Operations:
  - [ascent.ks] Monitors the rocket during the terminal count, launch & ascent
  - [initialize.ks] Sets up the environment for the operations code to execute
