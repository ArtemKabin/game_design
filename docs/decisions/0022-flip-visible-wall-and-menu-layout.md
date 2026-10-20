# 0022: FLIP: the back wall is visible, menus live on a CanvasLayer

* Date: 2026-10-20
* Status: accepted
* Participants: Person A, Person B

## Context
Game 2 ("FLIP", folder `game-2-flip/`) punishes hesitation with a back wall that advances at the scroll speed. The wall was pure logic in `game.gd` with no visual, so standing still looked like a random death. The main menu placed its Controls directly under a Node2D, which made the panel sit off-centre.

## Decision
The wall gets its own node (`Wall`, script `wall.gd`) that `game.gd` moves every frame. It carries a `Sprite2D` without texture as the asset placeholder; until a texture is assigned, the script draws a flat band that recolours on world flip. All menu UI sits on a CanvasLayer with a full-screen Control root and a CenterContainer around the panel.

## Consequences
Everything built for FLIP keeps open placeholders for assets and styling: Sprite2D or TextureRect nodes without textures plus a drawn fallback. Replacing the wall art means assigning a texture whose right edge is the wall front. The wall speed values (start 140 px/s, max 380 px/s) are unchanged and still open for tuning.
