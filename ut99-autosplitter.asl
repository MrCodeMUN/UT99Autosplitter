// UT99 Autosplitter v0.8
// Made by CodeM aka MrCodeMUN
// With inspiration from Quake III Arena, UT2k4 and Horizon Forbidden West ASL

state("UnrealTournament", "v469e - Release")
{
	// Parent addresses table:
	// 0x00037E70: 														UGameEngine
	// 0x00037E70, 0x44: 												Pointer to UWindowsClient
	// 0x00037E70, 0x44, 0x2C, 0x0: 									Pointer to UWindowsViewport
	// 0x00037E70, 0x44, 0x2C, 0x0, 0x30: 								Pointer to APlayerPawn
	// 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x64: 						Pointer to ALevelInfo
	// 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x64, 0x460: 					Pointer to AGameInfo
	// 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x64, 0x460, 0x3A0: 			Pointer to AGameInfoReplicationInfo
	// 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x64, 0x460, 0x3A0, 0x388: 	Pointer to AInfo (Team 0 info)
	// 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x44C: 						Pointer to APlayerReplicationInfo

	// Current state variables not used in the script, but that can be used with ASL Var Viewer
	// localizedLevelName: 		"ITV Oblivion", "ITV oubli", etc.
	// localizedGamemodeName: 	"Tournament DeathMatch", "Tournoi Combat à Mort", etc.
	string255 localizedLevelName : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x64, 0x390, 0x0;
	string255 localizedGamemodeName : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x64, 0x460, 0x334, 0x0;

	// Current state variables used in the script
	// playerPawnState: 	a combination of four bytes that can identify the "state" the player is in (waiting, walking, swimming, feigning death, game ended, spectator, etc.).
	// playerPawnViewState: a value influenced by crouching or swimming. Can be either 66, 74, 82, 90 or 98. If bBehindView is True (the player is in third person), the value will be upped by 1.
	// mapName: 			the map file name. "DM-Oblivion.unr", "DM-Peak.unr", etc.
	// gameSpeed: 			game speed in percentage (%).
	// playerGroundSpeed: 	the player's speeed on the ground. Default is 400.
	// remainingTime: 		game's remaining time in seconds.
	// elapsedTime: 		game's elapsed time in seconds.
	// playerScore: 		player's score. DOM gamemode's score is decimal, although hidden to the player. This is why it's a float.
	// playerTeamScore: 	player's team score. DOM gamemode's score is decimal, although hidden to the player. This is why it's a float.
	// gameItemGoals: 		score limit in DOM and CTF.
	// gameKillGoals: 		score limit in DM and LDM (Challenge ladder mode).
	// gameSecretGoals: 	usually a time goal in minutes. Will always be 1 in the second part of AS maps, for some reason.
	// airControl: 			player's air control value in percentage (%). Will be 1 if under the AntiGrav boots effect.
	// jumpZ:				player's jump height value. Default is 325, or 357,5 if in Hardcore mode. Will be 975 under the AntiGrav boots effect.

	// Alternatively, we can also check for the air control value of the AGameInfo object, which doesn't change during the match, but breaks in menus.
	// It can be found here: 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x64, 0x460, 0x1354

	byte4 playerPawnState : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x0C, 0x1C;
	byte playerPawnViewState : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x20C;
	string255 mapName : 0x00037E70, 0xD0, 0x0;
	float gameSpeed : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x64, 0x460, 0x224;
	float playerGroundSpeed : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x26C;
	int remainingTime : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x64, 0x460, 0x1370;
	int elapsedTime : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x64, 0x460, 0x1374;
	float playerScore : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x44C, 0x23C;
	float playerTeamScore : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x64, 0x460, 0x3A0, 0x388, 0x21C;
	int gameItemGoals : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x64, 0x460, 0x3A0, 0x398;
	int gameKillGoals : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x64, 0x460, 0x3A0, 0x39C;
	int gameSecretGoals : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x64, 0x460, 0x3A0, 0x3A0;
	float airControl : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x284;
	float jumpZ : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x27C;
}

startup
{
	// --------------------------
	// DEFINING VARIABLES
	// --------------------------
	// numberOfDeaths:			total deaths of the player during the run.
	// gameStyleGlitchStatus:	simple message explaining the reason why the game style glitch is being used.
	vars.numberOfDeaths = 0;
	vars.gameStyleGlitchStatus = "";

	// autoStartSettingName: 	used to get the auto-start setting name from a map file name.
	var autoStartSettingName = new Dictionary<string, string>()
	{
		{ "DM-Oblivion.unr", "auto_start_oblivion" },
		{ "DOM-Condemned.unr", "auto_start_condemned" },
		{ "CTF-Niven.unr", "auto_start_niven" },
		{ "AS-Frigate.unr", "auto_start_frigate" },
		{ "DM-Phobos.unr", "auto_start_phobos" }
	};

	// autoResetSettingName: 	used to get the auto-reset setting name from a map file name.
	var autoResetSettingName = new Dictionary<string, string>()
	{
		{ "DM-Oblivion.unr", "auto_reset_oblivion" },
		{ "DOM-Condemned.unr", "auto_reset_condemned" },
		{ "CTF-Niven.unr", "auto_reset_niven" },
		{ "AS-Frigate.unr", "auto_reset_frigate" },
		{ "DM-Phobos.unr", "auto_reset_phobos" }
	};

	// autoSplitSettingName: 	used to get the auto-split setting name from a map file name.
	var autoSplitSettingName = new Dictionary<string, string>()
	{
		{ "DM-Fractal.unr", "auto_split_fractal" },
		{ "DOM-Cryptic.unr", "auto_split_cryptic" },
		{ "CTF-EternalCave.unr", "auto_split_eternal_cave" },
		{ "DM-Peak.unr", "auto_split_peak" },
		{ "DOM-MetalDream.unr", "auto_split_metal_dream" },
		{ "CTF-November.unr", "auto_split_november" },
		{ "CTF-Orbital.unr", "auto_split_orbital" },
		{ "AS-Overlord.unr", "auto_split_overlord" },
		{ "DM-HyperBlast.unr", "auto_split_hyperblast" }
	};

	// Defining the different possible PlayerPawn states used in the script. Other states not used in the script includes:
	// FeigningDeath: 					{ 2, 28, 7, 248 }
	// Spectator / CheatFlying: 		{ 2, 12, 5, 249 }
	// Swimming: 						{ 2, 28, 5, 249 }
	// Camera (except in AS maps): 		{ 2, 12, 4, 248 }
	byte[] playerWaitingState = { 2, 12, 7, 216 };
	byte[] playerWalkingState = { 2, 28, 7, 249 };
	byte[] dyingState = { 2, 9, 7, 24 };
	byte[] gameEndedState = { 2, 9, 5, 24 };
	vars.playerWaitingState = playerWaitingState;
	vars.playerWalkingState = playerWalkingState;
	vars.dyingState = dyingState;
	vars.gameEndedState = gameEndedState;

	// Defining first and last levels
	var firstLevels = new List<String>(new string[] { "DM-Oblivion.unr", "DOM-Condemned.unr", "CTF-Niven.unr", "AS-Frigate.unr", "DM-Phobos.unr" });
	var thirdOrFinalLevels = new List<String>(new string[] { "DM-Fractal.unr", "DOM-Cryptic.unr", "CTF-EternalCave.unr", "DM-Peak.unr", "DOM-MetalDream.unr", "CTF-November.unr", "CTF-Orbital.unr", "AS-Overlord.unr", "DM-HyperBlast.unr" });

	// completedLevels: 	used to track down the levels completed by the player.
	// elapsedTime:			in-game time, basically.
	vars.completedLevels = new List<String>();
	vars.elapsedTime = TimeSpan.Zero;

	// --------------------------
	// DEFINING SETTINGS
	// --------------------------
	settings.Add("auto_start_level", true, "Auto-start at the start of a specific level");
		settings.Add("auto_start_oblivion", true, "ITV Oblivion", "auto_start_level");
		settings.Add("auto_start_condemned", false, "Condemned", "auto_start_level");
		settings.Add("auto_start_niven", false, "Niven Experimental Lab", "auto_start_level");
		settings.Add("auto_start_frigate", false, "Frigate", "auto_start_level");
		settings.Add("auto_start_phobos", false, "Phobos Moon", "auto_start_level");
	settings.Add("auto_reset_level", true, "Auto-reset at the start of a specific level");
		settings.Add("auto_reset_oblivion", true, "ITV Oblivion", "auto_reset_level");
		settings.Add("auto_reset_condemned", false, "Condemned", "auto_reset_level");
		settings.Add("auto_reset_niven", false, "Niven Experimental Lab", "auto_reset_level");
		settings.Add("auto_reset_frigate", false, "Frigate", "auto_reset_level");
		settings.Add("auto_reset_phobos", false, "Phobos Moon", "auto_reset_level");
	settings.Add("auto_split_level", false, "Auto-split at the end of a specific level");
		settings.Add("auto_split_fractal", false, "Fractal Reactor", "auto_split_level");
		settings.Add("auto_split_cryptic", false, "Cryptic", "auto_split_level");
		settings.Add("auto_split_eternal_cave", false, "Eternal Caves", "auto_split_level");
		settings.Add("auto_split_peak", false, "The Peak Monastery", "auto_split_level");
		settings.Add("auto_split_metal_dream", false, "Metal Dream", "auto_split_level");
		settings.Add("auto_split_november", false, "November Sub Pen", "auto_split_level");
		settings.Add("auto_split_orbital", false, "Orbital Station #12", "auto_split_level");
		settings.Add("auto_split_overlord", false, "Operation Overlord", "auto_split_level");
		settings.Add("auto_split_hyperblast", false, "HyperBlast", "auto_split_level");
	settings.Add("no_death_challenge", false, "No death challenge");
	settings.Add("disable_if_game_style_glitch", false, "[EXPERIMENTAL] Disable autosplitter if the Game Style glitched is used");
	settings.SetToolTip("auto_start_level", "If unchecked, will auto-start at the start of every level.");
	settings.SetToolTip("auto_reset_level", "WARNING! If unchecked, will auto-reset at the start of every level.");
	settings.SetToolTip("auto_split_level", "If unchecked, will auto-split at the end of every level.");
	settings.SetToolTip("no_death_challenge", "If 'Reset' is checked, will auto-reset the timer on death.");
	settings.SetToolTip("disable_if_game_style_glitch", "Disables autosplitter if game speed is not set to 100%, if air control is not set to 35% and if game style is not set to 'Hardcore'.");

	// --------------------------
	// DEFINING FUNCTIONS
	// --------------------------

	// Used to compute the module hash and determine the version of the game
	Func<ProcessModuleWow64Safe, string> CalcModuleHash = (module) => {
		byte[] exeHashBytes = new byte[0];
		using (var sha = System.Security.Cryptography.SHA256.Create())
		{
			using (var s = File.Open(module.FileName, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
			{
				exeHashBytes = sha.ComputeHash(s);
			}
		}
		var hash = exeHashBytes.Select(x => x.ToString("X2")).Aggregate((a, b) => a + b);
		return hash;
	};
	vars.CalcModuleHash = CalcModuleHash;

	// Casts a byte array as string for debugging purposes
	Func<byte[], string> ByteArrayToString = (bytes) => {
		var sb = new StringBuilder("new byte[] { ");

		foreach (var b in bytes) {
			sb.Append(b + ", ");
		}

		sb.Append("}");
		return sb.ToString();
	};
	vars.ByteArrayToString = ByteArrayToString;

	// Compares two byte arrays. Return True if they are equals.
	Func<byte[], byte[], bool> CompareByteArrays = (a, b) => {
		if (a == null || b == null) return a == b;
		if (a.Length != b.Length) return false;

		for (int i = 0; i < a.Length; i++) {
			if (a[i] != b[i]) return false;
		}

		return true;
	};

	// Checks if a playerPawnState corresponds to a specific stateToCompare. Return True if they are equal.
	Func<byte[], byte[], bool> IsInState = (playerPawnState, stateToCompare) => {
		return CompareByteArrays(playerPawnState, stateToCompare);
	};
	vars.IsInState = IsInState;

	// To ensure we only split at the end of the the second part of an AS map, we check for the property "bBehindView" of the PlayerPawn.
	// This value is only True if the defending team wins the match. It's also True at the end of a match in every other gamemode.
	Func<byte, bool> IsBehindViewEnabled = (playerPawnViewState) => {
		return playerPawnViewState % 2 == 1;
	};
	vars.IsBehindViewEnabled = IsBehindViewEnabled;

	// Checks if the level is one of the five first levels in the ladder mode.
	Func<string, bool> IsFirstLevel = (mapName) => {
		return firstLevels.Contains(mapName);
	};
	vars.IsFirstLevel = IsFirstLevel;

	// Checks if the level is one of the third or last levels in the ladder mode.
	Func<string, bool> IsThirdOrFinalLevel = (mapName) => {
		return thirdOrFinalLevels.Contains(mapName);
	};
	vars.IsThirdOrFinalLevel = IsThirdOrFinalLevel;

	// Gets the proper settings name from a map file name.
	Func<string, string> GetAutoStartSettingFromMapName = (mapName) => {
		return autoStartSettingName[mapName];
	};
	vars.GetAutoStartSettingFromMapName = GetAutoStartSettingFromMapName;

	Func<string, string> GetAutoResetSettingFromMapName = (mapName) => {
		return autoResetSettingName[mapName];
	};
	vars.GetAutoResetSettingFromMapName = GetAutoResetSettingFromMapName;

	Func<string, string> GetAutoSplitSettingFromMapName = (mapName) => {
		return autoSplitSettingName[mapName];
	};
	vars.GetAutoSplitSettingFromMapName = GetAutoSplitSettingFromMapName;

	// In order for a UT99 run to be considered valid, game speed has to be set to 100%, air control should be 35% and the game style should be set to 'Hardcore'.
	// As such, game speed should always be 1f. Player's ground speed should always be 400 ('Turbo' game style change this value to 560).
	// AntiGrav boots can affect player's air control value, so we also check for the player's jump height value.
	// Air control value is considered valid if:
	// - airControl is 0.35f and jumpZ is 357.5f 	(basic air control with no boots)
	// - airControl is 1f and jumpZ is 975f 		(air control is boosted because of the boots)
	Func<float, float, float, float, bool> IsPlayerFollowingRules = (gameSpeed, airControl, jumpZ, playerGroundSpeed) => {
		bool isAirControlOkay = (airControl == 0.35f && jumpZ != 975f) || (airControl == 1f && jumpZ == 975f);

		if (gameSpeed != 1f || !isAirControlOkay || playerGroundSpeed != 400f) {
			// Player is not following rules and has tempered his game settings
			if (gameSpeed != 1f) vars.gameStyleGlitchStatus = "Game Speed isn't set to 100%!";
			if (!isAirControlOkay) vars.gameStyleGlitchStatus = "Air Control isn't set to 35%!";
			if (playerGroundSpeed != 400f) vars.gameStyleGlitchStatus = "Game Style isn't set to 'Hardcore'!";
			print("[LiveSplit - UT99 Autosplitter] " + vars.gameStyleGlitchStatus);
			return false;
		}

		vars.gameStyleGlitchStatus = "";
		return true;
	};
	vars.IsPlayerFollowingRules = IsPlayerFollowingRules;

	// As I couldn't find a proper way to determine the player's victory at the end of a match, we just compare the current score of the player (or their team) to the game max score.
	Func<int, int, float, float, bool> HasPlayerWon = (gameItemGoals, gameKillGoals, playerScore, playerTeamScore) => {
		if (gameItemGoals > 0) {
			return (int) playerTeamScore >= gameItemGoals;
		}

		if (gameKillGoals > 0) {
			return (int) playerScore >= gameKillGoals;
		}

		return false;
	};
	vars.HasPlayerWon = HasPlayerWon;

	// Resets values of temp variables.
	Action ResetVarsValues = () => {
		vars.completedLevels.Clear();
		vars.numberOfDeaths = 0;
		vars.elapsedTime = TimeSpan.Zero;
	};
	vars.ResetVarsValues = ResetVarsValues;
}

init
{
	// At the script initialization, we check the Unreal Tournament's module hash to try and determine the game's version.
	// For now, only the release of the version 469e is supported.
	var module = modules.Single(x => String.Equals(x.ModuleName, "UnrealTournament.exe", StringComparison.OrdinalIgnoreCase));
	var hash = vars.CalcModuleHash(module);

	if (hash != "03E2900BDC7848AD6B86D3171F19E25A8E395FAAFBD9EE4FD9F5C30F6A2D4DBE") {
		if (MessageBox.Show(
			"It seems you are not running the version v469e - Release of Unreal Tournament (1999). The Autosplitter may not work properly.\n\nPlease update your game with the latest community patch, available on the OldUnreal GitHub's page.\n\nWould you like me to open the website for you?",
			"UT99 Autosplitter",
			MessageBoxButtons.YesNo,
			MessageBoxIcon.Warning
		) == DialogResult.Yes) {
			System.Diagnostics.Process.Start("https://github.com/OldUnreal/UnrealTournamentPatches/releases");
		}
	} else {
		version = "v469e - Release";
	}
}

update
{
	// Two things are happening here:
	// - if the game style glitch setting is enabled, we block every main functions of the script if we think the player is not following the rules
	// - everytime the player dies, we increment vars.numberOfDeaths by 1. This can lead to an auto-reset if the proper setting is enabled

	if (settings["disable_if_game_style_glitch"] && !vars.IsPlayerFollowingRules(current.gameSpeed, current.airControl, current.jumpZ, current.playerGroundSpeed)) {
		// Player is not following rules and has tempered his game settings
		return false;
	}

 	var oldStateIsDying = vars.IsInState(old.playerPawnState, vars.dyingState);
	var currentStateIsDying = vars.IsInState(current.playerPawnState, vars.dyingState);

	if (!oldStateIsDying && currentStateIsDying) {
		vars.numberOfDeaths += 1;
	}
}

start
{
	// We automatically start the timer if all of the following conditions are met:
	// - if the auto_start_level setting is enabled and the player is in the same level as the auto_start_level setting
	// - if the player was in a waiting state the frame before
	// - if the player is in a walking state

	bool canAutoStart = !settings["auto_start_level"];

	if (!canAutoStart && vars.IsFirstLevel(current.mapName)) {
		var settingName = vars.GetAutoStartSettingFromMapName(current.mapName);
		canAutoStart = settings[settingName];
	}

	var oldStateIsWaiting = vars.IsInState(old.playerPawnState, vars.playerWaitingState);
	var currentStateIsWalking = vars.IsInState(current.playerPawnState, vars.playerWalkingState);

	if (canAutoStart && oldStateIsWaiting && currentStateIsWalking) {
		vars.ResetVarsValues();
		return true;
	}

	return false;
}

split
{
	// We automatically split the timer if all of the following conditions are met:
	// - if the auto_split_level setting is enabled and the player is in the same level as the auto_split_level setting
	// - if the player is in a game ended state
	// - if no split already happened in the current level during the run
	// - if the player is victorious

	bool shouldSplit = false;

	if (settings["auto_split_level"]) {
		if (!vars.IsThirdOrFinalLevel(current.mapName)) {
			return false;
		}

		var settingName = vars.GetAutoSplitSettingFromMapName(current.mapName);
		if (!settings[settingName]) {
			return false;
		}
	}

	var hasGameEnded = vars.IsInState(current.playerPawnState, vars.gameEndedState);

	if (hasGameEnded) {
		var levelAlreadyCompleted = vars.completedLevels.Contains(current.mapName);

		if (levelAlreadyCompleted) {
			return false;
		}

		if (current.gameItemGoals > 0 || current.gameKillGoals > 0) {
			shouldSplit = vars.HasPlayerWon(current.gameItemGoals, current.gameKillGoals, current.playerScore, current.playerTeamScore);
		} else if (current.gameSecretGoals == 1) {
			shouldSplit = vars.IsBehindViewEnabled(current.playerPawnViewState); // gameSecretGoals is always 1 in the second part. If the defending team has won the match, the player will be in thrid person view.
		}
	}

	if (shouldSplit) {
		vars.completedLevels.Add(current.mapName);
		return true;
	}

	return false;
}

reset
{
	// We automatically reset the timer if all of the following conditions are met:
	// - if the auto_reset_level setting is enabled and the player is in the same level as the auto_reset_level setting
	// - if the player is in a waiting state
	// We also reset the timer if the no_death_challenge setting is enabled and the player has died at least once

	if (settings["no_death_challenge"] && vars.numberOfDeaths > 0) {
		return true;
	}

	if (old.mapName == current.mapName) {
		return false;
	}

	bool canAutoReset = !settings["auto_reset_level"];

	if (!canAutoReset && vars.IsFirstLevel(current.mapName)) {
		var settingName = vars.GetAutoResetSettingFromMapName(current.mapName);
		canAutoReset = settings[settingName];
	}

	var isPlayerWaiting = vars.IsInState(current.playerPawnState, vars.playerWaitingState);

	if (isPlayerWaiting && canAutoReset) {
		vars.ResetVarsValues();
		return true;
	}

	return false;
}

onReset
{
	vars.ResetVarsValues();
}

gameTime
{
	// We add 1 second to the in-game timer if the map elapsed time went up by 1, or if the remaining time went down by 1.
	if (current.elapsedTime - old.elapsedTime == 1 || old.remainingTime - current.remainingTime == 1) {
		return vars.elapsedTime += TimeSpan.FromSeconds(1);
	}

	return vars.elapsedTime;
}
