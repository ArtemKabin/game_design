# platform_draw.gd
# Draws a platform rectangle (centred on this node) with the floor tiles from
# assets/env: the red-carpet tile for safe zones, plain boards otherwise.
# Falls back to a flat recolouring rectangle if a tile is missing.
# Attach to a StaticBody2D or its child Node2D; set width/height in inspector.
extends Node2D

const TILE_W := 80.0
const TILE_SAFE_PATH   := "res://assets/env/floor_safe.png"
const TILE_SINGLE_PATH := "res://assets/env/floor_single.png"

@export var width:  float = 200.0
@export var height: float = 24.0
@export var is_ground: bool = false  # ground platforms draw slightly differently
@export var is_safe:   bool = false  # safe zone: never flips, carpet runner on top

var _tile: Texture2D = null


func _ready() -> void:
	_tile = load(TILE_SAFE_PATH if is_safe else TILE_SINGLE_PATH) as Texture2D
	WorldState.world_flipped.connect(_on_world_flipped)
	queue_redraw()


func _on_world_flipped(_is_dark: bool) -> void:
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(-width * 0.5, -height * 0.5, width, height)

	if _tile != null:
		# Tile the 80 px texture across the platform; the last piece is clipped.
		var x := rect.position.x
		var right := rect.end.x
		while x < right:
			var w := minf(TILE_W, right - x)
			draw_texture_rect_region(_tile,
				Rect2(x, rect.position.y, w, height),
				Rect2(0.0, 0.0, w, height))
			x += TILE_W
		return

	# Fallback: flat colour that recolours on world flip.
	var col: Color = WorldState.get_platform_color()
	draw_rect(rect, col)
	var edge_col := Color(col.r + 0.15, col.g + 0.15, col.b + 0.15, 0.5) \
		if WorldState.is_dark else Color(col.r - 0.15, col.g - 0.15, col.b - 0.15, 0.5)
	draw_rect(rect, edge_col, false, 1.5)
	if is_safe:
		var stripe := WorldState.get_bg_color()
		stripe.a = 0.35
		draw_rect(Rect2(rect.position.x + 6.0, rect.position.y + 6.0, rect.size.x - 12.0, 5.0), stripe)
