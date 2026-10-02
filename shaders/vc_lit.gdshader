shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;
// Vertex-colored lit geometry (props, ground, furniture, cars).
// UV2.x: 1 = ground (gets wet in rain), 2 = glossy paint (cars),
// UV2.y: emission 0..n (dim self-glow).
#include "res://shaders/detail.gdshaderinc"
#include "res://shaders/lamps.gdshaderinc"
global uniform float wet_amt;
global uniform float night_amt;
varying flat vec2 info;
varying vec3 wpos;
varying vec3 wnrm;
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
void vertex() {
	info = UV2;
	VERTEX = hide_cars(VERTEX, MODEL_MATRIX);
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize(mat3(MODEL_MATRIX) * NORMAL);
}
void fragment() {
	vec3 c = lin(COLOR.rgb);
	float ground = step(0.5, info.x) * step(info.x, 1.5);
	float paint = step(1.5, info.x) * step(info.x, 2.5);
	float wet = wet_amt * ground;
	float rough = mix(0.9, 0.32, paint);
	float spec = mix(0.3, 0.55, paint);
	float d = gfx_detail;
	float puddle = 0.0;
	if (d > 0.01) {
		float dist = length(VERTEX);
		float fade = clamp(1.0 - dist / (35.0 + 90.0 * d), 0.0, 1.0);
		// Large-scale weathering: nothing in this city is one flat color.
		float macro = dt_fbm(wpos * 0.21);
		c *= mix(1.0, 0.8 + 0.4 * macro, 0.65 * d * (1.0 - paint * 0.7));
		float h = 0.0;
		if (fade > 0.0) {
			if (ground > 0.5) {
				// Asphalt / concrete: aggregate grain, patches and cracks.
				float g1 = dt_noise(vec3(wpos.xz * 7.0, 0.0));
				float g2 = dt_noise(vec3(wpos.xz * 29.0, 1.7));
				float grain = g1 * 0.55 + g2 * 0.45;
				// Paved ground cracks and gets patched; grass and fields don't.
				float paved = 1.0 - smoothstep(0.0, 0.04, c.g - max(c.r, c.b) * 1.08);
				float crack = (1.0 - smoothstep(0.0, 0.018, abs(dt_noise(vec3(wpos.xz * 0.38, 3.1)) - 0.5))) * paved;
				float patch = smoothstep(0.62, 0.66, dt_noise(vec3(wpos.xz * 0.09, 9.0))) * paved;
				c *= 1.0 - crack * 0.4 * fade * d;
				c *= mix(1.0, 0.86 + 0.28 * grain, fade * d);
				c = mix(c, c * 0.78, patch * 0.6 * d);
				h = grain * 0.6 - crack * 1.5;
				// Puddles collect in the low spots when it rains.
				puddle = smoothstep(0.55, 0.64, dt_noise(vec3(wpos.xz * 0.16, 5.0))) * wet * paved;
			} else {
				float micro = dt_noise(wpos * 5.5) * 0.6 + dt_noise(wpos * 23.0) * 0.4;
				float vert = 1.0 - abs(wnrm.y);
				// Grime collects at the bottom of walls and objects.
				float grime = (1.0 - smoothstep(0.0, 1.3, wpos.y)) * vert * (1.0 - paint);
				c *= 1.0 - grime * 0.28 * d;
				c *= mix(1.0, 0.9 + 0.2 * micro, fade * d * (1.0 - paint * 0.8));
				h = micro * (1.0 - paint);
				rough += (micro - 0.5) * 0.12 * (1.0 - paint);
			}
			if (d > 0.6) {
				NORMAL = dt_bump(NORMAL, VERTEX, h, (ground > 0.5 ? 0.006 : 0.004) * fade * (1.0 - puddle));
			}
		}
	}
	float w2 = max(wet, puddle);
	c *= 1.0 - wet * 0.42 - puddle * 0.2;
	// Anything you walk on (tagged ground, or just flat and low) gets the
	// night lift, so pavements never vanish into black.
	float flr = max(ground, step(0.8, wnrm.y) * (1.0 - step(0.8, wpos.y))) * step(0.8, length(VERTEX));
	ALBEDO = c;
	ROUGHNESS = clamp(mix(rough, 0.16, wet) * (1.0 - puddle * 0.85), 0.03, 1.0);
	SPECULAR = mix(spec, 0.75, w2);
	EMISSION = c * info.y + (c + vec3(0.004)) * vec3(1.0, 0.85, 0.66) * night_amt * (0.17 + 0.22 * ground) + (c * 0.7 + vec3(0.008 + 0.09 * flr)) * lamp_light(wpos, normalize(wnrm)) * mix(0.35, 1.0, step(0.8, length(VERTEX))) + (c * 0.22 + vec3(0.006 + 0.07 * flr)) * vec3(0.78, 0.74, 0.9) * night_lift;
}
