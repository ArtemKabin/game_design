# sphere_draw.gd
# Custom drawing node for the flip sphere. Draws concentric rings that
# change appearance depending on the world state.
extends Node2D

var _dangerous: bool = false
var _pulse: float    = 0.0

const RADIUS := 22.0


func _ready() -> void:
	# Match initial world state.
	_dangerous = WorldState.is_dark


func _process(delta: float) -> void:
	_pulse += delta * 3.5
	queue_redraw()


func _draw() -> void:
	var base_color: Color
	var ring_color: Color

	if _dangerous:
		# Black world: sharp, bright, ominous.
		base_color = Color(1.0, 1.0, 1.0)
		ring_color = Color(1.0, 1.0, 1.0, 0.45 + 0.3 * sin(_pulse))
		# Draw spiky cross lines to signal danger.
		var spike_len: float = RADIUS + 10.0 + 4.0 * sin(_pulse)
		for i in range(8):
			var angle: float = i * TAU / 8.0
			var tip := Vector2(cos(angle), sin(angle)) * spike_len
			draw_line(Vector2.ZERO, tip, Color(1, 1, 1, 0.6), 1.5)
	else:
		# White world: soft, inviting.
		base_color = Color(0.08, 0.08, 0.08)
		ring_color = Color(0.08, 0.08, 0.08, 0.25 + 0.12 * sin(_pulse))

	# Outer glow ring.
	draw_circle(Vector2.ZERO, RADIUS + 6.0 + 2.0 * sin(_pulse), ring_color)
	# Main body.
	draw_circle(Vector2.ZERO, RADIUS, base_color)
	# Inner highlight.
	var highlight_alpha := 0.35 if not _dangerous else 0.7
	draw_circle(Vector2(-RADIUS * 0.28, -RADIUS * 0.28),
		RADIUS * 0.28, Color(1, 1, 1, highlight_alpha))


func set_dangerous(dangerous: bool) -> void:
	_dangerous = dangerous
	queue_redraw()
