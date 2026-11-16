# Game 3 – Atmosphere (Arbeitstitel)

Uni-Stress-Simulation in unserer Hochschule. Top-down, echtes 3D, Godot 4.7 (GL Compatibility).

## Steuerung
| Taste | Aktion |
| :--- | :--- |
| WASD / Pfeiltasten | Laufen |
| Shift | Rennen |
| E / Leertaste | Interagieren, mit Leuten reden, Dialog weiter |
| Mausrad | Zoom (draußen bis 400 m) |
| M | Kartenansicht von oben an/aus (Mausrad zoomt, Maustaste gedrückt halten verschiebt die Karte) |
| Maus (Minispiele) | Ziehen, Klicken, Schrubben |
| Esc (Minispiele) | Intro: zurück · im Spiel: aufgeben und werten |

## Aufbau
* `scripts/game_state.gd` (Autoload `GameState`): Uhr (08:00–22:00 in 14 min Echtzeit, `GAME_MINUTES_PER_SECOND`), Woche Mo–So, Stats Energie, Sättigung, Prüfungssicherheit, Stress (abgeleitet), Geld. Jede Aktion kostet Zeit. Dazu der Lernfortschritt aus den Minispielen: Lernpunkte, gefundene Notizen, Rekorde.
* `scripts/player.gd`, `scenes/player.tscn`: Bean (Kapsel 0,6 × 1,75 m), Füße bei y = 0.
* `scenes/dorm_room.tscn`: Wohnheimzimmer 16,5 m² (3,0 × 5,5 m) mit Schrank-/Waschbeckenteil.
* `scenes/dorm_floor.tscn`: Etage mit T-Flur, 6 Zimmern (4 am Hauptflur, 2 am Seitengang) Gemeinschaftsküche (rechts am Flurende), 2 WCs und 2 Duschkabinen mit Mini-Gang (unterhalb des Hauptflurs). Fremde Zimmer haben `locked = true` (Dach + geschlossene Tür), zum Öffnen Haken entfernen.
* `scripts/camera_rig.gd`: Top-down-Kamera, folgt dem Spieler.
* `scripts/block.gd`: Greybox-Baustein (Maße in Metern, Ursprung unten mittig). `cutaway = true` für Wände zur Kamera.
* `scripts/room_view.gd` (Autoload `RoomView`) + `scripts/zone.gd`: Jeder begehbare Raum hat eine `Zone`. Der Raum mit der Figur ist hell, andere abgedunkelt; Wände/Räume davor werden automatisch abgesenkt.
* `scripts/interactable.gd`: Station mit E-Aktion (Zeit + Stat-Änderungen als Exports).
* `scenes/outside.tscn`: draußen. Der Bewohner kommt bei 17F raus, alle Eingänge liegen am Fußweg zwischen den Häusern.
* `scripts/site.gd` + `scripts/site_building.gd` + `data/hka_site.json`: Wohnheim und Hochschulgelände 1:1 nach OpenStreetMap (Norden oben): Gebäude mit echten Umrissen und Stockwerken, verbundene Straßen und Wege, Parkplätze mit Autos, Hecken/Zäune, Wiesen, Wald. Nur von außen.
* Campus-Leben in `outside.tscn` (alles aus `data/hka_site.json`, gepoolt, nichts wird im Spiel erzeugt/gelöscht). Gemeinsame Helfer: `scripts/poly_path.gd` (`PolyPath`, Linie mit Längenabfrage) und `scripts/site_paths.gd` (`SitePaths`: Daten laden, Wege verketten, Fußweg-Graph, Positionen aller Fußgänger, für die Autos und Räder bremsen).
* `scripts/bikes.gd` (Knoten `Bikes`): Radfahrer auf dem langen Radweg quer über die Karte (rote Linie, `route_roads` = 133 + 5), rechts in beide Richtungen, verschwinden am Kartenrand. Modell `scenes/props/bike.tscn` ohne Kollision plus Fahrer; Räder drehen sich. Halten Abstand und bremsen für Fußgänger.
* `scripts/crowd.gd` (Knoten `Crowd`): `count` (90) anonyme Studis auf allen Fußwegen. Jeder läuft von einem Wegende (Haustür, Kartenrand) auf dem kürzesten Weg (AStar2D) zu einem anderen, „geht rein“ und taucht woanders wieder auf. Zwei MultiMeshes für alle, nicht fest, nicht ansprechbar (das sind die NPCs mit Namen). Bleiben kurz stehen, wenn die Figur im Weg steht.
* `scripts/traffic.gd` (Knoten `Traffic` in `outside.tscn`): Verkehr auf der vorderen Straße nördlich des Wohnheims (`route_roads` = Straßen-Indizes aus der JSON). Autos fahren rechts in beide Richtungen und verschwinden am Kartenrand (Pool, `pool_size`). Ein Teil (`park_chance`) parkt vorwärts in eine freie Bucht an der Straße, ein Teil (`lot_chance`) biegt in den großen Parkplatz links ab (Gassen `lot_aisles`), parkt in einer freien Lücke, setzt zurück, fährt zur Straße zurück und biegt ein, sobald frei ist. Freie Plätze werden aus den Daten bestimmt (Parkfläche, kein geparktes Auto, kein Baum, keine andere Straße), `debug_spots` zeigt sie an. Autos halten für Figur und NPCs und halten Abstand.
* `scripts/portal.gd` + `scripts/level.gd`: Türen zwischen Szenen (kosten Zeit), Spawnpunkte unter `Spawns`. Nach einem Minispiel steht die Figur wieder dort, wo sie losging.
* `scripts/hud.gd`: Uhr, Balken (mit Wert für Prüfungssicherheit und Stress), Lernpunkte, Notizen, Story-Fortschritt, Prompt, Stress-Vignette, Nacht-Überblendung.

## Minispiele
Drei Stationen im Wohnheim öffnen je ein eigenes Vollbild-Minispiel. Farbe von Bodenmarkierung und Schild = Stat-Farbe aus dem HUD.

| Station | Ort | Minispiel | Farbe | Kostet |
| :--- | :--- | :--- | :--- | :--- |
| Lernjournal | Schreibtisch (eigenes Zimmer) | `study_journal.tscn`: Lernkarten links ins Journal rechts ziehen, aktuelles Kapitel gibt Kombo, rote Ablenkungen nicht ins Journal. 60 s | blau (Prüfungssicherheit) | 60 min |
| Zimmer aufräumen | vor dem Bett | `room_cleanup.tscn`: Kleidung → Wäschekorb, Müll → Mülleimer, Kram → Regal. 45 s | gelb (Energie) | 30 min |
| Küche aufräumen | Gemeinschaftsküche, Spüle | `kitchen_cleanup.tscn`: Geschirr → Spüle, Reste → Müll, Flecken schrubben, versteckte Notizen finden. 50 s | grün (Sättigung) | 30 min |

* `scripts/minigame_trigger.gd` (`MinigameTrigger`, erbt von `Interactable`): öffnet das Minispiel, `minutes` = Spielzeit. `clutter` (optional) wird ausgeblendet, wenn das Minispiel heute schon gespielt wurde.
* `scripts/minigames/minigame.gd` (`Minigame`): gemeinsamer Rahmen in Code (Leiste mit Timer/Punkten/Notizen, Intro, Ergebnis mit Note 1,0–5,0, Stress-Vignette). Während eines Minispiels steht die Uhr; Zeit und Belohnung werden beim Zurückkommen gebucht (`GameState.apply_minigame_result`).
* `scripts/minigames/drag_item.gd` (`DragItem`): Ding, das man mit der Maus ziehen kann.
* Wertung: Punkte × Faktor = Lernpunkte (Journal ×Lernbonus, Zimmer ×0,5, Küche ×0,6). 40 Lernpunkte = 1 Prüfungssicherheit (× `learn_factor`, also weniger bei hohem Stress). Aufräumen senkt Stress.
* Notizen: liegen unter dem Kram (Zimmer 3, Küche 4) und geben je +15 Punkte. In der Küche steigt pro Notiz der Multiplikator der Runde um 0,25. Jede gefundene Notiz erhöht dauerhaft den Lernbonus im Journal um 10 % (max. ×2).

## Leute (NPCs)
* `data/encounters.json`: alle Figuren, Story-Beats, Zufallsbegegnungen und Smalltalk (Erklärung der Schlüssel unter `_info` in der Datei). Neue Beats/Begegnungen nur dort eintragen.
* `scripts/encounters.gd` (Autoload `Encounters`): Beim Treffen einer Figur kommt zuerst der nächste Story-Beat, wenn sie dran ist und die Bedingungen erfüllt sind (gelbes „!“ über der Figur), sonst einmal pro Figur und Tag eine Zufallsbegegnung (gewichtet, geseedet aus Figur + Tag + Spielstand, also kein Neuwürfeln), sonst Smalltalk. Dialogbox unten, Uhr und Figur stehen solange. Effekte: Notizen, Lernpunkte, Prüfungssicherheit, Stress, Energie, Sättigung, Geld, Zeit.
* `scripts/npc.gd` (`Npc`, erbt von `Interactable`): Kapsel wie die Spielfigur in eigener Farbe. Reden mit E oder durch Anrempeln. Läuft draußen auf den Fußwegen, im Wohnheim entlang `patrol` (Mitbewohner Jonas zwischen Küche und Flur). Bleibt stehen, wenn man im Weg steht, und dreht nach 1,5 s um.
* `scripts/npc_spawner.gd` (Knoten `Pedestrians` in `outside.tscn`): Fußweg-Netz aus der JSON im Bereich `area` (Weg zwischen den Häusern), setzt alle Figuren mit `place = outside` darauf.
* Stress: Aktionen, Minispiele und Begegnungen verschieben zusätzlich eine Stimmung (`GameState.mood`), die mit 4 Punkten pro Spielstunde abklingt. So hält ein Effekt ein paar Stunden statt Sekunden.
* Spielstand in `GameState`: `story_index`, `story_seen`, `npc_last_met`, `encounter_seed`. Das HUD zeigt Stress, Lernpunkte, Notizen und Story-Fortschritt.

Maßstab: 1 Einheit = 1 Meter (siehe `docs/decisions/0029`).

## Quellen
Gebäudeumrisse draußen abgeleitet aus Daten von © OpenStreetMap-Mitwirkende (ODbL), https://www.openstreetmap.org/copyright
