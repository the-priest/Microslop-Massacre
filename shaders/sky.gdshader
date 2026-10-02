shader_type sky;
// Procedural sky: graded atmosphere, sun haze, stars, moon, layered clouds
// lit by the sun, and the orange glow of the city on the horizon.
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
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += noise(p) * a;
		p = p * 2.07 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}
void sky() {
	vec3 d = normalize(EYEDIR);
	float h = clamp(d.y, -0.2, 1.0);
	vec3 sd = normalize(sun_dir);
	float sa = dot(d, sd);
	// Atmosphere: deeper overhead, hazier toward the horizon.
	vec3 col = mix(hor_col, top_col, pow(clamp(h, 0.0, 1.0), 0.48));
	col = mix(col, hor_col * 1.15, pow(1.0 - clamp(h, 0.0, 1.0), 10.0) * 0.6);
	// City glow (light pollution) along the horizon, stronger at night.
	col += glow_col * pow(1.0 - clamp(h, 0.0, 1.0), 5.0) * (0.55 + 0.6 * night);
	// Sun haze (forward scattering), warm near the horizon.
	float haze = pow(max(sa, 0.0), 8.0) * 0.25 + pow(max(sa, 0.0), 64.0) * 0.35;
	col += sun_col * haze * (1.0 - night * 0.7) * (0.6 + 0.4 * (1.0 - clamp(sd.y * 2.0, 0.0, 1.0)));
	// Stars (few: light pollution) with a slow twinkle.
	if (night > 0.3 && d.y > 0.05) {
		vec2 sp = d.xz / (d.y + 0.25) * 60.0;
		float hs = hash(floor(sp));
		float s = step(0.9962, hs) * (0.6 + 0.4 * sin(TIME * 2.0 + hs * 90.0));
		col += vec3(0.9, 0.95, 1.0) * s * 0.8 * night * clamp(d.y * 3.0, 0.0, 1.0);
	}
	// Sun / moon disc.
	col += sun_col * smoothstep(0.9986, 0.9995, sa) * mix(4.0, 1.6, night);
	// Clouds: two layers drifting at different speeds, lit on the sun side.
	if (d.y > 0.0) {
		vec2 cp = d.xz / (d.y + 0.12) * 1.4;
		float n1 = fbm(cp + vec2(TIME * 0.006, TIME * 0.002));
		float n2 = fbm(cp * 2.6 + vec2(-TIME * 0.01, 3.0));
		float n = n1 * 0.7 + n2 * 0.3;
		float cov = clamp(cloud, 0.0, 0.98);
		float cm = smoothstep(1.0 - cov * 0.9 - 0.08, 1.0 - cov * 0.9 + 0.22, n) * clamp(d.y * 5.0, 0.0, 1.0);
		float thick = smoothstep(0.4, 0.9, n);
		vec3 base = mix(hor_col * 1.2 + glow_col * 0.35, vec3(0.86, 0.87, 0.9) * (1.0 - night * 0.88), 0.55);
		vec3 shadowed = base * mix(1.0, 0.55, thick);
		vec3 lit = shadowed + sun_col * pow(max(sa, 0.0), 4.0) * 0.55 * (1.0 - night * 0.8) * (1.0 - thick * 0.5);
		// Underlit by the city at night.
		lit += glow_col * night * 0.35 * (1.0 - clamp(h * 2.0, 0.0, 1.0));
		col = mix(col, lit, cm * 0.85);
	}
	COLOR = col;
}
