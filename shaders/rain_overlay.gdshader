shader_type canvas_item;
// Screen-space rain streaks. Cheap, no particles.
uniform float amount : hint_range(0.0, 1.0) = 0.0;
float h(float x) { return fract(sin(x * 12.9898) * 43758.5453); }
void fragment() {
	vec2 uv = UV;
	float a = 0.0;
	for (int l = 0; l < 3; l++) {
		float fl = float(l);
		float cols = 90.0 + fl * 60.0;
		float cx = floor(uv.x * cols + uv.y * (4.0 + fl));
		float speed = 1.6 + h(cx + fl) * 1.2 + fl * 0.4;
		float off = h(cx * 1.7 + fl * 3.0);
		float y = fract(uv.y * (1.2 + fl * 0.4) - TIME * speed + off);
		float streak = smoothstep(0.0, 0.02, y) * smoothstep(0.12 + fl * 0.03, 0.0, y);
		float xin = fract(uv.x * cols + uv.y * (4.0 + fl));
		streak *= smoothstep(0.5, 0.0, abs(xin - 0.5)) * step(0.55, h(cx * 3.1 + fl));
		a += streak * (0.22 - fl * 0.05);
	}
	COLOR = vec4(0.75, 0.8, 0.9, a * amount);
}
