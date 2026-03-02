# UT99Autosplitter

This is a simple LiveSplit ASL script for Unreal Tournament (1999) speedrunning. So far, it only works with the **PC version 469e - Release** of the game.
You can download the latest release version of the game on the [OldUnreal's website](https://www.oldunreal.com/downloads/unrealtournament/full-game-installers/), or download the latest community patch on the [OldUnreal's GitHub page](https://github.com/OldUnreal/UnrealTournamentPatches/releases).

> [!NOTE]
> If you're not running the latest release version of the game, the autosplitter will prompt you to update your game.

## Installation

> [!TIP]
> Make sure you have installed the [latest version of LiveSplit](https://livesplit.org/downloads/).

Simply download the [ut99-autosplitter.asl file](https://github.com/MrCodeMUN/UT99Autosplitter/blob/main/ut99-autosplitter.asl).

After that, right click your splits and select **Edit Layout... > (+) > Control > Scriptable Auto splitter**. Then double click the **Scriptable Auto splitter** component, select **Browse** and choose the previously downloaded file. If no option appear, it means the script initialization has failed. Make sure you have the latest version of LiveSplit installed.

## Features

> [!NOTE]
> Some features won't properly work in practice sessions, as the autosplitter is tailored for ladder mode.

### Auto-start

By default, the autosplitter will auto-start the timer at the beginning of any level (right after spawning in the level). It can also auto-start at the beginning of a specific level, which can be specified in the autosplitter's settings.

### Auto-split

By default, the autosplitter will auto-split the timer at the end of any level, only if the player is victorious. It can also auto-split at the end of a specific level, which can be specified in the autosplitter's settings.

### Auto-reset

By default, if the 'Reset' checkbox is checked, the autosplitter will auto-reset the timer at the beginning of any level (when the "Waiting for ready players" screen is active). This is only useful if you are attempting a speedrun on a single level. However, it can also auto-reset at the beginning of a specific level, which can be specified in the autosplitter's settings.

### In-game time

The autosplitter is able to compute the total time spent in any level. You will no longer have to manually add up all of the in-game times after the completion of a run!

### Experimental: game style glitch recognition

If the corresponding setting is enabled, the script is able to deactivate itself if it thinks the player is not following the rules as mentionned on the [Unreal Tournament (1999)'s speedrun.com page](https://www.speedrun.com/ut99?h=Full_Game_Novice-PCMacLinux&rules=category&x=wdmz8952-wlexp148.81wrdvol). This is an optional setting.

## Setting up the autosplitter

Double clicking the **Scriptable Auto splitter** component in your layout editor will bring the settings window. If no option appear, it means the script initialization has failed. Make sure you have the latest version of LiveSplit installed. By default, the script will:

- auto-start and auto-reset at the beginning of the ITV Oblivion level
- auto-split at the end of every level if you are victorious

This works well with the **Full Game** category and the **DM** category, the two most popular categories on speedrun.com. Read below if you want to attempt other categories.

> [!CAUTION]
> If no checkboxes are checked **for specific levels**, but you still have the `Start` or `Reset` option checked, the timer will start/reset automatically at the start of **ANY** level.

### No splits

If you have no splits and just want to start and end the timer according to the category you are running, I recommend the following settings:

- check the **Auto-start at the start of a specific level** and the **Auto-reset at the start of a specific level** and select **the first level of your run** (either ITV Oblivion, Condemned, Niven, Frigate or Phobos). If you are attempting a single level run, leave these options unchecked
- check the **Auto-split at the end of a specific level** option and select **the last level of your run** (either The Peak Monastery, Metal Dream, November Sub Pen, Orbital Station #12, Operation Overlord or HyperBlast). If you are attempting a single level run, leave this option unchecked

### Full Game splits (Standard ladder)

#### Split by level

If you are attempting a **Full Game (Standard)** run and want to split at the end of each level, you are already set! This is the default script behaviour. But just in case, I recommend the following settings:

- check the **Auto-start at the start of a specific level** and the **Auto-reset at the start of a specific level** and select **ITV Oblivion**
- leave the **Auto-split at the end of a specific level** option unchecked

#### Split by gamemode

If you are attempting a **Full Game (Standard)** run and want to split at the end of each gamemode ladder, I recommend the following settings:

- check the **Auto-start at the start of a specific level** and the **Auto-reset at the start of a specific level** and select **ITV Oblivion**
- check the **Auto-split at the end of a specific level** option and select **The Peak Monastery**, **Metal Dream**, **November Sub Pen**, **Operation Overlord** and **HyperBlast**

You can also select **Fractal Reactor**, **Cryptic** and **Eternal Caves** if you want to split after unlocking a specific gamemode ladder.

### Full Game splits (GOTY ladder)

#### Split by level

If you are attempting a **Full Game (GOTY)** run and want to split at the end of each level, you are already set! This is the default script behaviour. But just in case, I recommend the following settings:

- check the **Auto-start at the start of a specific level** and the **Auto-reset at the start of a specific level** and select **ITV Oblivion**
- leave the **Auto-split at the end of a specific level** option unchecked

#### Split by gamemode

If you are attempting a **Full Game (GOTY)** run and want to split at the end of each gamemode ladder, I recommend the following settings:

- check the **Auto-start at the start of a specific level** and the **Auto-reset at the start of a specific level** and select **ITV Oblivion**
- check the **Auto-split at the end of a specific level** option and select **The Peak Monastery**, **Metal Dream**, **Orbital Station #12**, **Operation Overlord** and **HyperBlast**

You can also select **Fractal Reactor**, **Cryptic** and **Eternal Caves** if you want to split after unlocking a specific gamemode ladder.

### DM / DOM / CTF / Assault / Challenge

If you are attempting a **gamemode ladder** run and want to split at the end of each level, I recommend the following settings:

- check the **Auto-start at the start of a specific level** and the **Auto-reset at the start of a specific level** and select **the first level of your run** (either ITV Oblivion, Condemned, Niven, Frigate or Phobos)
- leave the **Auto-split at the end of a specific level** option unchecked

### Single level

If you are attempting a **single level** run, I recommend the following settings:

- uncheck the **Auto-start at the start of a specific level** and the **Auto-reset at the start of a specific level** options
- leave the **Auto-split at the end of a specific level** option unchecked

### In-game time

To display the in-game time, simply add a **Timer** (**Edit Layout... > (+) > Timer > Timer**), then double click the newly added **Timer** and change the **Timing Method** to **Game Time**.

### Extra options

For extra challenge, you can also check the **No death challenge** option. This will auto-reset the timer if you ever die during your run.

You can also check the **Disable autosplitter if the Game Style glitched is used** option. This will disable the autosplitter if the game speed is not set to 100%, if the air control is not set to 35% and if the game style is not set to 'Hardcore'.

## Have any issues?

If you have any trouble running the autosplitter properly, simply open an issue on the project's GitHub page, or send me a message on Discord. You can either add me (username **codem**) or ping me in the [Unreal Speedrunning Discord server](https://discord.gg/ReRRcSJ).

Also, if you wish to update the script so it can work for other versions, feel free to contact me or create a pull request. I'll be happy to share my knowledge and Cheat Engine table.

## Special thanks

- **liveth**, **/u/Envian**, **Driver** and **ISO2768mK** for their autosplitters (**Quake III Arena**, **UT2k4** and **Horizon Forbidden West**)
- **Stephen Chapman** for his [Cheat Engine tutorial playlist](https://www.youtube.com/playlist?list=PLNffuWEygffbbT9Vz-Y1NXQxv2m6mrmHr)
- **href404** and **zackan** for their help beta testing the script and their continuous support
- the **Unreal speedrunning community**, go checkout their [Discord server](https://discord.gg/ReRRcSJ)!
