# 0026: FLIP: hunter stars that freeze when seen and hunt when unseen

* Date: 2026-10-24
* Status: accepted
* Participants: Person A, Person B

## Context
Holes and spheres punish wrong timing, the sight radius punishes running blind. Nothing yet punishes staying in one world too long or standing still in the wrong place. We wanted a hazard that makes the hidden world itself feel unsafe.

## Decision
Stars (`star.gd`, `star.tscn`) exist in one world, like spheres. In their world they are visible, frozen and deadly on touch. In the other world they are invisible, harmless and walk toward the player at 100 px/s, slower than the player's start speed. Flipping back into the star's world while it stands on the player kills. A star only hunts while it is on screen; once it has been on screen and leaves it (the player outran it), it despawns. Stars are placed in the same chunk type as spheres (`sphere_chunk.gd`, key `stars`) and can be mixed with them.

## Consequences
To pass a star the player must flip to the world where it is hidden, run through it, outrun it, and flip back only when it is behind. Standing still in the hidden world near a star is the new danger, which fits "hesitate, then decide": hesitation has to happen on a safe zone or in the star's visible world. Chase speed and the off-screen margin are constants in `star.gd`. Look is a drawn placeholder. Stars and spheres do not rely on Area2D enter events alone: while deadly they check the overlap with the player geometrically every physics frame, so flipping into a hazard that stands inside the player always kills.
