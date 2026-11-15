# 0035: Game 3: full walls, dynamic cut-away and shaded rooms (RoomView)

* Date: 2026-11-15
* Status: accepted
* Participants: Person A, Person B

## Context
Static cut-away walls (0030) and flat locked rooms (`low_roof`, 0033) left the building looking unfinished: many walls were only 0.3 m stubs. We want all walls at full height, but walls and rooms in front of the player must never hide them. Rooms the player is not in should also be harder to read, which supports the atmosphere.

## Decision
All walls are full height. A new autoload `RoomView` (`scripts/room_view.gd`) knows the active zone. Every walkable room has a `Zone` (`scripts/zone.gd`, Area3D with interior size). The active zone is lit; every other zone is covered by a dark see-through shade. Occluders (Blocks with `cutaway`, locked rooms as a whole, zone shades) are cut down to 0.3 m when they lie on the camera side of the active zone, within 1.8 m of its front edge and overlapping it in x. They go back up when the player leaves. The `low_roof` option is removed; locked rooms switch between full box with roof and low slab automatically. The side corridor ends in the building exit (door, doormat) with the action "Wohnheim verlassen", which only shows a message for now.

## Consequences
New rooms need a `Zone` node and `cutaway = true` on walls facing the camera, nothing else. The rule assumes the fixed camera direction (looking north). In doorways between two zones the last entered zone stays active. Cutting is instant; a short tween could be added later.
