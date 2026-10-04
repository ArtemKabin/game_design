# 0014: The ship is one continuous world, the map is an overlay

* Date: 2026-10-04
* Status: accepted (replaces the hub map from 0004/0011 flow; the fog-of-war idea from 0004 stays)
* Participants: both developers

## Context
Until now the game jumped between separate scenes: menu, a hub map with level buttons, a level, a transition minigame scene. It felt like a menu system, not like a ship. The layout image in the README already shows the ship as one deck: bridge in the middle, a corridor from its left door running left and down into the cargo bay.

## Decision
* **One scene for the ship** (`world.tscn`). Rooms are children of it, placed where they are on the deck layout. Each room is its own scene whose root extends `Room` (`room.gd`): the world hands it the player, the room reports status text, game over and door hits back.
* **Doors connect rooms.** Walking into an open `ExitDoor` teleports the player into the target room at that door's `target_spawn`. The camera limits switch to the new room and the camera glides over. The previous room stays visible but **greyed out**; rooms the player has not reached are **invisible** (fog of war).
* **The map is an overlay**, opened with **Tab or M**, and it **pauses** the game. It draws visited rooms in true proportion: current room cyan, solved levels green, nothing for unvisited rooms.
* **The cargo rail corridor** (`corridor_l.tscn`, room id 10) is the transition minigame as a room: L-shaped, entered from the bridge at the top right, left and then down to Level 1. Only the cart can travel it; on foot the rail zaps you back to the platform. The cart parks on the goal platform and waits there for the trip back.
* **Level 1 has no exit of its own.** Entrance door in the top wall. The crates hide the **cargo control panel**; using it opens the **right-hand door on the bridge** (towards Level 2). The player drives the rail back up to the bridge.
* The main menu's Start loads the world; the hub map scene and the standalone transition scene are deleted.

## Consequences
Rooms never own the player, HUD, game-over panel or hint popup; those live in the world. A room-specific UI layer (Level 0's oxygen bar and wiring panel) has to be shown and hidden by the room itself, because CanvasLayers ignore the room's visibility. New rooms: extend `Room`, set `room_id`, `room_title`, `bounds`, place `ExitDoor` instances with `target_room_id` and `target_spawn`, call `register_doors()`. Door spawns must sit outside every door area of the target room, or the player bounces straight back. Restarts after game over reset the room, not the whole game.
