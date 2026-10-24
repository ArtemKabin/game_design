# 0027: FLIP: one hazard chunk type, three floor kinds, hazards on any floor

* Date: 2026-10-24
* Status: accepted
* Participants: Person A, Person B

## Context
Holes lived in one chunk type, spheres and stars in another, so a chunk could not combine "floor that exists in only one world" with hunters or spheres. We want chunks that chain several decisions.

## Decision
There is one hazard chunk (`flip_chunk.gd`). Its floor pattern has three characters: `#` ground only in white, `.` ground only in black, `=` ground in both worlds. Spheres and stars are placed on the same chunk by chunk-local x. A hazard must stand on ground of the world where it is hidden (usually `=`), otherwise the chunk is impassable; the chunk warns about such placements at build time. `=` segments are drawn with a dotted top edge so the player can read them as "safe to flip here". The separate sphere chunk is deleted; all pool entries are patterns in `game.gd`, now 28 of them including combinations.

## Consequences
Every hazard in the game is one line in the pool. Combinations create forced sequences (flip here, not there) and put the hunters exactly where hesitation happens, at hole edges. Content tuning is a matter of editing strings and weights.
