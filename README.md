# Game 1 Overview: Sci-Fi Puzzle Game ("Deceptive Wiring")

## 1. Concept & Game Name
A spaceship circuit puzzle game where the most intuitively obvious path is a trap. 

### Visuals & Room Design (Fog of War)
* Everything is pitch black at the start.
* Only the starting room is visible.
* Solving puzzles unlocks doors and reveals adjacent areas (such as Level 1 and Level 2).

### Official Name
* **Deceptive Wiring**

## 2. Level Overview (6 Planned Spaceship Levels & Hints)

| Level | Spaceship Area | Puzzle Mechanics & Linguistic Trap | Failure Hint ("Hinweis") | Visibility Status |
| :--- | :--- | :--- | :--- | :--- |
| **Level 0** | **Bridge / Life Support** (Tutorial Room) | User instruction: *"Repariere das Lebenserhaltungssystem."*<br>Trap: Using proper tools (wrench/soldering iron) triggers a lethal oxygen countdown. Hitting the air vent like an old TV fixes it. | *"Kennst du den Trick mit dem alten Röhrenfernseher? Manchmal hilft rohe Gewalt mehr als Präzision!"* | Visible from the start (fully lit). |
| **Level 1** | **Cargo Bay** | User instruction: *"Fahre das Hindernis um."*<br>Trap: Trying to steer around the crate (*umgehen*) fails; you must crash straight through it (*umfahren*). | *"Manchmal muss man Probleme direkt anfahren, anstatt ihnen aus dem Weg zu gehen."* | Unlocked and revealed after completing Level 0. |
| **Level 2** | **Engine Room** | User instruction: *"Folge der Leitung."*<br>Trap: Following the optical power line leads to a dead end; players must take over system command (*Leitung*). | *"Wer steuert hier eigentlich das Schiff? Hör auf die Kabel und übernimm das Kommando!"* | Revealed after completing Level 1. |
| **Level 3** | **Security Sector** | User instruction: *"Betätige die Schaltung."*<br>Trap: Digital buttons distract the player; the solution requires operating a mechanical gearshift. | *"Elektronik ist nicht alles. Manchmal braucht es handfestes Getriebe statt Digital-Schnickschnack."* | Adjacent to Level 2, accessible after its completion. |
| **Level 4** | **Reactor Core** | Complex language traps where technical vocabulary terms (*Leistung*, *Spannung*) must be interpreted in reverse. | *"Glaub nicht alles, was das Handbuch dir sagt. Die Definition von Leistung ist hier verdreht."* | Hidden in the fog, revealed after Level 3. |
| **Level 5** | **Evacuation Zone** (Finale) | The final room combining all learned "obvious is wrong" mechanics to save the ship. | *"Vergiss alles, was logisch erscheint. Der falsche Weg ist der einzige Ausweg."* | The ultimate goal, unlocked only after Level 4. |

---
## 3. Language Mechanics: Confusing Level Instructions in German
German is exceptionally well-suited for this game concept because grammatical quirks, separable verbs, and double meanings serve as psychological and logical traps within player instructions.

### Core Puzzles: Separable Verbs & Double Meanings
Depending on how the player reads or interprets an instruction, the seemingly logical path leads straight into a dead end.

| German Instruction / Word | Literal / Obvious Meaning | Actual Game Logic ("Wrong is Right") |
| :--- | :--- | :--- |
| **"Schlage auf den Lüftungsschacht."** *(Level 0)* | Gently tap or punch the air vent like an old television set to fix the rattling fan. | Trying to use technical repair tools (wrench/soldering iron) which triggers a countdown failure. |
| **"Fahre das Hindernis um."** *(Level 1)* | Steer around the obstacle (*umgehen*). | Ram and destroy the obstacle (*umfahren*). |
| **"Folge der Leitung."** *(Level 2)* | Follow a data or power line through the room. | Take over the leadership / system command (*Leitung*). |
| **"Betätige die Schaltung."** *(Level 3)* | Activate an electrical switch or circuit. | Operate a mechanical gearshift transmission. |

---

## 4. UI Design & Localization Challenge
Since the game is localized in German, UI elements and buttons must accommodate notoriously long German compound words (Komposita).

* **UI Button Example:** Where English uses short terms (e.g., *"Settings"*), German requires compound terms like *Leiterplattenkonfigurationsüberschreibungseinstellung*.
* **UI Design Tip:** Buttons should be flexible, dynamically scalable, or paired with icons to fit the space demands of the German language without cluttering the interface.