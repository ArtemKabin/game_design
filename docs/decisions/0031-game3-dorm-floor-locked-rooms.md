# 0031: Game 3: dorm floor with four rooms and locked rooms

* Date: 2026-11-15
* Status: accepted
* Participants: Person A, Person B

## Context
The dorm floor has four identical rooms in a row: one left of the main character's room and two to the right, all with their doors on the same side, connected by one corridor. The other rooms should not be visible or enterable for now, but should become enterable later without rebuilding them.

## Decision
`scenes/dorm_room.tscn` gets the script `scripts/dorm_room.gd` with `@export var locked`. A locked room adds a roof and a closed door, keeps its corridor wall at full height and removes its actions. `scenes/dorm_floor.tscn` places four room instances 3.2 m apart (neighbours share one 0.2 m wall) and a 1.8 m corridor along the door side. Both corridor ends are closed walls until we know where the floor continues (stairs, kitchen, exit).

## Consequences
Opening a room later means one checkbox (`locked = false`) on its instance, plus own furniture if it should differ. Neighbouring rooms overlap their shared walls with identical blocks; same colour, so no visible z-fighting. The end walls must be cut open once the rest of the building is defined.
