# UT99Autosplitter

This is a simple **LiveSplit ASL script** for **Unreal Tournament (1999)** speedrunning. So far, it only works with **version 469e - Release** of the game.
You can download the latest release version of the game on the [OldUnreal's website](https://www.oldunreal.com/downloads/unrealtournament/full-game-installers/), or download the latest community patch on the [OldUnreal's GitHub page](https://github.com/OldUnreal/UnrealTournamentPatches/releases).

> [!NOTE]
> If you're not running the latest release version of the game, the autosplitter will prompt you to update your game.

## Installation

Simply download the `ut99-autosplitter.asl` file. In your LiveSplit layout editor, add the `Scriptable Auto splitter` component and link the script to it.

## Settings

You can customize whenever you want to split during the run. By **default**, the timer will **split at the end of each level**.
If you prefer to only split on a specific level, you can use the `Auto-split on a specific level` option in the settings.
Simply check the box according to the levels you want to split on.

If the `Start` checkbox is checked, you can choose the level you wish to auto-start timer on. Simply check the `Auto-start on a specific level` checkbox corresponding to your level. Same thing applies to auto-reset.
By **default**, the timer will start and reset **at the start of the "ITV Oblivion" level**.

> [!CAUTION]
> If no checkboxes are checked **for specific levels**, but you still have the `Start` or `Reset` option checked, the timer will start/reset automatically at the start of **ANY** level.

## Features

The script implements the following features:

- auto-start right after spawning in any or a specific customizable level
- auto-split after a match has ended, either at the end of each level or at the end of a gamemode ladder (customizable in settings)
- auto-reset while on the "Waiting for ready players" screen in any or a specific customizable level
- in-game time

> [!NOTE]
> The auto-reset feature won't properly work in practice sessions.

## What is coming

Right now, the following features aren't implemented, and will hopefully be part of future releases of the script:

- check for victory before splitting
- stop updating the timer if game speed is not 100%, if game style is not Hardcore and if air strafing is not 35%.

## Have any issues?

If you have any trouble running the autosplitter properly, simply open an issue on the project's GitHub page, or send me a message on Discord. You can either add me (username **codem**) or ping me in the [Unreal Speedrunning Discord server](https://discord.gg/ReRRcSJ).

Also, if you wish to update the script so it can work for other versions, feel free to contact me or create a pull request. I'll be happy to share my knowledge and Cheat Engine table.
