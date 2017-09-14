# AFCS
Automated Flight Control System for vessels in Kerbal Space Program using kOS

## Systems
**Logger** - monitors and stores various flight parameters   
**Boot** - sets up the environment and runs operations uploaded to the probe core

## Change Log

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
