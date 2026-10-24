// sight_fog.gdshader
// Radial fog around the player. Everything farther than `radius` (in world px)
// is covered with the current background colour; a soft band fades in between.
// Drawn on a large ColorRect that follows the player (see sight_fog.gd).
shader_type canvas_item;

uniform vec4  fog_color : source_color = vec4(0.95, 0.95, 0.95, 1.0);
uniform float radius   = 520.0;   // fully clear inside this distance
uniform float softness = 120.0;   // width of the fade band
uniform vec2  size     = vec2(4000.0, 4000.0);   // ColorRect size in px

void fragment() {
	vec2 p = (UV - vec2(0.5)) * size;
	float d = length(p);
	float a = smoothstep(radius, radius + softness, d);
	COLOR = vec4(fog_color.rgb, a);
}
