class_name Player
extends CharacterBody3D
## Student as a simple bean (capsule, 0.6 m wide, 1.75 m tall, feet at y = 0).
## 1 unit = 1 m. Movement is relative to the camera.

signal interactable_changed(target: Interactable)

const WALK_SPEED := 3.5     ## m/s, brisk walk (real walk is ~1.4)
const SPRINT_SPEED := 6.0   ## m/s, running late
const ACCEL := 30.0         ## m/s²
const GRAVITY := 9.8

var _nearby: Array[Interactable] = []
var _focus: Interactable


func _ready() -> void:
	add_to_group("player")


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var dir := Vector3(input.x, 0.0, input.y)
	var cam := get_viewport().get_camera_3d()
	if cam:
		dir = dir.rotated(Vector3.UP, cam.global_rotation.y)
	if not GameState.is_free():
		dir = Vector3.ZERO

	var speed := SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(dir * speed, ACCEL * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	velocity.y = 0.0 if is_on_floor() else velocity.y - GRAVITY * delta
	move_and_slide()
	_update_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and _focus and GameState.is_free():
		_focus.interact()
		get_viewport().set_input_as_handled()


func add_interactable(i: Interactable) -> void:
	if not _nearby.has(i):
		_nearby.append(i)


func remove_interactable(i: Interactable) -> void:
	_nearby.erase(i)


func _update_focus() -> void:
	var best: Interactable = null
	var best_d := INF
	for i in _nearby:
		var d := global_position.distance_squared_to(i.global_position)
		if d < best_d:
			best_d = d
			best = i
	if best != _focus:
		_focus = best
		interactable_changed.emit(_focus)
