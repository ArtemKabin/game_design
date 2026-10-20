# wall.gd
# The advancing back wall ("Zögern-Strafe"). game.gd moves this node so that
# its local x=0 is the wall front; everything left of it is behind the wall.
#
# ASSET PLACEHOLDER:
#   $Sprite2D has no texture yet. As soon as a texture is assigned (in the
#   inspector or via code), the drawn fallback band disappears automatically.
#   Convention for the texture: its RIGHT edge is the wall front (x=0),
#   it should be tall enough to cover the camera (about 800 px) — see the
#   offset on the Sprite2D node in game.tscn.
extends Node2D

const BAND_WIDTH  := 1200.0   # how far the drawn band extends to the left
const BAND_TOP    := -700.0
const BAND_BOTTOM :=  700.0
const EDGE_WIDTH  :=   6.0    # bright/dark edge line at the wall front

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	WorldState.world_flipped.connect(_on_world_flipped)
	queue_redraw()


func _on_world_flipped(_is_dark: bool) -> void:
	queue_redraw()


func _draw() -> void:
	# Real asset present → nothing to draw.
	if sprite.texture != null:
		return

	var col := WorldState.get_fg_color()
	var height := BAND_BOTTOM - BAND_TOP

	# Solid band covering everything behind the wall.
	draw_rect(Rect2(-BAND_WIDTH, BAND_TOP, BAND_WIDTH, height), col)

	# Soft warning strip just in front of the wall so the player sees it coming.
	var warn := col
	warn.a = 0.22
	draw_rect(Rect2(0.0, BAND_TOP, 40.0, height), warn)

	# Hard edge line at the front.
	var edge := WorldState.get_bg_color()
	draw_rect(Rect2(-EDGE_WIDTH, BAND_TOP, EDGE_WIDTH, height), edge)
