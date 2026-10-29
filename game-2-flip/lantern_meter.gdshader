// lantern_meter.gdshader
// The HUD lantern doubles as the sight meter: `fill` 1.0 = fully coloured,
// lower values grey the lantern out from the TOP down (hard pixel edge).
shader_type canvas_item;

uniform float fill : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float grey = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	float cut = 1.0 - fill;             // everything above this line is grey
	float g = step(UV.y, cut);          // 1.0 where grey
	COLOR = vec4(mix(c.rgb, vec3(grey) * 0.8, g), c.a);
}
