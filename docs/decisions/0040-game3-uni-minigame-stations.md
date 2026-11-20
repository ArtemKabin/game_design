# 0040: Game 3: two minigames at university doors, timetable bonus, harder minigames overall

* Date: 2026-11-20
* Status: accepted
* Participants: Person A, Person B

## Context
The campus had doors that only said "Hier wird noch gearbeitet". The walk to the university and the timetable needed a reason, without building interiors. The first test also showed that the minigames were too easy and that a memory game with maths terms excludes players who are not good at maths.

## Decision
Two stations at real doors in `outside.tscn`: Vorlesung (building B, click key terms on the board before they disappear, avoid red phone distractions, missed terms cost points) and Lerngruppe (building LB, memory with 8 everyday pairs such as Mensa – Mittagessen, wrong pairs cost points). Played during their timetable slot they give ×1.3 study points. Stations have a big label and a beacon that only show in the map view, neighbouring labels sit left and right of their station, and all station, NPC and entrance labels are drawn on top of walls. All minigames got shorter timers or a higher par score.

## Consequences
The memory now tests memory only, not subject knowledge. Balancing is a first guess and needs playtest data.
