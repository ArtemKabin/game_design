class_name Room
extends Node2D

# Base class for every room in the ship (levels and corridors). See docs/decisions/0014.
# The world (world.gd) owns the player, the HUD and the camera. A room:
#  - gets the player handed in via enter(), gives it back via leave()
#  - reports text for the HUD with set_status()
#  - reports a game over with game_over.emit(); the world shows the panel and calls restart()
#  - reports a door the player walked into with door_entered; the world does the teleport
# Override _on_enter / _on_leave / _on_restart in the room script.

signal status_changed(text: String, instant: bool)
signal game_over(title: String, subtitle: String)
signal door_entered(door: Area2D)

@export var room_id: int = 0
@export var room_title: String = "RAUM"
# Playable area in room-local coordinates. Used for camera limits and the map overlay.
@export var bounds: Rect2 = Rect2(-600, -400, 1200, 800)

const CAMERA_MARGIN_SIDE := 80.0
const CAMERA_MARGIN_TOP := 160.0  # room for the HUD

var player: CharacterBody2D = null
var is_active: bool = false
var was_visited: bool = false
var is_game_over: bool = false


func global_bounds() -> Rect2:
	return Rect2(to_global(bounds.position), bounds.size)


func apply_camera_limits(cam: Camera2D) -> void:
	var b: Rect2 = global_bounds()
	cam.limit_left = int(b.position.x - CAMERA_MARGIN_SIDE)
	cam.limit_right = int(b.end.x + CAMERA_MARGIN_SIDE)
	cam.limit_top = int(b.position.y - CAMERA_MARGIN_TOP)
	cam.limit_bottom = int(b.end.y + CAMERA_MARGIN_SIDE)


# from_room_id: the room the player comes from (-1 at game start).
func enter(new_player: CharacterBody2D, from_room_id: int = -1) -> void:
	player = new_player
	is_active = true
	was_visited = true
	visible = true
	modulate = Color.WHITE
	apply_camera_limits(player.camera)
	_on_enter(from_room_id)


func leave() -> void:
	_on_leave()
	is_active = false
	modulate = Color(0.35, 0.35, 0.42, 1.0)


func restart() -> void:
	_on_restart()


# Status texts type in letter by letter (world.gd). instant = true shows the text at once,
# for quick reactions like a hit that does nothing.
func set_status(text: String, instant: bool = false) -> void:
	status_changed.emit(text, instant)


# Show a point in another room for a moment, e.g. a door that just opened there. Rooms
# are siblings under the world's Rooms node. The other room is lit up for the trip and
# greyed out again afterwards. Usage: await peek_room(0, Vector2(300, 0))
func peek_room(other_room_id: int, local_point: Vector2, hold_seconds: float = 1.2) -> void:
	for other in get_parent().get_children():
		if other is Room and other.room_id == other_room_id:
			var old_modulate: Color = other.modulate
			other.visible = true
			other.modulate = Color.WHITE
			await player.pan_camera_to(other.to_global(local_point), hold_seconds, 1.2, true)
			other.modulate = old_modulate
			return


# Hook up all ExitDoor children so the world learns when the player walks through one.
func register_doors(doors: Array) -> void:
	for door in doors:
		door.player_entered.connect(func() -> void: door_entered.emit(door))


func _on_enter(_from_room_id: int = -1) -> void:
	pass


func _on_leave() -> void:
	pass


func _on_restart() -> void:
	pass
