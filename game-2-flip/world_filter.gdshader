// world_filter.gdshader
// Full-screen colour grade: desaturate towards grey, then multiply by a tint.
// RED world: warm, saturated. BLUE world: grey with a blue cast.
// Lives on a ColorRect in a CanvasLayer below the HUD (world_filter.gd).
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec3  tint       = vec3(1.0, 1.0, 1.0);
uniform float saturation = 1.0;

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, saturation) * tint;
	COLOR = vec4(c, 1.0);
}
