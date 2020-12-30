# AFCS
Automated Flight Control System providing a generic operational framework for vessels in Kerbal Space Program using kOS

See [the wiki](https://github.com/KSAMissionCtrl/AFCS/wiki) for details

## Included Systems
**Boot** - sets up the environment and runs operations uploaded to the probe core   
**Logger** - monitors and stores various flight parameters, outputs generic status updates   
**HelpFunc** - includes useful general support functions for various operational aspects

## Change Log

**AFCS v1.2.0** (12/30/20)

- [helpFunc.ks] New helper function `pointingFrom` that will return the raw value of the difference between the current steering angle and the passed target angle. Companion to the already-existing `pointingAt` function that looks at a similar value but makes a determination and returns T/F instead of the value
- [logger.ks] New utility function `removeAddlLogData` that can be used to delete a key from the lexicon or even all the keys if not passed a key. This is useful for when a spacecraft changes configuration, such as decoupling a segment that included parts that were being accessed for data to be logged

**Kerbin II Operations Update** (12/16/20)

- New spacecraft commands for science and battery operation
- Scripts for de-orbit maneuver and re-entry procedures

**Progeny Mk7-B Flight 4** (10/29/20)

- SAS control modified for probe use instead of main vessel use
- Various typos fixed in code comments and log output
- Guidance routines updated for mission ascent profile
- Ascent routines updated for mission staging profile
- Probe deployment & initialization based on Kerbin II mission

**Progeny Mk7-B Flight 3** (10/6/20)

- Added altitude callouts to log output
- Staging command updated to split shroud and still valid but ascent code in place to hot-stage automatically at BECO
- Data logger timeout now uses defined value rather than magic number
- General code update to make use of improvements made in flights since last Progeny launch

**AFCS v1.1.0** (10/5/20)

- [boot.ks] Fix: Mis-spelling a single-word command like `disconnect` or `reboot` would crash the program
- [boot.ks] Change: No longer saving data for timers and ops since function handles cannot be serialized
- [boot.ks] Change: Auto-save on `disconnect` so the last-active state of the spacecraft is preserved
- [logger.ks] Fix: Starting to log data prior to lift off would crash the program due to uninitialized variables that only happens at L-0

**Ascension Mk2 Flight 2** (9/23/20)

- Brought up-to-date with general program advances made from previous Mk1 and Progeny Mk7 flights
- Terminal count EC monitoring takes into account RTG output

**AFCS v1.0.0** (9/7/20)

- [boot.ks] New flag defines to use with `sleep()` that will make it easier to remember what the two boolean values do
- [boot.ks] `copyName` variable changed to `fileName` to make it clearer what operation is being performed - no file is being copied it was just saving the name for use later
- [boot.ks] note included to raise awareness of [issue #1](https://github.com/KSAMissionCtrl/AFCS/issues/1)
- [boot.ks] `list` command now shows file sizes in addition to file names in a given directory
- [boot.ks] `reboot` now writes volatile data to memory before rebooting instead of relying on the user to do so first
- [boot.ks] new command `disconnect` - see [this issue](https://github.com/KSAMissionCtrl/AFCS/issues/3) for more details
- [logger.ks] atmospheric calculations are now more accurate

**Progeny Mk7-B Flight 2** (8/27/20)

AFCS:
  - [logger.ks] fixed atmospherics logging issue from outputting wrong values due to a type check, no longer directly changes the variables to "N/A" when outside the atmosphere
  
Operations:
  - Terminology changes to operations log output & function names
  - Added controller-based command for staging
  - Reduced initial ascent pitch over to remove gimbal lock
  - Stage fuel is now properly recorded
  - Adjusted launch time
  - Additional log output information when chute deployment happens later than planned

**Progeny Mk7-B Flight 1** (8/14/20)

Operations:
  - Brought ops files up to date with general improvements made during Ascension launches
  - Better handling of support arm retraction & check for new 4th arm
  - Less pitch-over at start to remove gimbal lock
  - Adjusted launch time and flight guidance

**Ascension Mk1 Flight 14** (7/16/20)

Operations:
  - Adjusted launch time and flight guidance
  - Radiation logging now takes into consideration "nominal" report for external sensor as well
  - Overall based on Flight 12 operations with improvements from Flight 13

**Ascension Mk1 Flight 13** (6/23/20)

AFCS:
  - [boot.ks] now both the `exe` and `cmd` commands for executing scripts halt further execution if a missing file is found, instead of just the `run` command
  - [logger.ks] fixes a small chance occurrence that when re-entring the atmosphere the check at the start of the logging function for <70km will come back false but a physics tick or few later due to instruction size by the time the code gets to the <70km check at the bottom of the function it can be true and try to access variables that were not set by the first check
  
Operations:
  - Change in how the LES tower abort routine handles switching to a return state
  - The `sleep` timer that handles logging now actually uses the `logInterval` variable
  - Control check start time adjusted for newer fully-actuating fins
  - Switch to alternator power now happens after launch clamp is confirmed released
  - Ascent guidance modified for two-phase flight and to align with current mission ascent profile
  - Removal of all `wait` timers
  - MaxQ monitoring during ascent can be restarted if the rocket starts gaining dynamic pressure again
  - Launch time and part management updated for current mission
  - Radiation sensor logging output now remains consisten in mrad/h and handles "nominal" status report

**Ascension Mk1 Flight 12** (3/20/20)

AFCS:
  - [boot.ks] New comm protocols in place
  - [logger.ks] No longer compares integers to strings in some cases
  
Operations:
  - Mission-specific launch time and ascent guidance
  - Better TWR monitoring for launch thrust
  - Updated electrical system management to prevent battery drain while alternator is active
  - Additional capsule sensor logging
  - Fix issue where telemetry data logging would not stop after landing/splashdown

**Ascension Mk2 Flight 1** (2/20/20)

AFCS:
  - [boot.ks] Boot script can now target the kOS core that it is running on without the part needing to be tagged. This means each individual core part can run the boot script independent of each other
  - [boot.ks] Execution times added to more run commands
  - [boot.ks] Vessel can now handle connection dropout to KSC during decoupling
  - [boot.ks] Vessel can go into hibernation without a wake file
  - [boot.ks] Hibernation can be set for up to 300 minutes
  - [boot.ks] Wakefile is now destroyed after being run only if it exists, so that a default one is not created
  - [helpFunc.ks] New function `pointingAt()` can determin if the vessel is oriented at a certain angle
  
Operations:
  - All new flight code based on Ascension Mk1 and Progenitor rockets to guide the Ascension Mk2 up into space and into orbit

**Ascension Mk1 Flight 11** (1/20/20)

Operations
  - Removed all code related to kerbed flight (LES, flight abort, etc)
  - Space operations (decoupling payload) moved to ascent.ks and recovery operations removed entirely as uneeded
  - Extra logging added for temperature monitoring of PLF and RTG
  - Pre-ignition control check shortened to just a roll check, which moves all 4 fins through full range of motion
  - Make sure on launch abort that the engine is active before attempting shut down
  - Include throttle profile to keep ascent speed in check
  - Update launch time, heading lock, EC drain checks

**Directory Update** (1/20/20)

Repository:
  - Changed Ascension operations folder to contain separate directories for the Mk1 and Mk2 operations scripts. This was done in advance of Mk1 #11 code update so proper diff files would be generated

**Progeny Mk6 Block I Flight 15** (12/18/19)

Operations
  - Launch time updated
  
**Progeny Mk6 Block I Flight 14** (12/10/19)

Operations
  - Launch time updated

**Progeny Mk6 Block I Flight 13** (11/22/19)

Operations
  - Launch time updated

**Progeny Mk6 Block I Flight 12** (11/13/19)

Operations
  - Functions for re-entry and recovery moved into their own file `return.ks`
  - All general operations code brought up to date with improvements made in flights for the Progenitor Mk7-A, Mk6-II and Ascension Mk1 that were performed since the last Mk6-I has flown
  - Mission specific science code updated to trigger onboard instruments
  - Launch time set

**Folder Restructure** (11/13/19)

Repository:
  - Changed operations folder to hold files not just for multiple vehicles but multiple vehicle types for each rocket program so that proper diff checks are made when new vehicle code is uploaded

**Ascension Mk1 Flight 10** (10/22/19)

Repository:
  - Reverted to the operations directory holding files for multiple vehicles. This is so a proper diff check can be performed when code is changed for a vehicle
  
Operations:
  - Launch time updated
  - Pitch hold now anticipates the upcoming hold angle much closer to the target
  - Steering remains locked while still in the atmosphere after MECO
  
**Progeny Mk7-A Flight 2** (9/26/19)

Operations:
  - Turning on and off the SAS now also enables/disables the reaction wheel system
  - Some functions for pre-launch operations changed to sleep timers to reduce instruction cost
  - Rocket now pitches over prior to engaging guidance lock
  - Upper fins are locked and do not steer until guidance is enabled
  - MaxQ monitoring is only done when needed rather than all the time to reduce instruction cost

**Ascension Mk1 Flight 9** (9/17/19)

Repository:
  - No longer holding operations files for multiple vehicles. You can look back at the commit history if you want to see past operations files
  
Operations:
   - Cleaned up terminal count monitoring, now using less operation loops and more sleep timers to save energy by executing less instructions each tick
   - EC drain monitoring now terminates at launch
   - Fixed issue where MaxQ was not reported on re-entry
   - Launch abort message for not reaching takeoff TWR now rounds off the reported TWR value
   - When an abort is thrown prior to launch but after main engine ignition, the abort routine now ensures the engine is shut down if that wasn't already the problem
   - Guidance code updated for planned ascent profile
   - When reaching pitch hold the lock to set angle is done prior to reaching the target so the rocket does not overshoot due to low control authority

**Ascension Mk1 Flight 8** (8/28/19)

AFCS:
  - Fixed logging issue that slightly undercalculated the total amount of battery capacity at boot
  - Added additional default logging variables for atmospheric data

Operations:
  - Decoupling the capsule is not longer a part of ascent operations and is a command file for controllers to activate when they are ready late in the mission before re-entry
  - Command files created for deploying/retracting the science instruments
  - Control surface movement check added to T-15s in terminal countdown
  - Fix pitch guidance to monitor actual pitch value and ensure lock occurs when value is reached. Also accounts for calculated value not reaching target and beginning to increase
  
**Ascension Mk1 Flight 7** (7/18/19)

Operations:
  - Proper use of `unlock` to release `lock`ed variables
  - New terminal count monitoring for better EC management prior to launch
  - Proper LES abort and recovery integration for crewed mission
  - Ascent triggers no longer activated until ascent is underway

**Progeny Mk6 Block II Flight 3** (7/9/19)

Operations:
  - Various changes made to comply with improvements made in code for recent Mk6-I and Mk7-A missions since last Mk6-II launch
  - Hibernation length shortened from 60 to 30 seconds
  - Hibernation activation changed to detect when rocket is within high radiation region and stay awake until it exits
  - Exit altitude for radiation belts logged as persistent variables so the rocket can be sure to stay on prior to entrance on the way back down for accurate belt width measurement
  - Allow upper fairings to be jettisoned

**Progeny Mk7-A Flight 1** (6/24/19)

AFCS:
  - Automatically powers on CPU at startup if hibernation module is present
  - `load` command can now load an entire folder of script files. Does not have option to load folders within the target folder
  - `cmd` and `run` commnds have been noted in code to only apply to files that can be found on the spacecraft
  - `exe` new command that runs a script file from the archive and does not store it onto the rocket for future local access with either `run` or `cmd`
  - Hibernation mode can now be activated without setting a wake-up timer, which means it would need a command from mission control
  - `setAbort()` no longer displays abort message when set to `false` and if `true` also unlocks steering and throttle
  - Logger now properly handles the presence on non-rechargeable batteries in the total amount of electrical use
  - Logger can now detect the presence of an accelerometer and log G forces if it is found
  
Operations:
  - Commands added to control reaction wheel system
  - All-new operations code based on Mk6 with additional fault-tolerance

**Ascension Mk1 Flight 6** (5/28/19)

Operations:
  - Terminal count monitoring no longer processes until terminal count begins
  - Launch time changes easier to do without needing system reboot
  - Ascent profile tweaked to better match ability of guidance system to follow it
  - Final pitch hold changed from 49° to 48°
  - Ascent guidance steering unlock taken out of trigger and placed in function to hopefully be executed properly this time
  - Initial pitch off pad decreased to further reduce possibility of gimbal lock for roll to heading after tower clear
  - Abort trigger from previous LES test removed
  - Added routine to fire retrothrusters in LES after re-entry shock wears off

**Ascension Mk1 Flight 5** (5/16/19)

Operations:
  - Trigger added to activate LES past 18.5km ASL
  - All operations and locked variables related to the lifter stage are ended/cleared upon capsule sep
  - Data logging now begins at ignition instead of lift off
  - New launch time

**Progeny Mk6 Block I Flight 11** (5/14/19)

Operations:
  - Routine to detach fairings at 45km
  - Launch time update
  - Science instruments updated
  - Radiation logging enabled

**Ascension Mk1 Block I Flight 4** (4/18/19)

AFCS:
  - Boot script now properly confirms all ship systems are ready before initiating boot
  - Hibernation support changes listed in Data Persistence & Hibernation are now actually synced to the repo
  - `setAbort` now alters a variabled named `launchAbort` to keep `abort` clear for use with the actual ship abort flag now that a Launch Escape System is attached
  
Operations:
  - Terminal count can now be changed with a change to `launchTime` rather than being locked to a time upon boot and needing to be completely reset if L-0 changes, although the `onTerminalCount` timer will need to be adjusted
  - Support added to fire off the LES if the fuel tank is no longer detected due to an explosion. Also takes into account whether the kick motor activates properly
  - Re-entry step added to fire LES when through maximum pressure to test it as a braking system in emergencies
  - Pitch profile and launch time adjusted
  - Removed old operations loop
  - Added proper support for getter/setter functions in logging data and accessing volatile variables
  - Removed ascent operations no longer in line with new LVD ascent profile (engine stays at full)
  - Detect wether landing over sea or terrain and arm floar collar accordingly

**Progeny Mk6 Block I Flight 10** (3/12/19)

Operations:
  - Change launch time
  - Change science instruments
  - Allow easier editing of launch time after AFCS is initialized
  - Fix rare bug that could cause rocket to think it already landed before it takes off

**Progeny Mk6 Block I Flight 9** (2/7/19)

Operations:
  - Change launch time
  - Change science instruments

**Progeny Mk6 Block II Flight 2** (1/31/19)

Operations:
  - Changes to match new bootscript handling of dynamic variables and sleep timers to replace triggers
  - New method of AoA calculation for second stage coast
  - Hibernation routines to allow for power to last the entire flight

**Ascension Mk1 Block I Flight 3** (1/22/19)

Operations:
  - [ascent.ks] General script overhaul to conform to new AFCS bootscript protocols and make use of new capabilities like sleep timers and comms loss handling
  - [ascent.ks] New pitch profile entered in quadtratic fit formula
  - [initialize.ks] New Launch time
  - [initialize.ks] Chute deploy speed defined so chute isn't popped when supersonic
  - [orbit.ks] New routines added for test mass separation
  - [return.ks] New routines added for landing of test mass

**Progeny Mk6 Block I Flight 8** (1/15/19)

Operations:
  - [ascent.ks] AoA monitoring now uses the newer code tested for the telemetry output
  - [ascent.ks] Change to how the rocket detects it has landed after re-entry
  - [initialize.ks] New launch time
  - [initialize.ks] Change to how the rocket detects it has landed after re-entry

**Data Persistence & Hibernation** (12/9/18)

NOTE: changes to boot.ks were not synced with this update - see commit for Ascension Mk1 Block I Flight 4

AFCS:
  - [boot.ks] `load:` command has been changed to only place a file from the archive into the /cmd directory on the vessel
  - [boot.ks] `run:` command has been changed to run a file in the /ops directory. If it is not found there, the /cmd directory is searched and if the file is there it is copied to the /ops directory
  - [boot.ks] `cmd:` this new command only runs a file if it is found in the /cmd directory. This means that any file run with this command will not be automatically run when the AFCS is awoken from hibernation or otherwise reloaded
  - [boot.ks] New `decl()`, `getter()` and `setter()` functions allow the computer to use persistent variables - if the computer is shut down and restarted or reloaded the variable data will be reloaded as well to use from the previous state. All necessary variables in the AFCS files have been modified to be persistent
  - [boot.ks] New `setCommStatus()` function allows the computer to turn on or off all communication devices
  - [boot.ks] `sleep()` has been moved from the helper functions file to made a core part of the bootscript
  - [boot.ks] New `hibernate()` function shuts down the probe core and optionally the comms to a trickle of power. It is automatically re-activated after a set period of time. Requires a [smart part timer](https://forum.kerbalspaceprogram.com/index.php?/topic/151340-14x-smart-parts-continued/)
  - [boot.ks] New `loadOpsFile()` and `runOpsFile()` functions let you perform `cmd:` and `run:` equivalent commands in script
  - [boot.ks] The status of the KSC comm connection is no longer logged if there are no active comm devices
  - [logger.ks] The ascent path data has been removed since there is a bug in kOS when serializing a `geoposition` object
  - [logger.ks] Fixed an issue where the EC resource monitor was locking to the wrong resource type

**Boot & Include updates** (12/9/18)

AFCS:
  - [boot.ks] New `load:` command can stash a script file into the /ops/ folder but will not run it until the ground controllers activate it with a `run:` command. You can still use `run` to load and then run a script at the same time, the difference in syntax is starting the file name with a "/" - if the flight computer sees this it knows it's searching for a file on the archive to load, otherwise it assumes the file is in the /ops/ folder on the vessel
  - [boot.ks] sleep timers are monitored every tick and called when they run out and then destroyed or reset accordingly
  - [helpFunc.ks] New function `sleep()` allows you to set a callback to a function after a given amount of time. The amount of time can either be in seconds from the moment the sleep command is given or at a certain UT. This callback can then be called repeatedly over that period or just once. Repeated callbacks are their own functions, but single-use callbacks are inserted into the operations queue to be handled
  - [logger.ks] Finally fixed the throttle output value
  - [logger.ks] Looks for and also monitors non-rechargeable battery sources for total EC logging
  - [logger.ks] Now outputs by default both surface and orbital velocity
  - [logger.ks] Total thrust is now only calculated based on active engines
  - [logger.ks] Logging reworked to use the `sleep()` function from the calling script

**New Comm & Control Interface** (11/27/18)

AFCS:
  - [boot.ks] Pretty much a complete refactoring of the entire boot system to standards of stricter comm and file protocols
  - [boot.ks] Actual commands can now be sent to the flight computer to carry out various actions including running files, deleting files and directories, listing directory contents and rebooting the computer
  - [boot.ks] When signal to KSC is regained, any locally stored data will be downloaded to the KSC archive
  - [boot.ks] Operations files are now stored as they are named on the archive rather than with generic opCode numbers
  - [boot.ks] Boot operations order has been changed to check for new bootscript first
  - [boot.ks] If KSC connection is available, on boot the computer will replace /include files in case any were updated
  - [helpFunc.ks] - New function `stashmit()` decides whether to write a file to the local drive or KSC drive, depending on signal status. If writing to the local drive it attempts to ensure the capacity of the drive is not exceeded
  - [logger.ks] - Updated to make use of `stashmit()`
  - [logger.ks] - Fixed current thrust and available thrust being outputted in the wrong order

**Progeny Mk6 Block I Flight 7** (7/31/18)

AFCS:
  - [helpFunc.ks] New function for calculating AoA that takes into account the roll and yaw of the vessel
  - [logger.ks] New AoA output next to old one to see what the difference is and judge its future use
  - [logger.ks] Thrust for the vessel is now logged as both current (dependent on the throttle setting) and available (the maximum amount for the given altitude)
  
Operations:
  - [ascent.ks] Science call trigger placed back in
  - [ascent.ks] Chute deployment monitoring function now removes itself properly from the operations queue after chute deployment so it doesn't crash the program
  - [initialize.ks] New launch time set
  - [initialize.ks] Fairing part finders removed, as they are no longer detached during re-entry
  - [initialize.ks] Radiation logging removed as no sensor for it aboard this rocket
  - [science.ks] Operations for observation of the mystery goo canisters

**Progeny Mk6 Block I Flight 6** (7/20/18)

AFCS:
  - New folder structure for Progeny operations files, as Block I and II have separate needs, except in payload control
  
Operations:
  - [ascent.ks] Overall structure adjusted to fit with recent improvements made to runtime operations for Ascension Mk1 and Progeny Mk6 Block II launches
  - [ascent.ks] Airbrakes now deploy based on dynamic pressure rather than altitude
  - [ascent.ks] Parachute now deploys based on speed as well as altitude
  - [initialize.ks] Overall structure adjusted to fit with recent improvements made to runtime operations for Ascension Mk1 and Progeny Mk6 Block II launches
  - [initialize.ks] New launch time set

**Ascension Mk1 Block I Flight 2** (7/17/18)

Operations:
- [ascent.ks] Generic pitch-over code removed and replaced with a quadratic fit curve to hit certain angles of pitch by certain altitudes for a more aggressive ascent profile
- [ascent.ks] Apokee hold removed, as to do this rocket would need to be able to continually adjust orientation during burn and it will lose this ability due to thinning air long before fuel expires
- [initialize.ks] Launch time updated
- [orbit.ks] Better detection for sub-orbital trajectory to kick in return routines
- [orbit.ks] Fixed bug that prevented chute deployment last flight
- [orbit.ks] Use of control surfaces to pitch level now kicks in at 35km denser air instead of 50km

**Progeny Mk6 Block II Flight 1** (6/20/18)

Operations:
  - [ascent.ks] Operations sequence changed to match what was done for Ascension launch
  - [ascent.ks] Extra stage added to handle release of radial boosters
  - [ascent.ks] Cutoff added to ensure rocket doesn't fly beyond 900km apokee
  - [ascent.ks] Ensures chute will not open if rocket is traveling too fast - unless its so low an attempt might as well be made
  - [initialize.ks] Added support for the new radial boosters
  - [initialize.ks] Launch time updated

**Ascension Mk1 Block I Flight 1** (6/8/18)

AFCS:
  - [boot.ks] Reduced log output for instruction loads to a single line that shows the time taken to execute
  - [helpFunc.ks] `surfaceGravity` is now a global variable that can be used anywhere
  - [helpFunc.ks] `setAbort()` is now a global function that can be used anywhere
  - [helpFunc.ks] `setAbort()` now also outputs the reason for the abort so a separate command for this is no longer needed
  
Operations: 
  - All new code to initialize then handle ascent, orbit and recovery for the Ascension Mk1 Block I rocket
  - [initialize.ks] Launch time updated
  
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
