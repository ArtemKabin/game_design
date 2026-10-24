# flip_chunk.gd
# THE hazard chunk. A row of equal-width SEGMENTS described by `pattern`,
# plus optional one-world hazards (spheres, stars) standing on them.
#
# Pattern characters (one char = SEGMENT_WIDTH px):
#   '#'  ground in the WHITE world only  (hole in black)
#   '.'  ground in the BLACK world only  (hole in white)
#   '='  ground in BOTH worlds           (solid; where hazards usually stand)
#
# VIRTUAL HOLES — there is no fall physics:
#   * One continuous StaticBody2D floor spans the whole chunk and NEVER changes.
#   * A hole is only (a) not drawn and (b) covered by an Area2D kill zone.
#   * On world flip, drawing and kill zones swap; the physics floor stays.
#
# Hazards (set by game.gd before add_child):
#   `spheres`: [x, in_dark_world, patrol_distance, patrol_speed]  (see sphere.gd)
#   `stars`:   [x, in_dark_world]                                  (see star.gd)
#   A hazard is passable only in the world where it is HIDDEN, so the segment
#   under it must be ground in that world ('=' always works). _build() warns
#   about placements that would make a chunk impassable.
#
# Timing window: each kill zone is HOLE_INSET narrower than its hole on both
# sides, so the player may flip while their centre is within EDGE_GRACE px of
# a ground/hole boundary. Tune EDGE_GRACE in playtesting.
#
# ASSET PLACEHOLDER: the floor look is drawn in _draw(). Replace by giving each
# segment a Sprite2D/TextureRect later; the pattern/kill-zone logic stays as is.
class_name FlipChunk
extends Chunk

signal hole_entered(body: Node)
signal sphere_hit(body: Node)
signal star_hit(body: Node)

const SEGMENT_WIDTH := 80.0
const FLOOR_HEIGHT  := 32.0
const KILL_HEIGHT   := 40.0
const HAZARD_Y      := -22.0  # hazard centre at player height, bottom on the floor
const PLAYER_HALF_W := 14.0   # must match player.tscn collision width / 2
const EDGE_GRACE    := 14.0   # how far past a boundary the player may still flip
const HOLE_INSET    := PLAYER_HALF_W + EDGE_GRACE

const SPHERE_SCENE := preload("res://sphere.tscn")
const STAR_SCENE   := preload("res://star.tscn")

@export var pattern: String = "####....####"
@export var spheres: Array  = []
@export var stars:   Array  = []

var _white_holes: Array[Area2D] = []   # deadly while the world is WHITE
var _black_holes: Array[Area2D] = []   # deadly while the world is BLACK
var placement_warnings: Array[String] = []   # filled by _build(), used by tests


func _ready() -> void:
	_build()
	WorldState.world_flipped.connect(_on_world_flipped)
	_apply_state(WorldState.is_dark)


## True if segment `index` is solid ground in the given world.
func is_ground(index: int, is_dark: bool) -> bool:
	var c := pattern[index]
	if c == "=":
		return true
	return (c == ".") if is_dark else (c == "#")


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

	# Kill zones: one per run of segments that are a hole in a given world.
	_build_hole_zones(false)   # holes in the white world
	_build_hole_zones(true)    # holes in the black world

	# Hazards.
	for spec in spheres:
		var s := SPHERE_SCENE.instantiate()
		s.position        = Vector2(float(spec[0]), HAZARD_Y)
		s.in_dark_world   = bool(spec[1])
		s.patrol_distance = float(spec[2])
		s.patrol_speed    = float(spec[3])
		add_child(s)
		s.hit.connect(func(body: Node) -> void: sphere_hit.emit(body))
		_check_placement("sphere", float(spec[0]), bool(spec[1]))

	for spec in stars:
		var st := STAR_SCENE.instantiate()
		st.position      = Vector2(float(spec[0]), HAZARD_Y)
		st.in_dark_world = bool(spec[1])
		add_child(st)
		st.hit.connect(func(body: Node) -> void: star_hit.emit(body))
		_check_placement("star", float(spec[0]), bool(spec[1]))


func _build_hole_zones(is_dark: bool) -> void:
	var n := pattern.length()
	var i := 0
	while i < n:
		if is_ground(i, is_dark):
			i += 1
			continue
		var j := i
		while j < n and not is_ground(j, is_dark):
			j += 1
		var zone := _make_kill_zone(i * SEGMENT_WIDTH + HOLE_INSET, j * SEGMENT_WIDTH - HOLE_INSET)
		if is_dark:
			_black_holes.append(zone)
		else:
			_white_holes.append(zone)
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
	zone.body_entered.connect(func(body: Node) -> void: hole_entered.emit(body))
	add_child(zone)
	return zone


## A hazard is passed in the world where it is hidden; the floor there must be ground.
func _check_placement(kind: String, x: float, in_dark: bool) -> void:
	var idx := clampi(int(x / SEGMENT_WIDTH), 0, pattern.length() - 1)
	var hidden_world_is_dark := not in_dark
	if not is_ground(idx, hidden_world_is_dark):
		var msg := "%s at x=%d stands on segment %d ('%s') of '%s', which is a hole in the world where it is hidden → impassable" \
			% [kind, int(x), idx, pattern[idx], pattern]
		placement_warnings.append(msg)
		push_warning("flip_chunk.gd: " + msg)


# ── Flip ──────────────────────────────────────────────────────────────────────
func _on_world_flipped(is_dark: bool) -> void:
	_apply_state(is_dark)


func _apply_state(is_dark: bool) -> void:
	for z in _white_holes:
		z.monitoring = not is_dark
	for z in _black_holes:
		z.monitoring = is_dark
	queue_redraw()


# ── Drawing (placeholder look) ────────────────────────────────────────────────
func _draw() -> void:
	var is_dark := WorldState.is_dark
	var col     := WorldState.get_platform_color()
	var dots    := WorldState.get_bg_color()
	dots.a = 0.55

	# Only the ground of the CURRENT world is drawn. Holes show nothing at all:
	# the other world's floor is invisible until you flip.
	for idx in range(pattern.length()):
		if not is_ground(idx, is_dark):
			continue
		var rect := Rect2(idx * SEGMENT_WIDTH, 0.0, SEGMENT_WIDTH, FLOOR_HEIGHT)
		draw_rect(rect, col)
		# '=' segments (solid in both worlds) get a dotted top edge so the
		# player can tell "safe to flip here" from one-world ground.
		if pattern[idx] == "=":
			for k in range(4):
				var dx := idx * SEGMENT_WIDTH + 10.0 + k * 20.0
				draw_rect(Rect2(dx, 5.0, 8.0, 4.0), dots)

	# Edge lines where the visible ground ends.
	var edge := WorldState.get_fg_color()
	edge.a = 0.6
	for idx in range(1, pattern.length()):
		if is_ground(idx, is_dark) != is_ground(idx - 1, is_dark):
			var x := idx * SEGMENT_WIDTH
			draw_line(Vector2(x, -6.0), Vector2(x, FLOOR_HEIGHT), edge, 2.0)
