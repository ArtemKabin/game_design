# 0024: FLIP: spheres exist in one world only, patrol chunks, no back wall

* Date: 2026-10-20
* Status: accepted (replaces the wall part of 0022)
* Participants: Person A, Person B

## Context
The spheres from the first prototype were platforms in one world and lethal in the other, and floated above the player's head, which no longer fits the virtual-hole mechanic (0023). The back wall from 0022 punished hesitation but made standing still feel like a random death.

## Decision
A sphere (`sphere.tscn`) exists in exactly one world, chosen per sphere (`in_dark_world`). In that world it is visible and kills on touch; in the other world it is invisible and inert. Spheres sit at player height on a floor that is solid in both worlds, so the player passes them by being in the other world. A sphere may patrol: from its start it moves `patrol_distance` px (negative = left) and back at a constant `patrol_speed`. Sphere chunks (`sphere_chunk.gd`) are defined as entries in the hazard pool in `game.gd` next to the hole patterns. The back wall is removed entirely: no wall node, no wall kill.

## Consequences
Hesitation is free; pressure comes only from the speed ramp. The hazard pool mixes holes and spheres by weight, so both can be tuned in one list. `wall.gd` is deleted. The old gap chunks (`chunk_gap_*.tscn`) still reference removed sphere properties and must not be spawned; they are candidates for deletion.
