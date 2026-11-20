# 0039: Game 3: the phone (Tab) holds map, contacts, to-dos and timetable

* Date: 2026-11-20
* Status: accepted
* Participants: Person A, Person B

## Context
The player needs to know where to go and what is due without anybody explaining it. A HUD full of lists would cover the 3D view.

## Decision
A phone overlay inside the HUD (`scripts/phone.gd`), opened with Tab, with four apps: Karte (switches the CameraRig to the map view), Kontakte (all characters from `encounters.json` with role, last meeting and "has news"), To-dos (week goals with progress, deadline, current difficulty, exam points) and Stundenplan (Monday to Friday, today and running slots highlighted). While the phone is open, the clock and the player stand still. The HUD shows the deadline below the clock.

## Consequences
Reading is never punished by lost time, which is a small exception to "every option has a price". The phone is the natural place for later features (messages, bank, food delivery).
