shader_type spatial;
// 1 m grid with a stronger line every 5 m, in world space. Greybox floor for
// checking the real scale while rebuilding the campus.

uniform vec3 base_color : source_color = vec3(0.5, 0.5, 0.5);
uniform vec3 line_color : source_color = vec3(0.33, 0.33, 0.35);

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float grid(vec2 p) {
	vec2 g = abs(fract(p - 0.5) - 0.5) / fwidth(p);
	return 1.0 - min(min(g.x, g.y), 1.0);
}

void fragment() {
	float l1 = grid(world_pos.xz) * 0.45;
	float l5 = grid(world_pos.xz / 5.0);
	ALBEDO = mix(base_color, line_color, max(l1, l5));
	ROUGHNESS = 0.9;
}
