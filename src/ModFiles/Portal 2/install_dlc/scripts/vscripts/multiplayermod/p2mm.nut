//----------------------------------------------------------------------------------//
//                                  COPYRIGHT                                       //
//                      © 2022 Portal 2: Multiplayer Mod                            //
//  https://github.com/Portal-2-Multiplayer-Mod/Portal-2-Multiplayer-Mod/LICENSE    //
//  In the case that this file does not exist at all or in the GitHub repository,   //
//      this project will fall under a GNU LESSER GENERAL PUBLIC LICENSE            //
//----------------------------------------------------------------------------------//

//---------------------------------------------------
//         *****!Do not edit this file!*****
//---------------------------------------------------
// Purpose: The heart of the mod's content. Runs on
// every map transition to bring about features and
//                 fixes for 3+ MP.
//---------------------------------------------------

/*
    TODO:
    - Redo the entire system for LoadMapSupportCode
        - Better to merge everything into one nut file per map, even with gamemode differences
*/

// In case this is the client VM...
if (!("Entities" in this)) { return }

printl("\n---------------------")
printl("==== calling p2mm.nut")
printl("---------------------\n")

// Make sure all the VScript functions from the plugin are available
IncludeScript("multiplayermod/pluginfunctionscheck.nut")

if (!PluginLoaded) {
    // One-off check for running p2mm on first map load
    try {
        if (HasStartedP2MM) {
            return
        }
    } catch (exception) {} // Should never have an exception, try catch is here for testing...

    if (!("HasStartedP2MM" in this)) {
        HasStartedP2MM <- true
        return
    }
}

iMaxPlayers <- (Entities.FindByClassname(null, "team_manager").entindex() - 1) // Determine what the "maxplayers" cap is

printlP2MM(0, true, "Session info...")
printlP2MM(0, true, "- Current map: " + GetMapName())
printlP2MM(0, true, "- Max players allowed on the server: " + iMaxPlayers)
printlP2MM(0, true, "- Dedicated server: " + IsDedicatedServer())
printlP2MM(0, true, "\n")

IncludeScript("multiplayermod/config.nut") // Import the user configuration and preferences and make sure nothing was invalid and compensate

printlP2MM(0, true, "FirstRunState(-1): " + FirstRunState(-1).tostring())
printlP2MM(0, true, "GetLastMap(): " + GetLastMap())
printlP2MM(0, true, "GetMapName(): " + GetMapName())

// Check if its the first map run so Last Map System stuff can be done
if (FirstRunState(-1)) {
    FirstRunState(0) // Set that first run state to false

    // Reset developer level, developer needs to stay enabled for VScript Debugging to work
    if (Config_DevMode || Config_VScriptDebug) {
        EntFire("p2mm_servercommand", "command", "developer 1")
    }
    else {
        EntFire("p2mm_servercommand", "command", "developer 0")
    }
    
    // Check if Last Map System supplied a value and that it's a valid map, then restart on that map
    if (IsMapValid(GetLastMap()) && (GetLastMap() != GetMapName())) {
        FirstRunState(1) // Set state back to true because we are using one map as a transition to the map we actually want to be our first map

        printlP2MM(0, true, "Transitioning to Last/Singleplayer Map!")
        printlP2MM(0, true, "FirstRunState(-1): " + FirstRunState(-1).tostring())
        printlP2MM(0, true, "GetLastMap(): " + GetLastMap())
        printlP2MM(0, true, "GetMapName(): " + GetMapName())

        EntFire("p2mm_servercommand", "command", "changelevel " + GetLastMap(), 1)
        return
    }
}

// Prints the current map, needed for the Last Map System
// \n was here :>
printlP2MM(0, false, "MAP LOADED: " + GetMapName())

//-------------------------------------------------------------------------------------------

// Continue loading the P2:MM fixes, game mode, and features

IncludeScript("multiplayermod/vars&funcs.nut")
IncludeScript("multiplayermod/safeguard.nut")
IncludeScript("multiplayermod/hooks.nut")
IncludeScript("multiplayermod/chatcommands.nut")

// Always have global root functions imported for any level
IncludeScript("multiplayermod/mapsupport/#propcreation.nut")
IncludeScript("multiplayermod/mapsupport/#rootfunctions.nut")

//---------------------------------------------------

// Print P2:MM game art in console
ConsoleAscii <- [
"########...#######...##..##.....##.##.....##",
"##.....##.##.....##.####.###...###.###...###",
"##.....##........##..##..####.####.####.####",
"########...#######.......##.###.##.##.###.##",
"##........##.........##..##.....##.##.....##",
"##........##........####.##.....##.##.....##",
"##........#########..##..##.....##.##.....##"
]
foreach (line in ConsoleAscii) { printl(line) }
delete ConsoleAscii
printl("")

//---------------------------------------------------

// Now, manage everything the player has set in config.nut
// If the gamemode has exceptions of any kind, it will revert to standard Portal 2 mapsupport

// Import map support code
// Map name will be wonky if the client VM attempts to get the map name
function LoadMapSupportCode(gametype) {
    printlP2MM(0, false, "=============================================================")
    printlP2MM(0, false, "Attempting to load " + gametype + " mapsupport code!")
    printlP2MM(0, false, "=============================================================\n")

    try {
        IncludeScript("multiplayermod/mapsupport/" + gametype + "/" + GetMapName() + ".nut")
    } catch (exception) {
        if (gametype == "portal2") {
            printlP2MM(1, false, "Failed to load mapsupport for " + GetMapName() + "\n")
        }
        else {
            printlP2MM(1, false, "Failed to load " + gametype + " mapsupport code! Reverting to standard Portal 2 mapsupport...")
            return LoadMapSupportCode("portal2")
        }
    }
}

// Now, manage everything the player has set in config.nut
// If the gamemode has exceptions of any kind, it will revert to standard Portal 2 mapsupport
switch (Config_GameMode) {
    case 0: LoadMapSupportCode("portal2"); break
    //case 1: LoadMapSupportCode("speedrun"); break
    default:
        printlP2MM(1, false, "\"Config_GameMode\" value in config.nut is invalid! Be sure it is set to an integer from 0-1. Reverting to standard Portal 2 mapsupport.")
        LoadMapSupportCode("portal2")
        break
}

//---------------------------------------------------

// Run InstantRun() shortly AFTER spawn (hooks.nut)
EntFire("p2mm_servercommand", "command", "script InstantRun()", 0.02)
