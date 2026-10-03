shader_type spatial;
render_mode unshaded, cull_disabled;
// Emissive vertex-colored geometry: neon, lamps, signals.
// UV2.x kind: 0 always on, 1 night lamp, 2 traffic light (UV2.y = lamp 0 red,1 yellow,2 green; UV.x = phase)
// 3 neon flicker, 4 blinking beacon.
global uniform float night_amt;
vec3 lin(vec3 c) { return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c)); }
varying vec3 info;
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
// Buildings brought down this session (Game.collapse_building): everything
// inside a box (center x, center z, half x, half z) and above the street
// drops to the ground. Reloads leave them out of the city altogether.
uniform vec4 collapse_box[8];
uniform int collapse_n = 0;
vec3 collapse_v(vec3 v, mat4 model) {
	if (collapse_n <= 0) return v;
	vec3 w = (model * vec4(v, 1.0)).xyz;
	if (w.y < 0.35) return v;
	for (int i = 0; i < 8; i++) {
		if (i >= collapse_n) break;
		vec4 b = collapse_box[i];
		if (abs(w.x - b.x) < b.z && abs(w.z - b.y) < b.w) {
			return (inverse(model) * vec4(w.x, -2.0, w.z, 1.0)).xyz;
		}
	}
	return v;
}
void vertex() { info = vec3(UV2, UV.x); VERTEX = collapse_v(hide_cars(VERTEX, MODEL_MATRIX), MODEL_MATRIX); }
void fragment() {
	vec3 c = lin(COLOR.rgb);
	float k = info.x;
	float amt = 1.0;
	if (k > 0.5 && k < 1.5) {
		amt = mix(0.12, 1.0, night_amt);
	} else if (k > 1.5 && k < 2.5) {
		float t = mod(TIME * 0.08 + info.z, 1.0);
		float lamp = info.y;
		float green = step(t, 0.45);
		float yellow = step(0.45, t) * step(t, 0.55);
		float red = step(0.55, t);
		amt = lamp < 0.5 ? red : (lamp < 1.5 ? yellow : green);
		amt = mix(0.08, 1.0, amt);
	} else if (k > 2.5 && k < 3.5) {
		float fl = step(0.08, fract(sin(floor(TIME * 12.0 + info.z * 31.0)) * 4375.85));
		amt = mix(0.4, 1.0, fl) * mix(0.5, 1.0, night_amt);
	} else if (k > 3.5) {
		amt = step(0.5, fract(TIME * 0.7 + info.z));
	}
	ALBEDO = c * amt * (1.0 + night_amt * 0.6);
}
