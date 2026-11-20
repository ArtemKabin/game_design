<!--
Sync Impact Report
- Version change: template → 1.0.0
- Added principles: I. Keep It Simple, II. Every Option Has a Price, III. Explainable Failure,
  IV. Onboarding First, V. Data in JSON, Code Builds UI
- Added sections: Technical Constraints, Development Workflow, Governance
- Templates requiring updates: none (plan/spec/tasks templates read this file at runtime)
- Follow-up TODOs: none
-->

# Game Design Uni-Projekte Constitution

Gilt für alle Spiele in diesem Repo (Game 1 Deceptive Wiring, Game 2 FLIP, Game 3 Atmosphere).
Zwei Studierende, kurze Sprints, Playtests mit Kommiliton:innen.

## Core Principles

### I. Keep It Simple (NON-NEGOTIABLE)
Die kleinste Lösung, die im Playtest das Gefühl transportiert, gewinnt. Keine neuen Szenen,
Autoloads oder Systeme, wenn ein bestehendes erweitert werden kann. Greybox vor Assets.
Begründung: Sprints dauern Tage, nicht Wochen; jede Zeile muss vor der Abgabe reviewt werden.

### II. Every Option Has a Price
Jede Aktion des Spielers kostet etwas (Spielzeit, Energie, Geld, Stress) und zeigt den Preis
vor der Entscheidung an (Prompt, Intro-Karte). Aus dem Feedback zu Game 1 und 2.

### III. Explainable Failure
Jeder Misserfolg (schlechte Note, verpasste Abgabe, hoher Stress) muss aus dem erklärbar sein,
was der Spieler gesehen hat. Bilanz-/Ergebnisbildschirme nennen die Ursachen in Zahlen.

### IV. Onboarding First
Ein neuer Spieler versteht ohne Erklärung von außen, was zu tun ist: Story-Intro, Steuerung
im Menü, To-dos im Spiel. Onboarding gehört in den ersten Sprint, nicht in den letzten.

### V. Data in JSON, Code Builds UI
Inhalte (Begegnungen, Stundenplan, Story-Texte, Kartendaten) liegen in `data/*.json` oder
als Konstanten an einer Stelle. UI wird in GDScript-Code aufgebaut wie `hud.gd` und
`minigame.gd`, damit Änderungen kleine, reviewbare Diffs bleiben.

## Technical Constraints

- Godot 4.7, GL Compatibility, Web-Export muss laufen (keine Threads, keine nativen Plugins).
- 1 Einheit = 1 Meter; Game 3 ist echtes 3D top-down (Entscheidung 0029).
- Persistenter Spielstand in `GameState` (Autoload); neue Werte dort, nicht verstreut.
- Texte im Spiel auf Deutsch.

## Development Workflow

- Arbeit auf Feature-Branches, nie direkt auf `main`; gegenseitiges Code-Review per PR.
- Commits nur nach Rückfrage, ohne KI-Attribution.
- Jede Entwicklungsentscheidung mit Gewicht bekommt einen Eintrag in `docs/decisions/`.
- README des Spiels wird mit jeder Funktion aktualisiert (Steuerung, Aufbau).
- Vor einem Playtest: Projekt startet headless ohne Skriptfehler, Kernloop einmal durchgespielt.

## Governance

Diese Constitution geht anderen Praktiken vor. Änderungen: Vorschlag im PR, beide
Teammitglieder stimmen zu, Version nach SemVer erhöhen (MAJOR: Prinzip entfernt/umdefiniert,
MINOR: Prinzip/Abschnitt neu, PATCH: Wortlaut). Jeder Plan (`/speckit-plan`) prüft im
Abschnitt "Constitution Check" alle fünf Prinzipien; Abweichungen stehen in "Complexity Tracking".

**Version**: 1.0.0 | **Ratified**: 2026-11-20 | **Last Amended**: 2026-11-20
