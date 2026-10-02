shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
// People: one merged mesh; limbs swing in the vertex shader.
// UV2 = (limb id, pivot height). limbs: 1 L leg, 2 R leg, 3 L arm, 4 R arm, 5 head
instance uniform float phase = 0.0;
instance uniform float amt = 0.0;
instance uniform float pose = 0.0;
instance uniform float flash = 0.0;
instance uniform float talk = 0.0;
instance uniform float raise = 0.0; // right arm up overhead (a raised fist)
vec3 lin(vec3 c) { return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c)); }
void vertex() {
	float limb = UV2.x;
	float pivot = UV2.y;
	float ang = 0.0;
	float s = sin(phase);
	if (limb > 0.5 && limb < 1.5) { ang = s * 0.65 * amt; }
	else if (limb > 1.5 && limb < 2.5) { ang = -s * 0.65 * amt; }
	else if (limb > 2.5 && limb < 3.5) { ang = -s * 0.5 * amt * (1.0 - pose) + pose * 1.35 + talk * 0.25 * sin(TIME * 3.0); }
	else if (limb > 3.5 && limb < 4.5) { ang = s * 0.5 * amt * (1.0 - pose) + pose * 1.45 + raise * 2.75; }
	else if (limb > 4.5) { ang = talk * 0.06 * sin(TIME * 7.0); }
	if (limb > 0.5) {
		vec3 v = VERTEX;
		v.y -= pivot;
		float c = cos(ang);
		float sn = sin(ang);
		float ny = v.y * c - v.z * sn;
		float nz = v.y * sn + v.z * c;
		VERTEX = vec3(v.x, ny + pivot, nz);
		vec3 n = NORMAL;
		NORMAL = vec3(n.x, n.y * c - n.z * sn, n.y * sn + n.z * c);
	}
}
void fragment() {
	vec3 c = lin(COLOR.rgb);
	ALBEDO = mix(c, vec3(1.0, 0.25, 0.2), flash * 0.6);
	ROUGHNESS = 0.85;
	EMISSION = vec3(1.0, 0.2, 0.15) * flash * 0.5;
}
