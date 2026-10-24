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

## Emitted when the player touches the sphere while it is deadly. Fired by the
## KillZone's body_entered AND by an explicit overlap check every physics frame,
## so a flip that makes the sphere appear inside the player always kills.
signal hit(body: Node)

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
var _player: Node2D = null
var _player_half: Vector2 = Vector2(14.0, 18.0)   # read from the player's collision shape


func _ready() -> void:
	_base = position
	# Colour = foreground of the world it lives in (contrasts with that background).
	var col := Color(0.95, 0.95, 0.95) if in_dark_world else Color(0.08, 0.08, 0.08)
	sphere_draw.color = col
	aura.color = col
	kill_zone.body_entered.connect(func(body: Node) -> void: hit.emit(body))
	WorldState.world_flipped.connect(_on_world_flipped)
	_apply_state(WorldState.is_dark)


func _process(delta: float) -> void:
	_time += delta
	var p := _base
	if patrol_distance != 0.0 and patrol_speed > 0.0:
		p.x += pingpong(_time * patrol_speed, absf(patrol_distance)) * signf(patrol_distance)
	p.y += sin(_time * TAU * bob_speed) * bob_amplitude
	position = p


func _physics_process(_delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Node2D
		if _player == null:
			return
		var shape := _player.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if shape and shape.shape is RectangleShape2D:
			_player_half = (shape.shape as RectangleShape2D).size * 0.5
	# Deadly and standing in the player → hit, no matter what the area reported.
	if kill_zone.monitoring and _overlaps_player():
		hit.emit(_player)


## Circle (this sphere) vs. the player's rectangle.
func _overlaps_player() -> bool:
	var v := global_position - _player.global_position
	var closest := Vector2(clampf(v.x, -_player_half.x, _player_half.x),
		clampf(v.y, -_player_half.y, _player_half.y))
	return v.distance_to(closest) <= RADIUS


func _on_world_flipped(is_dark: bool) -> void:
	_apply_state(is_dark)


func _apply_state(is_dark: bool) -> void:
	var active := (is_dark == in_dark_world)
	visible = active
	kill_zone.monitoring  = active
	kill_zone.monitorable = active
