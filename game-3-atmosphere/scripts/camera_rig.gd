extends Node3D
## Top-down follow camera. Looks down at `pitch_deg` from `distance` metres,
## follows the target smoothly. Mouse wheel zooms (steps grow with distance).
## M toggles a map view straight from above over `overview_center`; in the map
## view the map can be dragged with any mouse button held down.

@export var target: Node3D
@export_range(30.0, 90.0) var pitch_deg := 60.0
@export var distance := 11.0
@export var min_distance := 4.0
@export var max_distance := 80.0
@export var follow_speed := 6.0
@export var fov := 40.0
@export_group("Map view (M)")
@export var overview_center := Vector3.ZERO
@export var overview_distance := 60.0
@export var overview_max_distance := 900.0
## Area the map view may be dragged over (x/z), empty = unlimited.
@export var overview_bounds := Rect2()

@onready var cam: Camera3D = $Camera3D

var overview := false
var _blend := 0.0   ## 0 = follow view, 1 = map view


func _ready() -> void:
	cam.fov = fov
	if target:
		global_position = target.global_position
	_place_camera()


func _process(delta: float) -> void:
	_blend = move_toward(_blend, 1.0 if overview else 0.0, delta * 3.0)
	var t := 1.0 - exp(-follow_speed * delta)
	if overview:
		global_position = global_position.lerp(overview_center, t)
	elif target:
		global_position = global_position.lerp(target.global_position, t)
	_place_camera()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("map_view"):
		overview = not overview
		# Shadows only cover ~90 m around the camera; from map height they would end in a visible seam.
		for light in get_tree().current_scene.find_children("*", "DirectionalLight3D", true, false):
			light.shadow_enabled = not overview
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and overview and event.button_mask != 0:
		# Drag: move the map with the mouse, 1 pixel = the ground distance one pixel covers.
		var view_h := get_viewport().get_visible_rect().size.y
		var per_px := 2.0 * overview_distance * tan(deg_to_rad(cam.fov) / 2.0) / view_h
		overview_center -= Vector3(event.relative.x, 0.0, event.relative.y) * per_px
		if overview_bounds.has_area():
			overview_center.x = clampf(overview_center.x, overview_bounds.position.x, overview_bounds.end.x)
			overview_center.z = clampf(overview_center.z, overview_bounds.position.y, overview_bounds.end.y)
		global_position = overview_center
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		var zoom := 0.0
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = -1.0
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = 1.0
		if zoom != 0.0:
			if overview:
				overview_distance = clampf(overview_distance * (1.0 + 0.15 * zoom), min_distance, overview_max_distance)
			else:
				distance = clampf(distance + zoom * maxf(1.5, distance * 0.12), min_distance, max_distance)


func _place_camera() -> void:
	var s := smoothstep(0.0, 1.0, _blend)
	var p := deg_to_rad(lerpf(pitch_deg, 89.9, s))
	var dist := lerpf(distance, overview_distance, s)
	cam.position = Vector3(0.0, sin(p) * dist, cos(p) * dist)
	cam.rotation = Vector3(-p, 0.0, 0.0)
	# Depth precision: a near plane that grows with the zoom keeps flat ground layers apart.
	cam.near = clampf(dist * 0.02, 0.05, 25.0)
