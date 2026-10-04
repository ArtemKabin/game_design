# 0006: Scope cut to 3 levels, team split Person A / Person B, KEEP IT SIMPLE

* Date: kickoff meeting, October 2026 (recorded 2026-10-04)
* Status: accepted
* Participants: Person A, Person B

## Context
The concept had six levels. The time budget is roughly one week, and the feature list is long: level-transition minigames, fog of war, a general map, a fairly complex camera, tools or vehicles, a character, dialogue, UI. A Kanban board with a backlog was created and the scope reduced.

## Decision
Scope: **three levels**. Level 0 (tutorial), Level 1, Level 2 (final level). The other four level concepts remain in the backlog.

Team split:

| Person A | Person B |
| :--- | :--- |
| Build the first level with reusable functions and content (camera, controls, physics) | Extend the base logic with level-specific logic |
| Do not implement the whole level concept at once; lay the ground first | Create assets and keep this decision log |
| Level 0 and Level 1 | Level storyboards (approved by Person A) |
| | Level 2 (final level): concept and implementation |

Both: update the README, review each other's code, keep the Kanban board current.

Top rule: **KEEP IT SIMPLE.** Nothing on the feature list gets over-engineered.

## Consequences
Anything not needed for the three levels is a candidate to cut. When in doubt, the simpler implementation wins. Pull requests are reviewed by the other person before merging to `main`.
