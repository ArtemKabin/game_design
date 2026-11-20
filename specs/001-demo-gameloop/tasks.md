---
description: "Tasks: Demo-Gameloop"
---

# Tasks: Demo-Gameloop (eine Uni-Woche)

**Input**: `specs/001-demo-gameloop/` (plan.md, spec.md, research.md, data-model.md, contracts/)
**Tests**: keine automatisierten Tests angefordert; Validierung über Headless-Start + [quickstart.md](quickstart.md).
Pfade relativ zu `game-3-atmosphere/`.

## Phase 1: Setup

- [x] T001 Input-Aktion `phone` (Tab) in `project.godot` anlegen
- [x] T002 [P] `data/week.json` mit intro, schedule, todos, submission anlegen

## Phase 2: Foundational (blockiert alle Stories)

- [x] T003 `scripts/game_state.gd`: week_data laden, Uhr ×3, `reset_week()`, `week_runs`, `in_phone`, `exam_points`, `schedule_for()`, `slot_now()`, `submission_open()`, `difficulty()`, `todo_progress()`, `sleep_now()`, `finish_week()`, Frist Fr 18:00 in `_advance()`, Abgabe in `apply_minigame_result()`
- [x] T004 `scripts/minigames/minigame.gd`: Hooks `_result_extra()`, `_result_lines()`, neutraler Weiter-Button, `ratio`/`grade` ins Ergebnis

## Phase 3: User Story 1 – Menü und Intro (P1) 🎯 MVP

- [x] T005 [US1] `scripts/ui/main_menu.gd` + `scenes/ui/main_menu.tscn`: Titel, Neues Spiel, Steuerung, Einstellungen (`scripts/ui/maintenance_panel.gd`, Wartungs-Screen mit Zurück), Intro-Seiten aus week.json, Esc überspringt
- [x] T006 [US1] `project.godot`: `run/main_scene` → `res://scenes/ui/main_menu.tscn`
- [x] T007 [P] [US1] `data/encounters.json`: Jonas-Intro an "Klausur in drei Wochen" + Übungsblatt anpassen

## Phase 4: User Story 2 – Smartphone (P1)

- [x] T008 [US2] `scripts/phone.gd`: Overlay mit Homescreen + Apps Karte, Kontakte, To-dos, Stundenplan
- [x] T009 [US2] `scripts/hud.gd`: Handy einhängen, Hinweis "Tab: Handy"
- [x] T010 [P] [US2] `scripts/camera_rig.gd`: `toggle_overview()` (von Taste M und Karten-App)
- [x] T011 [P] [US2] `scripts/player.gd`: Figur steht bei `GameState.in_phone`; `scripts/encounters.gd`: `all_npcs()`

## Phase 5: User Story 3 – Uni-Minispiele (P2)

- [x] T012 [US3] `scripts/minigames/lecture.gd` + `scenes/minigames/lecture.tscn` (Klickziele, Stundenplan-Bonus)
- [x] T013 [P] [US3] `scripts/minigames/study_group.gd` + `scenes/minigames/study_group.tscn` (Memory)
- [x] T014 [US3] `scripts/minigame_trigger.gd`: Kartenbeschriftung (`map_label`), Prompt-Zusatz (Bonus/Sperre), Gruppe `door_station`
- [x] T015 [US3] `scenes/outside.tscn`: Stationen Vorlesung (Geb. B), Lerngruppe (Geb. LB), Abgabe (Geb. A); `scripts/site.gd`: Tür-Platzhalter an Stationen weglassen

## Phase 6: User Story 4 – Abgabe und Bilanz (P1)

- [x] T016 [US4] `scripts/minigames/submission.gd` + `scenes/minigames/submission.tscn` (erbt Vorlesung, Schwierigkeit aus Prüfungssicherheit)
- [x] T017 [US4] `scripts/ui/week_summary.gd` + `scenes/ui/week_summary.tscn` (Note, Ursachen, Klausurpunkte, Hauptmenü)

## Phase 7: User Story 5 – Schlafen und Boden (P3)

- [x] T018 [P] [US5] `scripts/sleep_spot.gd` + Station "Schlafen" in `scenes/dorm_room.tscn`
- [x] T019 [P] [US5] `scenes/main.tscn`: Gittermaterial durch schlichtes dunkles Material ersetzen

## Phase 8: Polish

- [x] T020 README.md (Steuerung, Aufbau, Minispiele, Woche) aktualisieren
- [x] T021 Entscheidung `docs/decisions/0037-game3-demo-gameloop.md`
- [x] T022 Headless-Start ohne Skriptfehler (`tests/loop_smoke_test.tscn`, 23 Checks grün)
- [ ] T023 Manueller Quickstart-Durchlauf im Editor (Optik: Handy, Kartenlabels, Weg zu Gebäude B/LB/A)

## Dependencies

- T003, T004 vor allen Stories. US4 (T016) braucht T012. T015 braucht T012–T014, T016 (Szenen müssen existieren).
- US1, US2, US5 sind unabhängig voneinander.
