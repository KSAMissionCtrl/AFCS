# AFCS
Automated Flight Control System for vessels in Kerbal Space Program using kOS

## Systems
**Logger** - monitors and stores various flight parameters, outputs generic status updates   
**Boot** - sets up the environment and runs operations uploaded to the probe core   
**HelpFunc** - includes useful general support functions for various operational aspects

## Change Log

**Progeny Mk6 Block II Flight 1** (6/20/18)

Operations:
  - [ascent.ks] Operations sequence changed to match what was done for Ascension launch
  - [ascent.ks] Extra stage added to handle release of radial boosters
  - [ascent.ks] Cutoff added to ensure rocket doesn't fly beyond 900km apokee
  - [ascent.ks] Ensures chute will not open if rocket is traveling too fast - unless its so low an attempt might as well be made
  - [initialize.ks] Added support for the new radial boosters

**Ascension Mk1 Block I Flight 1** (6/8/18)

AFCS:
  - [boot.ks] Reduced log output for instruction loads to a single line that shows the time taken to execute
  - [helpFunc.ks] `surfaceGravity` is now a global variable that can be used anywhere
  - [helpFunc.ks] `setAbort()` is now a global function that can be used anywhere
  - [helpFunc.ks] `setAbort()` now also outputs the reason for the abort so a separate command for this is no longer needed
  
Operations: 
  - All new code to initialize then handle ascent, orbit and recovery for the Ascension Mk1 Block I rocket
  
**Progeny Mk6 Block I Flight 5** (5/28/18)

AFCS:
  - New folder structure for operations files
  
Operations: 
  - [initialize.ks] New launch time set

**Progeny Mk6 Block I Flight 4** (5/8/18)

Operations:
  - [initialize.ks] New launch time set
  - [ascent.ks] Removed code that detached fairing peices after re-entry
  
**Progeny Mk6 Block I Flight 3** (5/2/18)

Operations:
  - [initialize.ks] New launch time set
  - [science.ks] Second payload instrument operations re-enabled
  
**Progeny Mk6 Block I Flight 2** (4/26/18)

Operations:
  - [ascent.ks] Added triggers in the descent phase to gradually deploy air brakes
  - [initialize.ks] New launch time set
  - [initialize.ks] Radiation data log now outputs in number format when rads/h are above 0.001
  - [initialize.ks] Parts are found for air brake usage
  - [science.ks] Second payload instrument operations commented out, only one instrument aboard

**Progeny Mk6 Block I Flight 1** (2/15/18)

AFCS:
  - [logger.ks] Any previous log data is no longer destroyed when the logger is initialized
  
Operations:
  - [ascent.ks] Reordered and renested some triggers for events now that space is guaranteed without a breakup
  - [ascent.ks] New trigger for fairing deploy in the lower atmosphere
  - [ascent.ks] Stage 3 dynamic pressure check and throttle up removed
  - [initialize.ks] New launch time set
  - [initialize.ks] Initial Stage 3 throttle changed to full thrust
  - [initialize.ks] Fairing parts found for later detachment command

**Progeny Mk5 Block I Flight 4** (1/17/18)

AFCS:
  - [logger.ks] Expanded Lat and Lon abbreviations into their full words for the log header
  - [logger.ks] Fixed logging custom data so the data is actually logged
  
Operations:
  - [ascent.ks] Now logs a final telemetry data set after splashdown occurs
  - [ascent.ks] Stage 3 coast removed, new ascent profile will stage the booster 1s after separation
  - [ascent.ks] Stage 3 engine will now continue to throttle up even in vacuum
  - [initialize.ks] New launch time set
  - [initialize.ks] Initial Stage 3 throttle changed from 2 to 2.5 TWR
  - [initialize.ks] Custom log data added for radiation instrument to log rad/h

**Progeny Mk5 Block I Flight 3** (12/11/17)

AFCS:
  - [boot.ks] Now using proper `return` method to preserve a trigger
  - [logger.ks] Allow for the addition of data logging fields on a per-launch basis
  
Operations:
  - [ascent.ks] Removed code profiling
  - [ascent.ks] Removed stage 3 fin shred, as fins are no longer on stage 3
  - [ascent.ks] Added check for Angle of Attack constraint. If exceeded during the coast phase, program waits for controllers to manually fire off the next booster
  - [initialize.ks] New launch time set
  - [initialize.ks] Removed stage 3 fin part lookup
  - [science.ks] Payload instrument triggers updated
  
**Progeny Mk5 Block I Flight 2** (10/26/17)

Operations:
  - [ascent.ks] Logging messages moved to after command execution so any non-executed commands don't push a message to the log saying they were executed
  - [ascent.ks] Brought back use of `isLanded` flag to signal the end of ascent execution so it cannot be determined independently of the function that actually detects landing after chute deploy
  - [ascent.ks] All boosters now properly check to see if they have ignited properly & gracefully handle ignition failure
  - [ascent.ks] Changed the `meco` function to `beco` as it is technically more correct
  - [initialize.ks] Launch time updated
  - [science.ks] Payload instrument triggers updated

**Progeny Mk5 Block I Flight 1** (10/19/17)

AFCS:
  - [boot.ks] Consolidated two log messages into a single line
  - [logger.ks] Removed helper functions
  - [helpfunc.ks] Added helper functions from `logger.ks`
  - Include files are now in their own folder as the boot script expects

Operations:
  - [ascent.ks] Dump function performance data for code review
  - [ascent.ks] Removed all generic stage and AG events, replaced with specific part actions
  - [initialize.ks] New launch time
  - [initialize.ks] Log performance data for code execution
  - [initialize.ks] Set ascent profile to begin boost at 1.5° pitch change
  - [initialize.ks] Get references to more parts needed to carry out various actions that used to be done via stage/AG commands
  - [science.ks] Update actions to apply to payload instruments

**Progeny Mk5 Flight 6** (10/12/17)

AFCS:
  - [boot.ks] Slight change to boot-up status text for signal detection
  - [boot.ks] Real-time reading of the KSC-based operations file has been reverted as the newer method was causing file-access errors to crash the program. You must now place operations files into the archive for the spacecraft to upload
  
Operations:
  - [ascent.ks] Runtime codes removed to use the new function monitoring system, where functions can be pushed to a stack to run every CPU tick, so anything that needs to be monitored can happen in its own function, then that function can call the next function to move to a new state
  - [ascent.ks] Some previous run states are now just triggers, like detecting chute initial & full deployment and waiting one second for a staging event. All are nested properly so a trigger that can't fire after another won't start to be evaluated until that trigger fires
  - [ascent.ks] Auto-throttle allows 3rd stage to advance the throttle to full while ensuring dynamic pressure continues to fall
  - [initialize.ks] Launch time updated, pitch over delta modified, obsolete variables removed, throttle lock placed here as it can be safely used even when no thrust is available
  - [science.ks] Instruments are now directly referenced and activated, including pad check at boot-up

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
