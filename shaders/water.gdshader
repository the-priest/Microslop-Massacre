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
	vec3 deep = mix(vec3(0.02, 0.05, 0.07), vec3(0.01, 0.015, 0.03), night_amt);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = mix(deep, sky_col.rgb * 0.6, fres * 0.8);
	ROUGHNESS = 0.12 + r * 0.1;
	SPECULAR = 0.8;
	// City lights shimmer on the water at night.
	EMISSION = vec3(1.0, 0.75, 0.45) * night_amt * step(0.985, fract(sin(dot(floor(wp.xz * 1.5), vec2(12.9, 78.2))) * 43758.5)) * r * 1.5;
}
