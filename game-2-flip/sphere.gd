# sphere.gd
# Floating dual-state hazard sphere.
#   WHITE world → StaticBody2D (SafeBody) active  = safe landing platform
#   BLACK world → Area2D (KillZone)       active  = instant death on touch
extends Node2D

@export var float_amplitude: float = 8.0
@export var float_speed:     float = 1.8

@onready var safe_body:   StaticBody2D = $SafeBody
@onready var kill_zone:   Area2D       = $KillZone
@onready var sphere_draw: Node2D       = $SphereDraw
@onready var aura:        Node2D       = $Aura

var _base_y: float = 0.0
var _time:   float = 0.0


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
	# Platform (white world)
	safe_body.process_mode = PROCESS_MODE_DISABLED if is_dark else PROCESS_MODE_INHERIT
	# Kill zone (black world)
	kill_zone.monitoring   = is_dark
	kill_zone.monitorable  = is_dark
	# Visuals
	sphere_draw.set_dangerous(is_dark)
	aura.set_dangerous(is_dark)
