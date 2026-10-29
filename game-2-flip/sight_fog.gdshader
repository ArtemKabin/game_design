// sight_fog.gdshader
// Radial fog around the player. Everything farther than `radius` (in world px)
// is covered with the current background colour; a soft band fades in between.
// Wall lanterns punch extra holes: up to MAX_LIGHTS positions (relative to the
// player, same space as `p`) each clear a disc of `light_radius`.
// Drawn on a large ColorRect that follows the player (see sight_fog.gd).
shader_type canvas_item;

const int MAX_LIGHTS = 8;

uniform vec4  fog_color : source_color = vec4(0.95, 0.95, 0.95, 1.0);
uniform float radius   = 520.0;   // fully clear inside this distance
uniform float softness = 120.0;   // width of the fade band
uniform vec2  size     = vec2(4000.0, 4000.0);   // ColorRect size in px

uniform vec2  lights[8];          // lantern positions relative to the player
uniform int   light_count = 0;
uniform float light_radius   = 90.0;
uniform float light_softness = 50.0;

void fragment() {
	vec2 p = (UV - vec2(0.5)) * size;
	float a = smoothstep(radius, radius + softness, length(p));
	for (int i = 0; i < MAX_LIGHTS; i++) {
		if (i >= light_count) {
			break;
		}
		float d = length(p - lights[i]);
		a = min(a, smoothstep(light_radius, light_radius + light_softness, d));
	}
	COLOR = vec4(fog_color.rgb, a);
}
