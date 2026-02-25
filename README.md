# UT99Autosplitter

This is a simple LiveSplit ASL script for Unreal Tournament 99 speedrunning. So far, it has only be tested with version 469e - Release of the game.

## Features

The script implements the following features:

- auto-start after spawning in any map
- auto-split after a match has ended
- auto-reset while on the "Waiting for ready players" screen

I would advise only using the auto-reset feature if you intend to speedrun a single level.

This script currenlty works for:

- DM splits per level
- DOM splits per level
- CTF splits per level
- AS splits per level
- Challenge splits per level
- Single level

## Downsides

At the moment, this script isn't able to:

- track the completed levels in a run: it will split everytime you finish a level, even if you finish the same level twice
- check for victory: the script will split at the end of every match, even after a defeat

## How to use

Simply download the "ut99-autosplitter.asl" file. In your LiveSplit layout editor, add the "Scriptable Auto splitter" component and link the script to it. Uncheck the "Reset" box if you're not attempting a single level speedrun.

## What is coming

In the future, I'd like to implement the following features:

- allow players to split per gamemode instead of splitting per single levels
- better autoreset
- check for victory
- remove loading times / compute in-game time on the fly
