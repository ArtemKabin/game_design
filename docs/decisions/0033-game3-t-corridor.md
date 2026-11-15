# 0033: Game 3: T-shaped dorm corridor with two more rooms

* Date: 2026-11-15
* Status: accepted (view handling superseded by 0035)
* Participants: Person A, Person B

## Context
The dorm corridor is T-shaped: from the middle of the main corridor a side corridor runs down (towards the camera), with two more dorm rooms on its left side. These rooms lie between the camera and the main corridor, so full walls and a roof at 2.6 m would hide the corridor and the player.

## Decision
The side corridor (1.8 m wide, interior x 1.0..2.8) branches off slightly right of the exact middle, so the two rotated rooms (doors facing east into it) end flush with the building's west edge. Both rooms are locked with the new `low_roof` option of `dorm_room.gd`: all walls are cut down to the 0.3 m stubs and a dark slab sits just below the stub tops. The room outlines and door positions stay readable, the inside does not, and nothing blocks the view.

## Consequences
Locked rooms now come in two looks: full box with roof (rooms behind the corridor) and flat slab (rooms in front of it). The south end of the side corridor is a closed wall until we know what comes next. The side corridor's east wall is full height; if something walkable is added east of it, it stays visible because the wall runs towards the camera.
