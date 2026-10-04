extends Node2D

# Level 1: Cargo Bay. Instruction: "Fahre das Hindernis um."
# Trap 1: the inviting bypass corridor on the RIGHT dead-ends ("umgehen").
# Trap 2: the quarantine cabins loop you straight back to the room start.
# Solution: board the heavy cart on the LEFT and ram the crates ("umfahren").

const FAIL_RESET_DELAY := 1.2

@onready var player: CharacterBody2D = $Player
@onready var start_position: Marker2D = $StartPosition
@onready var heavy_cart: Area2D = $HeavyCart
@onready var obstacle_wall: StaticBody2D = $ObstacleWall
@onready var obstacle_collision: CollisionShape2D = $ObstacleWall/CollisionShape2D
@onready var bypass_zone: Area2D = $BypassRightZone
@onready var quarantine_door: Area2D = $QuarantineDoor
@onready var status_label: Label = $CanvasLayer/HUD/StatusLabel
@onready var controls_label: Label = $CanvasLayer/HUD/ControlsGuideLabel
@onready var exit_door: Area2D = $ExitDoor

var is_near_cart: bool = false
var is_solved: bool = false
var is_resetting: bool = false


func _ready() -> void:
	exit_door.player_entered.connect(_on_exit_door_entered)

	heavy_cart.body_entered.connect(_on_cart_body_entered)
	heavy_cart.body_exited.connect(_on_cart_body_exited)
	bypass_zone.body_entered.connect(_on_bypass_zone_entered)
	quarantine_door.body_entered.connect(_on_quarantine_door_entered)
	player.interact_pressed.connect(_on_player_interact)
	player.hit_pressed.connect(_on_player_hit)

	status_label.text = "FRACHTRAUM: Frachtgut blockiert den Weg. Fahre das Hindernis um."
	controls_label.text = GameManager.CONTROLS_TEXT


# --- Cart (solution) --------------------------------------------------------

func _on_cart_body_entered(body: Node2D) -> void:
	if body == player and not is_solved:
		is_near_cart = true
		player.show_interaction_hint("[E] In den Schwerlastwagen steigen")


func _on_cart_body_exited(body: Node2D) -> void:
	if body == player:
		is_near_cart = false
		player.hide_interaction_hint()


func _on_player_interact() -> void:
	if is_near_cart and not is_solved and not is_resetting:
		_smash_obstacle()


func _on_player_hit() -> void:
	if not is_solved:
		status_label.text = "Schlagen bringt hier nichts. Die Kisten sind zu schwer."


func _smash_obstacle() -> void:
	is_solved = true
	is_near_cart = false
	player.hide_interaction_hint()
	player.set_physics_process(false)
	status_label.text = "Der Schwerlastwagen rollt los ..."

	var tween: Tween = create_tween()
	tween.tween_property(heavy_cart, "position", obstacle_wall.position, 0.7) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(_on_obstacle_hit)


func _on_obstacle_hit() -> void:
	obstacle_collision.set_deferred("disabled", true)
	var tween: Tween = create_tween()
	tween.tween_property(obstacle_wall, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(heavy_cart, "modulate:a", 0.0, 0.5)
	tween.tween_callback(_on_level_solved)


func _on_level_solved() -> void:
	player.set_physics_process(true)
	status_label.text = "ERFOLG: Umfahren heißt hier durchfahren! Der Weg nach links ist frei."
	GameManager.complete_level(1)
	_open_exit()


func _open_exit() -> void:
	player.set_movement_enabled(false)
	exit_door.open()
	await player.pan_camera_to(exit_door.global_position)
	status_label.text = "Eine Tür hat sich geöffnet. Links, hinter dem Frachtgut."
	player.set_movement_enabled(true)


func _on_exit_door_entered() -> void:
	GameManager.go_to_transition(1)


# --- Traps ------------------------------------------------------------------

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
	player.set_physics_process(false)
	player.hide_interaction_hint()

	await get_tree().create_timer(FAIL_RESET_DELAY).timeout

	player.global_position = start_position.global_position
	player.velocity = Vector2.ZERO
	player.set_physics_process(true)
	is_resetting = false
