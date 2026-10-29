# 0028: FLIP: help screen with the story and tips that unlock through deaths

* Date: 2026-10-30
* Status: accepted
* Participants: Person A, Person B

## Context
FLIP explains nothing before the first run. The game-over text names the cause of death in two lines, but there is no place that says why the corridor exists, what the two lanterns are, or how the ghosts work. New players die to the hunter without knowing that his sound is the warning. We also want a small storyline instead of a bare mechanic.

## Decision
A HILFE entry in the main menu and in the pause menu opens one overlay (`help_menu.tscn`, `help_menu.gd`): the story in six lines (lost in the woods, an abandoned hotel, two lanterns from the wall that show different corridors), then a list of tips.

Three tips are always visible: the flip key, lanterns mark safe floor, the light shrinks while running. Four more are locked and show as `? ? ?` until the player dies in the matching way: a hole unlocks the hole tip, a ghost the ghost tip, the hunter the hunter tip, and any death while sprinting (above 1.5 times the auto speed) unlocks the sprint tip on top. `game.gd` unlocks through `Settings.unlock_tip`, which persists the ids in `user://settings.cfg`, so the help grows per browser and stays across sessions. The game-over screen adds "Neuer Tipp in der Hilfe!" when something was unlocked; the hunter death prints its tip directly, because the sound cue cannot be guessed.

## Consequences
The first run is as blind as before; that is intended (hesitation is the game). Each death teaches exactly one thing and points to the help, which is where the story lives, so players read the story when they look for the tip. Tips are one dictionary entry each in `help_menu.gd`; adding a new cause of death means one `_unlock_tips("id")` call and one entry.
