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
| [0022](0022-flip-visible-wall-and-menu-layout.md) | FLIP: back wall is a visible node with Sprite2D placeholder; menu UI on CanvasLayer + Control + CenterContainer | accepted, wall part replaced by 0024 |
| [0023](0023-flip-virtual-holes-and-safe-zones.md) | FLIP: holes are virtual (solid floor + Area2D kill zone), safe zones alternate with pattern hazards | accepted |
| [0024](0024-flip-one-world-spheres-no-wall.md) | FLIP: spheres exist in one world only and may patrol; back wall removed | accepted |
| [0025](0025-flip-sight-radius-glowing-markers.md) | FLIP: sight radius shrinks with distance travelled and regrows when standing; safe markers glow above the fog | accepted |
| [0026](0026-flip-hunter-stars.md) | FLIP: hunter stars freeze and kill when visible, hunt the player when hidden, despawn off screen | accepted |
| [0027](0027-flip-one-chunk-type-three-floors.md) | FLIP: one hazard chunk type; floor chars `#` `.` `=`; spheres and stars on any pattern | accepted |
| [0028](0028-flip-help-story-and-unlockable-tips.md) | FLIP: HILFE overlay in main and pause menu with the story and tips; four tips unlock through deaths, persisted per browser | accepted |
| [0029](0029-game3-3d-topdown-real-scale.md) | Game 3: real 3D, top-down camera, 1 unit = 1 m, 1.75 m placeholder student, greybox blocks | accepted |
| [0030](0030-game3-bean-and-dorm-room.md) | Game 3: bean player; dorm room 3.0 × 5.5 m with closet part and middle doors; cutaway walls | accepted (view part superseded by 0035) |
| [0031](0031-game3-dorm-floor-locked-rooms.md) | Game 3: dorm floor with four rooms and a corridor; `locked` rooms get roof and closed door | accepted |
| [0032](0032-game3-shared-kitchen.md) | Game 3: shared kitchen 4.0 × 7.5 m at the corridor end: fridges, counter with stove, sinks and resident cabinets; bins, shelf and table on the right wall | accepted |
| [0033](0033-game3-t-corridor.md) | Game 3: T-shaped dorm corridor, side corridor with two rotated rooms; `low_roof` for locked rooms in front of walkable areas | accepted (view part superseded by 0035) |
| [0034](0034-game3-wc-and-showers.md) | Game 3: two WCs and a shower block (mini corridor, two separate cabins) south of the main corridor; transparent `Block` colours | accepted |
| [0035](0035-game3-room-view-zones.md) | Game 3: full walls; RoomView + Zones: active room lit, others shaded, occluders in front cut; dorm exit with doormat | accepted |
| [0036](0036-game3-outside-and-portals.md) | Game 3: real dorm and campus outside 1:1 from OSM (north up, relations, connected roads, no overlaps), entrances on the shared footway; Portals + Spawns; RoomView outdoors | accepted |

## Open questions (not yet decided)

* Polish of Level 2 (final level): wording of the three clearance steps, look of the shuttle, end screen text. The level itself is built (0020).
* Difficulty of the two rails and the junk shove in Level 1: needs playtesting with a keyboard.
