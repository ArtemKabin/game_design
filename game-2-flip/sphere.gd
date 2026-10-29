# sphere.gd
# Hazard "sphere" — on screen a floating sheet ghost — that exists in ONE world
# only, at player height.
#   in_dark_world = false → exists in the RED world
#   in_dark_world = true  → exists in the BLUE world
# In its own world it is visible and kills on touch (KillZone Area2D).
# In the other world it is invisible and does nothing.
#
# Optional patrol: moves from its start x to start x + patrol_distance and back,
# at a constant patrol_speed (px/s). patrol_distance = 0 → stationary.
#
# Look: assets/hazards/ghost_sphere.png, 4 frames of 28x36, tag "float"
# (art/ghost_sphere.aseprite). The sheet is sliced by SpriteSheetFrames.
extends Node2D

## Emitted when the player touches the ghost while it is deadly. Fired by the
## KillZone's body_entered AND by an explicit overlap check every physics frame,
## so a flip that makes the ghost appear inside the player always kills.
signal hit(body: Node)

const RADIUS := 13.0   # must match the KillZone shape in sphere.tscn (ghost sprite is 24 px wide)

const SHEET_PATH := "res://assets/hazards/ghost_sphere.png"
const FRAME_W := 28
const FRAME_H := 36
const ANIMS := {"float": {"from": 0, "to": 3, "fps": 1000.0 / 160.0}}

@export var in_dark_world:   bool  = false
@export var patrol_distance: float = 0.0
@export var patrol_speed:    float = 0.0
@export var bob_amplitude:   float = 0.0   # the sprite bobs by itself; extra bob optional
@export var bob_speed:       float = 1.6

@onready var kill_zone: Area2D           = $KillZone
@onready var sprite:    AnimatedSprite2D = $Sprite

var _base: Vector2 = Vector2.ZERO
var _time: float   = 0.0
var _player: Node2D = null
var _player_half: Vector2 = Vector2(14.0, 18.0)   # read from the player's collision shape


func _ready() -> void:
	_base = position
	var tex := load(SHEET_PATH) as Texture2D
	if tex:
		sprite.sprite_frames = SpriteSheetFrames.build(tex, FRAME_W, FRAME_H, ANIMS)
		sprite.play("float")
		# Desync neighbouring ghosts a little.
		sprite.frame = randi() % 4
	else:
		push_warning("sphere.gd: sprite sheet missing: %s" % SHEET_PATH)
	kill_zone.body_entered.connect(func(body: Node) -> void: hit.emit(body))
	WorldState.world_flipped.connect(_on_world_flipped)
	_apply_state(WorldState.is_dark)


func _process(delta: float) -> void:
	_time += delta
	var p := _base
	if patrol_distance != 0.0 and patrol_speed > 0.0:
		p.x += pingpong(_time * patrol_speed, absf(patrol_distance)) * signf(patrol_distance)
	if bob_amplitude != 0.0:
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


## Circle (this ghost) vs. the player's rectangle.
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
