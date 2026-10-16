# aura_draw.gd
# Animated aura ring behind the sphere. Separate node so z-order works.
extends Node2D

var _dangerous: bool = false
var _pulse: float    = 0.0

const RADIUS := 22.0


func _ready() -> void:
	_dangerous = WorldState.is_dark
	z_index = -1


func _process(delta: float) -> void:
	_pulse += delta * 2.2
	queue_redraw()


func _draw() -> void:
	var rings: int = 3 if _dangerous else 2
	for i in range(rings):
		var t: float = float(i) / float(rings)
		var r: float = RADIUS + 14.0 + t * 18.0 + 4.0 * sin(_pulse + t * TAU)
		var a: float = (0.18 - t * 0.06) * (1.0 + 0.4 * sin(_pulse))
		var col := Color(1, 1, 1, a) if _dangerous else Color(0, 0, 0, a)
		draw_circle(Vector2.ZERO, r, col)


func set_dangerous(dangerous: bool) -> void:
	_dangerous = dangerous
