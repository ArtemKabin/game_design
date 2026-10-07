extends CharacterBody2D

# Heavy cart ("Schwerlastwagen"). See docs/decisions/0012 and 0013.
#  - board(player): the player gets in (hidden, no collision); the cart camera takes over
#  - the cart always starts facing UP; press W (move_up) to start driving
#  - it never brakes; while driving, hold A to steer left and D to steer right
#    (continuous rotation, turn_speed_deg per second), so the player has to drive curves
#  - hits a wall: crashed_into_wall (showing game over is the level's job)
#  - hits a StaticBody2D in group "obstacle": passenger gets out, crashed_into_obstacle(obstacle)
#  - hits a body in group "pushable" (junk_crate.gd): shoves it along until it is blocked,
#    then stops in place and emits push_blocked(crate); the level decides what happens next

signal boarded
signal started_driving
signal crashed_into_wall(collider: Node2D)
signal crashed_into_obstacle(obstacle: Node2D)
signal push_blocked(crate: Node2D)
signal body_nearby(body: Node2D, is_near: bool)

enum State { PARKED, BOARDED, DRIVING, CRASHED }

const START_ACTION := "move_up"
const START_KEY_NAME := "W"

@export var speed: float = 220.0
@export var turn_speed_deg: float = 180.0

@onready var camera: Camera2D = $Camera2D
@onready var board_area: Area2D = $BoardArea

var state: State = State.PARKED
var passenger: CharacterBody2D = null


func _ready() -> void:
	# Sprite nose points along +x at rotation 0, so facing up is -90 degrees.
	rotation = Vector2.UP.angle()
	camera.enabled = false
	board_area.body_entered.connect(func(body: Node2D) -> void: body_nearby.emit(body, true))
	board_area.body_exited.connect(func(body: Node2D) -> void: body_nearby.emit(body, false))


func direction() -> Vector2:
	return Vector2.from_angle(rotation)


# --- Boarding ---------------------------------------------------------------

func board(player: CharacterBody2D) -> void:
	if state != State.PARKED:
		return
	state = State.BOARDED
	passenger = player
	if passenger:
		passenger.hide_interaction_hint()
		passenger.set_movement_enabled(false)
		passenger.visible = false
		_set_passenger_collision_disabled(true)
	camera.enabled = true
	camera.make_current()
	boarded.emit()


# Key the player has to press to start. Always W: the cart always starts facing up.
func start_key_name() -> String:
	return START_KEY_NAME


# --- Driving ----------------------------------------------------------------

func _physics_process(delta: float) -> void:
	# Polled rather than via _unhandled_input so the start also works when the
	# action is pressed programmatically (e.g. automated tests).
	if state == State.BOARDED and Input.is_action_just_pressed(START_ACTION):
		state = State.DRIVING
		started_driving.emit()
		return
	if state != State.DRIVING:
		return
	var steer: float = Input.get_axis("move_left", "move_right")  # -1 = left (A), +1 = right (D)
	rotation += steer * deg_to_rad(turn_speed_deg) * delta
	velocity = direction() * speed
	var motion: Vector2 = velocity * delta
	# Junk in the way is shoved ahead of the cart instead of crashed into.
	var ahead: KinematicCollision2D = move_and_collide(motion, true)
	if ahead and _is_pushable(ahead.get_collider()):
		if not ahead.get_collider().push(motion):
			_stop_pushing(ahead.get_collider())
			return
	move_and_slide()
	for i in get_slide_collision_count():
		var collider: Object = get_slide_collision(i).get_collider()
		if _is_pushable(collider):
			continue  # touching the crate we are pushing is fine
		_crash(collider as Node2D)
		return


func _is_pushable(body: Object) -> bool:
	return body is Node and (body as Node).is_in_group("pushable")


func _stop_pushing(crate: Node2D) -> void:
	state = State.CRASHED  # stopped; the level parks it again
	velocity = Vector2.ZERO
	push_blocked.emit(crate)


func _crash(collider: Node2D) -> void:
	state = State.CRASHED
	velocity = Vector2.ZERO
	modulate = Color(0.6, 0.6, 0.6, 1.0)
	if collider and collider.is_in_group("obstacle"):
		_dismount()
		crashed_into_obstacle.emit(collider)
	else:
		crashed_into_wall.emit(collider)


# Put the cart back into a usable parked state at a position, facing up.
# Whoever is inside gets out at dismount_offset (room-relative, e.g. beside the cart).
# Used for goal zones (cart waits there for the trip back) and for restarts after a crash.
func park_at(park_position: Vector2, dismount_offset: Vector2 = Vector2(60, 0)) -> void:
	global_position = park_position
	rotation = Vector2.UP.angle()
	velocity = Vector2.ZERO
	modulate = Color.WHITE
	_dismount(dismount_offset)
	camera.enabled = false
	state = State.PARKED


func _dismount(offset: Vector2 = Vector2.ZERO) -> void:
	if passenger == null:
		return
	if offset == Vector2.ZERO:
		# Step out behind the cart, away from whatever it just hit.
		offset = -direction() * 70.0
	passenger.global_position = global_position + offset
	passenger.visible = true
	_set_passenger_collision_disabled(false)
	passenger.set_movement_enabled(true)
	passenger.camera.make_current()
	camera.enabled = false
	passenger = null


func _set_passenger_collision_disabled(disabled: bool) -> void:
	var shape: CollisionShape2D = passenger.get_node_or_null("CollisionShape2D")
	if shape:
		shape.set_deferred("disabled", disabled)
