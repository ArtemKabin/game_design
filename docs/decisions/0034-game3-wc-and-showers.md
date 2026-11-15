# 0034: Game 3: two WCs and a shower block south of the main corridor

* Date: 2026-11-15
* Status: accepted
* Participants: Person A, Person B

## Context
The residents share two toilets and two showers. The toilets sit opposite the rooms: one next to the side corridor, one opposite the rightmost room on the main corridor. The showers lie below them and should be separate from each other but reachable through one small corridor.

## Decision
Node `Bath` in `scenes/dorm_floor.tscn`, interior x 3.0..8.0, between side corridor and kitchen line:
* WC1 (2.0 × 3.0 m), door to the side corridor; WC2 (2.8 × 3.0 m), door to the main corridor opposite the rightmost room's door. Each has a sink and a toilet; action "Toilette" (5 min, stress −2).
* Below them, over the full width of both WCs: a 1.0 m mini corridor entered from the side corridor, and two separate shower cabins south of it, each with its own door, a shower tray and a bench. Action "Duschen" per cabin (15 min, energy +8, stress −6).
`Block` supports transparent colours (alpha < 1) for glass.

## Consequences
The lower-right building edge now lines up with the kitchen's west wall (x 8.1). Hygiene is not a stat; showering only helps energy and stress for now.
