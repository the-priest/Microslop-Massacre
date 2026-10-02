shader_type sky;
// Cheap procedural sky: gradient, stars, moon, sun, city glow on the horizon.
uniform vec3 top_col = vec3(0.02, 0.03, 0.06);
uniform vec3 hor_col = vec3(0.10, 0.08, 0.10);
uniform vec3 glow_col = vec3(0.35, 0.18, 0.10);
uniform vec3 sun_dir = vec3(0.0, 0.3, -1.0);
uniform vec3 sun_col = vec3(1.0, 0.9, 0.7);
uniform float night = 1.0;
uniform float cloud = 0.3;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	float a = hash(i); float b = hash(i + vec2(1, 0)); float c = hash(i + vec2(0, 1)); float d = hash(i + vec2(1, 1));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}
void sky() {
	vec3 d = normalize(EYEDIR);
	float h = clamp(d.y, -0.2, 1.0);
	vec3 col = mix(hor_col, top_col, pow(clamp(h, 0.0, 1.0), 0.55));
	col += glow_col * pow(1.0 - clamp(h, 0.0, 1.0), 6.0) * (0.6 + 0.4 * night);
	// Stars (few: light pollution).
	if (night > 0.3 && d.y > 0.05) {
		vec2 sp = d.xz / (d.y + 0.25) * 60.0;
		float s = step(0.9965, hash(floor(sp)));
		col += vec3(s) * 0.7 * night * clamp(d.y * 3.0, 0.0, 1.0);
	}
	// Sun / moon disc.
	vec3 sd = normalize(sun_dir);
	float sa = dot(d, sd);
	col += sun_col * smoothstep(0.9985, 0.9995, sa) * 3.0;
	col += sun_col * pow(max(sa, 0.0), 180.0) * 0.4;
	// Clouds.
	if (d.y > 0.0) {
		vec2 cp = d.xz / (d.y + 0.15) * 1.6 + vec2(TIME * 0.004, 0.0);
		float n = noise(cp) * 0.6 + noise(cp * 2.3) * 0.3 + noise(cp * 5.1) * 0.1;
		float cm = smoothstep(1.0 - cloud, 1.0, n) * clamp(d.y * 4.0, 0.0, 1.0);
		vec3 ccol = mix(hor_col * 1.4 + glow_col * 0.3, vec3(0.8, 0.8, 0.85) * (1.0 - night * 0.85), 0.5);
		col = mix(col, ccol, cm * 0.8);
	}
	COLOR = col;
}
