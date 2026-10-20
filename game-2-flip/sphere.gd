# sphere.gd
# Hazard sphere that exists in ONE world only, at player height.
#   in_dark_world = false → exists in the WHITE world
#   in_dark_world = true  → exists in the BLACK world
# In its own world it is visible and kills on touch (KillZone Area2D).
# In the other world it is invisible and does nothing.
#
# Optional patrol: moves from its start x to start x + patrol_distance and back,
# at a constant patrol_speed (px/s). patrol_distance = 0 → stationary.
#
# ASSET PLACEHOLDER: the look is drawn by SphereDraw/Aura. Add a Sprite2D under
# this node later; the kill logic does not care how it looks.
extends Node2D

const RADIUS := 22.0   # must match the KillZone shape in sphere.tscn

@export var in_dark_world:   bool  = false
@export var patrol_distance: float = 0.0
@export var patrol_speed:    float = 0.0
@export var bob_amplitude:   float = 3.0
@export var bob_speed:       float = 1.6

@onready var kill_zone:   Area2D = $KillZone
@onready var sphere_draw: Node2D = $SphereDraw
@onready var aura:        Node2D = $Aura

var _base: Vector2 = Vector2.ZERO
var _time: float   = 0.0


func _ready() -> void:
	_base = position
	# Colour = foreground of the world it lives in (contrasts with that background).
	var col := Color(0.95, 0.95, 0.95) if in_dark_world else Color(0.08, 0.08, 0.08)
	sphere_draw.color = col
	aura.color = col
	WorldState.world_flipped.connect(_on_world_flipped)
	_apply_state(WorldState.is_dark)


func _process(delta: float) -> void:
	_time += delta
	var p := _base
	if patrol_distance != 0.0 and patrol_speed > 0.0:
		p.x += pingpong(_time * patrol_speed, absf(patrol_distance)) * signf(patrol_distance)
	p.y += sin(_time * TAU * bob_speed) * bob_amplitude
	position = p


func _on_world_flipped(is_dark: bool) -> void:
	_apply_state(is_dark)


func _apply_state(is_dark: bool) -> void:
	var active := (is_dark == in_dark_world)
	visible = active
	kill_zone.monitoring  = active
	kill_zone.monitorable = active
