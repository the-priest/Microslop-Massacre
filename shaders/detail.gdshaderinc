// Procedural surface detail shared by the world shaders. gfx_detail is set
// from the graphics preset: 0 = off (Low), 0.4 (Medium), 0.7 (High), 1 (Ultra).
global uniform float gfx_detail;

float dt_hash(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.71, 0.113, 0.419));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float dt_noise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(dt_hash(i), dt_hash(i + vec3(1, 0, 0)), f.x),
			mix(dt_hash(i + vec3(0, 1, 0)), dt_hash(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(dt_hash(i + vec3(0, 0, 1)), dt_hash(i + vec3(1, 0, 1)), f.x),
			mix(dt_hash(i + vec3(0, 1, 1)), dt_hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

float dt_fbm(vec3 p) {
	return dt_noise(p) * 0.55 + dt_noise(p * 2.03 + 3.1) * 0.3 + dt_noise(p * 4.11 + 7.7) * 0.15;
}

// Bump mapping without tangents (surface gradient): perturb the view-space
// normal n at view-space position vp by height field h (meters) scaled by k.
vec3 dt_bump(vec3 n, vec3 vp, float h, float k) {
	vec3 dpdx = dFdx(vp);
	vec3 dpdy = dFdy(vp);
	float dhx = dFdx(h) * k;
	float dhy = dFdy(h) * k;
	vec3 r1 = cross(dpdy, n);
	vec3 r2 = cross(n, dpdx);
	float det = dot(dpdx, r1);
	if (abs(det) < 1e-9) return n;
	vec3 g = sign(det) * (dhx * r1 + dhy * r2);
	return normalize(abs(det) * n - g);
}
