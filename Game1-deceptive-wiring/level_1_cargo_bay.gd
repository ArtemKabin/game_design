extends Room

# Level 1: Cargo Bay. Instruction: "Fahre das Hindernis um." See docs/decisions/0017 and 0018.
# Entered from the cargo rail through the door on the right wall. One long wall of space
# junk runs from the top wall to the bottom wall and splits the room: on the right the
# cart, the rail door and the quarantine door; on the left the airlock ("Müllschleuse")
# with a lever at its top.
# The bait: "umfahren" sounds like going around, and the open quarantine cabins at the
# bottom look like the way around. They are a queue that ends on the bridge. Hitting the
# junk does nothing. After enough hitting the narrator says "du musst das Hindernis
# UMFAHREN": board the cart and drive into the junk. The cart shoves it left until it
# stands on the airlock field at the wall, then the cart rolls back to its spot. Pull
# the lever: the junk sails into space, Level 1 is solved and the right door on the
# bridge opens; the camera flies over to the bridge to show it.

const CART_DISMOUNT_BESIDE := Vector2(60, 0)
const HITS_UNTIL_REVEAL := 3
# The junk counts as "in the airlock" once its centre is left of this (it stops at -550).
const AIRLOCK_X := -540.0

@onready var heavy_cart: CharacterBody2D = $HeavyCart
@onready var cart_start: Marker2D = $CartStart
@onready var junk: CharacterBody2D = $Junk
@onready var lever: Area2D = $Lever
@onready var entrance_door: Area2D = $EntranceDoor
@onready var quarantine_door: Area2D = $QuarantineDoor

var is_near_cart: bool = false
var is_near_lever: bool = false
var intro_shown: bool = false
var junk_jettisoned: bool = false
var hits_bare: int = 0


func is_solved() -> bool:
	return GameManager.get_level_state(room_id) == GameManager.LevelState.COMPLETED


func junk_in_airlock() -> bool:
	return junk.position.x <= AIRLOCK_X


func _ready() -> void:
	heavy_cart.body_nearby.connect(_on_cart_body_nearby)
	heavy_cart.boarded.connect(_on_cart_boarded)
	heavy_cart.started_driving.connect(_on_cart_started_driving)
	heavy_cart.push_blocked.connect(_on_cart_push_blocked)
	heavy_cart.crashed_into_wall.connect(_on_cart_crashed_into_wall)
	lever.body_entered.connect(_on_lever_body_entered)
	lever.body_exited.connect(_on_lever_body_exited)
	register_doors([entrance_door, quarantine_door])
	entrance_door.open(false)    # the player came in through it
	quarantine_door.open(false)  # cabins are open from the start, that is the bait
	apply_camera_limits(heavy_cart.camera)


func _on_enter(_from_room_id: int = -1) -> void:
	player.interact_pressed.connect(_on_player_interact)
	player.hit_pressed.connect(_on_player_hit)
	if not intro_shown:
		intro_shown = true
		_play_intro()
	elif is_solved():
		set_status("FRACHTRAUM: Müll entsorgt. Zurück über die Frachtschiene zur Brücke, rechts ist eine Tür offen.")
	elif junk_in_airlock():
		set_status("Der Müll steht in der Schleuse. Oben links der Hebel.")
	else:
		set_status("FRACHTRAUM: Weltraummüll versperrt den Raum. Fahre das Hindernis um.")


func _play_intro() -> void:
	set_status("FRACHTRAUM: Eine Wand aus Weltraummüll versperrt den Raum. Fahre das Hindernis um.")
	player.set_movement_enabled(false)
	await player.pan_camera_to(quarantine_door.global_position, 1.2)
	set_status("Da unten: Quarantäne-Kabinen, offen. Vielleicht geht es da herum.")
	player.set_movement_enabled(true)


func _on_leave() -> void:
	player.interact_pressed.disconnect(_on_player_interact)
	player.hit_pressed.disconnect(_on_player_hit)
	player.hide_interaction_hint()
	is_near_cart = false
	is_near_lever = false


func _on_restart() -> void:
	heavy_cart.park_at(cart_start.global_position, CART_DISMOUNT_BESIDE)
	set_status("Noch einmal. Der Müll ist das Ziel, nicht die Wand.")


# --- Hitting the junk by hand (never works, that is the joke) --------------

func _on_player_hit() -> void:
	if junk_jettisoned or is_game_over:
		return
	hits_bare += 1
	match hits_bare:
		1: set_status("Mit bloßen Händen? Der Müll wackelt nicht mal.", true)
		2: set_status("Noch mal. Der Müll lacht.", true)
		_:
			set_status("Wie ging das noch gleich? Du musst das Hindernis UMFAHREN. Der Schwerlastwagen steht rechts.", true)
			if hits_bare == HITS_UNTIL_REVEAL:
				player.set_movement_enabled(false)
				await player.pan_camera_to(heavy_cart.global_position, 1.0)
				player.set_movement_enabled(true)


# --- Cart: shove the junk into the airlock ----------------------------------

func _on_cart_body_nearby(body: Node2D, is_near: bool) -> void:
	if body != player or not is_active or junk_jettisoned:
		return
	is_near_cart = is_near
	if is_near and heavy_cart.state == heavy_cart.State.PARKED:
		player.show_interaction_hint("[E] In den Schwerlastwagen steigen")
	else:
		player.hide_interaction_hint()


func _on_cart_boarded() -> void:
	set_status("Du sitzt im Schwerlastwagen. [%s] zum Anfahren. Bremsen kann er nicht." \
		% heavy_cart.start_key_name())


func _on_cart_started_driving() -> void:
	set_status("Er rollt. Lenken mit A (links) und D (rechts).")


# The junk the cart was shoving cannot move further: either it stands on the airlock
# field at the wall, or something else is in the way. Either way the cart rolls back.
func _on_cart_push_blocked(_crate: Node2D) -> void:
	is_near_cart = false
	heavy_cart.park_at(cart_start.global_position, CART_DISMOUNT_BESIDE)
	if junk_in_airlock():
		set_status("Der Müll steht in der Schleuse. Der Wagen rollt zurück. Jetzt oben links den Hebel umlegen.")
	else:
		set_status("Der Wagen schiebt nicht weiter. Er rollt zurück auf seinen Platz.")


func _on_cart_crashed_into_wall(_collider: Node2D) -> void:
	GameManager.register_failure(room_id, "Mit dem Schwerlastwagen gegen die Wand gefahren.")
	game_over.emit("CRASH", "Der Schwerlastwagen kennt keine Bremse. Die Wand schon. Der Müll wäre das Ziel gewesen.")


# --- Lever: jettison the junk -----------------------------------------------

func _on_lever_body_entered(body: Node2D) -> void:
	if body == player and not junk_jettisoned:
		is_near_lever = true
		player.show_interaction_hint("[E] Hebel umlegen")


func _on_lever_body_exited(body: Node2D) -> void:
	if body == player:
		is_near_lever = false
		player.hide_interaction_hint()


func _on_player_interact() -> void:
	if is_near_lever and not junk_jettisoned:
		_pull_lever()
	elif is_near_cart and heavy_cart.state == heavy_cart.State.PARKED and not junk_jettisoned:
		heavy_cart.board(player)


func _pull_lever() -> void:
	if not junk_in_airlock():
		set_status("Der Hebel klemmt: Die Schleuse ist leer. Der Müll steht noch mitten im Raum.")
		return
	junk_jettisoned = true
	is_near_lever = false
	player.hide_interaction_hint()
	lever.modulate = Color(0.5, 0.9, 0.6, 1.0)
	_jettison(junk)
	player.set_movement_enabled(false)
	set_status("SCHLEUSE OFFEN. Der Müll segelt ins All. Level 1 gelöst!")
	# Opens the right door on the bridge (level_0_bridge.gd listens); the camera flies
	# over to show it: Level 0 is room 0, its right door sits at the right end of the room.
	GameManager.complete_level(room_id)
	await peek_room(0, Vector2(300, 0), 1.4)
	set_status("Auf der Brücke ist rechts eine Tür offen. Zurück über die Frachtschiene.")
	player.set_movement_enabled(true)


func _jettison(crate: Node2D) -> void:
	for child in crate.get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", true)
	var tween: Tween = create_tween()
	tween.tween_property(crate, "position:x", crate.position.x - 200.0, 0.8)
	tween.parallel().tween_property(crate, "modulate:a", 0.0, 0.8)
	tween.tween_callback(crate.queue_free)
