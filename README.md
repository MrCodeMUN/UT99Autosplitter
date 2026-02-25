# UT99Autosplitter

This is a simple LiveSplit ASL script for Unreal Tournament 99 speedrunning. So far, it has only be tested with version 469e - Release of the game.

## Installation

Simply download the "ut99-autosplitter.asl" file. In your LiveSplit layout editor, add the "Scriptable Auto splitter" component and link the script to it. Uncheck the "Reset" box if you're not attempting a single level speedrun.

## Settings

You can customize whenever you want to split during the run. By default, the timer will be split at the end of each level.
If you prefer to only split at the end of a gamemode ladder (just before triggering the trophy room cinematic), you can use the "Gamemode ladder splits" option in the settings.
Simply check the box according to the ladder version you are attempting (either standard or GOTY ladder).

## Features

The script implements the following features:

- auto-start after spawning in any map
- auto-split after a match has ended, either at the end of each level or at the end of a gamemode ladder (customizable in settings)
- auto-reset while on the "Waiting for ready players" screen

I would advise only using the auto-reset feature if you intend to speedrun a single level.

## Downsides

At the moment, this script isn't able to:

- track the completed levels in a run: it will split everytime you finish a level, even if you finish the same level twice
- check for victory: the script will split at the end of every match, even after a defeat

## What is coming

In the future, I'd like to implement the following features:

- better autoreset
- check for victory
- remove loading times / compute in-game time on the fly
