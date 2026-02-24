// UT99 Autosplitter v0.1
// Made by CodeM aka MrCodeMUN
// With inspiration from Quake III Arena and Horizon Forbidden West ASL

state("UnrealTournament")
{
	// Only tested with v469e release
	byte4 playerPawnState : 0x00037E70, 0x44, 0x2C, 0x0, 0x30, 0x0C, 0x1C;
}

startup
{
	// Casts a byte array as string for debugging purposes
	Func<byte[], string> ByteArrayToString = (bytes) => {
		var sb = new StringBuilder("new byte[] { ");
    		foreach (var b in bytes)
    		{
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
 
    		for (int i = 0; i < a.Length; i++)
    		{
        		if (a[i] != b[i]) return false;
    		}

		return true;
	};
	vars.CompareByteArrays = CompareByteArrays;

	// Defining PlayerPawn states
	byte[] playerWaitingState = { 2, 12, 7, 216 };
	byte[] defaultState = { 2, 28, 7, 249 };
	byte[] gameEndedState = { 2, 9, 5, 24 };

	vars.playerWaitingState = playerWaitingState;
	vars.defaultState = defaultState;
	vars.gameEndedState = gameEndedState;
}

start
{
	var oldStateIsWaiting = vars.CompareByteArrays(old.playerPawnState, vars.playerWaitingState);
	var currentStateIsDefault = vars.CompareByteArrays(current.playerPawnState, vars.defaultState);
	
	if (oldStateIsWaiting && currentStateIsDefault) {
		return true;
	}

    	return false;
}

split
{
	var oldStateIsGameEnded = vars.CompareByteArrays(old.playerPawnState, vars.gameEndedState);
	var currentStateIsGameEnded = vars.CompareByteArrays(current.playerPawnState, vars.gameEndedState);

	if (!oldStateIsGameEnded && currentStateIsGameEnded) {
		return true;
	}

    	return false;
}

reset
{
	var oldStateIsWaiting = vars.CompareByteArrays(old.playerPawnState, vars.playerWaitingState);
	var currentStateIsWaiting = vars.CompareByteArrays(current.playerPawnState, vars.playerWaitingState);

	if (!oldStateIsWaiting && currentStateIsWaiting) {
		return true;
	}

	return false;
}