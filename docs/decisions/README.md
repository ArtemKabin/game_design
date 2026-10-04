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

## Open questions (not yet decided)

* Concept and storyboard for Level 2 (final level). Nothing beyond the README exists yet.
