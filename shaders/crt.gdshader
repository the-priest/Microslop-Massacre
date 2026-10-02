shader_type canvas_item;

// CRT overlay: transparent dark scanlines + vignette + faint flicker.
// IMPORTANT: this must NOT sample TEXTURE — it sits on a plain ColorRect
// whose texture is a white 1x1 pixel. Instead we output near-black with a
// small alpha so it blends over whatever is behind it.
uniform float scan_strength : hint_range(0.0, 1.0) = 0.16;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.30;

void fragment() {
	float scan = sin(UV.y * 900.0) * 0.5 + 0.5;
	float a = scan * scan_strength;
	vec2 d = UV - vec2(0.5);
	a = clamp(a + dot(d, d) * vignette_strength * 2.2, 0.0, 0.85);
	a *= 0.97 + 0.03 * sin(TIME * 60.0); // phosphor flicker
	// faint green phosphor tint in the darkened areas
	COLOR = vec4(0.0, 0.03, 0.015, a);
}
