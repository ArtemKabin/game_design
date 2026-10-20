# sphere_draw.gd
# Placeholder look of a hazard sphere: body, pulsing ring and spikes.
# `color` is set by sphere.gd to the foreground colour of the sphere's world.
extends Node2D

const RADIUS := 22.0

var color: Color = Color(0.08, 0.08, 0.08)
var _pulse: float = 0.0


func _process(delta: float) -> void:
	_pulse += delta * 3.5
	queue_redraw()


func _draw() -> void:
	var ring := color
	ring.a = 0.35 + 0.2 * sin(_pulse)
	var spike := color
	spike.a = 0.6
	var spike_len: float = RADIUS + 10.0 + 4.0 * sin(_pulse)
	for i in range(8):
		var angle: float = i * TAU / 8.0
		draw_line(Vector2.ZERO, Vector2(cos(angle), sin(angle)) * spike_len, spike, 1.5)
	draw_circle(Vector2.ZERO, RADIUS + 6.0 + 2.0 * sin(_pulse), ring)
	draw_circle(Vector2.ZERO, RADIUS, color)
	# Highlight in the opposite tone so it reads on both sphere colours.
	var hl := Color(1, 1, 1, 0.5) if color.r < 0.5 else Color(0, 0, 0, 0.35)
	draw_circle(Vector2(-RADIUS * 0.28, -RADIUS * 0.28), RADIUS * 0.28, hl)
