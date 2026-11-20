# 0037: Game 3: closed demo loop (menu, phone, uni minigames, Friday submission)

* Date: 2026-11-20
* Status: proposed
* Participants: Person A, Person B
* Spec: `specs/001-demo-gameloop/` (GitHub Spec Kit: spec, plan, research, tasks)

## Context
The first playtest needs a complete loop: a start, one week, a consequence and an end. Until now the game started directly in the dorm, ran endlessly and had no goal for the week. Hours left before the demo, so no new places and no assets.

## Decision
* **Flow**: `scenes/ui/main_menu.tscn` (Neues Spiel, Steuerung, Einstellungen; no quit button, the demo runs in the browser) → story intro (pages in `data/week.json`) → dorm Monday 08:00 → week → `scenes/ui/week_summary.tscn` → menu. Menu and summary are built in code like the HUD.
* **Demo week = Monday to Friday.** It ends with the submission (Friday 08:00–18:00, building A) or when the deadline passes; sleeping on Friday without a submission also ends it. The weekend is only mentioned in the summary.
* **Faster clock**: `GAME_MINUTES_PER_SECOND` 1 → 3 (one day ≈ 4.7 min). New station "Schlafen" at the own bed ends the day at once.
* **Phone (Tab)**: overlay inside the HUD (`scripts/phone.gd`) with Karte (opens the map view), Kontakte (characters from `encounters.json`), To-dos and Stundenplan (`week.json`). The clock and player stand still while it is open.
* **Uni stations** in `outside.tscn` at real doors: Vorlesung (building B, click key terms, avoid phone distractions), Lerngruppe (building LB, memory term ↔ explanation), Abgabe (building A). A station played in its timetable slot gives ×1.3 study points. Big labels and beacons make them visible in the map view. The "under construction" door action is skipped where a station stands (group `door_station`).
* **Submission difficulty** comes from Prüfungssicherheit: errors stay visible 2.0 → 4.0 s, appear every 0.75 → 1.3 s, traps 35 → 5 %. The intro card names the level and the reason. Result × 25 = exam points (`GameState.exam_points`), kept across "Neues Spiel"; the exam itself after 3 loops is for the final release.
* `GameState.reset_week()` resets everything except exam points; `ensure_started()` lets the editor still run `main.tscn` directly.
* **Forgetting**: time that is not spent learning takes 1 Prüfungssicherheit per game hour (10 h per night), at most half of what was learned this week. Grinding one station and sleeping until Friday no longer works.
* **Missed submission** = grade 5,0 with a full-screen stamp and the reason (deadline passed / slept on Friday) before the summary.
* The dorm ground around the floor is a plain dark material instead of the grid shader.

## Consequences
A full demo week takes about 15–30 min. No saving: exam points live only as long as the game runs. The exam, weekends and more weeks are open for the final release. `tests/loop_smoke_test.tscn` runs the loop headless (menu, phone apps, all minigames, submission, deadline, reset, sleeping).
