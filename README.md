# AFCS
Automated Flight Control System for vessels in Kerbal Space Program using kOS

## Systems
**Logger** - monitors and stores various flight parameters   
**Boot** - sets up the environment and runs operations uploaded to the probe core

## Change Log

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
