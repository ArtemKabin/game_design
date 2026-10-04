# 0008: "2.5D" is implemented with Godot 2D scenes, the 3D scene stays a layout sketch

* Date: 2026-10-04
* Status: accepted
* Participants: both developers

## Context
Decision 0004 says 2.5D top-down, which does not pin down a Godot approach. The repo held both: Level 0 as a 2D scene (`Node2D`, `PointLight2D`, `CanvasModulate` for the dark room) and `scene.tscn`, a 3D sketch of the ship layout built from CSG boxes with a `CharacterBody3D` player. The main menu's start button pointed at the 3D sketch.

Options:

* 2D scenes with lighting, Y-sorting and pre-rendered sprites for the 2.5D look.
* 3D scenes with a fixed top-down camera and 2D sprites (`Sprite3D`).

## Decision
Rooms and the ship map are built as **2D scenes**, continuing the approach of Level 0. The "2.5D" look comes from 2D lighting, dark `CanvasModulate`, and later from Blender assets rendered out as sprites. `scene.tscn` is kept only as a layout reference for the map and is no longer started by the menu.

## Consequences
Level 0 stays as it is. Level 1 and the final level are built with the same node types, so camera, player and HUD can be reused. Blender work produces sprite sheets or single rendered images, not meshes for the game. If this turns out to be the wrong call, the switch to 3D has to happen before Level 1 is built, not after.
