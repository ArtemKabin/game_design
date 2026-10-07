# 0016: The cargo rail runs left, down, left and enters Level 1 from the right; the storage room is gone

* Date: 2026-10-07
* Status: accepted
* Participants: both developers

## Context
The rail corridor between the bridge and the cargo bay was an L (left, then down) and dropped into Level 1 through its top wall. The deck layout is being reworked room by room (the quarantine loop and the cargo bay itself follow next), and the storage room with the crowbar was a second tool-hunt stop that added a room and a stage without adding a new idea: the hammer already makes the "tools are bait" point.

## Decision
* The rail is an S: from the bridge door it runs **left, then down, then left again**. The far platform sits at the left end of the bottom segment and its door leads into Level 1 through the **right wall of the cargo bay**. The player gets out of the cart on the door side (right at the bridge platform, left at the cargo platform).
* The **storage room and the crowbar are removed**. After three hits with the rubber hammer the narrator goes straight to "Du musst das Hindernis UMFAHREN" and the camera pans to the cart.
* Level 1, the cabins and the cargo control room move together so their doors still line up; the cabins keep their place below the cargo bay for now.

## Consequences
`corridor_l.tscn` has three segments; the foot trap and the camera bounds cover all of them. The Level 1 entrance door and spawn are on the right wall, so the old top-wall entrance position is free for whatever the cargo bay rework needs. Decision 0015 stays valid except for the storage-room step (0017 and 0018 change the rest).
