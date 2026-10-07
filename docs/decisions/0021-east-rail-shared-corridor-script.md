# 0021: A second cart rail between bridge and hangar, both rails share one script

* Date: 2026-10-08
* Status: accepted
* Participants: both developers

## Context
Level 2 hung directly on the bridge's right door. The cart minigame is the game's connective tissue (0011, 0014), so the way to the final level should be a rail too, and it should not be a copy of the first one.

## Decision
* The **east rail** (`corridor_east.tscn`, room 20) runs **straight from the bridge's right door to the hangar**, with four blocks sticking into the passage alternately from the top and bottom wall: a slalom. Bays at both platforms, same cart, same rules (no brakes, wall is game over, on foot you are zapped back).
* The two rails use **one script**, `rail_corridor.gd` (renamed from `corridor_l.gd`). Scene nodes are named by role (GoalStart, GoalEnd, DoorToStart, DoorToEnd), and the texts and dismount sides are exports set per scene. The west rail scene is now `corridor_west.tscn`.
* Rooms: west rail 10, east rail 20; both get the rail hint after three crashes.

## Consequences
A third rail would be a scene file and nothing else. The hangar moved right to make room (world x = 2800). The slalom was checked headless: driving straight hits the first block, so the obstacles are real; the actual difficulty needs a keyboard.
