# safe_marker.gd
# Wall lantern that marks a safe zone. Red in the RED world, blue in the BLUE
# world, same style as the lanterns in the player's hands (assets/env/
# lantern_red.png, lantern_blue.png, 16x24, hook at the top).
# Sits on the wall layer BEHIND the player. The sight fog clears a small disc
# around every node in the "wall_lantern" group (sight_fog.gd), so the lantern
# and the wall around it stay visible even far from the player.
extends Node2D

const TEX_RED_PATH  := "res://assets/env/lantern_red.png"
const TEX_BLUE_PATH := "res://assets/env/lantern_blue.png"
const GLOW_RED  := Color("ff8c3b")
const GLOW_BLUE := Color("4fb8ff")
const DIAMOND_R := 9.0       # fallback marker if the textures are missing

@onready var sprite: Sprite2D = $Sprite2D

var _tex_red:  Texture2D = null
var _tex_blue: Texture2D = null
var _pulse: float = 0.0


func _ready() -> void:
	add_to_group("wall_lantern")
	_tex_red  = load(TEX_RED_PATH) as Texture2D
	_tex_blue = load(TEX_BLUE_PATH) as Texture2D
	WorldState.world_flipped.connect(_on_world_flipped)
	_apply_world(WorldState.is_dark)


func _process(delta: float) -> void:
	_pulse += delta * 2.0
	queue_redraw()


func _on_world_flipped(is_dark: bool) -> void:
	_apply_world(is_dark)


func _apply_world(is_dark: bool) -> void:
	sprite.texture = _tex_blue if is_dark else _tex_red
	queue_redraw()


func _draw() -> void:
	var glow := GLOW_BLUE if WorldState.is_dark else GLOW_RED

	# Light: a soft disc plus a brighter core, breathing slowly. The glass sits
	# a few px below the sprite centre (hook is at the top).
	var centre := Vector2(0.0, 1.0)
	var outer := glow
	outer.a = 0.10 + 0.03 * sin(_pulse)
	draw_circle(centre, 30.0 + 3.0 * sin(_pulse), outer)
	var inner := glow
	inner.a = 0.22 + 0.05 * sin(_pulse + 1.0)
	draw_circle(centre, 16.0 + 2.0 * sin(_pulse), inner)

	if sprite.texture != null:
		return

	# Fallback: diamond in the world's foreground colour.
	var col := WorldState.get_fg_color()
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -DIAMOND_R), Vector2(DIAMOND_R, 0),
		Vector2(0, DIAMOND_R), Vector2(-DIAMOND_R, 0)
	]), col)
