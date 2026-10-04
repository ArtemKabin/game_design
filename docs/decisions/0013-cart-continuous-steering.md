# 0013: The cart steers continuously with A/D and always starts facing up

* Date: 2026-10-04
* Status: accepted (replaces the control scheme in 0012; everything else in 0012 stays)
* Participants: both developers

## Context
The snake-style 90-degree turns from 0012 felt too mechanical, and the "which keys are allowed right now" rule was hard to explain. The first cart-run map was also too easy.

## Decision
* The cart **always starts facing up**. **W** starts it.
* It never brakes. While driving, **A steers left and D steers right continuously** (180 degrees per second). Curves have a radius, so the player really has to drive, not just pick directions.
* Speed raised from 160 to 220 pixels per second.
* The cart-run map got harder: three barriers forming a serpentine plus short stubs that stick into the passages, and the **exit is at the top** of the map.
* In Level 1 the cart now stands on the right side and the crates are far left, so the player has to cross the room in a curve.

## Consequences
Speed and turn rate are exported on the cart (`speed`, `turn_speed_deg`) and can be tuned per scene. Passage width matters: at 220 px/s and 180 deg/s the turning radius is about 70 px, so passages should stay above roughly 100 px. Minigame maps need playtesting with a real keyboard; the current one is intentionally demanding.
