// UT99 Autosplitter v0.5
// Made by CodeM aka MrCodeMUN
// With inspiration from Quake III Arena and Horizon Forbidden West ASL

// Only tested with v469e release
state("UnrealTournament")
{
	byte4 playerPawnState : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x0C, 0x1C;
	byte playerPawnBehindView : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x20C;
	string255 levelTitle : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x64, 0x390, 0x0;

	// Unused for now, may be useful later
	string255 gameName : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x64, 0x460, 0x334, 0x0;
}

startup
{
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
	settings.Add("standard_ladder_splits", false, "Gamemode ladder splits (Standard)");
	settings.Add("goty_ladder_splits", false, "Gamemode ladder splits (GOTY)");
	settings.Add("auto_start_oblivion", true, "Auto-start on ITV Oblivion");
	settings.Add("auto_start_condemned", false, "Auto-start on Condemned");
	settings.Add("auto_start_niven", false, "Auto-start on Niven Experimental Lab");
	settings.Add("auto_start_frigate", false, "Auto-start on Frigate");
	settings.Add("auto_start_phobos", false, "Auto-start on Phobos Moon");
	settings.Add("auto_reset_oblivion", true, "Auto-reset on ITV Oblivion");
	settings.Add("auto_reset_condemned", false, "Auto-reset on Condemned");
	settings.Add("auto_reset_niven", false, "Auto-reset on Niven Experimental Lab");
	settings.Add("auto_reset_frigate", false, "Auto-reset on Frigate");
	settings.Add("auto_reset_phobos", false, "Auto-reset on Phobos Moon");
	settings.SetToolTip("standard_ladder_splits", "Split at the end of a gamemode ladder and not at the end of each level (standard ladder).");
	settings.SetToolTip("goty_ladder_splits", "Split at the end of a gamemode ladder and not at the end of each level (GOTY ladder).");

	var autoStartSettingName = new Dictionary<string, string>()
	{
		{ "ITV Oblivion", "auto_start_oblivion" },
		{ "Condemned", "auto_start_condemned" },
		{ "Niven Experimental Lab", "auto_start_niven" },
		{ "Frigate", "auto_start_frigate" },
		{ "Phobos Moon", "auto_start_phobos" }
	};

	var autoResetSettingName = new Dictionary<string, string>()
	{
		{ "ITV Oblivion", "auto_reset_oblivion" },
		{ "Condemned", "auto_reset_condemned" },
		{ "Niven Experimental Lab", "auto_reset_niven" },
		{ "Frigate", "auto_reset_frigate" },
		{ "Phobos Moon", "auto_reset_phobos" }
	};

	// Defining PlayerPawn states
	byte[] playerWaitingState = { 2, 12, 7, 216 };
	byte[] playingState = { 2, 28, 7, 249 };
	byte[] gameEndedState = { 2, 9, 5, 24 };
	vars.playerWaitingState = playerWaitingState;
	vars.playingState = playingState;
	vars.gameEndedState = gameEndedState;

	Func<byte[], byte[], bool> IsInState = (playerPawnState, stateToCompare) => {
		return CompareByteArrays(playerPawnState, stateToCompare);
	};
	vars.IsInState = IsInState;

	// To ensure we only split at the end of the defense phase while playing "Assault" maps, we check
	// for the property "bBehindView" of the PlayerPawn. This value is only true at the actual end
	// of a match, whether it ended in a victory or not. Could be better, but it works for now.
	Func<byte, bool> IsBehindViewEnabled = (bBehindView) => {
		return bBehindView == 67;
	};
	vars.IsBehindViewEnabled = IsBehindViewEnabled;

	// Defining first and last levels
	var firstLevels = new List<String>(new string[] { "ITV Oblivion", "Condemned", "Niven Experimental Lab", "Frigate", "Phobos Moon" });
	var lastStandardLevels = new List<String>(new string[] { "The Peak Monastery", "Metal Dream", "November Sub Pen", "Operation Overlord", "HyperBlast" });
	var lastGOTYLevels = new List<String>(new string[] { "The Peak Monastery", "Metal Dream", "Orbital Station #12", "Operation Overlord", "HyperBlast" });

	Func<string, bool> IsFirstLevel = (levelTitle) => {
		return firstLevels.Contains(levelTitle);
	};
	vars.IsFirstLevel = IsFirstLevel;

	Func<string, bool, bool, bool> CanSplitOnLevel = (levelTitle, standardLadderSplits, gotyLadderSplits) => {
		if (!standardLadderSplits && !gotyLadderSplits) {
			return true;
		}

		if (gotyLadderSplits) {
			return lastGOTYLevels.Contains(levelTitle);
		}

		return lastStandardLevels.Contains(levelTitle);
	};
	vars.CanSplitOnLevel = CanSplitOnLevel;

	Func<string, string> GetAutoStartSettingFromLevelTitle = (levelTitle) => {
		return autoStartSettingName[levelTitle];
	};
	vars.GetAutoStartSettingFromLevelTitle = GetAutoStartSettingFromLevelTitle;

	Func<string, string> GetAutoResetSettingFromLevelTitle = (levelTitle) => {
		return autoResetSettingName[levelTitle];
	};
	vars.GetAutoResetSettingFromLevelTitle = GetAutoResetSettingFromLevelTitle;
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
	}
}

start
{
	bool canAutoStart = !settings["auto_start_oblivion"] && !settings["auto_start_condemned"] && !settings["auto_start_niven"] && !settings["auto_start_frigate"] && !settings["auto_start_phobos"];

	if (!canAutoStart && vars.IsFirstLevel(current.levelTitle)) {
		var settingName = vars.GetAutoStartSettingFromLevelTitle(current.levelTitle);
		canAutoStart = settings[settingName];
	}

	var oldStateIsWaiting = vars.IsInState(old.playerPawnState, vars.playerWaitingState);
	var currentStateIsPlaying = vars.IsInState(current.playerPawnState, vars.playingState);

	if (canAutoStart && oldStateIsWaiting && currentStateIsPlaying) {
		return true;
	}

	return false;
}

split
{
	var hasGameJustEnded = !vars.IsInState(old.playerPawnState, vars.gameEndedState) && vars.IsInState(current.playerPawnState, vars.gameEndedState);
	var isBehindViewEnabled = vars.IsBehindViewEnabled(current.playerPawnBehindView);
	var canSplitOnLevel = vars.CanSplitOnLevel(current.levelTitle, settings["standard_ladder_splits"], settings["goty_ladder_splits"]);

	if (hasGameJustEnded && isBehindViewEnabled && canSplitOnLevel) {
		return true;
	}

	return false;
}

reset
{
	bool canAutoReset = !settings["auto_reset_oblivion"] && !settings["auto_reset_condemned"] && !settings["auto_reset_niven"] && !settings["auto_reset_frigate"] && !settings["auto_reset_phobos"];

	if (!canAutoReset && vars.IsFirstLevel(current.levelTitle)) {
		var settingName = vars.GetAutoResetSettingFromLevelTitle(current.levelTitle);
		canAutoReset = settings[settingName];
	}

	var oldStateIsWaiting = vars.IsInState(old.playerPawnState, vars.playerWaitingState);
	var currentStateIsWaiting = vars.IsInState(current.playerPawnState, vars.playerWaitingState);

	if (!oldStateIsWaiting && currentStateIsWaiting && canAutoReset) {
		return true;
	}

	return false;
}