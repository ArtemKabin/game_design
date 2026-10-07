# 0020: Level 2 is the hangar: launch clearance by double meanings, then escape

* Date: 2026-10-08
* Status: accepted
* Participants: both developers

## Context
Level 2 was an open concept ("combines all mechanics"). With one week of scope, the final level needs to be small. A first draft used the Reactor Core backlog idea (manual says *Leistung erhöhen*, the correct action is the reverse) and was dropped the same day: an invented reversal cannot be deduced, the player can only guess, and the panel did not feel like the rest of the game, which lives on real German double meanings (*umfahren*, *Schlag auf den Schacht*).

## Decision
* Level 2 is the **hangar**, right of the bridge, with a **space shuttle** on a launch pad. The right door on the bridge, opened by Level 1, leads there.
* E at the shuttle opens a **launch-clearance panel**, built like the wiring panel in Level 0: a radio line from ground control and two buttons, the two readings of the instruction. Three steps in a row, each a **real double meaning**: *"Hebe ab."* (launch button vs. pick up the ringing phone), *"Stell die Triebwerke ein."* (adjust vs. shut down), *"Gib dein Gepäck auf."* (leave it vs. check it in). Ground control always means the less obvious one.
* The obvious reading gets a one-line remark, the step stays open, and the **launch window starts closing**: a bar runs from 100 to 0 in ten seconds (like the oxygen in Level 0) until all three steps are done; at 0 it is game over and the clearance starts over. The failure also counts towards the hint ("Jedes Wort hat zwei Bedeutungen. Die Bodenkontrolle meint immer die andere."). Room UI layers sit below the world's HUD layer so that the hint popup appears over the panel.
* After three steps the shuttle is cleared. E again: the player boards, the shuttle flies off, an **end screen** ("ENTKOMMEN") with a button to the main menu ends the game. No separate credits.

## Consequences
The game is complete end to end: bridge, rail, cargo bay, quarantine loop, hangar. Step texts live in a constant in `level_2_hangar.gd` (radio line, two options, fail and done texts), so wording can be tuned without touching the scene. The Reactor Core concept stays in the backlog as tried and rejected.
