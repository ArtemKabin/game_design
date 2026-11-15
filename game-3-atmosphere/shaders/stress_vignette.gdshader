shader_type canvas_item;
// Screen-edge darkening that grows and pulses with stress (0..1).
// First atmosphere hook: the player sees stress coming before it hurts.

uniform float stress : hint_range(0.0, 1.0) = 0.0;
uniform vec3 tint : source_color = vec3(0.12, 0.0, 0.02);

void fragment() {
	vec2 uv = SCREEN_UV - 0.5;
	float d = length(uv * vec2(1.6, 1.0));
	float pulse = 0.04 * stress * sin(TIME * (2.0 + stress * 4.0));
	float inner = mix(0.95, 0.35, stress) + pulse;
	float a = smoothstep(inner, inner + 0.55, d) * (0.25 + 0.6 * stress);
	COLOR = vec4(tint, a);
}
