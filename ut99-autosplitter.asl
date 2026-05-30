// UT99 Autosplitter v0.9
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
	// airControl: 				player's air control value in percentage (%). Will be 1 if under the AntiGrav boots effect. Previously used as an anti-cheat experimental feature.
	// jumpZ:					player's jump height value. Default is 325, or 357,5 if in Hardcore mode. Will be 975 under the AntiGrav boots effect. Previously used as an anti-cheat experimental feature.
	string255 localizedLevelName : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x64, 0x390, 0x0;
	string255 localizedGamemodeName : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x64, 0x460, 0x334, 0x0;
	float airControl : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x284;
	float jumpZ : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x27C;

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
}

startup
{
	// --------------------------
	// DEFINING VARIABLES
	// --------------------------
	// numberOfDeaths:				total deaths of the player during the run.
	// gameStyleGlitchStatus:		simple message explaining the reason if and why the game style glitch is being used.
	// humanPlayerScore:			player's score or player's team's score, depending on the current gamemode. Rounded to be more humanly readable.
	// scorePerMin:					player's score or player's team's score per minute, depending on the current gamemode. Rounded to be more humanly readable.
	// estimatedLevelInGameTime:	level in-game time prediction based on the player's current pace. Updates regurarly depending on score and elapsed time.
	vars.numberOfDeaths = 0;
	vars.gameStyleGlitchStatus = "";
	vars.humanPlayerScore = 0f;
	vars.scorePerMin = 0;
	vars.estimatedLevelInGameTime = TimeSpan.Zero;

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
	var thresholdLevels = new List<String>(new string[] { "DM-Fractal.unr", "DOM-Cryptic.unr", "CTF-EternalCave.unr", "DM-Peak.unr", "DOM-MetalDream.unr", "CTF-November.unr", "CTF-Orbital.unr", "AS-Overlord.unr", "DM-HyperBlast.unr" });

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
	settings.Add("ctf_flag_split", false, "Split after every flag capture on CTF maps");
	settings.Add("no_death_challenge", false, "No death challenge");
	settings.Add("lrt_instead_of_igt", false, "[EXPERIMENTAL] Set Game Time to Load Removed Time instead of the sum of all in-game elapsed times.");
	settings.SetToolTip("auto_start_level", "If unchecked, will auto-start at the start of every level.");
	settings.SetToolTip("auto_reset_level", "WARNING! If unchecked, will auto-reset at the start of every level.");
	settings.SetToolTip("auto_split_level", "If unchecked, will auto-split at the end of every level.");
	settings.SetToolTip("no_death_challenge", "If 'Reset' is checked, will auto-reset the timer on death.");
	settings.SetToolTip("lrt_instead_of_igt", "This is NOT used officilally in leaderboards. RTA is still the time you should record when submitting runs.");

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
		return thresholdLevels.Contains(mapName);
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
	// Many things are happening here:
	// - everytime the player dies, we increment vars.numberOfDeaths by 1. This can lead to an auto-reset if the proper setting is enabled
	// - we update the humanPlayerScore variable by rounding the playerScore or playerTeamScore value, depending on the gamemode
	// - we update the current level prediction time

 	var oldStateIsDying = vars.IsInState(old.playerPawnState, vars.dyingState);
	var currentStateIsDying = vars.IsInState(current.playerPawnState, vars.dyingState);

	if (!oldStateIsDying && currentStateIsDying) {
		vars.numberOfDeaths += 1;
	}

	// Setting humanPlayerScore, scorePerMin and estimatedLevelInGameTime
	if (current.mapName == null || (!current.mapName.StartsWith("DM") && !current.mapName.StartsWith("DOM") && !current.mapName.StartsWith("CTF"))) {
		vars.humanPlayerScore = "-";
		vars.scorePerMin = "-";
		vars.estimatedLevelInGameTime = "--:--:--";

		return;
	}

	var oldScoreToCheck = old.playerTeamScore;
	var oldGoalToCheck = old.gameItemGoals;
	var scoreToCheck = current.playerTeamScore;
	var goalToCheck = current.gameItemGoals;

	if (current.mapName != null && current.mapName.StartsWith("DM")) {
		oldScoreToCheck = old.playerScore;
		oldGoalToCheck = old.gameKillGoals;
		scoreToCheck = current.playerScore;
		goalToCheck = current.gameKillGoals;
	}

	if (oldScoreToCheck != scoreToCheck) {
		vars.humanPlayerScore = Math.Truncate(scoreToCheck * 10.0) / 10.0;
		vars.scorePerMin = current.elapsedTime == 0 ? 0 : Math.Truncate((scoreToCheck / current.elapsedTime) * 60 * 10.0) / 10.0;
		var scorePerSecond = vars.scorePerMin == 0 ? 0 : vars.scorePerMin / 60;

		if (current.mapName != null && current.mapName.StartsWith("DOM")) {
			scorePerSecond = 0.6f; // 0.6f is the best score per second possible in Domination
		}

		var remainingSeconds = scorePerSecond == 0 ? 0 : Math.Truncate((goalToCheck - scoreToCheck) / scorePerSecond);
		vars.estimatedLevelInGameTime = TimeSpan.FromSeconds(current.elapsedTime + remainingSeconds);
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

	// We also split the timer after every flag capture on CTF maps if the ctf_flag_split setting is enabled.
	if (settings["ctf_flag_split"] && current.mapName.StartsWith("CTF") && (current.playerTeamScore - old.playerTeamScore) == 1f) {
		if (current.playerTeamScore == 3f) {
			vars.completedLevels.Add(current.mapName);
		}

		return true;
	}

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
			// gameSecretGoals is always 1 in the second part of an Assault map.
			// If the defending team has won the match, the player will be in third person view.
			shouldSplit = vars.IsBehindViewEnabled(current.playerPawnViewState);
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
	// - if the player is not defending in an assault map
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
	var isDefendingOnAssault = current.gameSecretGoals == 1;

	if (isPlayerWaiting && !isDefendingOnAssault && canAutoReset) {
		vars.ResetVarsValues();
		return true;
	}

	return false;
}

onReset
{
	vars.ResetVarsValues();
}

isLoading
{
	// This is experimental and is not used officially in leaderboards.
	if (settings["lrt_instead_of_igt"]) {
		if (current.gameSpeed != 1f) {
			return true;
		}
	}

	return false;
}

gameTime
{
	// We add 1 second to the in-game timer if the map elapsed time went up by 1, or if the remaining time went down by 1.
	if (current.elapsedTime - old.elapsedTime == 1 || old.remainingTime - current.remainingTime == 1) {
		return vars.elapsedTime += TimeSpan.FromSeconds(1);
	}

	return vars.elapsedTime;
}
