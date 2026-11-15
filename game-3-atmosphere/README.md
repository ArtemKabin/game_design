# Game 3 – Atmosphere (Arbeitstitel)

Uni-Stress-Simulation in unserer Hochschule. Top-down, echtes 3D, Godot 4.7 (GL Compatibility).

## Steuerung
| Taste | Aktion |
| :--- | :--- |
| WASD / Pfeiltasten | Laufen |
| Shift | Rennen |
| E / Leertaste | Interagieren |
| Mausrad | Zoom (draußen bis 400 m) |
| M | Kartenansicht von oben an/aus (Mausrad zoomt, Maustaste gedrückt halten verschiebt die Karte) |

## Aufbau
* `scripts/game_state.gd` (Autoload `GameState`): Uhr (08:00–22:00 in 14 min Echtzeit, `GAME_MINUTES_PER_SECOND`), Woche Mo–So, Stats Energie, Sättigung, Prüfungssicherheit, Stress (abgeleitet), Geld. Jede Aktion kostet Zeit.
* `scripts/player.gd`, `scenes/player.tscn`: Bean (Kapsel 0,6 × 1,75 m), Füße bei y = 0.
* `scenes/dorm_room.tscn`: Wohnheimzimmer 16,5 m² (3,0 × 5,5 m) mit Schrank-/Waschbeckenteil.
* `scenes/dorm_floor.tscn`: Etage mit T-Flur, 6 Zimmern (4 am Hauptflur, 2 am Seitengang) Gemeinschaftsküche (rechts am Flurende), 2 WCs und 2 Duschkabinen mit Mini-Gang (unterhalb des Hauptflurs). Fremde Zimmer haben `locked = true` (Dach + geschlossene Tür), zum Öffnen Haken entfernen.
* `scripts/camera_rig.gd`: Top-down-Kamera, folgt dem Spieler.
* `scripts/block.gd`: Greybox-Baustein (Maße in Metern, Ursprung unten mittig). `cutaway = true` für Wände zur Kamera.
* `scripts/room_view.gd` (Autoload `RoomView`) + `scripts/zone.gd`: Jeder begehbare Raum hat eine `Zone`. Der Raum mit der Figur ist hell, andere abgedunkelt; Wände/Räume davor werden automatisch abgesenkt.
* `scripts/interactable.gd`: Station mit E-Aktion (Zeit + Stat-Änderungen als Exports).
* `scenes/outside.tscn`: draußen. Der Bewohner kommt bei 17F raus, alle Eingänge liegen am Fußweg zwischen den Häusern.
* `scripts/site.gd` + `scripts/site_building.gd` + `data/hka_site.json`: Wohnheim und Hochschulgelände 1:1 nach OpenStreetMap (Norden oben): Gebäude mit echten Umrissen und Stockwerken, verbundene Straßen und Wege, Parkplätze mit Autos, Hecken/Zäune, Wiesen, Wald. Nur von außen.
* `scripts/portal.gd` + `scripts/level.gd`: Türen zwischen Szenen (kosten Zeit), Spawnpunkte unter `Spawns`.
* `scripts/hud.gd`: Uhr, Balken, Prompt, Stress-Vignette, Nacht-Überblendung.

Maßstab: 1 Einheit = 1 Meter (siehe `docs/decisions/0029`).

## Quellen
Gebäudeumrisse draußen abgeleitet aus Daten von © OpenStreetMap-Mitwirkende (ODbL), https://www.openstreetmap.org/copyright
