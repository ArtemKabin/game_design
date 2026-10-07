# 0017: Quarantine cabins are airport queues with a station, and the loop ends on the bridge

* Date: 2026-10-07
* Status: accepted
* Participants: both developers

## Context
The four quarantine cabins were empty 600x400 boxes with two doors; D led back to A. Walking through them took seconds and the "loop" was just a text line. The cabins should cost the player something and the loop should hurt.

## Decision
* Each cabin (`quarantine_cabin.tscn`, 900x400) is an **airport-style queue**: five barrier tapes alternate from the top and bottom wall, so the player slaloms through six lanes.
* In the middle lane sits a **station** (A: disinfect hands, B: take temperature, C: fill in a form, D: swab). **The exit opens only once it is used** (E), and the door the player came through **stays locked for good**: no turning back once inside.
* A, B, C, D chain left to right. **D's exit leads to a new door at the bottom of the bridge (Level 0)**, not back to A. That door is a one-way airlock: from the bridge it only shows a message. The player has to drive the cargo rail again to get back to the cargo bay. The cart is brought back to the bridge platform when the player enters the rail from the bridge while the cart still waits below.
* **The tool hunt is gone**: no rubber hammer, no crowbar, no "Beschaffe ein Werkzeug". The cabins are the bait on their own: "umfahren" sounds like going around, and the open cabins look like the way around. Level 1's instruction is now simply "Fahre das Hindernis um"; hitting the crates by hand three times triggers the "UMFAHREN" hint and the camera pan to the cart.

## Consequences
The generic small side room and the inventory in `GameManager` are no longer needed (0018 removes the cargo control room too). Decision 0015 is superseded in its tool-hunt part; crates and cart stay, reworked in 0018. The cabins sit in a row below the deck, from under the cargo bay to under the bridge; on the map there is a vertical gap between D and the bridge door, which is acceptable (doors teleport anyway). Station labels and texts are per-instance exports in `world.tscn`, so a cabin's chore can be changed without touching the scene.
