extends Node3D
## Top-down follow camera. Looks down at `pitch_deg` from `distance` metres,
## follows the target smoothly. Mouse wheel zooms.

@export var target: Node3D
@export_range(30.0, 90.0) var pitch_deg := 60.0
@export var distance := 11.0
@export var min_distance := 6.0
@export var max_distance := 30.0
@export var follow_speed := 6.0
@export var fov := 40.0

@onready var cam: Camera3D = $Camera3D


func _ready() -> void:
	cam.fov = fov
	if target:
		global_position = target.global_position
	_place_camera()


func _process(delta: float) -> void:
	if target:
		global_position = global_position.lerp(target.global_position, 1.0 - exp(-follow_speed * delta))
	_place_camera()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = maxf(min_distance, distance - 1.5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = minf(max_distance, distance + 1.5)


func _place_camera() -> void:
	var p := deg_to_rad(pitch_deg)
	cam.position = Vector3(0.0, sin(p) * distance, cos(p) * distance)
	cam.rotation = Vector3(-p, 0.0, 0.0)
