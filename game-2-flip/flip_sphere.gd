# flip_sphere.gd
# A floating sphere with dual personality:
#   WHITE world → acts as a safe landing platform (StaticBody2D enabled).
#   BLACK world → becomes a deadly hazard (Area2D kill zone enabled, platform disabled).
#
# Node structure (see flip_sphere.tscn):
#   FlipSphere (Node2D, this script)
#     ├── SafeBody  (StaticBody2D)  ← enabled in white world
#     ├── KillZone  (Area2D)        ← enabled in black world
#     ├── Aura      (Node2D)        ← animated glow rings
#     └── SphereDraw (Node2D)       ← custom _draw()
extends Node2D

@export var float_amplitude: float = 8.0
@export var float_speed: float = 1.8

@onready var safe_body:   StaticBody2D = $SafeBody
@onready var kill_zone:   Area2D       = $KillZone
@onready var sphere_draw: Node2D       = $SphereDraw
@onready var aura:        Node2D       = $Aura

var _base_y: float = 0.0
var _time: float   = 0.0


func _ready() -> void:
	_base_y = position.y
	WorldState.world_flipped.connect(_on_world_flipped)
	_apply_state(WorldState.is_dark)


func _process(delta: float) -> void:
	_time += delta
	position.y = _base_y + sin(_time * TAU * float_speed) * float_amplitude


func _on_world_flipped(is_dark: bool) -> void:
	_apply_state(is_dark)


func _apply_state(is_dark: bool) -> void:
	# Platform mode (white world).
	safe_body.set_collision_layer_value(1, not is_dark)
	safe_body.process_mode = Node.PROCESS_MODE_INHERIT if not is_dark \
		else Node.PROCESS_MODE_DISABLED
	# Kill mode (black world).
	kill_zone.monitoring = is_dark
	kill_zone.monitorable = is_dark

	# Update visuals.
	if sphere_draw.has_method("set_dangerous"):
		sphere_draw.set_dangerous(is_dark)
	if aura.has_method("set_dangerous"):
		aura.set_dangerous(is_dark)
