# Research: Demo-Gameloop

## R1 Wochenende und Loop-Ende
- **Decision**: Demo-Woche = Mo–Fr. Loop endet mit der Abgabe oder Fr 18:00.
- **Rationale**: Abgabe ist der Höhepunkt; Sa/So ohne Inhalt würden den Playtest strecken.
- **Alternatives**: Sa/So spielbar (keine Inhalte), Ende Fr 22:00 (Leerlauf nach der Abgabe).

## R2 Uhrtempo
- **Decision**: `GAME_MINUTES_PER_SECOND` 1,0 → 3,0 (14 h ≈ 4,7 min), dazu Schlafen.
- **Rationale**: SC-002 (15–30 min pro Woche). Schlafen erlaubt Abkürzen.
- **Alternatives**: Tage kürzen (bricht Stundenplan-Uhrzeiten).

## R3 Handy
- **Decision**: Overlay im HUD (`phone.gd`, in Code gebaut), Taste Tab (Input `phone`), pausiert
  Uhr über `GameState.in_phone`. Karten-App ruft `CameraRig.toggle_overview()`.
- **Rationale**: HUD existiert in jeder Spielszene → kein neuer Autoload.
- **Alternatives**: Autoload-Overlay (mehr Kopplung), Zeit läuft weiter (unfair beim Lesen).

## R4 Minispiele
- **Decision**: Vorlesung (Klickziele: Fachbegriffe vs. Ablenkungen), Lerngruppe (Memory
  Begriff ↔ Erklärung), Abgabe (erbt Vorlesung: Fehler im Dokument anklicken).
- **Rationale**: Drei unterschiedliche Verben, aber nur zwei Mechaniken zu bauen.
- **Schwierigkeit Abgabe** (r = Prüfungssicherheit/100): Lebensdauer eines Fehlers
  2,0 → 4,0 s, Abstand zwischen Fehlern 0,7 → 1,3 s, Fallen-Anteil 35 % → 5 %. Stufe:
  r < 0,25 schwer, < 0,6 mittel, sonst leicht.
- **Klausurpunkte**: round(25 × Ergebnisquote); nicht abgegeben = 0.

## R5 Stations-Orte (outside.tscn, Türen aus `hka_site.json`)
- Vorlesung: Gebäude B, Tür 2, Station bei (-75.53, 0, -46.50)
- Lerngruppe: Gebäude LB, Tür 24, Station bei (-69.22, 0, -46.19)
- Abgabe: Gebäude A, Tür 8, Station bei (-112.65, 0, 36.73)
- Die "Hier wird noch gearbeitet"-Aktion an diesen Türen entfällt (Gruppe `door_station`).

## R6 Boden Wohnheim
- **Decision**: Gittershader in `main.tscn` durch einfaches dunkles Material ersetzen, Kollision bleibt.

## R7 Speichern
- **Decision**: Keins in der Demo. `exam_points` überlebt "Neues Spiel" im selben Lauf.
