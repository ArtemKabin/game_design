# safe_marker.gd
# Marks a safe zone. ASSET PLACEHOLDER: give $Sprite2D a texture and the drawn
# diamond disappears automatically.
extends Node2D

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	WorldState.world_flipped.connect(func(_d: bool) -> void: queue_redraw())
	queue_redraw()


func _draw() -> void:
	if sprite.texture != null:
		return
	var col := WorldState.get_fg_color()
	col.a = 0.55
	var r := 9.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -r), Vector2(r, 0), Vector2(0, r), Vector2(-r, 0)
	]), col)
