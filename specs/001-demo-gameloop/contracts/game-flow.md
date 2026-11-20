# Contract: Szenenfluss und GameState-API

## Szenenfluss

```text
main_menu.tscn ──Neues Spiel──▶ (Intro im Menü) ──▶ main.tscn (Zimmer, Mo 08:00)
     ▲                                                   │ Woche spielen
     │                                                   ▼
week_summary.tscn ◀── Abgabe beendet / Fr 18:00 / Schlafen Fr ohne Abgabe
```

## GameState (öffentlich, neu)

| Funktion | Zweck |
| :--- | :--- |
| `reset_week()` | Startwerte für Neues Spiel (exam_points bleibt) |
| `schedule_for(day) -> Array` | Termine eines Tages |
| `slot_now(station) -> Dictionary` | laufender Termin der Station (±30 min vorher) oder `{}` |
| `submission_open() -> bool` | Freitag 08:00–18:00 und noch nicht abgegeben |
| `difficulty() -> float` | 0..1 aus Prüfungssicherheit |
| `difficulty_name() -> String` | "schwer" / "mittel" / "leicht" |
| `todo_progress(todo) -> int` | Fortschritt eines To-dos |
| `sleep_now()` | Tag sofort beenden (Fr ohne Abgabe → Woche endet) |
| `finish_week()` | Bilanz-Szene laden |
| Signal `week_finished` | vor dem Szenenwechsel |

## Minigame-Hooks (neu in `minigame.gd`)

| Hook | Zweck |
| :--- | :--- |
| `_result_extra() -> Dictionary` | zusätzliche Felder fürs Ergebnis |
| `_result_lines() -> PackedStringArray` | zusätzliche Zeilen auf der Ergebniskarte |

## Eingaben

| Aktion | Taste | Wo |
| :--- | :--- | :--- |
| `phone` | Tab | Spielszenen (HUD) |
| `ui_cancel` | Esc | Handy: zurück/schließen, Intro: überspringen |
