shader_type canvas_item;
// Glitch overlay for low stability / Mr. Robot moments: slice shift + RGB split.
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
float rnd(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 uv = SCREEN_UV;
	float band = floor(uv.y * 28.0);
	float t = floor(TIME * 18.0);
	float on = step(1.0 - intensity * 0.6, rnd(vec2(band, t)));
	uv.x += (rnd(vec2(band, t + 1.0)) - 0.5) * intensity * 0.08 * on;
	float sp = intensity * 0.008;
	vec3 c;
	c.r = texture(screen_tex, uv + vec2(sp, 0.0)).r;
	c.g = texture(screen_tex, uv).g;
	c.b = texture(screen_tex, uv - vec2(sp, 0.0)).b;
	float line = step(0.985 - intensity * 0.05, rnd(vec2(band, floor(TIME * 40.0))));
	c = mix(c, vec3(0.1, 1.0, 0.4), line * intensity * 0.5);
	COLOR = vec4(c, 1.0);
}
