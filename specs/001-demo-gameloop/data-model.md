# Data Model: Demo-Gameloop

## GameState (neu/geändert)

| Feld | Typ | Bedeutung | Reset bei Neues Spiel |
| :--- | :--- | :--- | :--- |
| `week_data` | Dictionary | Inhalt von `data/week.json` | nein |
| `week_runs` | Dictionary id → int | Minispiel-Läufe diese Woche (To-dos) | ja |
| `lectures_on_time` | int | Vorlesungen im Stundenplan-Termin | ja |
| `in_phone` | bool | Handy offen → Uhr + Figur stehen | ja |
| `submission` | Dictionary | `{done, grade, ratio, level, exam_points}` | ja |
| `week_over` | bool | Bilanz wurde ausgelöst | ja |
| `exam_points` | int | globale Klausurvorbereitung (Summe) | **nein** |
| `loops_done` | int | gespielte Wochen | nein |

Konstanten: `GAME_MINUTES_PER_SECOND = 3.0`, `EXAM_LOOPS = 3`, `EXAM_POINTS_PER_SUBMISSION = 25`.

## data/week.json

```json
{
  "intro": ["Seite 1", "..."],
  "schedule": [{"day": 0, "start": "10:00", "end": "11:30", "title": "Analysis – Vorlesung",
                "place": "Gebäude B", "station": "lecture"}],
  "todos": [{"text": "Vorlesungen besuchen", "station": "lecture", "target": 3}],
  "submission": {"day": 4, "start": "08:00", "end": "18:00", "place": "Gebäude A",
                 "title": "Übungsblatt 1 Analysis abgeben"}
}
```

Station-IDs = Dateiname des Minispiels: `lecture`, `study_group`, `submission`,
`study_journal`, `room_cleanup`, `kitchen_cleanup`.

## Minispiel-Ergebnis (erweitert)

Bestehend `{id, title, completed, score, points, notes, d_energy, d_stress}`, neu optional:
`ratio` (0..1), `grade` (String), `level` (String, nur Abgabe).
