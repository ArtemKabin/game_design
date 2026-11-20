# itch.io-Seite: Game 3 Demo (Playtest 1)

Text und Einstellungen für die Projektseite auf itch.io. Build: `build/atmosphere-web.zip`
(gleiche Datei geht an den Dozenten). Entscheidung: `docs/decisions/0043`.

## Einstellungen auf itch.io

| Feld | Wert |
| :--- | :--- |
| Title | [Name in Abstimmung] – Demo |
| Kind of project | HTML |
| Upload | `atmosphere-web.zip`, Haken bei „This file will be played in the browser“ |
| Viewport dimensions | 1280 × 720 |
| Embed options | „Fullscreen button“ an, „Automatically start on page load“ aus (Klick zum Starten), „Mobile friendly“ aus |
| SharedArrayBuffer support | aus (der Build ist single-threaded und braucht es nicht) |
| Classification | Games · Genre: Simulation · Tags: university, student, stress, top-down, 3D, singleplayer |
| Visibility | Restricted oder Draft bis zum Playtest, dann Public bzw. per Link |

## Beschreibung (zum Einfügen)

**[Name in Abstimmung]** – eine Woche Uni. Eine Abgabe. Und irgendwo dazwischen: du.

Erstes Semester, Wohnheim 17F. Am Freitag um 18 Uhr ist das erste Übungsblatt in Gebäude A fällig, in drei Wochen die Klausur. Geh in Vorlesungen, triff deine Lerngruppe, führ dein Lernjournal, räum auf, iss, schlaf. Jede Aktion kostet Zeit, und was du nicht wiederholst, vergisst du langsam wieder. Je sicherer du dich fühlst, desto leichter wird die Abgabe.

Unser Hochschul-Campus und das Wohnheim sind 1:1 nach OpenStreetMap nachgebaut (© OpenStreetMap-Mitwirkende, ODbL).

Dies ist die **Demo für den ersten Playtest** (Greybox, ohne Grafik-Assets und Sound). Eine Woche dauert etwa 15–30 Minuten.

### Steuerung

| Taste | Aktion |
| :--- | :--- |
| WASD / Pfeiltasten | Laufen |
| Shift | Rennen |
| E / Leertaste | Interagieren, reden, weiter |
| Tab | Handy: Karte, Kontakte, To-dos, Stundenplan |
| M | Karte an/aus (Maus ziehen = verschieben) |
| Mausrad | Zoom |
| Maus | Minispiele |
| Esc | Zurück / Intro überspringen |

Tipp: Wenn die Tasten nicht reagieren, einmal ins Spielfenster klicken.

### Bekannte Mängel

* Der Name steht noch nicht fest, im Menü steht ein Platzhalter.
* Greybox-Optik, keine Musik, keine Soundeffekte.
* Kein Speicherstand: Neu laden im Browser setzt alles zurück. Die Klausurpunkte zählen nur, solange der Tab offen ist.
* Gespielt wird nur Montag bis Freitag. Wochenende, weitere Wochen und die Klausur nach drei Wochen fehlen noch.
* „Einstellungen“ ist ein Platzhalter (Wartungsarbeiten).
* Uni-Gebäude kann man nicht betreten; Vorlesung, Lerngruppe und Abgabe sind Vollbild-Minispiele an den Eingängen. Die meisten anderen Türen sagen „Hier wird noch gearbeitet“.
* Balancing ist ein erster Wurf: Uhrtempo, Schwierigkeit der Minispiele und das Vergessen werden mit euren Daten angepasst.
* Nur Tastatur und Maus, keine Touch- oder Controller-Steuerung.
* Erster Ladevorgang ca. 10 MB (entpackt 40 MB). Auf schwachen Laptops kann der Außenbereich ruckeln.
* Einige Beschriftungen können sich bei bestimmten Zoomstufen noch überlappen.
* Ladehänger beim ersten Betreten des Campus (der Web-Build läuft auf einem Thread).
* Wenig Story-Inhalt (7 Story-Begegnungen und einige Zufallsbegegnungen).

### Was wir bis zu den nächsten Tests angehen

* Namen festlegen.
* Speichern im Browser, damit die Woche und die Klausurpunkte einen Reload überleben.
* Mehrere Wochen-Loops, Wochenende und die Klausur nach drei Wochen, bei der die gesammelten Klausurpunkte zählen.
* Einstellungen: Lautstärke, Vollbild, Spieltempo, Tastenbelegung.
* Sound und Musik, erste Assets für Figur, Zimmer und Campus.
* Mehr Ereignisse aus verschiedenen Pools, Ereignisketten, Jobs, Fahrrad, Essen kaufen.
* Balancing anhand eures Feedbacks und Performance im Außenbereich.
* Ladeschirm beim Wechsel nach draußen, Shader im Menü vorwärmen.

### Technische Hinweise

* Empfohlen: aktueller Chrome, Edge oder Firefox am Laptop/PC mit **aktivierter Hardwarebeschleunigung** (Browser-Einstellungen → System). Ohne sie läuft das Spiel sehr langsam.
* Beim ersten Verlassen des Wohnheims und bei der ersten Karte hängt das Spiel einige Sekunden, weil der Campus aufgebaut wird. Bitte warten, nicht neu laden. Meldet der Browser „Seite reagiert nicht“, auf **Warten** klicken.

**Danke fürs Testen! Bitte füllt danach den Feedbackbogen aus.**

Kartendaten (Gebäude, Wege, Bäume) abgeleitet aus © OpenStreetMap-Mitwirkende, verfügbar unter der Open Database License (ODbL): https://www.openstreetmap.org/copyright – die abgeleiteten Kartendaten im Spiel stehen ebenfalls unter der ODbL.
