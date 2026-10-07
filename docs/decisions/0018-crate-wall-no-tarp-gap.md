# 0018: The crates are space junk: shove them into the airlock with the cart, a lever jettisons them

* Date: 2026-10-07
* Status: accepted
* Participants: both developers

## Context
The crates in Level 1 formed a box around the goal door with a tarp-covered gap that was a deliberate soft lock (0015), and the solution was to ram them. With the quarantine loop now doing the misdirection (0017), a second trap in the same room was one too many, and ramming was a one-hit action. Pushing by hand (Sokoban style) was considered; the cart was chosen because "Fahre das Hindernis um" keeps its double meaning and the brakeless cart stays the star of the level.

## Decision
* The crates are **space junk**: one long pushable crate (`junk_crate.tscn`, group `pushable`) forming a **straight wall from the top wall to the bottom wall** at x = -300. It cuts the cargo bay in two: cart, rail door and quarantine door on the right, the **airlock** ("Müllschleuse") on the left. No tarp, no gap, no soft lock. One wall instead of several crates: one trip with the cart is enough, the driving is not the puzzle.
* The cart **shoves** the junk it drives into. Junk slides **left only** and stops at the wall, on the airlock field. Then the cart stops and **rolls back to its spot** at the bottom right; the player gets out there. A wall crash with the cart is still game over.
* A **lever at the top of the airlock** jettisons the junk once it stands on the field: the junk slides off and fades, nothing more (a longer hatch-and-stars sequence was tried and dropped as too much). That completes Level 1 and opens the right door on the bridge; the camera flies over to the bridge (`Room.peek_room`, camera limits lifted for the trip) to show that door, then returns. If the junk is not in the airlock, the lever only says so.
* The **goal door and the cargo control room are gone**; the lever replaces the switch. The generic small side room (`small_room.tscn`) and the inventory in `GameManager` were removed with it.

## Consequences
`heavy_cart.gd` knows about pushables: it tests the motion ahead, calls `push()` on the crate, and emits `push_blocked` when the crate cannot move; the level decides what happens then. Level 1 never soft-locks any more; the pause menu's "Neu starten" stays as a general restart. After Level 1 the player drives the rail back to the bridge and continues to Level 2 (still to be built).
