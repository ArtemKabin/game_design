# Implementation Plan: Demo-Gameloop (eine Uni-Woche)

**Branch**: `001-demo-gameloop` | **Date**: 2026-11-20 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/001-demo-gameloop/spec.md`

## Summary

Den Loop Menü → Story-Intro → Woche Mo–Fr → Abgabe → Wochenbilanz → Menü schließen. Neue Teile
werden wie HUD und Minispiele im Code aufgebaut (keine neuen Spielorte): zwei UI-Szenen (Menü mit
Intro, Wochenbilanz), ein Handy-Overlay im HUD, drei Minispiele auf Basis von `Minigame`
(Vorlesung, Lerngruppe, Abgabe), Wochenlogik in `GameState`, Inhalte in `data/week.json`.

## Technical Context

**Language/Version**: GDScript, Godot 4.7.2 (GL Compatibility)
**Primary Dependencies**: keine neuen (bestehende Autoloads `GameState`, `Encounters`, `RoomView`)
**Storage**: keine Speicherung (Demo); Inhalte in `game-3-atmosphere/data/week.json`
**Testing**: Headless-Start (`--headless --quit-after`) ohne Skriptfehler + manueller Durchlauf nach [quickstart.md](quickstart.md)
**Target Platform**: Desktop + Web-Export
**Project Type**: Spiel (ein Godot-Projekt)
**Performance Goals**: keine neuen Kosten im 3D (nur UI und Control-Minispiele)
**Constraints**: wenige Stunden bis zur Playtest-Demo; keine Assets
**Scale/Scope**: 2 neue UI-Szenen, 3 Minispiele, 1 Handy-Overlay, 1 Datendatei

## Constitution Check

| Prinzip | Prüfung | Ergebnis |
| :--- | :--- | :--- |
| I. Keep It Simple | Keine neuen Spielorte/Autoloads; Handy lebt im HUD, Wochenlogik in GameState; Abgabe erbt vom Vorlesungs-Minispiel | ✅ |
| II. Every Option Has a Price | Alle Stationen zeigen Minuten im Prompt; Schlafen zeigt "Tag beenden"; Handy pausiert (Ausnahme, bewusst) | ✅ |
| III. Explainable Failure | Abgabe-Intro nennt Schwierigkeit + Grund; Bilanz nennt Prüfungssicherheit, To-dos, Note, Punkte | ✅ |
| IV. Onboarding First | Menü mit Steuerung, Story-Intro, To-dos + Stundenplan im Handy, Kartenbeschriftung | ✅ |
| V. Data in JSON, Code Builds UI | `data/week.json` für Intro, Stundenplan, To-dos; alle UIs in Code | ✅ |

## Project Structure

### Documentation (this feature)

```text
specs/001-demo-gameloop/
├── plan.md              # dieses Dokument
├── research.md          # Entscheidungen
├── data-model.md        # Daten in GameState und week.json
├── quickstart.md        # Testdurchlauf
├── contracts/
│   └── game-flow.md     # Szenenfluss, GameState-API, week.json-Schema
└── tasks.md             # /speckit-tasks
```

### Source Code (repository root)

```text
game-3-atmosphere/
├── project.godot                       # main_scene → Menü, Input "phone" (Tab)
├── data/
│   ├── week.json                       # NEU: intro, schedule, todos, submission
│   └── encounters.json                 # Story-Text an "Klausur in 3 Wochen" anpassen
├── scenes/
│   ├── main.tscn                       # Kachelboden → schlichter Boden
│   ├── dorm_room.tscn                  # NEU Station "Schlafen"
│   ├── outside.tscn                    # NEU 3 Uni-Stationen
│   ├── ui/main_menu.tscn               # NEU Menü + Steuerung + Intro
│   ├── ui/week_summary.tscn            # NEU Wochenbilanz
│   └── minigames/lecture.tscn, study_group.tscn, submission.tscn   # NEU
└── scripts/
    ├── game_state.gd                   # reset, Woche, Stundenplan, Abgabe, Klausurpunkte, Pause
    ├── hud.gd                          # Tab-Hinweis, Handy einhängen
    ├── phone.gd                        # NEU Handy-Overlay (4 Apps)
    ├── camera_rig.gd                   # toggle_overview() für die Karten-App
    ├── player.gd                       # steht bei offenem Handy
    ├── minigame_trigger.gd             # Kartenbeschriftung, Prompt-Zusätze, Sperren (Abgabe)
    ├── sleep_spot.gd                   # NEU Schlafen
    ├── site.gd                         # Tür-Platzhalter an Stationen weglassen
    ├── encounters.gd                   # all_npcs() für Kontakte
    ├── ui/main_menu.gd, ui/week_summary.gd                      # NEU
    └── minigames/minigame.gd (+Hooks), lecture.gd, study_group.gd, submission.gd  # NEU
```

**Structure Decision**: Bestehendes Godot-Projekt `game-3-atmosphere/`, neue UI-Szenen unter `scenes/ui/`.

## Complexity Tracking

Keine Verstöße.
