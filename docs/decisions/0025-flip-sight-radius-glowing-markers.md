# 0025: FLIP: sight radius shrinks with distance, safe markers glow above the fog

* Date: 2026-10-24
* Status: accepted
* Participants: Person A, Person B

## Context
With virtual holes (0023) and one-world spheres (0024) the player had perfect information about the current world and, without the wall, no reason to ever stop. Running and flipping on time was enough. The core idea "hesitate, then decide" needs something the player does not know and a way to learn it by stopping.

## Decision
A sight radius around the player (`sight_fog.gd`, `sight_fog.gdshader`) hides everything beyond it under the background colour. It starts at its maximum, shrinks with every pixel travelled (distance based, so sprinting blinds faster than walking) and regrows while the player stands still. Values: 340 px max, 90 px min, max to min after about 715 px, min back to max in about 1.1 s of standing. The camera shows about 524 px to each side, so max plus fade must stay below that or the fog is never seen. The radius logic runs in the physics step, because the player only moves on physics ticks. The fog node is a child of the player and follows the world flip colour. Safe-zone markers (`safe_marker.gd`) glow permanently with a pulsing halo and render above the fog, so the player always sees where a stop is safe.

## Consequences
Stopping becomes a tool: it is the only way to see what lies ahead. Safe zones are the visible anchors to plan the next stretch. The constants live in `sight_fog.gd` and are the main tuning knobs for difficulty. The HUD is unaffected (CanvasLayer). Marker art can replace the drawn diamond; the halo stays.
