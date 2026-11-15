# 0030: Game 3: bean player and the dorm room layout

* Date: 2026-11-15
* Status: accepted (view handling superseded by 0035)
* Participants: Person A, Person B

## Context
The first placeholder student (0029) was built from limbs and was more detail than a greybox needs. The first location is the main character's room in the Wohnheim: 16.5 m², long, with a walk-in closet with a sink, separated by a wall with its own door.

## Decision
The player is a plain capsule ("bean"), 0.6 m wide and 1.75 m tall. The room (`scenes/dorm_room.tscn`) is 3.0 × 5.5 m inside, 2.6 m ceiling. The entrance door (0.9 × 2.1 m) sits in the middle of one short wall and leads into the closet part (3.0 × 1.45 m: wardrobe, sink, mirror). A 0.1 m partition with a middle door separates it from the living part (3.0 × 3.95 m: bed, desk, chair, shelf, window opposite the entrance). Walls on the camera side and the partition use `Block.cutaway`: in game they are drawn only 0.3 m high, collision stays full height.

## Consequences
The bean has no visible facing direction; it does not need one while there is no aimed action. If the real room has the closet at the window end instead, only the partition and the furniture move. The cutaway is static and assumes the fixed camera yaw; a rotating camera would need dynamic hiding.
