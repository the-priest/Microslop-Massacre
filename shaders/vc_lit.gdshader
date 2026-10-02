shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;
// Vertex-colored lit geometry (props, ground, furniture, cars).
// UV2.x: 1 = ground (gets wet in rain), UV2.y: emission 0..n (dim self-glow).
global uniform float wet_amt;
global uniform float night_amt;
varying vec2 info;
// City chunks only: parked cars that were stolen collapse away (hide_box =
// center x, center z, half x, half z). Everything else leaves hide_n at 0.
uniform vec4 hide_box[32];
uniform int hide_n = 0;
vec3 hide_cars(vec3 v, mat4 model) {
	if (hide_n <= 0) return v;
	vec3 w = (model * vec4(v, 1.0)).xyz;
	if (w.y < 0.03 || w.y > 3.4) return v;
	for (int i = 0; i < 32; i++) {
		if (i >= hide_n) break;
		vec4 b = hide_box[i];
		if (abs(w.x - b.x) < b.z && abs(w.z - b.y) < b.w) {
			return (inverse(model) * vec4(b.x, -4.0, b.y, 1.0)).xyz;
		}
	}
	return v;
}
vec3 lin(vec3 c) { return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c)); }
void vertex() { info = UV2; VERTEX = hide_cars(VERTEX, MODEL_MATRIX); }
void fragment() {
	vec3 c = lin(COLOR.rgb);
	float ground = step(0.5, info.x) * step(info.x, 1.5);
	float wet = wet_amt * ground;
	c *= 1.0 - wet * 0.45;
	ALBEDO = c;
	ROUGHNESS = mix(0.9, 0.18, wet);
	SPECULAR = mix(0.3, 0.7, wet);
	EMISSION = c * info.y;
}
