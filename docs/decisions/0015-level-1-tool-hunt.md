# 0015: Level 1 is a tool hunt that ends with "umfahren" meaning drive around

* Date: 2026-10-04
* Status: superseded by 0016 to 0018 (the cart through the crates stays, tool hunt and tarp gap are gone)
* Participants: both developers

## Context
Level 1 was solved by ramming the crates with the cart. That made "Fahre das Hindernis um" a one-step action and the quarantine cabins were just a trap button. The game is supposed to lead the player on, not test reflexes.

## Decision
The crates block the way to the cargo control panel (the switch for the door to Level 2). The level now plays like this:

1. On entering, the narrator says: there is an obstacle in front of the switch, get a tool. The camera pans to the open quarantine door at the bottom.
2. The quarantine cabins A, B, C, D are real small rooms (`small_room.tscn`). D's exit leads back to A: a loop. D holds a **rubber hammer**.
3. Hitting the crates with the hammer: after three tries the narrator admits it is rubber and a **storage room** opens on the right wall of Level 1. It holds a **crowbar**.
4. Hitting with the crowbar: after three tries the narrator says "Wie ging das noch gleich? Du musst das Hindernis UMFAHREN. Der Wagen steht rechts."
5. The solution: board the cart and **plough straight through the crates**. The hit stack flies apart, the **goal door** in the middle of the left wall opens into the **cargo control room**; flip the switch there. A wall crash with the cart is still game over.
6. The crates are stacked around the goal door with one gap at the bottom right, a little wider than the cart (a tarp asset hangs there later). On foot the tarp jams. The cart fits, but that is the **dead end**: the tarp tangles in the cart, the cart is dead, the goal door stays shut, and on foot nobody gets back through the tarp. No game over; the narrator says the player should have found another way to the switch. The only way out is the **Escape menu** ("Neu starten", back to the bridge with fresh progress).

The joke is the tool hunt itself: hammer and crowbar are useless, the cart that stood there all along does it.

The right-hand bypass trap from the first draft is gone; the level has enough misdirection. The storage room's door is on its left wall, next to Level 1.

## Consequences
`small_room.tscn` is a generic side room with two doors (side configurable) and an optional pickup that can act as a switch (`completes_level`); cabins, storage and the cargo control room are instances configured in `world.tscn`. The player has an inventory (`GameManager.add_item / has_item`). The cart reports what it crashed into, so Level 1 can tell the crates apart from a wall. Nothing in Level 1 breaks the crates; a player who skips the tool hunt and drives around immediately still wins, which is fine.
