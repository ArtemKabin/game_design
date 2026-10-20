# flip_chunk.gd
# A hazard chunk for the flip mechanic.
#
# The chunk is a row of equal-width SEGMENTS described by `pattern`:
#   '#' = ground in the WHITE world      '.' = hole in the WHITE world
# The BLACK world is the exact inverse: every '#' becomes a hole, every '.' becomes ground.
#
# VIRTUAL HOLES — there is no fall physics:
#   * One continuous StaticBody2D floor spans the whole chunk and NEVER changes.
#   * A hole is only (a) drawn as a gap and (b) covered by an Area2D kill zone.
#   * On world flip, the drawing and the kill zones swap; the physics floor stays.
#   * Ground segments in the current world are drawn solid and are walkable.
#     Hole segments in the current world draw NOTHING (the other world's floor
#     is invisible until you flip) and are deadly.
#
# Timing window: each kill zone is HOLE_INSET narrower than its hole on both
# sides, so the player may flip while their centre is within EDGE_GRACE px of
# a ground/hole boundary. Tune EDGE_GRACE in playtesting.
#
# ASSET PLACEHOLDER: the look is drawn in _draw(). Replace by giving each segment
# a Sprite2D/TextureRect later; the pattern/kill-zone logic stays as is.
class_name FlipChunk
extends Chunk

signal hole_entered(body: Node)

const SEGMENT_WIDTH := 80.0
const FLOOR_HEIGHT  := 32.0
const KILL_HEIGHT   := 40.0
const PLAYER_HALF_W := 14.0   # must match player.tscn collision width / 2
const EDGE_GRACE    := 14.0   # how far past a boundary the player may still flip
const HOLE_INSET    := PLAYER_HALF_W + EDGE_GRACE

@export var pattern: String = "####....####"

var _white_holes: Array[Area2D] = []   # deadly while the world is WHITE
var _black_holes: Array[Area2D] = []   # deadly while the world is BLACK


func _ready() -> void:
	_build()
	WorldState.world_flipped.connect(_on_world_flipped)
	_apply_state(WorldState.is_dark)


# ── Build ─────────────────────────────────────────────────────────────────────
func _build() -> void:
	var n := pattern.length()
	width = n * SEGMENT_WIDTH

	# Continuous physics floor — never toggled.
	var floor_body := StaticBody2D.new()
	floor_body.name = "Floor"
	floor_body.collision_layer = 1
	floor_body.collision_mask  = 0
	floor_body.position = Vector2(width * 0.5, FLOOR_HEIGHT * 0.5)
	var floor_shape := CollisionShape2D.new()
	var floor_rect  := RectangleShape2D.new()
	floor_rect.size = Vector2(width, FLOOR_HEIGHT)
	floor_shape.shape = floor_rect
	floor_body.add_child(floor_shape)
	add_child(floor_body)

	# One kill zone per run of equal segments.
	var i := 0
	while i < n:
		var c := pattern[i]
		var j := i
		while j < n and pattern[j] == c:
			j += 1
		var x0 := i * SEGMENT_WIDTH
		var x1 := j * SEGMENT_WIDTH
		var zone := _make_kill_zone(x0 + HOLE_INSET, x1 - HOLE_INSET)
		if c == ".":
			_white_holes.append(zone)
		else:
			_black_holes.append(zone)
		i = j


func _make_kill_zone(x0: float, x1: float) -> Area2D:
	var zone := Area2D.new()
	zone.name = "KillZone"
	zone.collision_layer = 0
	zone.collision_mask  = 1
	zone.monitoring  = false
	zone.monitorable = false
	zone.position = Vector2((x0 + x1) * 0.5, 0.0)
	var shape := CollisionShape2D.new()
	var rect  := RectangleShape2D.new()
	rect.size = Vector2(maxf(x1 - x0, 8.0), KILL_HEIGHT)
	shape.shape = rect
	zone.add_child(shape)
	zone.body_entered.connect(_on_zone_body_entered)
	add_child(zone)
	return zone


# ── Flip ──────────────────────────────────────────────────────────────────────
func _on_world_flipped(is_dark: bool) -> void:
	_apply_state(is_dark)


func _apply_state(is_dark: bool) -> void:
	for z in _white_holes:
		z.monitoring = not is_dark
	for z in _black_holes:
		z.monitoring = is_dark
	queue_redraw()


func _on_zone_body_entered(body: Node) -> void:
	hole_entered.emit(body)


## True if segment `index` is solid ground in the given world.
func is_ground(index: int, is_dark: bool) -> bool:
	var white_ground := pattern[index] == "#"
	return white_ground != is_dark


# ── Drawing (placeholder look) ────────────────────────────────────────────────
func _draw() -> void:
	var is_dark := WorldState.is_dark
	var col     := WorldState.get_platform_color()

	# Only the ground of the CURRENT world is drawn. Holes show nothing at all:
	# the other world's floor is invisible until you flip.
	for idx in range(pattern.length()):
		if is_ground(idx, is_dark):
			var rect := Rect2(idx * SEGMENT_WIDTH, 0.0, SEGMENT_WIDTH, FLOOR_HEIGHT)
			draw_rect(rect, col)

	# Edge lines at every ground/hole boundary — the spots where you flip.
	var edge := WorldState.get_fg_color()
	edge.a = 0.6
	for idx in range(1, pattern.length()):
		if pattern[idx] != pattern[idx - 1]:
			var x := idx * SEGMENT_WIDTH
			draw_line(Vector2(x, -6.0), Vector2(x, FLOOR_HEIGHT), edge, 2.0)
