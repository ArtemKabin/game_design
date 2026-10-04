extends Room

# Level 1: Cargo Bay. Instruction: "Fahre das Hindernis um." See docs/decisions/0015.
# Crates are stacked around the goal door in the middle of the left wall; behind it sits
# the cargo control room with the switch that opens the door to Level 2 on the bridge.
# The game sends the player hunting for tools first: the quarantine cabins (a loop that
# yields a rubber hammer), then a storage room with a crowbar. Nothing breaks the crates.
# After enough hitting the narrator says "du musst das Hindernis UMFAHREN" and the player,
# primed to destroy them, rams them with the cart: game over. "Umfahren" here means drive
# AROUND: the crate wall has one small gap at its bottom right, big enough for the cart.
# On foot a tarp blocks the gap until the level is solved.

const GAP_RESET_POINT := Vector2(-200, 210)
const CART_DISMOUNT_BESIDE := Vector2(60, 0)
const HITS_UNTIL_REVEAL := 3

@onready var spawn_point: Marker2D = $SpawnPoint
@onready var heavy_cart: CharacterBody2D = $HeavyCart
@onready var cart_start: Marker2D = $CartStart
@onready var crates: Node2D = $Crates
@onready var crates_front: Area2D = $CratesFront
@onready var gap_block: Area2D = $GapBlock
@onready var goal_platform: Area2D = $GoalPlatform
@onready var entrance_door: Area2D = $EntranceDoor
@onready var quarantine_door: Area2D = $QuarantineDoor
@onready var storage_door: Area2D = $StorageDoor
@onready var goal_door: Area2D = $GoalDoor

var is_near_cart: bool = false
var is_near_crates: bool = false
var intro_shown: bool = false
var cart_parked_at_platform: bool = false
var hits_bare: int = 0
var hits_rubber: int = 0
var hits_crowbar: int = 0


func is_solved() -> bool:
	return GameManager.get_level_state(room_id) == GameManager.LevelState.COMPLETED


func _ready() -> void:
	heavy_cart.body_nearby.connect(_on_cart_body_nearby)
	heavy_cart.boarded.connect(_on_cart_boarded)
	heavy_cart.started_driving.connect(_on_cart_started_driving)
	heavy_cart.crashed_into_wall.connect(_on_cart_crashed_into_wall)
	crates_front.body_entered.connect(_on_crates_front_body_entered)
	crates_front.body_exited.connect(_on_crates_front_body_exited)
	gap_block.body_entered.connect(_on_gap_block_body_entered)
	goal_platform.body_entered.connect(_on_goal_platform_body_entered)
	register_doors([entrance_door, quarantine_door, storage_door, goal_door])
	entrance_door.open(false)    # the player came in through it
	quarantine_door.open(false)  # cabins are open from the start, that is the bait
	apply_camera_limits(heavy_cart.camera)


func _on_enter(from_room_id: int = -1) -> void:
	player.interact_pressed.connect(_on_player_interact)
	player.hit_pressed.connect(_on_player_hit)
	if not intro_shown:
		intro_shown = true
		_play_intro()
	elif is_solved():
		set_status("FRACHTRAUM: erledigt. Zurück nach oben zur Frachtschiene. Die Plane an der Lücke ist jetzt offen.")
	elif cart_parked_at_platform:
		set_status("Der Wagen steht hinter den Kisten. Die Zieltür ist offen.")
	elif from_room_id == storage_door.target_room_id:
		set_status("Brechstange dabei. Dann mal ran an die Kisten.")
	elif GameManager.has_item("rubber_hammer"):
		set_status("Hammer dabei. Dann mal ran an die Kisten.")
	else:
		set_status("FRACHTRAUM: Frachtgut versperrt die Tür zur Frachtsteuerung. Beschaffe ein Werkzeug.")


func _play_intro() -> void:
	set_status("FRACHTRAUM: Frachtgut versperrt die Tür zur Frachtsteuerung, dem Schalter für Level 2. Beschaffe ein Werkzeug, um ranzukommen.")
	player.set_movement_enabled(false)
	await player.pan_camera_to(quarantine_door.global_position, 1.2)
	set_status("Da unten: Quarantäne-Kabinen, offen. Werkzeug? Vielleicht. Schau zuerst dort.")
	player.set_movement_enabled(true)


func _on_leave() -> void:
	player.interact_pressed.disconnect(_on_player_interact)
	player.hit_pressed.disconnect(_on_player_hit)
	player.hide_interaction_hint()
	is_near_cart = false
	is_near_crates = false


func _on_restart() -> void:
	heavy_cart.park_at(cart_start.global_position, CART_DISMOUNT_BESIDE)
	set_status("Noch einmal. Umfahren heißt hier: drum herum. Unten rechts an den Kisten ist eine Lücke.")


# --- Hitting the crates (never works, that is the joke) --------------------

func _on_crates_front_body_entered(body: Node2D) -> void:
	if body == player and not is_solved():
		is_near_crates = true
		player.show_interaction_hint("[F] Auf die Kisten einschlagen")


func _on_crates_front_body_exited(body: Node2D) -> void:
	if body == player:
		is_near_crates = false
		player.hide_interaction_hint()


func _on_player_hit() -> void:
	if is_solved() or is_game_over:
		return
	if not is_near_crates:
		set_status("Du schlägst in die Luft.")
		return
	if GameManager.has_item("crowbar"):
		_hit_with_crowbar()
	elif GameManager.has_item("rubber_hammer"):
		_hit_with_rubber_hammer()
	else:
		hits_bare += 1
		set_status("Mit bloßen Händen? Die Kisten lachen. Such ein Werkzeug, die Kabinen unten sind offen.")


func _hit_with_rubber_hammer() -> void:
	hits_rubber += 1
	match hits_rubber:
		1: set_status("*Quietsch.* Die Kiste wackelt nicht mal.")
		2: set_status("*Quietsch. Quietsch.* Ernsthaft?")
		_:
			if not storage_door.is_open:
				_reveal_storage()
			else:
				set_status("Der Hammer ist aus Gummi. Das Lager rechts hat richtiges Werkzeug.")


func _reveal_storage() -> void:
	set_status("Der Hammer ist aus Gummi. Natürlich. Such ein RICHTIGES Werkzeug.")
	player.set_movement_enabled(false)
	storage_door.open()
	await player.pan_camera_to(storage_door.global_position, 1.0)
	set_status("Rechts hat sich ein Lagerraum geöffnet. Da liegt richtiges Werkzeug.")
	player.set_movement_enabled(true)


func _hit_with_crowbar() -> void:
	hits_crowbar += 1
	match hits_crowbar:
		1: set_status("Die Brechstange biegt sich. Die Kisten nicht.")
		2: set_status("Du stemmst. Die Kisten gähnen.")
		_:
			set_status("Wie ging das noch gleich? Du musst das Hindernis UMFAHREN. Der Schwerlastwagen steht rechts.")
			if hits_crowbar == HITS_UNTIL_REVEAL:
				player.set_movement_enabled(false)
				await player.pan_camera_to(heavy_cart.global_position, 1.0)
				player.set_movement_enabled(true)


# --- Cart: the real solution is to drive AROUND the crates -----------------

func _on_cart_body_nearby(body: Node2D, is_near: bool) -> void:
	if body != player or not is_active or cart_parked_at_platform:
		return
	is_near_cart = is_near
	if is_near and heavy_cart.state == heavy_cart.State.PARKED:
		player.show_interaction_hint("[E] In den Schwerlastwagen steigen")
	else:
		player.hide_interaction_hint()


func _on_player_interact() -> void:
	if is_near_cart and heavy_cart.state == heavy_cart.State.PARKED and not cart_parked_at_platform:
		heavy_cart.board(player)


func _on_cart_boarded() -> void:
	set_status("Du sitzt im Schwerlastwagen. [%s] zum Anfahren. Bremsen kann er nicht." \
		% heavy_cart.start_key_name())


func _on_cart_started_driving() -> void:
	set_status("Er rollt. Lenken mit A (links) und D (rechts).")


func _on_cart_crashed_into_wall(collider: Node2D) -> void:
	GameManager.register_failure(room_id, "Mit dem Schwerlastwagen gecrasht.")
	if collider and collider.get_parent() == crates:
		game_over.emit("💥 CRASH", "Umfahren heißt hier nicht überfahren. Fahr drum herum: unten rechts an den Kisten ist eine Lücke.")
	else:
		game_over.emit("💥 CRASH", "Der Schwerlastwagen kennt keine Bremse. Die Wand schon.")


func _on_goal_platform_body_entered(body: Node2D) -> void:
	if body != heavy_cart or heavy_cart.state != heavy_cart.State.DRIVING:
		return
	cart_parked_at_platform = true
	heavy_cart.park_at(goal_platform.global_position, CART_DISMOUNT_BESIDE)
	player.hide_interaction_hint()
	goal_door.open()
	set_status("Durch die Lücke! Drum herum, nicht durch. Die Zieltür öffnet sich: Frachtsteuerung.")


func _on_gap_block_body_entered(body: Node2D) -> void:
	if body != player or not is_active or heavy_cart.passenger != null or is_solved():
		return
	set_status("Eine Plane hängt in der Lücke und klemmt. Zu Fuß kommst du da nicht durch. Der Wagen schon.")
	player.global_position = to_global(GAP_RESET_POINT)
