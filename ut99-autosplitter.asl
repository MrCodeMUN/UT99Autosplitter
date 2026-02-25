// UT99 Autosplitter v0.3
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
	settings.SetToolTip("standard_ladder_splits", "Split at the end of a gamemode ladder and not at the end of each level (standard ladder).");
	settings.SetToolTip("goty_ladder_splits", "Split at the end of a gamemode ladder and not at the end of each level (GOTY ladder).");

	// Defining PlayerPawn states
	byte[] playerWaitingState = { 2, 12, 7, 216 };
	byte[] playingState = { 2, 28, 7, 249 };
	byte[] gameEndedState = { 2, 9, 5, 24 };

	// Defining last levels
	var lastStandardLevels = new List<String>(new string[] { "The Peak Monastery", "Metal Dream", "November Sub Pen", "Operation Overlord", "HyperBlast" });
	var lastGOTYLevels = new List<String>(new string[] { "The Peak Monastery", "Metal Dream", "Orbital Station #12", "Operation Overlord", "HyperBlast" });

	Func<byte[], bool> IsPlayerWaiting = (playerPawnState) => {
		return CompareByteArrays(playerPawnState, playerWaitingState);
	};
	vars.IsPlayerWaiting = IsPlayerWaiting;

	Func<byte[], bool> IsPlaying = (playerPawnState) => {
		return CompareByteArrays(playerPawnState, playingState);
	};
	vars.IsPlaying = IsPlaying;

	Func<byte[], bool> HasGameEnded = (playerPawnState) => {
		return CompareByteArrays(playerPawnState, gameEndedState);
	};
	vars.HasGameEnded = HasGameEnded;

	// To ensure we only split at the end of the defense phase while playing "Assault" maps, we check
	// for the property "bBehindView" of the PlayerPawn. This value is only true at the actual end
	// of a match, whether it ended in a victory or not. Could be better, but it works for now.
	Func<byte, bool> IsBehindViewEnabled = (bBehindView) => {
		return bBehindView == 67;
	};
	vars.IsBehindViewEnabled = IsBehindViewEnabled;

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
}

start
{
	var oldStateIsWaiting = vars.IsPlayerWaiting(old.playerPawnState);
	var currentStateIsPlaying = vars.IsPlaying(current.playerPawnState);

	if (oldStateIsWaiting && currentStateIsPlaying) {
		return true;
	}

	return false;
}

split
{
	var hasGameJustEnded = !vars.HasGameEnded(old.playerPawnState) && vars.HasGameEnded(current.playerPawnState);
	var isBehindViewEnabled = vars.IsBehindViewEnabled(current.playerPawnBehindView);
	var canSplitOnLevel = vars.CanSplitOnLevel(current.levelTitle, settings["standard_ladder_splits"], settings["goty_ladder_splits"]);

	if (hasGameJustEnded && isBehindViewEnabled && canSplitOnLevel) {
		return true;
	}

	return false;
}

reset
{
	var oldStateIsWaiting = vars.IsPlayerWaiting(old.playerPawnState);
	var currentStateIsWaiting = vars.IsPlayerWaiting(current.playerPawnState);

	if (!oldStateIsWaiting && currentStateIsWaiting) {
		return true;
	}

	return false;
}