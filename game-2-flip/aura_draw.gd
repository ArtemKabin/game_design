# aura_draw.gd
# Animated aura rings behind a hazard sphere. Separate node so z-order works.
# `color` is set by sphere.gd.
extends Node2D

const RADIUS := 22.0

var color: Color = Color(0.08, 0.08, 0.08)
var _pulse: float = 0.0


func _ready() -> void:
	z_index = -1


func _process(delta: float) -> void:
	_pulse += delta * 2.2
	queue_redraw()


func _draw() -> void:
	for i in range(3):
		var t: float = float(i) / 3.0
		var r: float = RADIUS + 14.0 + t * 18.0 + 4.0 * sin(_pulse + t * TAU)
		var col := color
		col.a = (0.18 - t * 0.06) * (1.0 + 0.4 * sin(_pulse))
		draw_circle(Vector2.ZERO, r, col)
