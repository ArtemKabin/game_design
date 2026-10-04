# 0011: Levels end with an exit door, a minigame sits between levels

* Date: 2026-10-04
* Status: accepted (minigame design open)
* Participants: both developers

## Context
After solving a level, a "continue" button appeared in the HUD. That breaks the room feeling: the player is in a spaceship, not in a menu.

## Decision
* Solving a level opens an **exit door** at the edge of the room (shared scene `exit_door.tscn`). The camera pans to the door for a moment so the player notices it, then returns. Walking through the door leaves the level.
* Doors are on the **left** side, in line with the left-to-right subversion.
* Between two levels a **small minigame** is played (`transition_minigame.tscn`). Its design is still open; the scene is a placeholder with a continue button. After the minigame the next level starts directly, or the map if that level has no scene yet.
* The map stays as the level-select hub reachable from the main menu.

## Consequences
Every level needs an `ExitDoor` instance and calls `open()` plus a camera pan when solved. The continue buttons are gone. The minigame concept has to be designed and recorded in a follow-up entry.
