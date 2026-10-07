extends Room

# Cargo rail corridor ("Frachtschiene"), the cart minigame between two levels. Used by
# corridor_west.tscn (bridge to cargo bay, an S: left, down, left) and corridor_east.tscn
# (bridge to hangar, straight right with a slalom of blocks). Only the heavy cart can
# travel it: on foot the rail zaps you back to the platform. The cart has no brakes and
# steers with A/D (heavy_cart.gd). Reach the goal platform at the other end without
# touching a wall; there the cart parks, the player gets out and the door opens.
# The trip is made in both directions. Scene nodes: HeavyCart, GoalStart, GoalEnd,
# DoorToStart, DoorToEnd, FootTrap. Texts and dismount sides are exports.

# Where the player steps out of the parked cart: on the side of the door. Keep the spot
# clear of the door area (door 60 wide, player 32), or the player spawns inside the door
# when coming back and bounces straight back.
@export var dismount_start: Vector2 = Vector2(60, 0)
@export var dismount_end: Vector2 = Vector2(-70, 0)
@export var status_forward: String = "FRACHTSCHIENE: Zu Fuß geht hier nichts. [E] in den Wagen, [W] losfahren, A/D lenken."
@export var status_back: String = "Zurück zur Brücke: [E] einsteigen, [W] losfahren, A/D lenken."
@export var route_forward: String = "links, runter, wieder links"
@export var route_back: String = "rechts, hoch, wieder rechts"
@export var arrived_end: String = "Plattform erreicht. Die Tür öffnet sich."
@export var arrived_start: String = "Plattform erreicht. Zurück auf die Brücke."

@onready var heavy_cart: CharacterBody2D = $HeavyCart
@onready var goal_start: Area2D = $GoalStart
@onready var goal_end: Area2D = $GoalEnd
@onready var foot_trap: Area2D = $FootTrap
@onready var door_to_start: Area2D = $DoorToStart
@onready var door_to_end: Area2D = $DoorToEnd

var destination: Area2D = null
var last_park_position: Vector2 = Vector2.ZERO
var last_dismount: Vector2 = Vector2.ZERO
var is_near_cart: bool = false


func _ready() -> void:
	heavy_cart.body_nearby.connect(_on_cart_body_nearby)
	heavy_cart.boarded.connect(_on_cart_boarded)
	heavy_cart.started_driving.connect(_on_cart_started_driving)
	heavy_cart.crashed_into_wall.connect(_on_cart_crashed_into_wall)
	goal_start.body_entered.connect(_on_goal_body_entered.bind(goal_start))
	goal_end.body_entered.connect(_on_goal_body_entered.bind(goal_end))
	foot_trap.body_entered.connect(_on_foot_trap_body_entered)
	register_doors([door_to_start, door_to_end])
	door_to_start.open(false)  # the player came in through it
	apply_camera_limits(heavy_cart.camera)
	_park_cart_at(goal_start)


# Park the cart on a platform and remember where the player gets out there.
func _park_cart_at(goal: Area2D) -> void:
	last_park_position = goal.global_position
	last_dismount = dismount_end if goal == goal_end else dismount_start
	heavy_cart.park_at(last_park_position, last_dismount)


func _on_enter(from_room_id: int = -1) -> void:
	player.interact_pressed.connect(_on_player_interact)
	# Coming from the far end means the trip goes back to the start.
	var from_end: bool = from_room_id == door_to_end.target_room_id
	destination = goal_start if from_end else goal_end
	# The cart waits at the platform the player arrives at. It may stand at the other end
	# (the quarantine loop drops the player on the bridge while the cart is still parked
	# at the cargo bay). Then it is brought back, so the rail has to be driven again.
	var start_goal: Area2D = goal_end if from_end else goal_start
	if heavy_cart.state == heavy_cart.State.PARKED and last_park_position != start_goal.global_position:
		_park_cart_at(start_goal)
	set_status(status_back if from_end else status_forward)


func _on_leave() -> void:
	player.interact_pressed.disconnect(_on_player_interact)
	player.hide_interaction_hint()
	is_near_cart = false


func _on_restart() -> void:
	heavy_cart.park_at(last_park_position, last_dismount)
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
	var where: String = route_forward if destination == goal_end else route_back
	set_status("Er rollt. Ziel: die leuchtende Plattform %s. Keine Wand berühren!" % where)


func _on_cart_crashed_into_wall(_collider: Node2D) -> void:
	GameManager.register_failure(room_id, "Frachtschiene: gegen die Wand gefahren.")
	game_over.emit("CRASH", "Der Schwerlastwagen kennt keine Bremse. Die Wand schon.")


func _on_goal_body_entered(body: Node2D, goal: Area2D) -> void:
	if body != heavy_cart or heavy_cart.state != heavy_cart.State.DRIVING or goal != destination:
		return
	_park_cart_at(goal)
	if goal == goal_end:
		door_to_end.open()
		set_status(arrived_end)
	else:
		set_status(arrived_start)


# --- On foot ----------------------------------------------------------------

func _on_foot_trap_body_entered(body: Node2D) -> void:
	if body != player or not is_active or heavy_cart.passenger != null:
		return
	set_status("Zu Fuß? Die Frachtschiene steht unter Strom. Nimm den Wagen.")
	player.global_position = last_park_position + last_dismount
