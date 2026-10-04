extends Node2D

# Level 1: Cargo Bay. Instruction: "Fahre das Hindernis um."
# Trap 1: the inviting bypass corridor on the RIGHT dead-ends ("umgehen").
# Trap 2: the quarantine cabins loop you straight back to the room start.
# Solution: board the heavy cart and ram the crates ("umfahren"). The cart drives
# snake-style and never brakes: a wall is game over, the crates are an obstacle
# (group "obstacle") that breaks and lets the player out. See heavy_cart.gd.

const FAIL_RESET_DELAY := 1.2

@onready var player: CharacterBody2D = $Player
@onready var start_position: Marker2D = $StartPosition
@onready var heavy_cart: CharacterBody2D = $HeavyCart
@onready var bypass_zone: Area2D = $BypassRightZone
@onready var quarantine_door: Area2D = $QuarantineDoor
@onready var exit_door: Area2D = $ExitDoor
@onready var status_label: Label = $CanvasLayer/HUD/StatusLabel
@onready var controls_label: Label = $CanvasLayer/HUD/ControlsGuideLabel
@onready var game_over_ui: Control = $CanvasLayer/GameOverUI

var is_near_cart: bool = false
var is_solved: bool = false
var is_resetting: bool = false


func _ready() -> void:
	heavy_cart.body_nearby.connect(_on_cart_body_nearby)
	heavy_cart.boarded.connect(_on_cart_boarded)
	heavy_cart.started_driving.connect(_on_cart_started_driving)
	heavy_cart.crashed_into_obstacle.connect(_on_cart_crashed_into_obstacle)
	heavy_cart.crashed_into_wall.connect(_on_cart_crashed_into_wall)
	exit_door.player_entered.connect(_on_exit_door_entered)
	bypass_zone.body_entered.connect(_on_bypass_zone_entered)
	quarantine_door.body_entered.connect(_on_quarantine_door_entered)
	player.interact_pressed.connect(_on_player_interact)
	player.hit_pressed.connect(_on_player_hit)
	game_over_ui.restart_requested.connect(restart_level)

	status_label.text = "FRACHTRAUM: Frachtgut blockiert den Weg. Fahre das Hindernis um."
	controls_label.text = GameManager.CONTROLS_TEXT


# --- Cart (solution) --------------------------------------------------------

func _on_cart_body_nearby(body: Node2D, is_near: bool) -> void:
	if body != player or is_solved:
		return
	is_near_cart = is_near
	if is_near and heavy_cart.state == heavy_cart.State.PARKED:
		player.show_interaction_hint("[E] In den Schwerlastwagen steigen")
	else:
		player.hide_interaction_hint()


func _on_player_interact() -> void:
	if is_near_cart and not is_solved and not is_resetting:
		heavy_cart.board(player)


func _on_player_hit() -> void:
	if not is_solved and heavy_cart.state == heavy_cart.State.PARKED:
		status_label.text = "Schlagen bringt hier nichts. Die Kisten sind zu schwer."


func _on_cart_boarded() -> void:
	status_label.text = "Du sitzt im Schwerlastwagen. [%s] zum Anfahren. Bremsen kann er nicht." \
		% heavy_cart.facing_key_name()


func _on_cart_started_driving() -> void:
	status_label.text = "Er rollt. Quer zur Fahrtrichtung lenken: W/S beim Geradeausfahren, A/D beim Hoch- oder Runterfahren."


func _on_cart_crashed_into_obstacle(obstacle: Node2D) -> void:
	_break_obstacle(obstacle)
	is_solved = true
	is_near_cart = false
	player.hide_interaction_hint()
	status_label.text = "ERFOLG: Umfahren heißt hier durchfahren! Der Weg nach links ist frei."
	GameManager.complete_level(1)
	_open_exit()


func _on_cart_crashed_into_wall() -> void:
	GameManager.register_failure(1, "Mit dem Schwerlastwagen gegen die Wand gefahren.")
	game_over_ui.show_game_over("💥 CRASH",
		"Der Schwerlastwagen kennt keine Bremse. Die Wand schon.")


func _break_obstacle(obstacle: Node2D) -> void:
	for child in obstacle.get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.set_deferred("disabled", true)
	var tween: Tween = create_tween()
	tween.tween_property(obstacle, "modulate:a", 0.0, 0.5)
	tween.tween_callback(obstacle.queue_free)


func restart_level() -> void:
	get_tree().reload_current_scene()


# --- Exit -------------------------------------------------------------------

func _open_exit() -> void:
	player.set_movement_enabled(false)
	exit_door.open()
	await player.pan_camera_to(exit_door.global_position)
	status_label.text = "Eine Tür hat sich geöffnet. Links, wo das Frachtgut war."
	player.set_movement_enabled(true)


func _on_exit_door_entered() -> void:
	GameManager.go_to_transition(1)


# --- Traps (only for the player on foot) ------------------------------------

func _on_bypass_zone_entered(body: Node2D) -> void:
	if body != player or is_solved or is_resetting:
		return
	_fail("FALLE: Die Umleitung endet im Nichts. Rechts herum geht es nicht.",
		"Rechtsausweichen-Falle ausgelöst.")


func _on_quarantine_door_entered(body: Node2D) -> void:
	if body != player or is_solved or is_resetting:
		return
	_fail("FALLE: Kabine A, B, C, D ... und wieder am Anfang. Die Kabinen führen im Kreis.",
		"Quarantäne-Schleife ausgelöst.")


func _fail(message: String, reason: String) -> void:
	is_resetting = true
	status_label.text = message
	GameManager.register_failure(1, reason)
	player.set_movement_enabled(false)
	player.hide_interaction_hint()

	await get_tree().create_timer(FAIL_RESET_DELAY).timeout

	player.global_position = start_position.global_position
	player.set_movement_enabled(true)
	is_resetting = false
