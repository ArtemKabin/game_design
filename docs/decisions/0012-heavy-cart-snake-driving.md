# 0012: The heavy cart drives snake-style, the transition minigame is a cart run

* Date: 2026-10-04
* Status: accepted
* Participants: both developers

## Context
In the first Level 1 build the cart was a static prop: stand next to it, press E, done. That is not a mechanic. The transition minigame between levels (0011) had no design yet.

## Decision
One shared cart (`heavy_cart.tscn`) with these rules:

* The player **boards** the cart (E next to it). While inside, the player is the cart (hidden on foot; with assets later the cart sprite is the player).
* The cart has a facing direction. It **starts** when the key of that direction is pressed (faces right → D).
* It **never brakes**. While driving, only the two directions **perpendicular** to the travel direction turn it (driving sideways: W/S; driving up or down: A/D). While it turns, input is ignored until it faces the new direction.
* Hitting a **wall** is **game over** (restart the level or run).
* Hitting an **obstacle** (a `StaticBody2D` in group `obstacle`, like the crates in Level 1) breaks the obstacle; the cart stops and the player gets out and continues on foot.

The **transition minigame** ("Frachtlauf") uses the same cart on a map with many corners: a serpentine of inner walls. Reach the glowing exit zone without touching a wall. It plays like Snake with the cart controls.

## Consequences
Level 1 now has a real failure state (game over on wall crash) and the cart path matters: start facing right, turn up before the right wall, turn left before the top wall, hit the crates. Every room that uses the cart needs its walls as `StaticBody2D` and anything breakable in group `obstacle`. Minigame maps are cheap to make: inner walls plus an exit zone. One map exists; more variants per transition are a later step.
