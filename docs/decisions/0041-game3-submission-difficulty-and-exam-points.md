# 0041: Game 3: Friday submission gets easier with Prüfungssicherheit and gives exam points; missing it is a 5,0

* Date: 2026-11-20
* Status: accepted
* Participants: Person A, Person B

## Context
The week needs a consequence that comes from what the player did. In the first test a player passed the submission with full points at only 34 % Prüfungssicherheit.

## Decision
The submission (building A, Friday 08:00–18:00) is a minigame: click wrong formulas (red) on the sheet, leave correct ones (green). Prüfungssicherheit sets the difficulty: errors stay 1.3 → 2.6 s, appear every 0.5 → 0.85 s, traps 45 → 15 %; under 25 % is "schwer", from 60 % "leicht". Missed errors cost points, a 1,0 needs an almost perfect run. The intro card names level and reason. The result × 25 becomes exam points for the exam after three week loops (`GameState.exam_points`). A missed submission is a 5,0 with a full-screen stamp and the reason (deadline passed or slept on Friday), then the week summary shows grade, causes in numbers and exam points.

## Consequences
Every bad result can be explained from the screen (explainable failure). The exam itself is for the final release.
