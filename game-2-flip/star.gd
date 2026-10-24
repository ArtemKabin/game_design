# star.gd
# Hunter hazard that exists in ONE world only ("weeping angel" rule):
#   * In ITS world it is VISIBLE, stands still and kills on touch.
#   * In the OTHER world it is invisible, harmless, and walks toward the player
#     at CHASE_SPEED — but only while it is on screen.
#   Flip back into its world while it stands on you → you die.
#   To pass a star: flip to the world where it is hidden, run through, outrun it,
#   then flip back once it is behind you.
#
# Screen rule: a star that has been on screen and then leaves the screen (e.g.
# the player outran it) despawns. A star that has never been on screen waits.
#
# ASSET PLACEHOLDER: the look is drawn in _draw(). Add a Sprite2D under this
# node later; the chase/kill logic does not care how it looks.
extends Node2D

const RADIUS           := 20.0    # must match the KillZone shape in star.tscn
const CHASE_SPEED      := 100.0   # px/s, below the player's start speed (140)
const OFFSCREEN_MARGIN := 60.0    # px beyond the camera edge still counts as on screen

## Emitted when the player touches the star while it is deadly. Fired by the
## KillZone's body_entered AND by an explicit overlap check every physics frame,
## so a flip that makes the star appear inside the player always kills, even if
## the physics server does not report a new "entered" pair for the overlap.
signal hit(body: Node)

@export var in_dark_world: bool = false

@onready var kill_zone: Area2D = $KillZone

var _player: Node2D = null
var _player_half: Vector2 = Vector2(14.0, 18.0)   # read from the player's collision shape
var _frozen: bool   = true
var _seen:   bool   = false   # has been on screen at least once
var _pulse:  float  = 0.0
var _color:  Color  = Color(0.08, 0.08, 0.08)


func _ready() -> void:
	_color = Color(0.95, 0.95, 0.95) if in_dark_world else Color(0.08, 0.08, 0.08)
	kill_zone.body_entered.connect(func(body: Node) -> void: hit.emit(body))
	WorldState.world_flipped.connect(_on_world_flipped)
	_apply_state(WorldState.is_dark)


func _process(delta: float) -> void:
	_pulse += delta * 3.0
	queue_redraw()


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

	if _frozen or not on_screen:
		return

	# Hunt: walk toward the player along the floor.
	var dx := _player.global_position.x - global_position.x
	global_position.x += clampf(dx, -CHASE_SPEED * delta, CHASE_SPEED * delta)


## Circle (this star) vs. the player's rectangle.
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


# ── Drawing (placeholder look): five-point star with a pulsing halo ───────────
func _draw() -> void:
	var halo := _color
	halo.a = 0.18 + 0.08 * sin(_pulse)
	draw_circle(Vector2.ZERO, RADIUS + 8.0 + 3.0 * sin(_pulse), halo)

	var pts := PackedVector2Array()
	for i in range(10):
		var r: float = RADIUS if i % 2 == 0 else RADIUS * 0.45
		var a: float = -PI * 0.5 + i * PI / 5.0
		pts.append(Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, _color)

	# Eye in the opposite tone: it is watching you.
	var eye := Color(1, 1, 1, 0.9) if _color.r < 0.5 else Color(0, 0, 0, 0.8)
	draw_circle(Vector2(0.0, -2.0), 3.5, eye)
