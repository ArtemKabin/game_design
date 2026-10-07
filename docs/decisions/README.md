# Decision Log (Entscheidungsprotokoll)

Every non-trivial development decision gets one short file in this folder. The point is that both developers can look up *why* something is the way it is, weeks later, without digging through chat history.

Owner: Person B keeps the log, but **anyone** adds an entry when a decision is made. Reviewer of a PR checks whether a new entry is needed.

## Rules

* One file per decision, numbered: `NNNN-short-title.md`.
* Keep it short. Context, decision, consequences. Three paragraphs is plenty.
* Decisions are never deleted or edited after the fact. If a decision is reversed, add a new entry and set the old one to `Status: superseded by NNNN`.
* Language: English (same as the README).

## Template

```markdown
# NNNN: Title

* Date: YYYY-MM-DD
* Status: accepted | superseded by NNNN | open
* Participants: Person A, Person B

## Context
What was the question or problem? What alternatives were on the table?

## Decision
What did we decide, in one or two sentences?

## Consequences
What follows from it? What do we give up?
```

## Index

| # | Title | Status |
| :--- | :--- | :--- |
| [0001](0001-puzzle-genre.md) | Puzzle game instead of game-loop or inverse side-scroller | accepted |
| [0002](0002-godot-web-export-hosting.md) | Godot with web export, self-hosted via GitHub Actions or itch.io | accepted |
| [0003](0003-title-and-setting.md) | Title "Deceptive Wiring" and spaceship setting | accepted |
| [0004](0004-perspective-map-camera.md) | 2.5D top-down, fog-of-war map with zoom, room-to-room camera | accepted |
| [0005](0005-art-direction-and-assets.md) | Dark blue accent palette, assets made in Blender | accepted |
| [0006](0006-scope-and-team-split.md) | Scope cut to 3 levels, team split Person A / Person B, KEEP IT SIMPLE | accepted, role split replaced by 0009 |
| [0007](0007-hosting-on-itch-io.md) | Web build is hosted on itch.io | accepted |
| [0008](0008-2-5d-as-2d-scenes.md) | "2.5D" is implemented with 2D scenes, 3D scene stays a layout sketch | accepted |
| [0009](0009-no-fixed-role-split.md) | No fixed role split, both continue from the current state | accepted |
| [0010](0010-keyboard-first-ui.md) | Everything is playable without a mouse, one key set everywhere | accepted |
| [0011](0011-exit-door-and-transition-minigame.md) | Levels end with an exit door, a minigame sits between levels | accepted |
| [0012](0012-heavy-cart-snake-driving.md) | Heavy cart drives snake-style, transition minigame is a cart run | accepted, controls replaced by 0013 |
| [0013](0013-cart-continuous-steering.md) | Cart steers continuously with A/D, always starts facing up, harder map | accepted |
| [0014](0014-one-world-map-overlay.md) | The ship is one continuous world, the map is a Tab/M overlay, corridor is the minigame | accepted |
| [0015](0015-level-1-tool-hunt.md) | Level 1 is a tool hunt (cabins loop, rubber hammer, crowbar); "umfahren" means drive around | superseded by 0016 to 0018 |
| [0016](0016-rail-s-shape-no-storage-room.md) | Cargo rail runs left, down, left and enters Level 1 from the right; storage room and crowbar removed | accepted |
| [0017](0017-quarantine-queues-loop-to-bridge.md) | Quarantine cabins are airport queues with a mandatory station and locked doors; D exits onto the bridge; no tool hunt | accepted |
| [0018](0018-crate-wall-no-tarp-gap.md) | The crates are space junk: shove them into the airlock with the cart, a lever jettisons them; cargo control room gone | accepted |
| [0019](0019-hud-and-text-polish.md) | HUD shows only the room title, status text types in and waits to be read, no emojis, bigger rail stubs | accepted |
| [0020](0020-level-2-launch-clearance.md) | Level 2 is the hangar: launch clearance by real double meanings (abheben, einstellen, aufgeben), launch-window countdown, then escape and end screen | accepted |
| [0021](0021-east-rail-shared-corridor-script.md) | A second cart rail (east, slalom) between bridge and hangar; both rails share rail_corridor.gd | accepted |

## Open questions (not yet decided)

* Polish of Level 2 (final level): wording of the three clearance steps, look of the shuttle, end screen text. The level itself is built (0020).
* Difficulty of the two rails and the junk shove in Level 1: needs playtesting with a keyboard.
