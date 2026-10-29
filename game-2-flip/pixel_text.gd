# pixel_text.gd
# Draws text with the pixel font sheet assets/ui/pixel_font.png (5x7 glyphs in
# 6x8 cells, drawn in art/pixel_font.aseprite). Upper-case only; lower-case is
# converted. Unknown characters draw as a space.
#
#   var t := PixelText.new(); t.text = "SCORE 12"; t.scale_factor = 3
#
# Colour via `color` (plus an optional drop shadow). The node sizes itself to
# the text so it works inside containers; with `align_center` the text is
# centred inside whatever width the node has.
class_name PixelText
extends Control

const SHEET_PATH := "res://assets/ui/pixel_font.png"
const CHARS      := "ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÜ0123456789 .:-!,?'"
const GLYPH_W    := 6
const GLYPH_H    := 8
const ADVANCE    := 6   # cell width incl. 1 px spacing

@export var text: String = "" : set = set_text
@export var scale_factor: int = 3 : set = set_scale_factor
@export var color: Color = Color.WHITE : set = set_color
@export var shadow: bool = true
@export var shadow_color: Color = Color(0.0, 0.0, 0.0, 0.55)
@export var align_center: bool = false
@export var align_right: bool = false   # text ends at the node's right edge

var _tex: Texture2D = null


func _ready() -> void:
	_tex = load(SHEET_PATH) as Texture2D
	if _tex == null:
		push_warning("pixel_text.gd: font sheet missing: %s" % SHEET_PATH)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_size()
	queue_redraw()


func _notification(what: int) -> void:
	# Anchored nodes get their final size after _ready; redraw so centring is right.
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func set_text(v: String) -> void:
	text = v.to_upper()
	_update_size()
	queue_redraw()


func set_scale_factor(v: int) -> void:
	scale_factor = maxi(v, 1)
	_update_size()
	queue_redraw()


func set_color(v: Color) -> void:
	color = v
	queue_redraw()


## Width of the widest line.
func text_width() -> float:
	var longest := 0
	for line in text.split("\n"):
		longest = maxi(longest, line.length())
	return float(longest * ADVANCE * scale_factor)


func line_height() -> float:
	return float((GLYPH_H + 2) * scale_factor)


func text_height() -> float:
	var lines := text.split("\n").size()
	return float(GLYPH_H * scale_factor + (lines - 1) * line_height())


func _update_size() -> void:
	custom_minimum_size = Vector2(text_width(), text_height())


func _draw() -> void:
	if _tex == null:
		return
	var sf := float(scale_factor)
	var y := floorf((size.y - text_height()) * 0.5) if (align_center or align_right) else 0.0
	for line in text.split("\n"):
		var line_w := float(line.length() * ADVANCE * scale_factor)
		var x := 0.0
		if align_center:
			x = floorf((size.x - line_w) * 0.5)
		elif align_right:
			x = size.x - line_w
		for ch in line:
			var idx := CHARS.find(ch)
			if idx < 0:
				idx = CHARS.find(" ")
			var src := Rect2(idx * GLYPH_W, 0, GLYPH_W, GLYPH_H)
			if shadow:
				draw_texture_rect_region(_tex, Rect2(x + sf, y + sf, GLYPH_W * sf, GLYPH_H * sf), src, shadow_color)
			draw_texture_rect_region(_tex, Rect2(x, y, GLYPH_W * sf, GLYPH_H * sf), src, color)
			x += ADVANCE * sf
		y += line_height()
