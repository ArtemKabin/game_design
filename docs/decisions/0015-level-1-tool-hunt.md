# 0015: Level 1 is a tool hunt that ends with "umfahren" meaning drive around

* Date: 2026-10-04
* Status: accepted
* Participants: both developers

## Context
Level 1 was solved by ramming the crates with the cart. That made "Fahre das Hindernis um" a one-step action and the quarantine cabins were just a trap button. The game is supposed to lead the player on, not test reflexes.

## Decision
The crates block the way to the cargo control panel (the switch for the door to Level 2). The level now plays like this:

1. On entering, the narrator says: there is an obstacle in front of the switch, get a tool. The camera pans to the open quarantine door at the bottom.
2. The quarantine cabins A, B, C, D are real small rooms (`small_room.tscn`). D's exit leads back to A: a loop. D holds a **rubber hammer**.
3. Hitting the crates with the hammer: after three tries the narrator admits it is rubber and a **storage room** opens on the right wall of Level 1. It holds a **crowbar**.
4. Hitting with the crowbar: after three tries the narrator says "Wie ging das noch gleich? Du musst das Hindernis UMFAHREN. Der Wagen steht rechts."
5. Primed to destroy the crates, the player rams them with the cart: **game over** ("Umfahren heißt hier nicht überfahren").
6. The actual solution: under the crates is a gap on the cargo rail. Only the cart may use it (on foot the rail zaps you back). Drive **around** the crates, park on the platform, use the panel.

The right-hand bypass trap from the first draft is gone; the level has enough misdirection.

## Consequences
`small_room.tscn` is a generic side room with two doors and an optional pickup; cabins and storage are instances configured in `world.tscn`. The player has an inventory (`GameManager.add_item / has_item`). The cart reports what it crashed into, so Level 1 can tell the crates apart from a wall. Nothing in Level 1 breaks the crates; a player who skips the tool hunt and drives around immediately still wins, which is fine.
