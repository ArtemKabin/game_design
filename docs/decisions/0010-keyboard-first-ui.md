# 0010: Everything is playable without a mouse

* Date: 2026-10-04
* Status: accepted
* Participants: both developers

## Context
Menus, the ship map and in-level buttons (continue, restart, hint popup, the wiring trap panel) were mouse-only, while the levels themselves are played with the keyboard. Switching between keyboard and mouse felt wrong.

## Decision
Every menu and button is reachable with the keyboard. One key set everywhere:

| Keys | Meaning |
| :--- | :--- |
| W / S, A / D, arrow keys | move the player in levels, move the selection in menus |
| E | interact (levels), accept (menus) |
| F | hit (levels), accept (menus) |
| Enter, Space | accept (menus) |

Implemented through Godot's focus system: W/S/A/D are added to the built-in `ui_up/down/left/right` actions, E and F to `ui_accept`. Each menu focuses a sensible first button on open. Mouse still works.

## Consequences
In Level 0, F must beat the focused wiring button, otherwise pressing F while the trap panel is open would connect a wire instead of hitting the vent. The level handles `hit` in `_input` before the GUI sees the event. New UI needs to focus a button when it appears, or it is unreachable without a mouse. Reviewers check for that.
