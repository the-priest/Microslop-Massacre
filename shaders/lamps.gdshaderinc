// The streetlamps nearest the camera, as real (single-pass) point lights.
// NightLights fills these on the shared world materials every few frames:
// xyz = lamp head position, w = range; lamp_col.rgb = linear colour * energy.
uniform vec4 lamp_pos[16];
uniform vec4 lamp_col[16];
uniform int lamp_n = 0;
// City sky glow on dark surfaces at night (scaled by the Night brightness
// setting). 0 indoors and by day.
uniform float night_lift = 0.0;

// Diffuse light from the nearby lamps on a surface (world position/normal).
vec3 lamp_light(vec3 p, vec3 n) {
	vec3 acc = vec3(0.0);
	for (int i = 0; i < 16; i++) {
		if (i >= lamp_n) break;
		vec3 d = lamp_pos[i].xyz - p;
		float r = lamp_pos[i].w;
		float dist = length(d);
		if (dist >= r) continue;
		float att = 1.0 - dist / r;
		att *= att;
		float ndl = max(dot(n, d / max(dist, 0.001)), 0.0) * 0.75 + 0.25;
		acc += lamp_col[i].rgb * att * ndl;
	}
	return acc;
}
