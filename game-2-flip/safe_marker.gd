# safe_marker.gd
# Marks a safe zone and GLOWS permanently, drawn above the sight fog
# (z_index above sight_fog's), so the player always sees where stopping is safe.
#
# ASSET PLACEHOLDER: give $Sprite2D a texture and the drawn diamond disappears;
# the pulsing halo stays so the glow survives the asset swap.
extends Node2D

const Z_ABOVE_FOG := 60      # sight_fog.gd's node sits at z_index 50
const DIAMOND_R   := 9.0

@onready var sprite: Sprite2D = $Sprite2D

var _pulse: float = 0.0


func _ready() -> void:
	z_index = Z_ABOVE_FOG
	WorldState.world_flipped.connect(func(_d: bool) -> void: queue_redraw())
	queue_redraw()


func _process(delta: float) -> void:
	_pulse += delta * 2.0
	queue_redraw()


func _draw() -> void:
	var col := WorldState.get_fg_color()

	# Glow: a faint filled disc plus two thin rings that breathe in and out.
	var glow := col
	glow.a = 0.07 + 0.03 * sin(_pulse)
	draw_circle(Vector2.ZERO, DIAMOND_R + 16.0 + 3.0 * sin(_pulse), glow)
	for i in range(2):
		var t: float = float(i) / 2.0
		var r: float = DIAMOND_R + 7.0 + t * 12.0 + 3.0 * sin(_pulse + t * TAU)
		var ring := col
		ring.a = (0.45 - t * 0.2) * (0.8 + 0.3 * sin(_pulse + t * PI))
		draw_circle(Vector2.ZERO, r, ring, false, 1.5)

	if sprite.texture != null:
		return

	# Diamond (placeholder).
	var body := col
	body.a = 0.95
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -DIAMOND_R), Vector2(DIAMOND_R, 0),
		Vector2(0, DIAMOND_R), Vector2(-DIAMOND_R, 0)
	]), body)
