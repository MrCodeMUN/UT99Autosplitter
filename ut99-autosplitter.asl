// UT99 Autosplitter v1.0
// Made by CodeM aka MrCodeMUN
// With inspiration from Quake III Arena, UT2k4 and Horizon Forbidden West ASL
//
// v1.0 by HotDoshirak, written with AI assistance: version-independent memory access.
// Instead of hard-coded pointer paths for a single build, the script reads Unreal Engine's own reflection data at runtime:
// Core.dll exports UObject::GObjObjects and FName::Names, which let us find the GameEngine object and every UnrealScript
// class, and each UProperty stores its own memory offset. This works for 32-bit (v469e and older 469 builds) and 64-bit
// (v469f and newer) builds alike, without having to update the script for every game patch.
// Only a handful of native (C++-only) offsets are guessed with small heuristics, see vars.TryResolve below.

state("UnrealTournament") {}

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

	// Map names are read from the level's package name, so they don't have the ".unr" extension.
	// autoStartSettingName: 	used to get the auto-start setting name from a map name.
	var autoStartSettingName = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
	{
		{ "DM-Oblivion", "auto_start_oblivion" },
		{ "DOM-Condemned", "auto_start_condemned" },
		{ "CTF-Niven", "auto_start_niven" },
		{ "AS-Frigate", "auto_start_frigate" },
		{ "DM-Phobos", "auto_start_phobos" }
	};

	// autoResetSettingName: 	used to get the auto-reset setting name from a map name.
	var autoResetSettingName = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
	{
		{ "DM-Oblivion", "auto_reset_oblivion" },
		{ "DOM-Condemned", "auto_reset_condemned" },
		{ "CTF-Niven", "auto_reset_niven" },
		{ "AS-Frigate", "auto_reset_frigate" },
		{ "DM-Phobos", "auto_reset_phobos" }
	};

	// autoSplitSettingName: 	used to get the auto-split setting name from a map name.
	var autoSplitSettingName = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
	{
		{ "DM-Fractal", "auto_split_fractal" },
		{ "DOM-Cryptic", "auto_split_cryptic" },
		{ "CTF-EternalCave", "auto_split_eternal_cave" },
		{ "DM-Peak", "auto_split_peak" },
		{ "DOM-MetalDream", "auto_split_metal_dream" },
		{ "CTF-November", "auto_split_november" },
		{ "CTF-Orbital", "auto_split_orbital" },
		{ "AS-Overlord", "auto_split_overlord" },
		{ "DM-HyperBlast", "auto_split_hyperblast" }
	};

	// PlayerPawn states used in the script, identified by their UnrealScript state name.
	// Other states not used in the script include FeigningDeath, PlayerSwimming, CheatFlying, PlayerSpectating, etc.
	vars.playerWaitingState = "PlayerWaiting";
	vars.playerWalkingState = "PlayerWalking";
	vars.dyingState = "Dying";
	vars.gameEndedState = "GameEnded";

	// Known builds: hash, version name and compatibility status.
	vars.knownVersions = new Dictionary<string, Tuple<string, bool>>()
	{
		{ "2D64AD2C96A68503AB991091091B6CFA5B469477BFC57D73F1AB9C70F5E71162", Tuple.Create("v436", false) },
		{ "B632148FC07D69260AD6304E96620F5ADB3FFA00BBB9176147A0C929028318FC", Tuple.Create("v451", false) },
		{ "CAC582AB5308DBE0DC0DA82E0EBC15C51DDCBFFF4627E38821B179E6BBA13B64", Tuple.Create("v451b", false) },
		{ "9016162E9650F72AA6EA30047F9BC5D2EC9C48A433F064C0CA6453036CAB5680", Tuple.Create("v469a", false) },
		{ "D77EE35CAA6EB14E55AF116239DBADECAFA428D7CF8F322A88DDF41DA6F7AC91", Tuple.Create("v469b", false) },
		{ "010FB16101B054A8C535D87EBE16A96C8EE088641AF2289F1E3B988B1B150B3F", Tuple.Create("v469c - RC2", true) },
		{ "1ABFC42D668DD7E1A64F1C918E165E6BCA860A42EEE5C5F9EB03245E7A97D345", Tuple.Create("v469c - RC3", true) },
		{ "4F81A00C31BCDCF69F42A69DDA8B1102B3106868A383008FCC06E6F29C5E8376", Tuple.Create("v469c - RC4", true) },
		{ "944342836834383DFBBEBB4B047708A6471CE17FD912BF6F5E7E9734F9821D13", Tuple.Create("v469c", true) },
		{ "347A1669155C6BE46E74EE0E35791A6B65368E66F993F7DCBBB2279F6D401C76", Tuple.Create("v469d - RC2", true) },
		{ "90E443D57727EED9A4CF205F1757ABC961C75D9BEEE2484FF987ED25648B0F38", Tuple.Create("v469d - RC4", true) },
		{ "56A5F9B060B12D651CC6E7C836C149136C30BABEAC4FD178D43DE4976C226CCF", Tuple.Create("v469d", true) },
		{ "B7D2DCFA35B88ED5AD782F02B5CE9CCF1A12445418210180484063E217E227BF", Tuple.Create("v469e - RC4", true) },
		{ "D74E0EF07F2C88B99DF1C57671C4DC54857C8F2814B56573AE24FE6A6CB39E2B", Tuple.Create("v469e - RC7", true) },
		{ "ED050EE7F9E9182AC64BE09DF30A33BD40D88AB27D80DE73B0B884764C1728B7", Tuple.Create("v469e - RC8", true) },
		{ "F5489BFF8DE96F163F53A4E31B97B43A5C954B5654ED76C0BFFF188AC6054F42", Tuple.Create("v469e - RC9", true) },
		{ "13F15B6F8D1371D25D3C2669B704E9866C7D37721F3637ED699896694222A7F9", Tuple.Create("v469e - RC10", true) },
		{ "03E2900BDC7848AD6B86D3171F19E25A8E395FAAFBD9EE4FD9F5C30F6A2D4DBE", Tuple.Create("v469e", true) },
		{ "BFE240B884DC4141BDF8BA0CD7E45ABF693709AA79CC1613A0D505BF6EE5F09B", Tuple.Create("v469f - RC5 (64-bit)", true) },
		{ "7EF4C07E096E392EA24DD4CE1E20921A5073EA5B25990ACB2DB81B8399DB5B3C", Tuple.Create("v469f - RC6 (64-bit)", true) }
	};

	// Defining first and last levels
	var firstLevels = new HashSet<string>(autoStartSettingName.Keys, StringComparer.OrdinalIgnoreCase);
	var thresholdLevels = new HashSet<string>(autoSplitSettingName.Keys, StringComparer.OrdinalIgnoreCase);

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

	// Checks if a playerPawnState corresponds to a specific stateToCompare. Return True if they are equal.
	Func<string, string, bool> IsInState = (playerPawnState, stateToCompare) => {
		return playerPawnState == stateToCompare;
	};
	vars.IsInState = IsInState;

	// Checks if the level is one of the five first levels in the ladder mode.
	Func<string, bool> IsFirstLevel = (mapName) => {
		return mapName != null && firstLevels.Contains(mapName);
	};
	vars.IsFirstLevel = IsFirstLevel;

	// Checks if the level is one of the third or last levels in the ladder mode.
	Func<string, bool> IsThirdOrFinalLevel = (mapName) => {
		return mapName != null && thresholdLevels.Contains(mapName);
	};
	vars.IsThirdOrFinalLevel = IsThirdOrFinalLevel;

	// Gets the proper settings name from a map name.
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

	// --------------------------
	// RUNTIME OFFSET RESOLUTION
	// --------------------------
	// Layout of the UObject header. It hasn't changed since 1999, only the pointer size differs:
	// vtable, Index, HashNext, StateFrame, _Linker, _LinkerIndex, Outer, ObjectFlags, Name, Class
	// FNameEntry: Index, Flags, HashNext, Name[] (UTF-16)
	// FStateFrame: vtable, Node, Object, Code, Locals, CurrentFrame, StateNode, ProbeMask, ...
	// These are double-checked at runtime against the engine's own reflection (Object.Outer and Object.Class properties).

	// Read the current FName entry: indices may be reused after map changes.
	Func<Process, int, string> NameOf = (proc, index) => {
		IntPtr namesArray = vars.namesArray;
		int ps = proc.Is64Bit() ? 8 : 4;
		if (index <= 0 || index >= proc.ReadValue<int>(namesArray + ps)) {
			return null;
		}

		IntPtr entry = proc.ReadPointer(proc.ReadPointer(namesArray) + index * ps);
		if (entry == IntPtr.Zero) {
			return null;
		}

		// Read full class names (e.g. TournamentGameReplicationInfo).
		// If the fixed-size read crosses an inaccessible page, fall back
		// to reading UTF-16 code units until the null terminator.
		IntPtr text = entry + (proc.Is64Bit() ? 0x10 : 0x0C);
		string name = proc.ReadString(text, ReadStringType.UTF16, 128);
		if (name != null) return name;
		var chars = new List<char>();
		for (int i = 0; i < 128; i++) {
			byte[] pair = proc.ReadBytes(text + i * 2, 2);
			if (pair == null || pair.Length != 2) return null;
			ushort code = BitConverter.ToUInt16(pair, 0);
			if (code == 0) return new string(chars.ToArray());
			chars.Add((char)code);
		}
		return null;
	};
	vars.NameOf = NameOf;

	// Finds a symbol exported by a loaded module by parsing its PE export table in memory.
	Func<Process, ProcessModuleWow64Safe, string, IntPtr> FindExport = (proc, module, prefix) => {
		IntPtr b = module.BaseAddress;
		int pe = proc.ReadValue<int>(b + 0x3C);
		int exportRva = proc.ReadValue<int>(b + pe + (proc.Is64Bit() ? 0x88 : 0x78));
		IntPtr exports = b + exportRva;
		int count = proc.ReadValue<int>(exports + 0x18);
		IntPtr functions = b + proc.ReadValue<int>(exports + 0x1C);
		IntPtr names = b + proc.ReadValue<int>(exports + 0x20);
		IntPtr ordinals = b + proc.ReadValue<int>(exports + 0x24);

		for (int i = 0; i < count; i++) {
			string name = proc.ReadString(b + proc.ReadValue<int>(names + i * 4), ReadStringType.ASCII, 128);
			if (name != null && name.StartsWith(prefix)) {
				int ordinal = proc.ReadValue<ushort>(ordinals + i * 2);
				return b + proc.ReadValue<int>(functions + ordinal * 4);
			}
		}

		return IntPtr.Zero;
	};

	// Finds the GameEngine object and every offset the script needs, then creates the memory watchers.
	// Returns false if the game isn't ready yet (still starting up), in which case it'll be called again later.
	Func<Process, bool> TryResolve = (proc) => {
		bool is64 = proc.Is64Bit();
		int ps = is64 ? 8 : 4;
		int oOuter = is64 ? 0x30 : 0x18;
		int oName = is64 ? 0x3C : 0x20;
		int oClass = is64 ? 0x40 : 0x24;
		int oStateFrame = 3 * ps;
		int oStateNode = 6 * ps;

		var core = proc.ModulesWow64Safe().FirstOrDefault(m => m.ModuleName.Equals("Core.dll", StringComparison.OrdinalIgnoreCase));
		if (core == null) {
			return false;
		}

		IntPtr objectsArray = FindExport(proc, core, "?GObjObjects@UObject@@");
		IntPtr namesArray = FindExport(proc, core, "?Names@FName@@");
		if (objectsArray == IntPtr.Zero || namesArray == IntPtr.Zero) {
			print("[UT99] Core.dll exports not found");
			return false;
		}
		vars.namesArray = namesArray;

		Func<IntPtr, IntPtr> Ptr = (a) => proc.ReadPointer(a);
		Func<IntPtr, string> ObjName = (o) => o == IntPtr.Zero ? null : NameOf(proc, proc.ReadValue<int>(o + oName));
		Func<IntPtr, IntPtr> ObjClass = (o) => o == IntPtr.Zero ? IntPtr.Zero : Ptr(o + oClass);
		Func<IntPtr, IntPtr> ObjOuter = (o) => o == IntPtr.Zero ? IntPtr.Zero : Ptr(o + oOuter);

		// Resolve the indices of the names we're looking for
		var wanted = new HashSet<string> {
			"Class", "Object", "Actor", "Pawn", "Player", "LevelInfo", "GameInfo", "DeathMatchPlus", "PlayerReplicationInfo",
			"TeamInfo", "TournamentGameReplicationInfo", "GameEngine"
		};
		var nameIndex = new Dictionary<string, int>();
		int namesCount = proc.ReadValue<int>(namesArray + ps);
		byte[] nameEntries = proc.ReadBytes(Ptr(namesArray), namesCount * ps);
		if (nameEntries == null) {
			return false;
		}
		for (int i = 0; i < namesCount && nameIndex.Count < wanted.Count; i++) {
			IntPtr entry = is64 ? (IntPtr) BitConverter.ToInt64(nameEntries, i * ps) : (IntPtr) BitConverter.ToInt32(nameEntries, i * ps);
			if (entry == IntPtr.Zero) continue;
			string name = NameOf(proc, i);
			if (name != null && wanted.Contains(name) && !nameIndex.ContainsKey(name)) {
				nameIndex[name] = i;
			}
		}
		if (nameIndex.Count < wanted.Count) {
			print("[UT99] Missing names: " + string.Join(", ", wanted.Where(w => !nameIndex.ContainsKey(w))));
			return false;
		}

		// Walk every object once to find the classes and the GameEngine instance
		int objectsCount = proc.ReadValue<int>(objectsArray + ps);
		byte[] objectEntries = proc.ReadBytes(Ptr(objectsArray), objectsCount * ps);
		if (objectEntries == null) {
			return false;
		}
		var objects = new List<IntPtr>();
		var objectNames = new List<int>();
		var objectClasses = new List<IntPtr>();
		IntPtr classClass = IntPtr.Zero;
		for (int i = 0; i < objectsCount; i++) {
			IntPtr o = is64 ? (IntPtr) BitConverter.ToInt64(objectEntries, i * ps) : (IntPtr) BitConverter.ToInt32(objectEntries, i * ps);
			if (o == IntPtr.Zero) continue;
			byte[] header = proc.ReadBytes(o + oName, oClass - oName + ps);
			if (header == null) continue;
			int name = BitConverter.ToInt32(header, 0);
			IntPtr cls = is64 ? (IntPtr) BitConverter.ToInt64(header, oClass - oName) : (IntPtr) BitConverter.ToInt32(header, oClass - oName);
			objects.Add(o);
			objectNames.Add(name);
			objectClasses.Add(cls);
			if (cls == o && name == nameIndex["Class"]) {
				classClass = o; // Core.Class is its own class
			}
		}
		if (classClass == IntPtr.Zero) {
			return false;
		}

		var classes = new Dictionary<string, IntPtr>();
		for (int i = 0; i < objects.Count; i++) {
			if (objectClasses[i] != classClass) continue;
			foreach (var kv in nameIndex) {
				if (kv.Value == objectNames[i] && !classes.ContainsKey(kv.Key)) {
					classes[kv.Key] = objects[i];
				}
			}
		}
		foreach (var c in new[] { "Object", "Actor", "Pawn", "Player", "LevelInfo", "GameInfo", "DeathMatchPlus", "PlayerReplicationInfo", "TeamInfo", "TournamentGameReplicationInfo", "GameEngine" }) {
			if (!classes.ContainsKey(c)) {
				print("[UT99] Class not loaded yet: " + c);
				return false;
			}
		}

		IntPtr engine = IntPtr.Zero;
		for (int i = 0; i < objects.Count; i++) {
			if (objectClasses[i] == classes["GameEngine"]) {
				engine = objects[i];
				break;
			}
		}
		if (engine == IntPtr.Zero) {
			return false;
		}

		// DeepPointer needs a static address holding the engine pointer: UnrealTournament.exe keeps one in a global variable
		// (0x37E70 in v469e, 0x33800 in v469f RC6). We find it by searching the module's memory for the engine's address.
		var exe = proc.ModulesWow64Safe().First(m => m.ModuleName.Equals("UnrealTournament.exe", StringComparison.OrdinalIgnoreCase));
		int enginePtrOffset = -1;
		for (int page = 0; page < exe.ModuleMemorySize && enginePtrOffset < 0; page += 0x1000) {
			byte[] bytes = proc.ReadBytes(exe.BaseAddress + page, 0x1000);
			if (bytes == null) continue;
			for (int o = 0; o + ps <= bytes.Length; o += ps) {
				long v = is64 ? BitConverter.ToInt64(bytes, o) : BitConverter.ToUInt32(bytes, o);
				if (v == (long) engine) { enginePtrOffset = page + o; break; }
			}
		}
		if (enginePtrOffset < 0) { print("[UT99] Static GameEngine pointer not found in UnrealTournament.exe"); return false; }

		// UField::SuperField follows the UObject header: in the Pawn class, it points to the Actor class.
		IntPtr pawnClass = classes["Pawn"];
		int oSuper = -1;
		for (int o = oClass + ps; o <= oClass + 8 * ps; o += ps) {
			if (Ptr(pawnClass + o) == classes["Actor"]) { oSuper = o; break; }
		}
		if (oSuper < 0) { print("[UT99] UField::SuperField not found"); return false; }
		int oNext = oSuper + ps;

		// UStruct::Children: the head of the linked list of fields (properties, functions, states) declared by the class.
		Func<IntPtr, int, string, bool> ChainContains = (cls, oHead, fieldName) => {
			IntPtr f = Ptr(cls + oHead);
			for (int guard = 0; f != IntPtr.Zero && guard < 4096; guard++) {
				if (ObjOuter(f) != cls) return false;
				if (ObjName(f) == fieldName) return true;
				f = Ptr(f + oNext);
			}
			return false;
		};
		int oChildren = -1;
		for (int o = oNext + ps; o < 0x100; o += ps) {
			if (ChainContains(pawnClass, o, "GroundSpeed")) { oChildren = o; break; }
		}
		if (oChildren < 0) { print("[UT99] UStruct::Children not found"); return false; }

		Func<IntPtr, string, IntPtr> FindField = (cls, fieldName) => {
			for (; cls != IntPtr.Zero; cls = Ptr(cls + oSuper)) {
				IntPtr f = Ptr(cls + oChildren);
				for (int guard = 0; f != IntPtr.Zero && guard < 4096; guard++) {
					if (ObjName(f) == fieldName) return f;
					f = Ptr(f + oNext);
				}
			}
			return IntPtr.Zero;
		};

		// UProperty::Offset: the Object.Outer and Object.Class properties mirror the UObject header, so their offsets are known.
		IntPtr outerProp = FindField(classes["Object"], "Outer");
		IntPtr classProp = FindField(classes["Object"], "Class");
		int oPropOffset = -1;
		for (int o = oNext + ps; o < 0x100; o += 4) {
			if (proc.ReadValue<int>(outerProp + o) == oOuter && proc.ReadValue<int>(classProp + o) == oClass) { oPropOffset = o; break; }
		}
		if (oPropOffset < 0) { print("[UT99] UProperty::Offset not found"); return false; }

		Func<string, string, int> Off = (className, propName) => {
			IntPtr prop = FindField(classes[className], propName);
			if (prop == IntPtr.Zero) throw new Exception("Property not found: " + className + "." + propName);
			return proc.ReadValue<int>(prop + oPropOffset);
		};

		// UBoolProperty::BitMask: bBehindView and bIsPlayer share the same 32-bit word but use different bits.
		IntPtr behindViewProp = FindField(pawnClass, "bBehindView");
		IntPtr isPlayerProp = FindField(pawnClass, "bIsPlayer");
		uint behindViewMask = 0;
		for (int o = oPropOffset + 4; o < oPropOffset + 0x60; o += 4) {
			uint a = proc.ReadValue<uint>(behindViewProp + o), b = proc.ReadValue<uint>(isPlayerProp + o);
			if (a != 0 && b != 0 && a != b && (a & (a - 1)) == 0 && (b & (b - 1)) == 0) { behindViewMask = a; break; }
		}
		if (behindViewMask == 0) { print("[UT99] UBoolProperty::BitMask not found"); return false; }

		// UEngine::Client is a native-only member in UT: it's the pointer to the *Client object.
		int oClient = -1;
		for (int o = oClass + ps; o < 0x200; o += ps) {
			string cn = ObjName(ObjClass(Ptr(engine + o)));
			if (cn != null && cn.EndsWith("Client")) { oClient = o; break; }
		}
		if (oClient < 0) { print("[UT99] UEngine::Client not found"); return false; }

		// UClient::Viewports is a native TArray: its first element is a *Viewport object owned by the client.
		IntPtr client = Ptr(engine + oClient);
		int oViewports = -1;
		for (int o = oClass + ps; o < 0x200; o += ps) {
			IntPtr data = Ptr(client + o);
			if (data == IntPtr.Zero) continue;
			IntPtr viewport = Ptr(data);
			string cn = ObjName(ObjClass(viewport));
			if (cn != null && cn.EndsWith("Viewport") && ObjOuter(viewport) == client) { oViewports = o; break; }
		}
		if (oViewports < 0) { print("[UT99] UClient::Viewports not found (no viewport yet?)"); return false; }

		int oActor = Off("Player", "Actor");
		int oLevel = Off("Actor", "Level");
		int oTitle = Off("LevelInfo", "Title");
		int oTimeSeconds = Off("LevelInfo", "TimeSeconds");
		int oGame = Off("LevelInfo", "Game");
		int oGameName = Off("GameInfo", "GameName");
		int oGRI = Off("GameInfo", "GameReplicationInfo");
		int oRemainingTime = Off("DeathMatchPlus", "RemainingTime");
		int oElapsedTime = Off("DeathMatchPlus", "ElapsedTime");
		int oPRI = Off("Pawn", "PlayerReplicationInfo");
		int oGroundSpeed = Off("Pawn", "GroundSpeed");
		int oJumpZ = Off("Pawn", "JumpZ");
		int oAirControl = Off("Pawn", "AirControl");
		int oBehindView = Off("Pawn", "bBehindView");
		int oPlayerScore = Off("PlayerReplicationInfo", "Score");
		int oTeamScore = Off("TeamInfo", "Score");
		int oTeams = Off("TournamentGameReplicationInfo", "Teams");
		int oGoalTeamScore = Off("TournamentGameReplicationInfo", "GoalTeamScore");
		int oFragLimit = Off("TournamentGameReplicationInfo", "FragLimit");
		int oTimeLimit = Off("TournamentGameReplicationInfo", "TimeLimit");

		// Parent addresses table (all paths start at "UnrealTournament.exe", enginePtrOffset, which is the UGameEngine):
		// oClient:													Pointer to UWindowsClient
		// oClient, oViewports, 0x0:								Pointer to UWindowsViewport
		// oClient, oViewports, 0x0, oActor:						Pointer to APlayerPawn
		// ... oActor, oLevel:										Pointer to ALevelInfo
		// ... oActor, oLevel, oGame:								Pointer to AGameInfo
		// ... oActor, oLevel, oGame, oGRI:							Pointer to ATournamentGameReplicationInfo
		// ... oActor, oLevel, oGame, oGRI, oTeams:					Pointer to ATeamInfo (Team 0 info)
		// ... oActor, oPRI:										Pointer to APlayerReplicationInfo
		// ... oActor, oLevel, oOuter:								Pointer to the map's package (its name is the map name)
		Func<int[], DeepPointer> FromPawn = (offsets) => new DeepPointer("UnrealTournament.exe", enginePtrOffset, new[] { oClient, oViewports, 0x0, oActor }.Concat(offsets).ToArray());

		var watchers = new MemoryWatcherList {
			new StringWatcher(FromPawn(new[] { oLevel, oTitle, 0x0 }), ReadStringType.UTF16, 512) { Name = "localizedLevelName" },
			new MemoryWatcher<float>(FromPawn(new[] { oLevel, oTimeSeconds })) { Name = "timeSeconds" },
			new StringWatcher(FromPawn(new[] { oLevel, oGame, oGameName, 0x0 }), ReadStringType.UTF16, 512) { Name = "localizedGamemodeName" },
			new MemoryWatcher<float>(FromPawn(new[] { oAirControl })) { Name = "airControl" },
			new MemoryWatcher<float>(FromPawn(new[] { oJumpZ })) { Name = "jumpZ" },
			new MemoryWatcher<int>(FromPawn(new[] { oStateFrame, oStateNode, oName })) { Name = "playerPawnStateName" },
			new MemoryWatcher<uint>(FromPawn(new[] { oBehindView })) { Name = "playerPawnViewState" },
			new MemoryWatcher<int>(FromPawn(new[] { oLevel, oOuter, oName })) { Name = "mapNameIndex" },
			new MemoryWatcher<float>(FromPawn(new[] { oGroundSpeed })) { Name = "playerGroundSpeed" },
			new MemoryWatcher<int>(FromPawn(new[] { oLevel, oGame, oRemainingTime })) { Name = "remainingTime" },
			new MemoryWatcher<int>(FromPawn(new[] { oLevel, oGame, oElapsedTime })) { Name = "elapsedTime" },
			new MemoryWatcher<float>(FromPawn(new[] { oPRI, oPlayerScore })) { Name = "playerScore" },
			new MemoryWatcher<float>(FromPawn(new[] { oLevel, oGame, oGRI, oTeams, oTeamScore })) { Name = "playerTeamScore" },
			new MemoryWatcher<int>(FromPawn(new[] { oLevel, oGame, oGRI, oGoalTeamScore })) { Name = "gameItemGoals" },
			new MemoryWatcher<int>(FromPawn(new[] { oLevel, oGame, oGRI, oFragLimit })) { Name = "gameKillGoals" },
			new MemoryWatcher<int>(FromPawn(new[] { oLevel, oGame, oGRI, oTimeLimit })) { Name = "gameSecretGoals" }
		};
		// Like the classic state descriptor, a failed read (e.g. no player pawn while loading) gives 0.
		// StringWatcher throws when set to null, so strings keep their last value instead.
		foreach (var w in watchers.Where(x => !(x is StringWatcher))) {
			w.FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
		}
		vars.watchers = watchers;
		vars.behindViewMask = behindViewMask;

		print(string.Format(
			"[UT99] Resolved ({0}-bit). Engine=UnrealTournament.exe+0x{1:X} Client=+0x{2:X} Viewports=+0x{3:X} Actor=+0x{4:X} Level=+0x{5:X} Game=+0x{6:X} GRI=+0x{7:X} " +
			"ElapsedTime=+0x{8:X} PRI=+0x{9:X} bBehindView=+0x{10:X}/0x{11:X} UProperty.Offset=+0x{12:X} UStruct.Children=+0x{13:X}",
			is64 ? 64 : 32, enginePtrOffset, oClient, oViewports, oActor, oLevel, oGame, oGRI, oElapsedTime, oPRI, oBehindView, behindViewMask, oPropOffset, oChildren));
		return true;
	};
	vars.TryResolve = TryResolve;
}

init
{
	// At the script initialization, we check the Unreal Tournament's module hash to try and determine the game's version.
	var module = modules.Single(x => String.Equals(x.ModuleName, "UnrealTournament.exe", StringComparison.OrdinalIgnoreCase));
	var hash = vars.CalcModuleHash(module);

	vars.unknownBuild = false;
	vars.resolutionFailures = 0;
	vars.compatibilityWarningShown = false;
	Tuple<string, bool> build;

	string knownVersion;
	if (vars.knownVersions.TryGetValue(hash, out build)) {
		version = build.Item1;
		print("[UT99] Detected version: " + version);

		if (!build.Item2)
		{
			vars.compatibilityWarningShown = true;

			if (MessageBox.Show(
				"You are running Unreal Tournament " + version + ", which is not supported by this autosplitter.\n\n" +
				"Please update to OldUnreal v469c or newer.\n\n" +
				"Would you like to open the OldUnreal download page?",
				"UT99 Autosplitter",
				MessageBoxButtons.YesNo,
				MessageBoxIcon.Warning
			) == DialogResult.Yes)
			{
				System.Diagnostics.Process.Start(
					"https://github.com/OldUnreal/UnrealTournamentPatches/releases"
				);
			}
		}
	} else {
		// Unknown build: attempt dynamic resolution.
    	// Warn after 10 failed resolution attempts.
		vars.unknownBuild = true;
		version = "Unknown " + (game.Is64Bit() ? "64-bit" : "32-bit") + " build";
		print("[UT99] Unknown build (SHA-256: " + hash + "). Attempting dynamic offset resolution.");
	}

	// Offsets are resolved in update, as the engine might still be starting up at this point.
	vars.ready = false;
	vars.nextResolveAttempt = DateTime.MinValue;

	current.localizedLevelName = "";
	current.timeSeconds = 0f;
	current.localizedGamemodeName = "";
	current.airControl = 0f;
	current.jumpZ = 0f;
	current.playerPawnState = "";
	current.isBehindView = false;
	current.mapName = "";
	current.playerGroundSpeed = 0f;
	current.remainingTime = 0;
	current.elapsedTime = TimeSpan.FromSeconds(0);
	current.playerScore = 0f;
	current.playerTeamScore = 0f;
	current.gameItemGoals = 0;
	current.gameKillGoals = 0;
	current.gameSecretGoals = 0;
}

update
{
	if (!vars.ready) {
		if (DateTime.Now < vars.nextResolveAttempt) {
			return false;
		}

		vars.nextResolveAttempt = DateTime.Now.AddSeconds(1);

		try {
			var sw = System.Diagnostics.Stopwatch.StartNew();
			vars.ready = vars.TryResolve(game);
			print("[UT99] Offset resolution " + (vars.ready ? "succeeded" : "not ready yet") + " (" + sw.ElapsedMilliseconds + " ms)");
		} catch (Exception e) {
			print("[UT99] Offset resolution failed: " + e.Message);
		}

		if (!vars.ready && vars.unknownBuild && !vars.compatibilityWarningShown)
		{
			vars.resolutionFailures++;

			if (vars.resolutionFailures >= 10)
			{
				vars.compatibilityWarningShown = true;

				if (MessageBox.Show(
					"This build of Unreal Tournament is not recognized, and the autosplitter failed to initialize after 10 attempts.\n\n" +
					"Your game version may not be compatible. Please use a supported OldUnreal build (v469c or newer).\n\n" +
					"Would you like to open the OldUnreal download page?",
					"UT99 Autosplitter",
					MessageBoxButtons.YesNo,
					MessageBoxIcon.Warning
				) == DialogResult.Yes)
				{
					System.Diagnostics.Process.Start(
						"https://github.com/OldUnreal/UnrealTournamentPatches/releases"
					);
				}
			}
		}

		if (!vars.ready) {
			return false;
		}
	}

	// Reading the current state
	// localizedLevelName: 		"ITV Oblivion", "ITV oubli", etc.
	// timeSeconds:				time elapsed since the map has finished loading (real-time).
	// localizedGamemodeName: 	"Tournament DeathMatch", "Tournoi Combat à Mort", etc.
	// airControl: 				player's air control value in percentage (%). Will be 1 if under the AntiGrav boots effect. Previously used as an anti-cheat experimental feature.
	// jumpZ:					player's jump height value. Default is 325, or 357,5 if in Hardcore mode. Will be 975 under the AntiGrav boots effect. Previously used as an anti-cheat experimental feature.
	// playerPawnState: 		the UnrealScript state the player is in ("PlayerWaiting", "PlayerWalking", "Dying", "GameEnded", "PlayerSwimming", etc.).
	// isBehindView: 			True if the player is in third person (bBehindView).
	// mapName: 				the map name, without extension. "DM-Oblivion", "DM-Peak", etc.
	// playerGroundSpeed: 		the player's speeed on the ground. Default is 400.
	// remainingTime: 			game's remaining time in seconds.
	// elapsedTime: 			game's elapsed time in seconds.
	// playerScore: 			player's score. DOM gamemode's score is decimal, although hidden to the player. This is why it's a float.
	// playerTeamScore: 		player's team score. DOM gamemode's score is decimal, although hidden to the player. This is why it's a float.
	// gameItemGoals: 			score limit in DOM and CTF.
	// gameKillGoals: 			score limit in DM and LDM (Challenge ladder mode).
	// gameSecretGoals: 		usually a time goal in minutes. Will always be 1 in the second part of AS maps, for some reason.
	var w = vars.watchers;
	w.UpdateAll(game);

	current.localizedLevelName = w["localizedLevelName"].Current;
	current.timeSeconds = w["timeSeconds"].Current;
	current.localizedGamemodeName = w["localizedGamemodeName"].Current;
	current.airControl = w["airControl"].Current;
	current.jumpZ = w["jumpZ"].Current;
	current.playerPawnState = vars.NameOf(game, w["playerPawnStateName"].Current);
	current.isBehindView = (w["playerPawnViewState"].Current & vars.behindViewMask) != 0;
	current.mapName = vars.NameOf(game, w["mapNameIndex"].Current);
	current.playerGroundSpeed = w["playerGroundSpeed"].Current;
	current.remainingTime = w["remainingTime"].Current;
	current.elapsedTime = w["elapsedTime"].Current;
	current.playerScore = w["playerScore"].Current;
	current.playerTeamScore = w["playerTeamScore"].Current;
	current.gameItemGoals = w["gameItemGoals"].Current;
	current.gameKillGoals = w["gameKillGoals"].Current;
	current.gameSecretGoals = w["gameSecretGoals"].Current;

	// Many things are happening here:
	// - we count the number of seconds elapsed in game
	// - everytime the player dies, we increment vars.numberOfDeaths by 1. This can lead to an auto-reset if the proper setting is enabled
	// - we update the humanPlayerScore variable by rounding the playerScore or playerTeamScore value, depending on the gamemode
	// - we update the current level prediction time

	// We add 1 second to the in-game timer if the map elapsed time went up by 1, or if the remaining time went down by 1.
    if (current.elapsedTime - old.elapsedTime == 1 || old.remainingTime - current.remainingTime == 1)
    {
        vars.elapsedTime += TimeSpan.FromSeconds(1);
    }

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

	if (current.mapName.StartsWith("DM")) {
		oldScoreToCheck = old.playerScore;
		oldGoalToCheck = old.gameKillGoals;
		scoreToCheck = current.playerScore;
		goalToCheck = current.gameKillGoals;
	}

	if (oldScoreToCheck != scoreToCheck) {
		vars.humanPlayerScore = Math.Truncate(scoreToCheck * 10.0) / 10.0;
		vars.scorePerMin = current.elapsedTime == 0 ? 0 : Math.Truncate((scoreToCheck / current.elapsedTime) * 60 * 10.0) / 10.0;
		var scorePerSecond = vars.scorePerMin == 0 ? 0 : vars.scorePerMin / 60;

		if (current.mapName.StartsWith("DOM")) {
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

	if (current.mapName == null) {
		return false;
	}

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
			// If the defending team has won the match, the player will be in third person view (bBehindView).
			shouldSplit = current.isBehindView;
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
	if (settings["lrt_instead_of_igt"])
		return old.timeSeconds == current.timeSeconds || current.timeSeconds == 0f;

	// Freeze the timer between IGT updates.
	// This is intended! IGT is computed in the gameTime function, not measured in real-time.
	return true;
}

gameTime
{
    if (!settings["lrt_instead_of_igt"])
        return vars.elapsedTime;
}
