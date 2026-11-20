# Feature Specification: Demo-Gameloop (eine Uni-Woche)

**Feature Branch**: `001-demo-gameloop`
**Created**: 2026-11-20
**Status**: Implemented (Demo)
**Input**: "Gameloop schließen für die Playtest-Demo: Einführungsscreen mit Story, Hauptmenü ähnlich Game 2 (ohne Assets), Smartphone mit Steuerung/UI (Karte, Kontakte, To-do-Liste, Stundenplan), 1–3 Minispiele an Uni-Eingängen, Abgabe am Freitag, deren Schwierigkeit von der Prüfungssicherheit abhängt und Punkte für eine globale Prüfungssicherheit (Klausur nach 3 Loops) sammelt. Loop endet nach einer Spielwoche. Keine neuen Spielorte. Kachelboden um das Wohnheim entfernen."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Start: Menü und Story-Intro (Priority: P1)

Ein Playtester startet das Spiel, landet im Hauptmenü, wählt "Neues Spiel", liest ein kurzes
Story-Intro (wer bin ich, was passiert diese Woche, was ist das Ziel) und steht danach am Montag
08:00 in seinem Wohnheimzimmer.

**Why this priority**: Ohne Einstieg weiß ein Playtester nicht, worum es geht (Onboarding First).

**Independent Test**: Spiel starten → Menü sichtbar → Neues Spiel → Intro durchklicken oder mit Esc
überspringen → Spielfigur im Zimmer, Uhr "Woche 1 · Montag 08:00".

**Acceptance Scenarios**:

1. **Given** das Spiel startet, **When** es geladen ist, **Then** erscheint das Hauptmenü mit
   "Neues Spiel", "Steuerung" und "Einstellungen" (Wartungs-Screen mit Zurück).
2. **Given** das Hauptmenü, **When** "Steuerung" gewählt wird, **Then** erscheint eine Übersicht
   aller Tasten, mit Zurück ins Menü.
3. **Given** das Intro läuft, **When** der Spieler Leertaste/E/Klick drückt, **Then** kommt die
   nächste Seite; **When** Esc, **Then** startet das Spiel sofort.
4. **Given** ein vorheriger Durchlauf, **When** "Neues Spiel" gewählt wird, **Then** beginnt die
   Woche mit Startwerten (Uhr, Stats, Lernpunkte, To-dos); nur die globale Klausurvorbereitung
   bleibt erhalten.

---

### User Story 2 - Smartphone (Priority: P1)

Der Spieler öffnet jederzeit sein Handy (Tab) und sieht vier Apps: Karte, Kontakte, To-dos,
Stundenplan. Damit weiß er ohne Erklärung, wo er hin muss und was diese Woche ansteht.

**Why this priority**: Das Handy ersetzt die Erklärung von außen und trägt die Woche
(Stundenplan, Deadline).

**Independent Test**: Im Spiel Tab drücken → Handy erscheint, Uhr steht → jede App öffnen und
mit Zurück/Esc zum Homescreen → Tab schließt.

**Acceptance Scenarios**:

1. **Given** das Spiel läuft, **When** Tab gedrückt wird, **Then** öffnet sich das Handy, die
   Spielzeit steht und die Figur bewegt sich nicht.
2. **Given** das Handy ist offen, **When** "Karte" gewählt wird, **Then** schließt das Handy und
   die Kartenansicht von oben öffnet sich; die Uni-Stationen sind darauf beschriftet.
3. **Given** "Kontakte", **Then** stehen dort alle Figuren mit Rolle, wann man sie zuletzt
   getroffen hat und ob sie gerade etwas Wichtiges zu erzählen haben.
4. **Given** "To-dos", **Then** stehen dort die Wochenziele mit Fortschritt (z. B. "Vorlesungen
   besuchen 1/3") und die Abgabe mit Frist; erledigte sind abgehakt.
5. **Given** "Stundenplan", **Then** stehen dort die Termine Mo–Fr mit Uhrzeit und Gebäude;
   der heutige Tag und ein laufender Termin sind hervorgehoben.

---

### User Story 3 - Minispiele an der Uni (Priority: P2)

An Eingängen von Uni-Gebäuden gibt es Stationen: "Vorlesung" (Gebäude B) und "Lerngruppe"
(Gebäude LB). Sie kosten Spielzeit, bringen Lernpunkte und damit Prüfungssicherheit. Eine
Vorlesung zur Zeit im Stundenplan bringt mehr.

**Why this priority**: Gibt dem Weg zur Uni und dem Stundenplan einen Sinn.

**Independent Test**: Zur Station laufen → E → Minispiel spielen → Ergebnis → zurück an der
Station, Uhr vorgerückt, Lernpunkte und To-do-Fortschritt gestiegen.

**Acceptance Scenarios**:

1. **Given** der Spieler steht an der Vorlesungs-Station, **Then** zeigt der Prompt Titel, Dauer
   und ob gerade laut Stundenplan Vorlesung ist (Bonus).
2. **Given** das Vorlesungs-Minispiel, **When** der Spieler Fachbegriffe anklickt, **Then** gibt
   es Punkte; Ablenkungen anzuklicken kostet Punkte.
3. **Given** das Lerngruppen-Minispiel, **When** der Spieler zwei Karten aufdeckt, die
   zusammengehören (Begriff ↔ Erklärung), **Then** bleiben sie offen und geben Punkte.
4. **Given** ein Minispiel wurde heute schon gespielt, **Then** kann es trotzdem nochmal
   gespielt werden (kostet erneut Zeit).

---

### User Story 4 - Abgabe am Freitag und Wochenbilanz (Priority: P1)

Am Freitag (08:00–18:00) gibt man in Gebäude A das Übungsblatt ab: ein Minispiel, das leichter
ist, je höher die Prüfungssicherheit ist. Die Note bringt Punkte für die globale
Klausurvorbereitung. Danach (oder wenn die Frist 18:00 verstreicht) endet die Woche mit einer
Bilanz und es geht zurück ins Menü.

**Why this priority**: Schließt den Loop: Handeln in der Woche → spürbare Konsequenz → Ende.

**Independent Test**: Woche bis Freitag spielen (Schlafen überspringt Tage) → Gebäude A → Abgabe
spielen → Bilanz mit Note, Ursachen und Klausurpunkten → Menü.

**Acceptance Scenarios**:

1. **Given** es ist nicht Freitag, **When** der Spieler die Abgabe-Station nutzt, **Then** kommt
   "Abgabe erst am Freitag (08:00–18:00)".
2. **Given** Freitag vor 18:00, **When** die Abgabe startet, **Then** zeigt die Intro-Karte die
   Schwierigkeit und den Grund ("Prüfungssicherheit 34 % → mittel").
3. **Given** höhere Prüfungssicherheit, **Then** ist die Abgabe messbar leichter (mehr Zeit pro
   Fehler, weniger Fallen).
4. **Given** die Abgabe ist beendet, **Then** erscheint die Wochenbilanz mit Note, erledigten
   To-dos, Prüfungssicherheit, gewonnenen und gesamten Klausurpunkten und dem Hinweis auf die
   Klausur in 3 Wochen.
5. **Given** Freitag 18:00 ohne Abgabe, **Then** erscheint die Wochenbilanz mit "nicht abgegeben"
   und 0 Klausurpunkten.

---

### User Story 5 - Schlafen und Wohnheim-Boden (Priority: P3)

Der Spieler kann im eigenen Bett schlafen und den Tag beenden. Der gekachelte Boden um das
Wohnheim-Stockwerk ist weg.

**Independent Test**: Bett → "Schlafen" → nächster Tag 08:00. Kein Gitter-/Kachelboden um die
Etage sichtbar.

**Acceptance Scenarios**:

1. **Given** der Spieler am Bett, **When** "Schlafen" gewählt wird, **Then** folgt die
   Nacht-Überblendung und der nächste Tag beginnt 08:00 (am Freitag vor der Abgabe warnt der
   Prompt, dass die Abgabe dann verpasst wird).
2. **Given** die Wohnheim-Szene, **Then** liegt um die Etage ein schlichter dunkler Boden ohne
   Kachelmuster.

### Edge Cases

- Handy während Dialog oder Minispiel: öffnet nicht.
- Kartenansicht offen und Handy öffnen: Karte wird zuerst geschlossen.
- Frist 18:00 läuft ab, während ein Minispiel läuft: Uhr steht im Minispiel; beim Zurückkehren
  wird die Zeit gebucht, überschreitet sie 18:00, endet die Woche danach.
- Abgabe gestartet, aber im Intro mit Esc abgebrochen: zählt nicht, Frist läuft weiter.
- Schlafen am Freitag ohne Abgabe: Woche endet mit "nicht abgegeben".

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Das Spiel MUSS im Hauptmenü starten (Neues Spiel, Steuerung, Einstellungen als Wartungs-Screen mit Zurück; kein Beenden).
- **FR-002**: "Neues Spiel" MUSS ein mehrseitiges Story-Intro zeigen (weiterklicken, Esc überspringt)
  und danach Montag 08:00 im eigenen Zimmer starten.
- **FR-003**: "Neues Spiel" MUSS alle Wochenwerte zurücksetzen; die globale Klausurvorbereitung bleibt.
- **FR-004**: Tab MUSS das Handy öffnen/schließen; solange es offen ist, stehen Uhr und Figur.
- **FR-005**: Das Handy MUSS die Apps Karte, Kontakte, To-dos und Stundenplan haben.
- **FR-006**: Stundenplan, To-dos und Intro-Texte MÜSSEN aus einer Datendatei kommen.
- **FR-007**: Es MUSS zwei Uni-Minispiele an Gebäudeeingängen geben (Vorlesung, Lerngruppe) und
  eine Abgabe-Station; sie sind in der Kartenansicht beschriftet.
- **FR-008**: Eine Vorlesung, die während ihres Stundenplan-Termins gespielt wird, MUSS mehr
  Lernpunkte geben (×1,3) und das im Prompt anzeigen.
- **FR-009**: Die Abgabe MUSS nur freitags 08:00–18:00 möglich sein und ihre Schwierigkeit aus der
  aktuellen Prüfungssicherheit ableiten; die Intro-Karte nennt Stufe und Grund.
- **FR-010**: Das Abgabe-Ergebnis MUSS Klausurpunkte (0–25) für die globale Klausurvorbereitung geben.
- **FR-011**: Nach der Abgabe oder bei verstrichener Frist (Fr 18:00) MUSS eine Wochenbilanz kommen,
  die Ergebnis und Ursachen in Zahlen nennt, mit Rückkehr ins Menü.
- **FR-012**: Im eigenen Zimmer MUSS man schlafen können (Tag sofort beenden).
- **FR-013**: Der Kachel-/Gitterboden um die Wohnheim-Etage MUSS durch einen schlichten Boden ersetzt werden.
- **FR-015**: Zeit ohne Lernen MUSS Prüfungssicherheit langsam wieder abziehen, höchstens 50 % des in der Woche Gelernten.
- **FR-016**: Eine verpasste Abgabe MUSS als Note 5,0 mit eigenem Screen und Grund angezeigt werden.
- **FR-014**: Die Story-Texte der Figuren MÜSSEN zur Wochenstruktur passen (Klausur in 3 Wochen).

### Key Entities

- **Stundenplan-Termin**: Tag, Start, Ende, Titel, Gebäude, zugehörige Station.
- **Wochen-To-do**: Text, zugehörige Station, Ziel-Anzahl, Fortschritt diese Woche.
- **Abgabe-Ergebnis**: abgegeben ja/nein, Note, Schwierigkeitsstufe, Klausurpunkte.
- **Klausurvorbereitung (global)**: Summe der Klausurpunkte über Loops, Wochen bis zur Klausur.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Ein neuer Spieler findet ohne Hilfe von außen innerhalb von 3 Minuten Spielzeit die
  erste Uni-Station (über Handy-Karte oder Stundenplan).
- **SC-002**: Eine komplette Demo-Woche (Mo bis Abgabe) ist in 15–30 Minuten Echtzeit spielbar.
- **SC-003**: Bei Prüfungssicherheit ≥ 60 % erreichen Testspieler in der Abgabe im Schnitt eine
  bessere Note als bei < 25 %.
- **SC-004**: Jede Wochenbilanz nennt mindestens 3 Zahlen, die das Ergebnis erklären.
- **SC-005**: Das Spiel startet ohne Skriptfehler und der Loop Menü → Woche → Bilanz → Menü ist
  ohne Neustart wiederholbar.

## Assumptions

- Demo spielt nur Mo–Fr; das Wochenende ist in der Bilanz nur erwähnt (Loop endet mit der Abgabe).
- Für die Demo läuft die Uhr schneller: 1 Spieltag (08–22 Uhr) ≈ 4,7 min Echtzeit (statt 14 min).
- Keine neuen Spielorte; Minispiele sind Vollbild wie die bestehenden drei.
- Keine Speicherung im Browser für die Demo; die globale Klausurvorbereitung hält nur, solange das
  Spiel läuft. Speichern und die echte Klausur nach 3 Loops sind Teil des finalen Releases.
- Handy pausiert die Zeit (Demo-Entscheidung zugunsten der Lesbarkeit).
- Platzhalter-Optik, keine neuen Assets.
