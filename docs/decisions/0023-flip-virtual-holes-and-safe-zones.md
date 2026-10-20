# 0023: FLIP: virtual holes on a solid floor, safe zones between hazards

* Date: 2026-10-20
* Status: accepted
* Participants: Person A, Person B

## Context
The flip mechanic needs ground and holes that swap on every world flip, except on safe zones. The player has no jump. Real holes (toggling colliders) would need step-up handling: a player who flips a few pixels early falls, and the newly solid segment then stands in front of them as a wall. The old gap chunks with spheres were in fact impassable without a jump.

## Decision
Holes are virtual. Every hazard chunk (`flip_chunk.gd`, built from a pattern string such as `####....####`) has one continuous physics floor that never changes. A hole is only drawn as a gap and covered by an `Area2D` kill zone. On flip, drawing and kill zones swap; the physics stays. Dying in a hole plays a short fall animation (`kill_by_fall`). Kill zones are inset by the player's half width plus a grace of 14 px, so the player may flip while within that distance of a ground/hole boundary. Safe zones (`chunk_safe.tscn`) are flat, never invert and alternate with hazards. The flip cooldown drops to 0.15 s; every pattern run is at least two segments (160 px) long.

## Consequences
No fall physics and no stuck-on-wall cases. Patterns live in `game.gd` as a weighted list; new hazards are one line. The sphere and gap chunk files stay in the repo but are no longer spawned. Restart teleports the player one physics frame before new chunks appear, otherwise a new kill zone could overlap the death position and kill again. Looks are drawn placeholders; segment and marker sprites can replace them without touching the logic.
