# 0029: Game 3: real 3D, top-down camera, 1 unit = 1 metre

* Date: 2026-11-15
* Status: accepted
* Participants: Person A, Person B

## Context
Game 3 (theme "Atmosphere", feeling: uni stress) rebuilds our own Hochschule. Game 1 and 2 faked 2.5D with 2D scenes (0008). For a building that testers should recognise, and where walking distance costs game time, we need real proportions.

## Decision
Game 3 is a real 3D Godot project (`game-3-atmosphere/`, GL Compatibility for the web export) with a fixed top-down follow camera (60° pitch, mouse-wheel zoom). 1 unit = 1 metre. The placeholder student is built from primitives at 1.75 m with feet at y = 0; nose and an orange backpack show the facing direction (Game 1 feedback: the square player had no readable direction). Rooms are blocked out with `Block` (`scripts/block.gd`, origin bottom-centre, size in metres) on a 1 m grid floor, next to a scale reference (door 1.0 × 2.1 m, wall 3 m, table 0.75 m).

## Consequences
Real floor plans can be copied in metres. The placeholder model can later be swapped for a Blender model of the same height without touching the levels. Walls between camera and player will need hiding or cut-away once real rooms exist; that is not solved yet.
