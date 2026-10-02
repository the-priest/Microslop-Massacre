shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
// Fake light pools under street lamps: additive radial gradient, night only.
global uniform float night_amt;
vec3 lin(vec3 c) { return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c)); }
void fragment() {
	vec2 d = UV - vec2(0.5);
	float r = length(d) * 2.0;
	float a = smoothstep(1.0, 0.0, r);
	a *= a;
	ALBEDO = lin(COLOR.rgb) * a * night_amt * 0.22;
}
