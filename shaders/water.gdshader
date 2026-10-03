shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx, cull_disabled;
global uniform float night_amt;
global uniform vec4 sky_col;
varying vec3 wp;
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += sin(wp.x * 0.15 + TIME * 0.8) * 0.06 + cos(wp.z * 0.12 + TIME * 0.6) * 0.06;
}
void fragment() {
	float r = sin(wp.x * 0.9 + TIME * 1.3) * cos(wp.z * 0.7 - TIME) * 0.5 + 0.5;
	// Blue-green by day, ink at night; wide, slow wind streaks so a sea isn't
	// one flat colour from the air.
	vec3 deep = mix(vec3(0.05, 0.15, 0.22), vec3(0.01, 0.015, 0.03), night_amt);
	vec3 light = mix(vec3(0.1, 0.24, 0.32), vec3(0.015, 0.025, 0.045), night_amt);
	float streak = sin(wp.x * 0.021 + wp.z * 0.013 + TIME * 0.15) * cos(wp.z * 0.017 - wp.x * 0.008 - TIME * 0.1) * 0.5 + 0.5;
	vec3 base = mix(deep, light, streak * 0.45);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = mix(base, sky_col.rgb * 0.5, fres * 0.45);
	// Two sets of moving ripples bend the normal, so the sun glints. They fade
	// out with distance, where they'd only alias into rings.
	float near_k = clamp(1.0 - length(VERTEX) / 350.0, 0.0, 1.0);
	vec3 n = vec3(
		(sin(wp.x * 0.6 + TIME * 1.1) * 0.05 + cos(wp.z * 0.45 - TIME * 0.9) * 0.04) * near_k,
		1.0,
		(cos(wp.x * 0.35 + TIME * 0.7) * 0.04 + sin(wp.z * 0.8 + TIME * 1.2) * 0.05) * near_k);
	NORMAL = normalize(mat3(VIEW_MATRIX) * normalize(n));
	ROUGHNESS = mix(0.45, 0.1 + r * 0.08, near_k);
	// Far off, a mirror-flat sea would just reflect the sky white.
	SPECULAR = mix(0.3, 0.8, near_k);
	// City lights shimmer on the water at night.
	EMISSION = vec3(1.0, 0.75, 0.45) * night_amt * step(0.985, fract(sin(dot(floor(wp.xz * 1.5), vec2(12.9, 78.2))) * 43758.5)) * r * 1.5;
}
