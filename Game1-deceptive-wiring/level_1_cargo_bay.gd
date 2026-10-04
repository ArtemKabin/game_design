extends Room

# Level 1: Cargo Bay. Instruction: "Fahre das Hindernis um."
# You arrive from the cargo rail through the door in the top wall.
# Trap 1: the inviting bypass corridor on the RIGHT dead-ends ("umgehen").
# Trap 2: the quarantine cabins (bottom) loop you straight back to the entrance.
# Solution: board the heavy cart and ram the crates ("umfahren"). Behind the crates
# sits the cargo control panel; using it opens the right-hand door on the bridge.
# Then it is back up through the rail to the bridge. A wall crash with the cart is game over.

const FAIL_RESET_DELAY := 1.2
const CART_DISMOUNT_BESIDE := Vector2(-60, 0)

@onready var spawn_point: Marker2D = $SpawnPoint
@onready var heavy_cart: CharacterBody2D = $HeavyCart
@onready var cart_start: Marker2D = $CartStart
@onready var control_panel: Area2D = $ControlPanel
@onready var bypass_zone: Area2D = $BypassRightZone
@onready var quarantine_door: Area2D = $QuarantineDoor
@onready var entrance_door: Area2D = $EntranceDoor

var is_near_cart: bool = false
var is_near_panel: bool = false
var is_solved: bool = false
var is_resetting: bool = false


func _ready() -> void:
	heavy_cart.body_nearby.connect(_on_cart_body_nearby)
	heavy_cart.boarded.connect(_on_cart_boarded)
	heavy_cart.started_driving.connect(_on_cart_started_driving)
	heavy_cart.crashed_into_obstacle.connect(_on_cart_crashed_into_obstacle)
	heavy_cart.crashed_into_wall.connect(_on_cart_crashed_into_wall)
	control_panel.body_entered.connect(_on_panel_body_entered)
	control_panel.body_exited.connect(_on_panel_body_exited)
	bypass_zone.body_entered.connect(_on_bypass_zone_entered)
	quarantine_door.body_entered.connect(_on_quarantine_door_entered)
	register_doors([entrance_door])
	entrance_door.open(false)  # the player came in through it
	apply_camera_limits(heavy_cart.camera)


func _on_enter() -> void:
	player.interact_pressed.connect(_on_player_interact)
	player.hit_pressed.connect(_on_player_hit)
	if is_solved:
		set_status("FRACHTRAUM: erledigt. Zurück nach oben zur Frachtschiene.")
	else:
		set_status("FRACHTRAUM: Frachtgut blockiert den Weg. Fahre das Hindernis um.")


func _on_leave() -> void:
	player.interact_pressed.disconnect(_on_player_interact)
	player.hit_pressed.disconnect(_on_player_hit)
	player.hide_interaction_hint()
	is_near_cart = false
	is_near_panel = false


func _on_restart() -> void:
	heavy_cart.park_at(cart_start.global_position, CART_DISMOUNT_BESIDE)
	set_status("Noch einmal. [E] einsteigen, [W] losfahren, A/D lenken. Die Kisten sind das Ziel, nicht die Wand.")


# --- Cart (solution, part 1) ------------------------------------------------

func _on_cart_body_nearby(body: Node2D, is_near: bool) -> void:
	if body != player or not is_active or is_solved:
		return
	is_near_cart = is_near
	if is_near and heavy_cart.state == heavy_cart.State.PARKED:
		player.show_interaction_hint("[E] In den Schwerlastwagen steigen")
	else:
		player.hide_interaction_hint()


func _on_player_interact() -> void:
	if is_resetting:
		return
	if is_near_panel and not is_solved:
		_solve()
	elif is_near_cart and heavy_cart.state == heavy_cart.State.PARKED:
		heavy_cart.board(player)


func _on_player_hit() -> void:
	if not is_solved and heavy_cart.state == heavy_cart.State.PARKED:
		set_status("Schlagen bringt hier nichts. Die Kisten sind zu schwer.")


func _on_cart_boarded() -> void:
	set_status("Du sitzt im Schwerlastwagen. [%s] zum Anfahren. Bremsen kann er nicht." \
		% heavy_cart.start_key_name())


func _on_cart_started_driving() -> void:
	set_status("Er rollt. Lenken mit A (links) und D (rechts). Die Wand verzeiht nichts.")


func _on_cart_crashed_into_obstacle(obstacle: Node2D) -> void:
	_break_obstacle(obstacle)
	is_near_cart = false
	player.hide_interaction_hint()
	set_status("Umfahren heißt hier durchfahren! Hinter den Kisten: die Frachtsteuerung.")


func _on_cart_crashed_into_wall() -> void:
	GameManager.register_failure(room_id, "Mit dem Schwerlastwagen gegen die Wand gefahren.")
	game_over.emit("💥 CRASH", "Der Schwerlastwagen kennt keine Bremse. Die Wand schon.")


func _break_obstacle(obstacle: Node2D) -> void:
	for child in obstacle.get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.set_deferred("disabled", true)
	var tween: Tween = create_tween()
	tween.tween_property(obstacle, "modulate:a", 0.0, 0.5)
	tween.tween_callback(obstacle.queue_free)


# --- Control panel (solution, part 2) ---------------------------------------

func _on_panel_body_entered(body: Node2D) -> void:
	if body == player and not is_solved:
		is_near_panel = true
		player.show_interaction_hint("[E] Frachtsteuerung umlegen")


func _on_panel_body_exited(body: Node2D) -> void:
	if body == player:
		is_near_panel = false
		player.hide_interaction_hint()


func _solve() -> void:
	is_solved = true
	is_near_panel = false
	player.hide_interaction_hint()
	GameManager.complete_level(1)
	set_status("ERFOLG: Frachtsteuerung umgelegt. Auf der Brücke hat sich rechts eine Tür geöffnet. Zurück durch die Frachtschiene!")


# --- Traps (only for the player on foot) ------------------------------------

func _on_bypass_zone_entered(body: Node2D) -> void:
	if body != player or not is_active or is_solved or is_resetting:
		return
	_fail("FALLE: Die Umleitung endet im Nichts. Rechts herum geht es nicht.",
		"Rechtsausweichen-Falle ausgelöst.")


func _on_quarantine_door_entered(body: Node2D) -> void:
	if body != player or not is_active or is_solved or is_resetting:
		return
	_fail("FALLE: Kabine A, B, C, D ... und wieder am Eingang. Die Kabinen führen im Kreis.",
		"Quarantäne-Schleife ausgelöst.")


func _fail(message: String, reason: String) -> void:
	is_resetting = true
	set_status(message)
	GameManager.register_failure(room_id, reason)
	player.set_movement_enabled(false)
	player.hide_interaction_hint()

	await get_tree().create_timer(FAIL_RESET_DELAY).timeout

	player.global_position = spawn_point.global_position
	player.set_movement_enabled(true)
	is_resetting = false
