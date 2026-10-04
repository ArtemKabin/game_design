extends Room

# Cargo rail corridor ("Frachtschiene") between Level 0 and Level 1, shaped like an L:
# from the bridge door it runs left, then down to Level 1. Only the heavy cart can travel
# it: on foot the rail zaps you back to the platform. The cart has no brakes and steers
# with A/D (heavy_cart.gd). Reach the goal platform at the other end without touching a
# wall; there the cart parks, the player gets out and the door opens.
# The trip is made twice: down to Level 1, and back up to the bridge after Level 1 is solved.

# The player always steps out to the right of the parked cart: below the bottom platform
# sits the door to Level 1, and right of the top platform there is room before the bridge door.
const DISMOUNT_BESIDE := Vector2(60, 0)

@onready var heavy_cart: CharacterBody2D = $HeavyCart
@onready var goal_top: Area2D = $GoalTop
@onready var goal_bottom: Area2D = $GoalBottom
@onready var foot_trap: Area2D = $FootTrap
@onready var door_to_level0: Area2D = $DoorToLevel0
@onready var door_to_level1: Area2D = $DoorToLevel1

var destination: Area2D = null
var last_park_position: Vector2 = Vector2.ZERO
var is_near_cart: bool = false


func _ready() -> void:
	heavy_cart.body_nearby.connect(_on_cart_body_nearby)
	heavy_cart.boarded.connect(_on_cart_boarded)
	heavy_cart.started_driving.connect(_on_cart_started_driving)
	heavy_cart.crashed_into_wall.connect(_on_cart_crashed_into_wall)
	goal_top.body_entered.connect(_on_goal_body_entered.bind(goal_top))
	goal_bottom.body_entered.connect(_on_goal_body_entered.bind(goal_bottom))
	foot_trap.body_entered.connect(_on_foot_trap_body_entered)
	register_doors([door_to_level0, door_to_level1])
	door_to_level0.open(false)  # the player came in through it
	apply_camera_limits(heavy_cart.camera)
	last_park_position = heavy_cart.global_position
	destination = goal_bottom


func _on_enter() -> void:
	player.interact_pressed.connect(_on_player_interact)
	# Coming from Level 1 means the cart waits at the bottom and the goal is the top.
	var from_bottom: bool = player.global_position.distance_to(goal_bottom.global_position) \
		< player.global_position.distance_to(goal_top.global_position)
	destination = goal_top if from_bottom else goal_bottom
	if from_bottom:
		set_status("Zurück zur Brücke: [E] einsteigen, [W] losfahren, A/D lenken. Hoch und dann nach rechts.")
	else:
		set_status("FRACHTSCHIENE: Zu Fuß geht hier nichts. [E] in den Wagen, [W] losfahren, A/D lenken.")


func _on_leave() -> void:
	player.interact_pressed.disconnect(_on_player_interact)
	is_near_cart = false


func _on_restart() -> void:
	heavy_cart.park_at(last_park_position, DISMOUNT_BESIDE)
	set_status("Noch einmal. [E] einsteigen, [W] losfahren. Lenk früher, nicht stärker.")


# --- Cart -------------------------------------------------------------------

func _on_cart_body_nearby(body: Node2D, is_near: bool) -> void:
	if body != player or not is_active:
		return
	is_near_cart = is_near
	if is_near and heavy_cart.state == heavy_cart.State.PARKED:
		player.show_interaction_hint("[E] In den Schwerlastwagen steigen")
	else:
		player.hide_interaction_hint()


func _on_player_interact() -> void:
	if is_near_cart and heavy_cart.state == heavy_cart.State.PARKED:
		heavy_cart.board(player)


func _on_cart_boarded() -> void:
	set_status("[%s] zum Anfahren. Er bremst nicht. A = links, D = rechts." % heavy_cart.start_key_name())


func _on_cart_started_driving() -> void:
	var where: String = "nach links, dann runter" if destination == goal_bottom else "hoch, dann nach rechts"
	set_status("Er rollt. Ziel: die leuchtende Plattform %s. Keine Wand berühren!" % where)


func _on_cart_crashed_into_wall() -> void:
	GameManager.register_failure(room_id, "Frachtschiene: gegen die Wand gefahren.")
	game_over.emit("💥 CRASH", "Der Schwerlastwagen kennt keine Bremse. Die Wand schon.")


func _on_goal_body_entered(body: Node2D, goal: Area2D) -> void:
	if body != heavy_cart or heavy_cart.state != heavy_cart.State.DRIVING or goal != destination:
		return
	last_park_position = goal.global_position
	heavy_cart.park_at(last_park_position, DISMOUNT_BESIDE)
	if goal == goal_bottom:
		door_to_level1.open()
		set_status("Plattform erreicht. Die Tür nach unten öffnet sich: Level 1, Frachtraum.")
	else:
		set_status("Plattform erreicht. Rechts geht es zurück auf die Brücke.")


# --- On foot ----------------------------------------------------------------

func _on_foot_trap_body_entered(body: Node2D) -> void:
	if body != player or not is_active or heavy_cart.passenger != null:
		return
	set_status("Zu Fuß? Die Frachtschiene steht unter Strom. Nimm den Wagen.")
	player.global_position = last_park_position + DISMOUNT_BESIDE
