# 0032: Game 3: shared kitchen at the end of the dorm corridor

* Date: 2026-11-15
* Status: accepted
* Participants: Person A, Person B

## Context
The four residents share one kitchen at the right end of the corridor. It is as deep as corridor plus room (7.5 m). Its width was not specified.

## Decision
The kitchen is part of `scenes/dorm_floor.tscn` (node `Kitchen`), 4.0 × 7.5 m inside, visible and open. The door sits in the corridor's end wall. Read from the entrance, facing into the room: two fridges directly left of the door, then one counter along the whole left wall with two sinks, stove and oven, and one small wall cabinet per resident (the player's in the bean's blue). Along the right wall, from the back corner forward: three bins (paper, Gelber Sack, residual waste), a large open shelf, and a dining table against the wall with four chairs. The back wall stays free. Windows in the front and back wall. Actions: "Snack aus dem Kühlschrank" (5 min) and "Kochen" (40 min, costs 3 €).

## Consequences
Width 4.0 m leaves a walkway of about 2 m between counter and table. If the real kitchen is narrower, the right-wall furniture has to move closer to the counter. Food is still bought with money directly at the stove; groceries as items in the fridge come later.
