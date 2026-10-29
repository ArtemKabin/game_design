# star.gd
# Hunter hazard ("star" in the code, an angry ghost on screen) that exists in
# ONE world only ("weeping angel" rule):
#   * In ITS world it is VISIBLE and kills on touch. It stands still — unless
#     it is inside the player's lantern light (sight_fog radius): then it
#     shies away from the player at FLEE_SPEED. Light is how you survive it.
#   * In the OTHER world it is invisible, harmless, and walks toward the player
#     at CHASE_SPEED — but only while it is on screen.
#   Flip back into its world while it stands on you → you die.
#   To pass a hunter: flip to the world where it is hidden, run through, outrun
#   it, then flip back once it is behind you.
#
# Screen rule: a hunter that has been on screen and then leaves the screen (e.g.
# the player outran it) despawns. One that has never been on screen waits.
#
# Look: assets/hazards/ghost_hunter.png, 4 frames of 28x36, tag "float"
# (art/ghost_hunter.aseprite). The sheet is sliced by SpriteSheetFrames.
extends Node2D

## Emitted when the player touches the hunter while it is deadly. Fired by the
## KillZone's body_entered AND by an explicit overlap check every physics frame,
## so a flip that makes the hunter appear inside the player always kills.
signal hit(body: Node)

const RADIUS           := 13.0    # must match the KillZone shape in star.tscn (ghost sprite is 24 px wide)
const CHASE_SPEED      := 100.0   # px/s, below the player's start speed (140)
const FLEE_SPEED       := 120.0   # px/s backing away from the light; still slower than running
const OFFSCREEN_MARGIN := 60.0    # px beyond the camera edge still counts as on screen

const SHEET_PATH := "res://assets/hazards/ghost_hunter.png"
const FRAME_W := 28
const FRAME_H := 36
const ANIMS := {"float": {"from": 0, "to": 3, "fps": 1000.0 / 120.0}}

@export var in_dark_world: bool = false

@onready var kill_zone: Area2D           = $KillZone
@onready var sprite:    AnimatedSprite2D = $Sprite

var _player: Node2D = null
var _player_half: Vector2 = Vector2(14.0, 18.0)   # read from the player's collision shape
var _frozen: bool   = true
var _seen:   bool   = false   # has been on screen at least once


func _ready() -> void:
	var tex := load(SHEET_PATH) as Texture2D
	if tex:
		sprite.sprite_frames = SpriteSheetFrames.build(tex, FRAME_W, FRAME_H, ANIMS)
		sprite.play("float")
		sprite.frame = randi() % 4
	else:
		push_warning("star.gd: sprite sheet missing: %s" % SHEET_PATH)
	kill_zone.body_entered.connect(func(body: Node) -> void: hit.emit(body))
	WorldState.world_flipped.connect(_on_world_flipped)
	_apply_state(WorldState.is_dark)


func _physics_process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Node2D
		if _player == null:
			return
		var shape := _player.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if shape and shape.shape is RectangleShape2D:
			_player_half = (shape.shape as RectangleShape2D).size * 0.5

	var on_screen := _is_on_screen()
	if on_screen:
		_seen = true
	elif _seen:
		queue_free()          # left the screen after being seen → gone for good
		return

	# Deadly and standing in the player → hit, no matter what the area reported.
	if kill_zone.monitoring and _overlaps_player():
		hit.emit(_player)

	if not on_screen:
		return

	var dx := _player.global_position.x - global_position.x
	if _frozen:
		# Visible: shy away from the lantern light, otherwise hold still.
		if absf(dx) < _player_light_radius():
			var away := -signf(dx) if dx != 0.0 else 1.0
			global_position.x += away * FLEE_SPEED * delta
		return

	# Hidden: hunt, walk toward the player along the floor.
	global_position.x += clampf(dx, -CHASE_SPEED * delta, CHASE_SPEED * delta)


## Radius of the player's lantern light (sight_fog.gd), 0 if unavailable.
func _player_light_radius() -> float:
	var fog := _player.get_node_or_null("SightFog")
	if fog == null:
		return 0.0
	return float(fog.get("radius"))


## Circle (this hunter) vs. the player's rectangle.
func _overlaps_player() -> bool:
	var v := global_position - _player.global_position
	var closest := Vector2(clampf(v.x, -_player_half.x, _player_half.x),
		clampf(v.y, -_player_half.y, _player_half.y))
	return v.distance_to(closest) <= RADIUS


func _is_on_screen() -> bool:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return true
	var half := get_viewport().get_visible_rect().size * 0.5 / cam.zoom
	var center := cam.get_screen_center_position()
	return absf(global_position.x - center.x) <= half.x + OFFSCREEN_MARGIN \
		and absf(global_position.y - center.y) <= half.y + OFFSCREEN_MARGIN


func _on_world_flipped(is_dark: bool) -> void:
	_apply_state(is_dark)


func _apply_state(is_dark: bool) -> void:
	var in_own_world := (is_dark == in_dark_world)
	visible = in_own_world
	_frozen = in_own_world                 # seen → stands still; unseen → hunts
	kill_zone.monitoring  = in_own_world   # deadly only where it can be seen
	kill_zone.monitorable = in_own_world
