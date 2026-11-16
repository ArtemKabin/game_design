extends Node3D
## Root of a playable place (dorm floor, outside, ...). Needs the children
## Player, CameraRig and HUD. When the scene was entered through a Portal, the
## player starts at the Marker3D named GameState.spawn_point under "Spawns".
## Coming back from a minigame, the player stands where they left, and the
## minigame's time and rewards are applied (GameState.apply_minigame_result).


func _ready() -> void:
	var spawn := GameState.spawn_point
	GameState.spawn_point = ""
	if spawn != "":
		var marker := get_node_or_null("Spawns/" + spawn) as Node3D
		if marker:
			$Player.global_position = marker.global_position
			$CameraRig.global_position = marker.global_position
		else:
			push_warning("Spawn point not found: " + spawn)
	var back: Variant = GameState.take_return_position()
	if back is Vector3:
		$Player.global_position = back
		$CameraRig.global_position = back
	if GameState.arrival_message != "":
		GameState.message.emit(GameState.arrival_message)
		GameState.arrival_message = ""
	GameState.apply_minigame_result()
