# sight_fog.gd
# Sight radius around the player.
#   * Starts at SIGHT_MAX.
#   * Shrinks with every pixel the player travels (distance based, so slow
#     walking shrinks slowly and sprinting shrinks fast).
#   * Regrows while the player stands still.
# Everything outside the radius is hidden under the background colour, so the
# only way to see what lies ahead is to stop. Safe-zone markers (safe_marker.gd)
# draw ABOVE this fog so the player always sees where stopping is safe.
#
# Node setup (game.tscn): this Node2D follows the player; its child "Rect" is a
# 4000x4000 ColorRect with sight_fog.gdshader.
extends Node2D

# The camera shows about 576 px to each side of the player (1152 px window, zoom 1),
# so SIGHT_MAX + SOFTNESS must stay clearly below that or the fog is never seen.
const SIGHT_MAX      := 340.0   # px — radius at the start / after a stop
const SIGHT_MIN      := 90.0    # px — never smaller than this (player + one segment)
const SHRINK_PER_PX  := 0.35    # radius px lost per px travelled → max to min after ~715 px
const REGROW_PER_SEC := 220.0   # radius px regained per second while standing (~1.1 s min→max)
const STOP_SPEED     := 12.0    # px/s below which the player counts as standing
const SOFTNESS       := 70.0    # fade band width in px

# Wall lanterns (group "wall_lantern") each clear a small disc of fog around
# them, about the player's minimum sight, so safe zones stay visible.
const LIGHT_RADIUS   := SIGHT_MIN
const LIGHT_SOFTNESS := 50.0
const MAX_LIGHTS     := 8       # must match the array size in sight_fog.gdshader
const LIGHT_RANGE    := 1400.0  # lanterns farther than this are ignored

@onready var rect: ColorRect = $Rect

var radius:    float = SIGHT_MAX
var fog_color: Color = Color(0.95, 0.95, 0.95)

var _player: Node2D
var _last_x: float = 0.0


func _ready() -> void:
	# This node is a child of the player (game.tscn), so it moves with them exactly.
	_player = get_parent() as Node2D
	_last_x = _player.global_position.x
	fog_color = WorldState.get_bg_color()
	WorldState.world_flipped.connect(_on_world_flipped)
	rect.material.set_shader_parameter("softness", SOFTNESS)
	rect.material.set_shader_parameter("size", rect.size)
	rect.material.set_shader_parameter("light_radius", LIGHT_RADIUS)
	rect.material.set_shader_parameter("light_softness", LIGHT_SOFTNESS)
	_apply()


# Radius logic runs in the PHYSICS step: the player only moves on physics ticks,
# so measuring in _process (which may run several times per tick) would see
# "no movement" most frames and regrow the radius while running.
func _physics_process(delta: float) -> void:
	if delta <= 0.0:
		return
	var x := _player.global_position.x
	var moved := absf(x - _last_x)
	_last_x = x

	if moved / delta < STOP_SPEED:
		radius = minf(radius + REGROW_PER_SEC * delta, SIGHT_MAX)
	else:
		radius = maxf(radius - moved * SHRINK_PER_PX, SIGHT_MIN)

	_apply()


func _apply() -> void:
	rect.material.set_shader_parameter("radius", radius)
	rect.material.set_shader_parameter("fog_color", fog_color)
	_apply_lights()


## Pass the nearest wall lanterns to the shader, relative to the player.
func _apply_lights() -> void:
	var origin := _player.global_position
	var lights := PackedVector2Array()
	for node in get_tree().get_nodes_in_group("wall_lantern"):
		if not (node is Node2D):
			continue
		var rel: Vector2 = (node as Node2D).global_position - origin
		if absf(rel.x) <= LIGHT_RANGE:
			lights.append(rel)
	if lights.size() > MAX_LIGHTS:
		lights.resize(MAX_LIGHTS)
	var count := lights.size()
	while lights.size() < MAX_LIGHTS:
		lights.append(Vector2.ZERO)
	rect.material.set_shader_parameter("lights", lights)
	rect.material.set_shader_parameter("light_count", count)


func _on_world_flipped(_is_dark: bool) -> void:
	# Same timing as bg.gd so fog and background change together.
	var tween := create_tween()
	tween.tween_property(self, "fog_color", WorldState.get_bg_color(), 0.35) \
		.set_trans(Tween.TRANS_SINE)


## Sight as 0..1 (SIGHT_MIN → 0, SIGHT_MAX → 1), for the HUD lantern meter.
func level() -> float:
	return clampf((radius - SIGHT_MIN) / (SIGHT_MAX - SIGHT_MIN), 0.0, 1.0)


## Back to full sight (new run).
func reset() -> void:
	radius = SIGHT_MAX
	_last_x = _player.global_position.x
	_apply()
