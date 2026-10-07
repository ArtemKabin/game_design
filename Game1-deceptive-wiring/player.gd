extends CharacterBody2D

# Shared top-down player with flashlight. Instance res://player.tscn in every level.
# Movement and keys come from the Input Map in project.godot:
#   move_up / move_down / move_left / move_right (WASD + arrows), interact (E), hit (F)

signal interact_pressed
signal hit_pressed

@export var speed: float = 220.0

@onready var interact_label: Label = $InteractHintLabel
@onready var camera: Camera2D = $Camera2D

var can_move: bool = true


func _ready() -> void:
	interact_label.visible = false


func _physics_process(_delta: float) -> void:
	if not can_move:
		return
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * speed
	move_and_slide()


func set_movement_enabled(enabled: bool) -> void:
	can_move = enabled
	velocity = Vector2.ZERO


# Short camera trip to a point of interest (e.g. a door that just opened) and back.
# The camera is detached from the player for the duration; its limits still apply unless
# ignore_limits is set (for a look into another room, see Room.peek_room).
# Usage: await player.pan_camera_to(door.global_position)
func pan_camera_to(target: Vector2, hold_seconds: float = 0.8, travel_seconds: float = 0.6,
		ignore_limits: bool = false) -> void:
	var home: Vector2 = global_position
	var limits: Array[int] = [camera.limit_left, camera.limit_top, camera.limit_right, camera.limit_bottom]
	if ignore_limits:
		camera.limit_left = -10000000
		camera.limit_top = -10000000
		camera.limit_right = 10000000
		camera.limit_bottom = 10000000
	camera.top_level = true
	camera.global_position = home
	var tween: Tween = create_tween()
	tween.tween_property(camera, "global_position", target, travel_seconds) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_interval(hold_seconds)
	tween.tween_property(camera, "global_position", home, travel_seconds) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	camera.top_level = false
	camera.position = Vector2.ZERO
	camera.limit_left = limits[0]
	camera.limit_top = limits[1]
	camera.limit_right = limits[2]
	camera.limit_bottom = limits[3]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		interact_pressed.emit()
	elif event.is_action_pressed("hit"):
		hit_pressed.emit()


func show_interaction_hint(text: String) -> void:
	interact_label.text = text
	interact_label.visible = true


func hide_interaction_hint() -> void:
	interact_label.visible = false
