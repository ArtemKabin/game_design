# 0038: Game 3: main menu with story intro, settings as a maintenance screen, title placeholder

* Date: 2026-11-20
* Status: accepted
* Participants: Person A, Person B

## Context
Playtesters need to know who they are and what this week is about before they walk around (onboarding first, feedback from Game 1 and 2). The menu should feel like Game 2 but without assets. The game has no name yet; "Atmosphere" is only the course theme.

## Decision
The game starts in `scenes/ui/main_menu.tscn`, built in code: Neues Spiel, Steuerung, Einstellungen. "Neues Spiel" shows five intro pages (typewriter text, Space/click next, Esc skips) and then Monday 08:00 in the room. Einstellungen opens a `MaintenancePanel` (construction tape, "Wartungsarbeiten", planned settings, Zurück) that can be reused for anything not built yet. No Beenden button, because the demo runs in the browser. The title reads "[Name in Abstimmung]" until the team has voted; project and build names stay "Atmosphere".

## Consequences
Settings themselves (volume, fullscreen, speed, key bindings) are open. The name has to be changed in the menu once it is decided.
