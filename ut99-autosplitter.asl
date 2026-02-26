// UT99 Autosplitter v0.6
// Made by CodeM aka MrCodeMUN
// With inspiration from Quake III Arena and Horizon Forbidden West ASL

// Only tested with v469e release
state("UnrealTournament")
{
	byte4 playerPawnState : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x0C, 0x1C;
	byte playerPawnViewState : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x20C;
	string255 mapName : 0x00037E70, 0xD0, 0x0;
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
	Func<byte, bool> IsBehindViewEnabled = (playerPawnViewState) => {
		return playerPawnViewState % 2 == 1;
	};
	vars.IsBehindViewEnabled = IsBehindViewEnabled;

	// Defining first and last levels
	var firstLevels = new List<String>(new string[] { "DM-Oblivion.unr", "DOM-Condemned.unr", "CTF-Niven.unr", "AS-Frigate.unr", "DM-Phobos.unr" });
	var lastStandardLevels = new List<String>(new string[] { "DM-Peak.unr", "DOM-MetalDream.unr", "CTF-November.unr", "AS-Overlord.unr", "DM-HyperBlast.unr" });
	var lastGOTYLevels = new List<String>(new string[] { "DM-Peak.unr", "DOM-MetalDream.unr", "CTF-Orbital.unr", "AS-Overlord.unr", "DM-HyperBlast.unr" });

	Func<string, bool> IsFirstLevel = (mapName) => {
		return firstLevels.Contains(mapName);
	};
	vars.IsFirstLevel = IsFirstLevel;

	Func<string, bool, bool, bool> CanSplitOnLevel = (mapName, standardLadderSplits, gotyLadderSplits) => {
		if (!standardLadderSplits && !gotyLadderSplits) {
			return true;
		}

		if (gotyLadderSplits) {
			return lastGOTYLevels.Contains(mapName);
		}

		return lastStandardLevels.Contains(mapName);
	};
	vars.CanSplitOnLevel = CanSplitOnLevel;

	Func<string, string> GetAutoStartSettingFromMapName = (mapName) => {
		return autoStartSettingName[mapName];
	};
	vars.GetAutoStartSettingFromMapName = GetAutoStartSettingFromMapName;

	Func<string, string> GetAutoResetSettingFromMapName = (mapName) => {
		return autoResetSettingName[mapName];
	};
	vars.GetAutoResetSettingFromMapName = GetAutoResetSettingFromMapName;

	vars.completedLevels = new List<String>();
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

	if (!canAutoStart && vars.IsFirstLevel(current.mapName)) {
		var settingName = vars.GetAutoStartSettingFromMapName(current.mapName);
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
	var hasGameEnded = vars.IsInState(current.playerPawnState, vars.gameEndedState);
	var isBehindViewEnabled = vars.IsBehindViewEnabled(current.playerPawnViewState);
	var canSplitOnLevel = vars.CanSplitOnLevel(current.mapName, settings["standard_ladder_splits"], settings["goty_ladder_splits"]);
	var levelAlreadyCompleted = vars.completedLevels.Contains(current.mapName);

	if (hasGameEnded && isBehindViewEnabled && canSplitOnLevel && !levelAlreadyCompleted) {
		vars.completedLevels.Add(current.mapName);
		return true;
	}

	return false;
}

reset
{
	if (old.mapName == current.mapName) {
		return false;
	}

	bool canAutoReset = !settings["auto_reset_oblivion"] && !settings["auto_reset_condemned"] && !settings["auto_reset_niven"] && !settings["auto_reset_frigate"] && !settings["auto_reset_phobos"];

	if (!canAutoReset && vars.IsFirstLevel(current.mapName)) {
		var settingName = vars.GetAutoResetSettingFromMapName(current.mapName);
		canAutoReset = settings[settingName];
	}

	var isPlayerWaiting = vars.IsInState(current.playerPawnState, vars.playerWaitingState);

	if (isPlayerWaiting && canAutoReset) {
		return true;
	}

	return false;
}

onReset
{
	vars.completedLevels.Clear();
}
