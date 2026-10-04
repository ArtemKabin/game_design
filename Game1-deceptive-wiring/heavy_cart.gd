extends CharacterBody2D

# Heavy cart ("Schwerlastwagen"). Snake-style driving, see docs/decisions/0012.
#  - board(player): the player gets in (hidden, no collision); the cart camera takes over
#  - press the key of the direction the cart faces to start driving
#  - it never brakes; while driving only the two perpendicular directions turn it
#  - while turning, input is ignored until the cart faces the new direction
#  - hits a wall: crashed_into_wall (showing game over is the level's job)
#  - hits a StaticBody2D in group "obstacle": passenger gets out, crashed_into_obstacle(obstacle)

signal boarded
signal started_driving
signal crashed_into_wall
signal crashed_into_obstacle(obstacle: Node2D)
signal body_nearby(body: Node2D, is_near: bool)

enum State { PARKED, BOARDED, DRIVING, TURNING, CRASHED }

const DIRECTION_ACTIONS := {
	"move_right": Vector2.RIGHT,
	"move_left": Vector2.LEFT,
	"move_up": Vector2.UP,
	"move_down": Vector2.DOWN,
}
const ACTION_KEY_NAMES := {
	"move_right": "D", "move_left": "A", "move_up": "W", "move_down": "S",
}

@export var initial_direction: Vector2 = Vector2.RIGHT
@export var speed: float = 160.0
@export var turn_time: float = 0.35

@onready var camera: Camera2D = $Camera2D
@onready var board_area: Area2D = $BoardArea

var state: State = State.PARKED
var direction: Vector2 = Vector2.RIGHT
var passenger: CharacterBody2D = null


func _ready() -> void:
	direction = initial_direction.normalized()
	rotation = direction.angle()
	camera.enabled = false
	board_area.body_entered.connect(func(body: Node2D) -> void: body_nearby.emit(body, true))
	board_area.body_exited.connect(func(body: Node2D) -> void: body_nearby.emit(body, false))


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


func facing_action() -> String:
	for action in DIRECTION_ACTIONS:
		if DIRECTION_ACTIONS[action] == direction:
			return action
	return ""


# Key the player has to press to start, e.g. "D" when the cart faces right.
func facing_key_name() -> String:
	return ACTION_KEY_NAMES.get(facing_action(), "?")


# --- Driving ----------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	match state:
		State.BOARDED:
			if event.is_action_pressed(facing_action()):
				state = State.DRIVING
				started_driving.emit()
		State.DRIVING:
			for action in DIRECTION_ACTIONS:
				var new_direction: Vector2 = DIRECTION_ACTIONS[action]
				var is_perpendicular: bool = is_zero_approx(new_direction.dot(direction))
				if is_perpendicular and event.is_action_pressed(action):
					_turn_to(new_direction)
					return


func _turn_to(new_direction: Vector2) -> void:
	state = State.TURNING
	direction = new_direction
	var target_rotation: float = rotation + angle_difference(rotation, new_direction.angle())
	var tween: Tween = create_tween()
	tween.tween_property(self, "rotation", target_rotation, turn_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		if state == State.TURNING:
			state = State.DRIVING)


func _physics_process(_delta: float) -> void:
	if state != State.DRIVING and state != State.TURNING:
		return
	velocity = direction * speed
	move_and_slide()
	if get_slide_collision_count() > 0:
		var collider: Object = get_slide_collision(0).get_collider()
		if collider is Node and collider.is_in_group("obstacle"):
			_crash(collider)
		else:
			_crash(null)


func _crash(obstacle: Node2D) -> void:
	state = State.CRASHED
	velocity = Vector2.ZERO
	modulate = Color(0.6, 0.6, 0.6, 1.0)
	if obstacle:
		_dismount()
		crashed_into_obstacle.emit(obstacle)
	else:
		crashed_into_wall.emit()


func _dismount() -> void:
	if passenger == null:
		return
	# Step out behind the cart, away from whatever it just hit.
	passenger.global_position = global_position - direction * 70.0
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
