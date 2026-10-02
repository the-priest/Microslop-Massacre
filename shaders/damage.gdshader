shader_type canvas_item;
// Damage + low-health red vignette and low-stability glitch tint.
uniform float hurt : hint_range(0.0, 1.0) = 0.0;
uniform float low : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec2 d = UV - 0.5;
	float v = clamp(dot(d, d) * 2.8, 0.0, 1.0);
	float pulse = 0.75 + 0.25 * sin(TIME * 4.0);
	float a = v * (hurt * 0.8 + low * 0.5 * pulse);
	COLOR = vec4(0.6, 0.0, 0.02, a);
}
