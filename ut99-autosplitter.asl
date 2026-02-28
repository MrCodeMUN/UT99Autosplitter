// UT99 Autosplitter v0.7
// Made by CodeM aka MrCodeMUN
// With inspiration from Quake III Arena and Horizon Forbidden West ASL

state("UnrealTournament", "v469e - Release")
{
	// Current state variables that can be used with ASL Var Viewer
	string255 gamemodeName : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x64, 0x460, 0x334, 0x0;
	string255 levelName : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x64, 0x390, 0x0;
	string255 levelAuthor : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x64, 0x39C, 0x0;
	string255 levelIdealPlayerCount : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x64, 0x3A8, 0x0;
	float fovAngle : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x304;
	int playerHealth : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x31C;

	// Current state variables used in the script
	byte4 playerPawnState : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x0C, 0x1C;
	byte playerPawnViewState : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x20C;
	string255 mapName : 0x00037E70, 0xD0, 0x0;
	float gameSpeed : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x64, 0x460, 0x224;
	float groundSpeed : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x26C;
	int remainingTime : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x64, 0x460, 0x1370;
	int elapsedTime : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x64, 0x460, 0x1374;

	// This is the player's air control value. Under the AntiGrav boots effect, this value will go up to 100%. This is why we also check for the player's jump height value.
	// Alternatively, we can also check for the air control value of the GameInfo object, which doesn't change during the match, but breaks in menus.
	// It can be found here: 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x64, 0x460, 0x1354
	float airControl : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x284;
	float jumpZ : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x27C;
}

startup
{
	vars.numberOfDeaths = 0;
	vars.gameStyleGlitchStatus = "";

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

	// Compares two byte arrays. Return true if they are equals.
	Func<byte[], byte[], bool> CompareByteArrays = (a, b) => {
		if (a == null || b == null) return a == b;
		if (a.Length != b.Length) return false;

		for (int i = 0; i < a.Length; i++) {
			if (a[i] != b[i]) return false;
		}

		return true;
	};

	// Defining settings
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

	var autoStartSettingName = new Dictionary<string, string>()
	{
		{ "DM-Oblivion.unr", "auto_start_oblivion" },
		{ "DOM-Condemned.unr", "auto_start_condemned" },
		{ "CTF-Niven.unr", "auto_start_niven" },
		{ "AS-Frigate.unr", "auto_start_frigate" },
		{ "DM-Phobos.unr", "auto_start_phobos" }
	};

	var autoResetSettingName = new Dictionary<string, string>()
	{
		{ "DM-Oblivion.unr", "auto_reset_oblivion" },
		{ "DOM-Condemned.unr", "auto_reset_condemned" },
		{ "CTF-Niven.unr", "auto_reset_niven" },
		{ "AS-Frigate.unr", "auto_reset_frigate" },
		{ "DM-Phobos.unr", "auto_reset_phobos" }
	};

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

	// Defining PlayerPawn states
	byte[] playerWaitingState = { 2, 12, 7, 216 };
	byte[] playerWalkingState = { 2, 28, 7, 249 };
	byte[] dyingState = { 2, 9, 7, 24 };
	byte[] gameEndedState = { 2, 9, 5, 24 };
	vars.playerWaitingState = playerWaitingState;
	vars.playerWalkingState = playerWalkingState;
	vars.dyingState = dyingState;
	vars.gameEndedState = gameEndedState;

	Func<byte[], byte[], bool> IsInState = (playerPawnState, stateToCompare) => {
		return CompareByteArrays(playerPawnState, stateToCompare);
	};
	vars.IsInState = IsInState;

	// To ensure we only split at the end of the defense phase while playing "Assault" maps, we check
	// for the property "bBehindView" of the PlayerPawn. This value is only true at the actual end
	// of a match, whether it ended in a victory or not. Could be better, but it works for now.
	Func<byte, bool> IsBehindViewEnabled = (playerPawnViewState) => {
		return playerPawnViewState % 2 == 1;
	};
	vars.IsBehindViewEnabled = IsBehindViewEnabled;

	// Defining first and last levels
	var firstLevels = new List<String>(new string[] { "DM-Oblivion.unr", "DOM-Condemned.unr", "CTF-Niven.unr", "AS-Frigate.unr", "DM-Phobos.unr" });
	var thirdOrFinalLevels = new List<String>(new string[] { "DM-Fractal.unr", "DOM-Cryptic.unr", "CTF-EternalCave.unr", "DM-Peak.unr", "DOM-MetalDream.unr", "CTF-November.unr", "CTF-Orbital.unr", "AS-Overlord.unr", "DM-HyperBlast.unr" });

	Func<string, bool> IsFirstLevel = (mapName) => {
		return firstLevels.Contains(mapName);
	};
	vars.IsFirstLevel = IsFirstLevel;

	Func<string, bool> IsThirdOrFinalLevel = (mapName) => {
		return thirdOrFinalLevels.Contains(mapName);
	};
	vars.IsThirdOrFinalLevel = IsThirdOrFinalLevel;

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

	Func<float, float, float, float, bool> PlayerIsFollowingRules = (gameSpeed, airControl, jumpZ, groundSpeed) => {
		bool isAirControlOkay = (airControl == 0.35f && jumpZ != 975f) || (airControl == 1f && jumpZ == 975f);

		if (gameSpeed != 1f || !isAirControlOkay || groundSpeed != 400f) {
			// Player is not following rules and has tempered his game settings
			if (gameSpeed != 1f) vars.gameStyleGlitchStatus = "Game Speed isn't set to 100%!";
			if (!isAirControlOkay) vars.gameStyleGlitchStatus = "Air Control isn't set to 35%!";
			if (groundSpeed != 400f) vars.gameStyleGlitchStatus = "Game Style isn't set to 'Hardcore'!";
			return false;
		}

		vars.gameStyleGlitchStatus = "";
		return true;
	};
	vars.PlayerIsFollowingRules = PlayerIsFollowingRules;

	vars.completedLevels = new List<String>();
	vars.elapsedTime = TimeSpan.Zero;

	Action ResetVarsValues = () => {
		vars.completedLevels.Clear();
		vars.numberOfDeaths = 0;
		vars.elapsedTime = TimeSpan.Zero;
	};
	vars.ResetVarsValues = ResetVarsValues;
}

init
{
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
	if (settings["disable_if_game_style_glitch"] && !vars.PlayerIsFollowingRules(current.gameSpeed, current.airControl, current.jumpZ, current.groundSpeed)) {
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
	bool canAutoStart = !settings["auto_start_level"];

	if (!canAutoStart && vars.IsFirstLevel(current.mapName)) {
		var settingName = vars.GetAutoStartSettingFromMapName(current.mapName);
		canAutoStart = settings[settingName];
	}

	var oldStateIsWaiting = vars.IsInState(old.playerPawnState, vars.playerWaitingState);
	var currentStateIsPlaying = vars.IsInState(current.playerPawnState, vars.playerWalkingState);

	if (canAutoStart && oldStateIsWaiting && currentStateIsPlaying) {
		vars.ResetVarsValues();
		return true;
	}

	return false;
}

split
{
	bool canAutoSplit = !settings["auto_split_level"];

	if (!canAutoSplit && vars.IsThirdOrFinalLevel(current.mapName)) {
		var settingName = vars.GetAutoSplitSettingFromMapName(current.mapName);
		canAutoSplit = settings[settingName];
	}

	var hasGameEnded = vars.IsInState(current.playerPawnState, vars.gameEndedState);
	var isBehindViewEnabled = vars.IsBehindViewEnabled(current.playerPawnViewState);
	var levelAlreadyCompleted = vars.completedLevels.Contains(current.mapName);

	if (hasGameEnded && isBehindViewEnabled && canAutoSplit && !levelAlreadyCompleted) {
		vars.completedLevels.Add(current.mapName);
		return true;
	}

	return false;
}

reset
{
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
	if (current.elapsedTime - old.elapsedTime == 1 || old.remainingTime - current.remainingTime == 1) {
		return vars.elapsedTime += TimeSpan.FromSeconds(1);
	}

	return vars.elapsedTime;
}