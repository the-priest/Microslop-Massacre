shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;
// Procedural building facades: windows, storefronts, brick, night lights.
// UV = facade meters (u along wall, v = height), UV2 = (style, seed).
// COLOR = wall color (sRGB). Style 0 = plain surface (roofs, trims).

#include "res://shaders/detail.gdshaderinc"
#include "res://shaders/lamps.gdshaderinc"
global uniform float night_amt;
global uniform float wet_amt;
global uniform vec4 sky_col;

varying vec2 fuv;
varying flat vec2 finfo;
varying vec3 wpos;
varying vec3 wnrm;

const float FLOOR_H[11] = float[](3.2, 3.1, 3.4, 3.8, 3.8, 5.0, 3.0, 4.0, 3.6, 3.5, 4.0);
const float SPACING[11] = float[](3.0, 2.8, 3.2, 2.6, 1.6, 6.0, 2.6, 1.4, 2.2, 4.0, 8.0);
const float WIN_W[11]   = float[](1.0, 1.1, 1.2, 1.8, 1.5, 3.2, 1.2, 1.3, 1.2, 2.6, 0.0);
const float WIN_H[11]   = float[](1.4, 1.5, 1.9, 2.0, 3.3, 1.2, 1.4, 3.6, 2.2, 1.6, 0.0);
const float SILL[11]    = float[](0.9, 0.9, 0.8, 0.9, 0.25, 3.3, 1.0, 0.2, 0.8, 1.0, 0.0);
const float GROUND[11]  = float[](0.0, 4.0, 3.4, 5.0, 6.0, 0.0, 4.0, 6.0, 6.0, 4.0, 0.0);
const float LIT[11]     = float[](0.0, 0.42, 0.40, 0.45, 0.38, 0.15, 0.55, 0.35, 0.45, 0.35, 0.0);
const float BRICK[11]   = float[](0.0, 1.0, 0.6, 0.0, 0.0, 0.4, 1.0, 0.0, 0.3, 0.0, 0.0);

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

vec3 lin(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c));
}

// Buildings brought down this session (Game.collapse_building): everything
// inside a box (center x, center z, half x, half z) and above the street
// drops to the ground. Reloads leave them out of the city altogether.
uniform vec4 collapse_box[8];
uniform int collapse_n = 0;
vec3 collapse_v(vec3 v, mat4 model) {
	if (collapse_n <= 0) return v;
	vec3 w = (model * vec4(v, 1.0)).xyz;
	if (w.y < 0.35) return v;
	for (int i = 0; i < 8; i++) {
		if (i >= collapse_n) break;
		vec4 b = collapse_box[i];
		if (abs(w.x - b.x) < b.z && abs(w.z - b.y) < b.w) {
			return (inverse(model) * vec4(w.x, -2.0, w.z, 1.0)).xyz;
		}
	}
	return v;
}
void vertex() {
	fuv = UV;
	finfo = UV2;
	VERTEX = collapse_v(VERTEX, MODEL_MATRIX);
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize(mat3(MODEL_MATRIX) * NORMAL);
}

void fragment() {
	vec3 wall = lin(COLOR.rgb);
	int st = int(finfo.x + 0.5);
	float seed = abs(finfo.y);
	bool shops = finfo.y >= 0.0;
	float wet = wet_amt * step(wpos.y, 0.3);
	vec3 albedo = wall;
	vec3 emit = vec3(0.0);
	float rough = 0.92;
	float spec = 0.25;
	float hgt = 0.0;
	if (st > 0 && st < 11) {
		float fh = FLOOR_H[st];
		float sp = SPACING[st];
		float ww = WIN_W[st];
		float wh = WIN_H[st];
		float sill = SILL[st];
		float g = shops ? GROUND[st] : 0.0;
		// Distance fade of fine detail (kills moire on far towers).
		float px = max(fwidth(fuv.x), fwidth(fuv.y));
		float detail = 1.0 - clamp((px - sp * 0.08) / (sp * 0.25), 0.0, 1.0);
		// Brick mortar.
		float brick = BRICK[st];
		if (brick > 0.0) {
			float row = floor(fuv.y / 0.28);
			float mortar = step(0.86, fract(fuv.y / 0.28)) + step(0.94, fract(fuv.x / 0.56 + row * 0.5));
			albedo = mix(albedo, albedo * 0.72, clamp(mortar, 0.0, 1.0) * brick * detail * 0.6);
			// Individual bricks vary a little in tone.
			float bh = dt_hash(vec3(floor(fuv.x / 0.56 + row * 0.5), row, seed));
			albedo *= mix(1.0, 0.9 + 0.2 * bh, brick * detail * gfx_detail);
			// Soft mortar profile for relief (hard steps alias into white lines).
			float my = smoothstep(0.78, 0.9, fract(fuv.y / 0.28)) * (1.0 - smoothstep(0.96, 1.0, fract(fuv.y / 0.28)));
			float mx = smoothstep(0.9, 0.95, fract(fuv.x / 0.56 + row * 0.5)) * (1.0 - smoothstep(0.98, 1.0, fract(fuv.x / 0.56 + row * 0.5)));
			hgt -= clamp(my + mx, 0.0, 1.0) * brick * 0.006 * detail;
		}
		// Window grid above the ground band.
		float vy = fuv.y - g;
		if (vy > 0.0 && ww > 0.0) {
			vec2 cell = vec2(floor(fuv.x / sp), floor(vy / fh));
			vec2 f = vec2(fract(fuv.x / sp) * sp, fract(vy / fh) * fh);
			float inx = step(abs(f.x - sp * 0.5), ww * 0.5);
			float iny = step(sill, f.y) * step(f.y, sill + wh);
			float win = inx * iny;
			// Frame lines inside big glass (mullions).
			float mull = 0.0;
			if (st == 4 || st == 7) {
				mull = step(abs(f.x - sp * 0.5), 0.05) + step(abs(f.y - (sill + wh * 0.5)), 0.04);
			}
			float h = hash(cell + vec2(seed * 7.13, seed * 3.71));
			float h2 = hash(cell.yx + vec2(seed, 11.0));
			vec3 glass = vec3(0.035, 0.045, 0.06);
			vec3 refl = sky_col.rgb * (0.35 + 0.35 * h2);
			if (st == 7 || st == 4) {
				glass = vec3(0.03, 0.06, 0.09);
				refl = sky_col.rgb * 0.7 + vec3(0.02, 0.05, 0.09);
			}
			float lit_ratio = LIT[st];
			float on = step(h, lit_ratio) * night_amt + step(h, lit_ratio * 0.25) * (1.0 - night_amt) * 0.25;
			vec3 warm = mix(vec3(1.0, 0.72, 0.38), vec3(1.0, 0.86, 0.6), h2);
			vec3 cool = mix(vec3(0.7, 0.8, 1.0), vec3(0.85, 0.92, 1.0), h2);
			vec3 lamp = (st == 3 || st == 4 || st == 7) ? cool : warm;
			if (h2 > 0.93) { lamp = vec3(0.35, 0.55, 1.0); } // TV glow
			if (st == 6 && h2 < 0.2) { lamp = vec3(1.0, 0.35, 0.3); } // red lanterns
			// Curtains: a solid panel over part of some windows.
			float wx = (f.x - (sp - ww) * 0.5) / max(ww, 0.01);
			float curtain = step(0.6, h2) * step(wx, 0.35 + 0.3 * h);
			vec3 wcol = mix(glass, refl, 0.5);
			wcol = mix(wcol, vec3(0.12, 0.09, 0.07) * (0.6 + h2), curtain * 0.8);
			float wmask = clamp(win - mull, 0.0, 1.0) * detail;
			albedo = mix(albedo, wcol, wmask);
			hgt -= wmask * 0.03;
			emit += lamp * on * wmask * (0.5 + h2 * 0.45) * (1.0 - curtain * 0.5);
			rough = mix(rough, 0.15, wmask);
			spec = mix(spec, 0.6, wmask);
			// Far away: average the window light so towers still glitter.
			float far_lit = (1.0 - detail) * lit_ratio * night_amt * (ww * wh) / (sp * fh);
			emit += lamp * far_lit * 0.8;
			albedo = mix(albedo, mix(albedo, glass, (ww * wh) / (sp * fh)), 1.0 - detail);
			// Sills / floor bands.
			float band = step(abs(f.y - sill + 0.08), 0.06) * inx * detail;
			albedo = mix(albedo, albedo * 1.25, band);
		}
		// Storefront / lobby band.
		if (g > 0.0 && fuv.y < g) {
			float bay = 5.0;
			float bf = fract(fuv.x / bay) * bay;
			float bcell = floor(fuv.x / bay);
			float hb = hash(vec2(bcell, seed * 5.1));
			float pier = step(bf, 0.45) + step(bay - 0.45, bf);
			float glassy = (1.0 - clamp(pier, 0.0, 1.0)) * step(0.35, fuv.y) * step(fuv.y, g - 0.8);
			float closed = step(0.82, hb); // shuttered shops
			vec3 shop = mix(vec3(1.0, 0.8, 0.5), vec3(0.8, 0.9, 1.0), step(0.5, hb));
			if (st == 6) { shop = mix(vec3(1.0, 0.45, 0.3), vec3(1.0, 0.85, 0.4), hb); }
			vec3 shutter = vec3(0.18, 0.18, 0.19) * (0.8 + 0.2 * step(0.5, fract(fuv.y * 6.0)));
			vec3 inside = shop * 0.12 + vec3(0.02);
			vec3 sc = mix(inside, shutter, closed);
			albedo = mix(albedo, sc, glassy * detail);
			float shelf = step(0.5, fract(fuv.y * 1.6)) * 0.3;
			emit += shop * glassy * (1.0 - closed) * (0.05 + 0.5 * night_amt) * (1.0 - shelf) * detail;
			// Sign band just above the glass.
			float sband = step(g - 0.8, fuv.y) * step(fuv.y, g - 0.15);
			albedo = mix(albedo, albedo * 0.45, sband);
			rough = mix(rough, 0.2, glassy);
		}
		// Grime at the base.
		albedo *= mix(0.78, 1.0, clamp(fuv.y / 2.5, 0.0, 1.0));
		if (gfx_detail > 0.01) {
			// Weathering: rain streaks running down from sills, soot, patchy repairs.
			float macro = dt_fbm(vec3(fuv.x * 0.18, fuv.y * 0.12, seed * 3.0));
			float streak = dt_noise(vec3(fuv.x * 2.2, fuv.y * 0.09, seed * 7.0));
			float s2 = smoothstep(0.55, 0.85, streak) * detail;
			albedo *= mix(1.0, 0.82 + 0.36 * macro, 0.6 * gfx_detail);
			albedo *= 1.0 - s2 * 0.18 * gfx_detail;
			rough = mix(rough, rough - 0.1, s2 * wet_amt);
		}
	} else if (st == 0) {
		// Plain: roofs and trims get a little noise.
		float n = hash(floor(wpos.xz * 0.5));
		albedo *= 0.9 + n * 0.12;
	}
	// Rain: darker, glossier near the ground.
	albedo *= 1.0 - wet * 0.35;
	rough = mix(rough, 0.25, wet);
	// Night: sodium streetlight spill on the lower floors and city glow higher
	// up, so walls read as walls instead of black voids between the windows.
	float spill = (1.0 - smoothstep(0.0, 14.0, wpos.y)) * 0.6 + 0.17;
	emit += (albedo + vec3(0.006)) * vec3(1.0, 0.8, 0.6) * spill * night_amt;
	emit += (albedo + vec3(0.01)) * lamp_light(wpos, normalize(wnrm));
	float flr = step(0.8, wnrm.y) * (1.0 - step(0.8, wpos.y));
	emit += (albedo * 0.5 + vec3(0.006 + 0.07 * flr)) * vec3(0.78, 0.74, 0.9) * night_lift;
	emit += vec3(0.09) * flr * lamp_light(wpos, normalize(wnrm));
	if (gfx_detail > 0.6 && st > 0) {
		// Relief only up close; far away it would only shimmer.
		float near = 1.0 - smoothstep(12.0, 30.0, length(VERTEX));
		if (near > 0.0) {
			NORMAL = normalize(mix(NORMAL, dt_bump(NORMAL, VERTEX, hgt, 1.0), near));
		}
	}
	ALBEDO = albedo;
	ROUGHNESS = rough;
	SPECULAR = spec;
	EMISSION = emit;
}
