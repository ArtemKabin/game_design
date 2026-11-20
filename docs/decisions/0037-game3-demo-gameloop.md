# 0037: Game 3: the demo loop is one week, Monday to Friday, ending with the submission

* Date: 2026-11-20
* Status: accepted
* Participants: Person A, Person B

## Context
The first playtest needs a closed loop: a start, a goal, a consequence and an end. Until now the game started in the dorm and ran forever. A full week Monday to Sunday at the old clock speed (14 min per day) would take over 1.5 hours, far too long for a playtest. Details: `specs/001-demo-gameloop/` (GitHub Spec Kit, see 0044).

## Decision
The demo week runs Monday to Friday. It ends when the exercise sheet is submitted (Friday 08:00–18:00, building A), when the deadline passes, or when the player sleeps on Friday without submitting. The weekend is only one line in the week summary. The clock runs 3× faster (`GAME_MINUTES_PER_SECOND` = 3, one day ≈ 4.7 min). A "Schlafen" station at the own bed ends the day at once. Week content (intro text, timetable, to-dos, submission window) lives in `data/week.json`. `GameState.reset_week()` starts a new week and keeps only the exam points.

## Consequences
A full demo week takes 15–30 min. Saturday and Sunday, more weeks and the exam are left for the final release. No saving yet: exam points live as long as the game runs.
