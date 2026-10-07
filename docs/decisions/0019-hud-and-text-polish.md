# 0019: HUD shows only the room title, status text types in and waits to be read, no emojis

* Date: 2026-10-08
* Status: accepted
* Participants: both developers

## Context
The HUD repeated the game title in every room, status lines flashed by when several events fired in a row, door labels said "AUSGANG" under every door, and emojis in buttons and titles looked out of place in the ship.

## Decision
* The header shows **only the room title** ("LEVEL 0: BRÜCKE", "FRACHTSCHIENE", ...). The game title lives in the main menu.
* The yellow status line **types in letter by letter** and then **stays for a reading time** (two seconds plus a little per character) before the next text replaces it. Only the newest waiting text is kept, so a burst of events shows the last one, not a backlog. Implemented in `world.gd`; rooms keep calling `set_status()` as before.
* **No emojis anywhere**, no "AUSGANG" under doors, no "Gehe heran & drücke E" under the vent, no map hint in the controls line (Tab/M still works).
* The rail corridor got **bays at both platforms** (340 px tall instead of 220) so there is room around the parked cart, and the three **stubs are bigger** (90 px into the 220 px passage) so the drive is not trivial.

## Consequences
A status text can lag behind the game by a few seconds when events come thick and fast; game over has its own panel, so it is never delayed. Texts should stay short.
