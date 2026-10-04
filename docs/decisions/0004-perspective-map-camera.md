# 0004: 2.5D top-down, fog-of-war map with zoom, room-to-room camera

* Date: kickoff meeting, October 2026 (recorded 2026-10-04)
* Status: accepted
* Participants: Person A, Person B

## Context
How does the player see the ship and move between puzzles?

## Decision
* 2.5D game, top-down view.
* A fog-of-war map with zoom in / zoom out and a full-map view, inspired by strategy games (Command & Conquer, The Settlers).
* Mixed with room-to-room movement and an interactive camera as in The Binding of Isaac.
* Level 0 sits in the center of the map; rooms light up as they are unlocked.

## Consequences
Camera and controls are foundation work (Person A) and must be reusable across levels. The map is its own scene with level buttons that reflect the state kept in the game manager. The exact Godot implementation of "2.5D" (2D nodes vs. 3D nodes with fixed camera) is still an open question, see the index README.
