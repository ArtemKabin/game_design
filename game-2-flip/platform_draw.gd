# platform_draw.gd
# Draws a static platform rectangle that recolours on world flip.
# Attach to a StaticBody2D or its child Node2D; set width/height in inspector.
extends Node2D

@export var width:  float = 200.0
@export var height: float = 24.0
@export var is_ground: bool = false  # ground platforms draw slightly differently
@export var is_safe:   bool = false  # safe zone: never flips, gets a lighter inner stripe


func _ready() -> void:
	WorldState.world_flipped.connect(_on_world_flipped)
	queue_redraw()


func _on_world_flipped(_is_dark: bool) -> void:
	queue_redraw()


func _draw() -> void:
	var col: Color = WorldState.get_platform_color()
	var rect := Rect2(-width * 0.5, -height * 0.5, width, height)
	draw_rect(rect, col)

	# Subtle edge line.
	var edge_col := Color(col.r + 0.15, col.g + 0.15, col.b + 0.15, 0.5) \
		if WorldState.is_dark else Color(col.r - 0.15, col.g - 0.15, col.b - 0.15, 0.5)
	draw_rect(rect, edge_col, false, 1.5)

	# Safe zone: a soft inner stripe so it reads as "nothing happens here".
	if is_safe:
		var stripe := WorldState.get_bg_color()
		stripe.a = 0.35
		var inner := Rect2(rect.position.x + 6.0, rect.position.y + 6.0,
			rect.size.x - 12.0, 5.0)
		draw_rect(inner, stripe)
