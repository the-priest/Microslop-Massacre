class_name PersonMesh
extends RefCounted
## Builds low-poly people as ONE mesh per look. Limbs carry (limb id, pivot)
## in UV2 so npc.gdshader animates walking/aiming/talking on the GPU.
## Model faces -Z, feet at y = 0.

static var _cache: Dictionary = {}

const SKINS := [Color(0.93, 0.76, 0.64), Color(0.85, 0.66, 0.52), Color(0.72, 0.52, 0.38), Color(0.55, 0.38, 0.26), Color(0.4, 0.27, 0.18), Color(0.96, 0.82, 0.72)]
const HAIRS := [Color(0.08, 0.06, 0.05), Color(0.25, 0.16, 0.1), Color(0.45, 0.32, 0.18), Color(0.75, 0.6, 0.35), Color(0.55, 0.55, 0.55), Color(0.15, 0.1, 0.08), Color(0.5, 0.2, 0.1)]
const TOPS := [Color(0.1, 0.1, 0.12), Color(0.35, 0.1, 0.1), Color(0.15, 0.25, 0.4), Color(0.6, 0.6, 0.62), Color(0.2, 0.3, 0.2), Color(0.5, 0.4, 0.25), Color(0.7, 0.35, 0.15), Color(0.3, 0.25, 0.35), Color(0.85, 0.85, 0.82)]
const BOTTOMS := [Color(0.12, 0.14, 0.2), Color(0.1, 0.1, 0.1), Color(0.3, 0.28, 0.24), Color(0.2, 0.22, 0.25), Color(0.35, 0.3, 0.25)]


static func random_look(rng: RandomNumberGenerator) -> Dictionary:
	var female := rng.randf() < 0.5
	var styles := ["tshirt", "jacket", "hoodie", "coat", "shirt"]
	return {
		"female": female,
		"skin": SKINS[rng.randi() % SKINS.size()],
		"hair": HAIRS[rng.randi() % HAIRS.size()],
		"hair_style": (["long", "bun", "bob", "short"] if female else ["short", "short", "bald", "cap", "buzz"])[rng.randi() % (4 if female else 5)],
		"top": TOPS[rng.randi() % TOPS.size()],
		"top_style": styles[rng.randi() % styles.size()],
		"bottom": BOTTOMS[rng.randi() % BOTTOMS.size()],
		"shoes": [Color(0.08, 0.08, 0.08), Color(0.3, 0.2, 0.12), Color(0.85, 0.85, 0.85)][rng.randi() % 3],
		"height": rng.randf_range(0.92, 1.06) * (0.95 if female else 1.0),
		"build": rng.randf_range(0.9, 1.2),
		"glasses": rng.randf() < 0.15,
		"bag": rng.randf() < 0.2,
	}


static func key_of(look: Dictionary) -> String:
	var parts: PackedStringArray = []
	var keys := look.keys()
	keys.sort()
	for k in keys:
		var v: Variant = look[k]
		if v is Color:
			parts.append("%s=%s" % [k, (v as Color).to_html(false)])
		elif v is float:
			parts.append("%s=%.2f" % [k, v])
		else:
			parts.append("%s=%s" % [k, str(v)])
	return "|".join(parts)


static func mesh(look: Dictionary) -> ArrayMesh:
	var key := key_of(look)
	if _cache.has(key):
		return _cache[key]
	var b := MeshBatch.new()
	_build(b, look)
	var m := b.to_mesh()
	_cache[key] = m
	return m


static func _part(b: MeshBatch, c: Vector3, s: Vector3, col: Color, limb: int, pivot: float) -> void:
	b.box(c, s, col, 0.0, Vector2(limb, pivot), 63)


static func _build(b: MeshBatch, L: Dictionary) -> void:
	var h: float = float(L.get("height", 1.0))
	var w: float = float(L.get("build", 1.0))
	var female: bool = bool(L.get("female", false))
	var skin: Color = L.get("skin", SKINS[0])
	var hair: Color = L.get("hair", HAIRS[0])
	var top: Color = L.get("top", TOPS[0])
	var bottom: Color = L.get("bottom", BOTTOMS[0])
	var shoes: Color = L.get("shoes", Color(0.08, 0.08, 0.08))
	var style: String = str(L.get("top_style", "tshirt"))
	var hs: String = str(L.get("hair_style", "short"))
	var leg_h := 0.86 * h
	var hip_y := leg_h
	# Legs (limb 1 left, 2 right). Skirts use top color on the upper leg.
	for side in [-1, 1]:
		var limb := 1 if side < 0 else 2
		var lx := 0.1 * float(side) * w
		_part(b, Vector3(lx, leg_h * 0.5, 0), Vector3(0.15 * w, leg_h, 0.17), bottom, limb, hip_y)
		_part(b, Vector3(lx, 0.05, -0.04), Vector3(0.16 * w, 0.1, 0.27), shoes, limb, hip_y)
	if bool(L.get("skirt", false)):
		_part(b, Vector3(0, hip_y - 0.18, 0), Vector3(0.38 * w, 0.4, 0.24), L.get("skirt_col", bottom), 0, 0)
	# Hips + torso.
	var torso_h := 0.56 * h
	var ty := hip_y + 0.07 + torso_h * 0.5
	_part(b, Vector3(0, hip_y + 0.04, 0), Vector3(0.34 * w, 0.14, 0.2), bottom, 0, 0)
	var tw := (0.36 if female else 0.42) * w
	_part(b, Vector3(0, ty, 0), Vector3(tw, torso_h, 0.22 * w), top, 0, 0)
	match style:
		"suit":
			var shirt: Color = L.get("shirt", Color(0.9, 0.9, 0.9))
			_part(b, Vector3(0, ty + 0.1, -0.112 * w), Vector3(0.12, torso_h * 0.6, 0.01), shirt, 0, 0)
			_part(b, Vector3(0, ty + 0.05, -0.118 * w), Vector3(0.05, torso_h * 0.55, 0.01), L.get("tie", Color(0.5, 0.05, 0.05)), 0, 0)
		"hoodie":
			_part(b, Vector3(0, ty + torso_h * 0.5 + 0.02, 0.08), Vector3(0.3 * w, 0.12, 0.12), top.darkened(0.1), 0, 0)
			_part(b, Vector3(0, ty - 0.1, -0.115 * w), Vector3(0.24 * w, 0.14, 0.02), top.darkened(0.15), 0, 0)
		"jacket", "coat":
			_part(b, Vector3(0, ty, -0.113 * w), Vector3(0.1, torso_h * 0.95, 0.01), L.get("shirt", top.lightened(0.3)), 0, 0)
			if style == "coat":
				_part(b, Vector3(0, hip_y - 0.12, 0), Vector3(tw + 0.02, 0.3, 0.23 * w), top, 0, 0)
		"uniform":
			_part(b, Vector3(-0.09 * w, ty + 0.12, -0.113 * w), Vector3(0.08, 0.06, 0.01), Color(0.85, 0.75, 0.3), 0, 0)
			_part(b, Vector3(0, hip_y + 0.1, 0), Vector3(tw + 0.01, 0.06, 0.23 * w), Color(0.06, 0.06, 0.06), 0, 0)
		"vest":
			_part(b, Vector3(0, ty, 0), Vector3(tw + 0.04, torso_h * 0.8, 0.26 * w), Color(0.15, 0.17, 0.12), 0, 0)
	if bool(L.get("chain", false)):
		_part(b, Vector3(0, ty + torso_h * 0.35, -0.114 * w), Vector3(0.14, 0.03, 0.01), Color(0.9, 0.75, 0.2), 0, 0)
	if bool(L.get("badge", false)):
		_part(b, Vector3(0.1 * w, ty + 0.12, -0.114 * w), Vector3(0.06, 0.08, 0.01), Color(0.9, 0.8, 0.3), 0, 0)
	if bool(L.get("bag", false)):
		_part(b, Vector3(0, ty, 0.16 * w), Vector3(0.26 * w, 0.34, 0.12), Color(0.15, 0.13, 0.12), 0, 0)
	# Arms (limb 3 left, 4 right), pivot at the shoulder.
	var sh_y := hip_y + 0.07 + torso_h - 0.04
	var arm_l := 0.58 * h
	var sleeve: Color = top if style != "tshirt" else skin
	for side in [-1, 1]:
		var limb := 3 if side < 0 else 4
		var ax := (tw * 0.5 + 0.065) * float(side)
		if style == "tshirt":
			_part(b, Vector3(ax, sh_y - 0.1, 0), Vector3(0.13, 0.2, 0.14), top, limb, sh_y)
			_part(b, Vector3(ax, sh_y - 0.2 - (arm_l - 0.2) * 0.5, 0), Vector3(0.1, arm_l - 0.2, 0.11), skin, limb, sh_y)
		else:
			_part(b, Vector3(ax, sh_y - arm_l * 0.5, 0), Vector3(0.12, arm_l, 0.13), sleeve, limb, sh_y)
		_part(b, Vector3(ax, sh_y - arm_l - 0.05, 0), Vector3(0.09, 0.1, 0.1), skin, limb, sh_y)
		if side > 0 and bool(L.get("gun", false)):
			_part(b, Vector3(ax, sh_y - arm_l - 0.06, -0.1), Vector3(0.05, 0.1, 0.24), Color(0.05, 0.05, 0.05), limb, sh_y)
		elif side > 0 and bool(L.get("club", false)):
			_part(b, Vector3(ax, sh_y - arm_l - 0.05, -0.3), Vector3(0.05, 0.05, 0.6), Color(0.35, 0.25, 0.15), limb, sh_y)
	# Neck + head (limb 5).
	var neck_y := sh_y + 0.06
	_part(b, Vector3(0, neck_y, 0), Vector3(0.1, 0.1, 0.1), skin, 5, neck_y)
	var head_s := 0.23
	var hy := neck_y + 0.05 + head_s * 0.55
	_part(b, Vector3(0, hy, 0), Vector3(head_s * 0.92, head_s * 1.1, head_s), skin, 5, neck_y)
	# Face.
	var fz := -head_s * 0.5 - 0.004
	_part(b, Vector3(-0.045, hy + 0.02, fz), Vector3(0.035, 0.022, 0.01), Color(0.05, 0.05, 0.05), 5, neck_y)
	_part(b, Vector3(0.045, hy + 0.02, fz), Vector3(0.035, 0.022, 0.01), Color(0.05, 0.05, 0.05), 5, neck_y)
	_part(b, Vector3(0, hy - 0.07, fz), Vector3(0.06, 0.015, 0.01), skin.darkened(0.35), 5, neck_y)
	if bool(L.get("beard", false)):
		_part(b, Vector3(0, hy - 0.07, fz + 0.03), Vector3(head_s * 0.85, 0.09, 0.06), hair, 5, neck_y)
	if bool(L.get("glasses", false)):
		_part(b, Vector3(0, hy + 0.02, fz - 0.006), Vector3(0.17, 0.045, 0.01), Color(0.05, 0.05, 0.06), 5, neck_y)
	if bool(L.get("mask", false)):
		_part(b, Vector3(0, hy, fz - 0.008), Vector3(head_s * 0.95, head_s * 1.05, 0.02), Color(0.92, 0.9, 0.85), 5, neck_y)
		_part(b, Vector3(0, hy - 0.03, fz - 0.02), Vector3(0.1, 0.012, 0.01), Color(0.1, 0.1, 0.1), 5, neck_y)
		_part(b, Vector3(0, hy - 0.06, fz - 0.02), Vector3(0.05, 0.05, 0.01), Color(0.1, 0.1, 0.1), 5, neck_y)
	# Hair.
	var top_y := hy + head_s * 0.55
	match hs:
		"short":
			_part(b, Vector3(0, top_y, 0.01), Vector3(head_s * 0.98, 0.06, head_s * 1.02), hair, 5, neck_y)
			_part(b, Vector3(0, hy + 0.04, head_s * 0.5), Vector3(head_s * 0.95, head_s * 0.7, 0.03), hair, 5, neck_y)
		"buzz":
			_part(b, Vector3(0, top_y - 0.01, 0.01), Vector3(head_s * 0.96, 0.03, head_s), hair, 5, neck_y)
		"bald":
			_part(b, Vector3(0, hy + 0.01, head_s * 0.5), Vector3(head_s * 0.95, head_s * 0.35, 0.02), hair, 5, neck_y)
		"long":
			_part(b, Vector3(0, top_y, 0.01), Vector3(head_s, 0.06, head_s * 1.04), hair, 5, neck_y)
			_part(b, Vector3(0, hy - 0.05, head_s * 0.45), Vector3(head_s * 1.05, head_s * 1.5, 0.08), hair, 5, neck_y)
			_part(b, Vector3(-head_s * 0.5, hy - 0.02, 0), Vector3(0.03, head_s * 1.1, head_s * 0.9), hair, 5, neck_y)
			_part(b, Vector3(head_s * 0.5, hy - 0.02, 0), Vector3(0.03, head_s * 1.1, head_s * 0.9), hair, 5, neck_y)
		"bob":
			_part(b, Vector3(0, top_y, 0.01), Vector3(head_s * 1.02, 0.07, head_s * 1.04), hair, 5, neck_y)
			_part(b, Vector3(0, hy, head_s * 0.46), Vector3(head_s * 1.06, head_s * 0.95, 0.06), hair, 5, neck_y)
			_part(b, Vector3(-head_s * 0.51, hy + 0.01, 0), Vector3(0.04, head_s * 0.9, head_s * 0.95), hair, 5, neck_y)
			_part(b, Vector3(head_s * 0.51, hy + 0.01, 0), Vector3(0.04, head_s * 0.9, head_s * 0.95), hair, 5, neck_y)
			_part(b, Vector3(0, top_y - 0.05, fz - 0.005), Vector3(head_s * 0.9, 0.05, 0.02), hair, 5, neck_y)
		"bun":
			_part(b, Vector3(0, top_y, 0.01), Vector3(head_s * 0.98, 0.06, head_s * 1.02), hair, 5, neck_y)
			_part(b, Vector3(0, top_y + 0.03, head_s * 0.45), Vector3(0.1, 0.1, 0.1), hair, 5, neck_y)
			_part(b, Vector3(0, hy + 0.04, head_s * 0.5), Vector3(head_s * 0.95, head_s * 0.7, 0.03), hair, 5, neck_y)
		"slick":
			_part(b, Vector3(0, top_y + 0.01, 0.02), Vector3(head_s * 0.98, 0.07, head_s * 1.06), hair, 5, neck_y)
			_part(b, Vector3(0, hy + 0.05, head_s * 0.5), Vector3(head_s * 0.95, head_s * 0.6, 0.03), hair, 5, neck_y)
		"cap":
			var cap_c: Color = L.get("cap_col", Color(0.15, 0.2, 0.35))
			_part(b, Vector3(0, top_y + 0.01, 0.0), Vector3(head_s * 1.02, 0.08, head_s * 1.04), cap_c, 5, neck_y)
			_part(b, Vector3(0, top_y - 0.02, -head_s * 0.62), Vector3(head_s * 0.9, 0.02, 0.12), cap_c, 5, neck_y)
		"hood":
			_part(b, Vector3(0, top_y + 0.01, 0.02), Vector3(head_s * 1.15, 0.09, head_s * 1.15), top, 5, neck_y)
			_part(b, Vector3(-head_s * 0.56, hy, 0.02), Vector3(0.05, head_s * 1.15, head_s * 1.1), top, 5, neck_y)
			_part(b, Vector3(head_s * 0.56, hy, 0.02), Vector3(0.05, head_s * 1.15, head_s * 1.1), top, 5, neck_y)
			_part(b, Vector3(0, hy, head_s * 0.56), Vector3(head_s * 1.15, head_s * 1.15, 0.05), top, 5, neck_y)
	if bool(L.get("hat_beanie", false)):
		_part(b, Vector3(0, top_y + 0.01, 0.01), Vector3(head_s * 1.04, 0.1, head_s * 1.06), Color(0.1, 0.1, 0.1), 5, neck_y)


## Named looks for story characters.
static func preset(id: String) -> Dictionary:
	match id:
		"mr_robot":
			return {"skin": Color(0.88, 0.7, 0.58), "hair": Color(0.45, 0.42, 0.4), "hair_style": "buzz", "top": Color(0.28, 0.3, 0.2), "top_style": "jacket", "shirt": Color(0.2, 0.2, 0.2), "bottom": Color(0.12, 0.12, 0.14), "height": 1.02, "build": 1.1, "glasses": true, "beard": false}
		"darlene":
			return {"female": true, "skin": Color(0.95, 0.8, 0.7), "hair": Color(0.08, 0.06, 0.05), "hair_style": "bob", "top": Color(0.1, 0.1, 0.1), "top_style": "jacket", "shirt": Color(0.6, 0.1, 0.15), "bottom": Color(0.08, 0.08, 0.1), "height": 0.95, "build": 0.9}
		"angela":
			return {"female": true, "skin": Color(0.96, 0.82, 0.72), "hair": Color(0.82, 0.68, 0.42), "hair_style": "long", "top": Color(0.85, 0.88, 0.92), "top_style": "shirt", "bottom": Color(0.12, 0.13, 0.18), "skirt": true, "skirt_col": Color(0.15, 0.15, 0.2), "height": 0.96, "build": 0.9}
		"tyrell":
			return {"skin": Color(0.95, 0.82, 0.72), "hair": Color(0.8, 0.68, 0.45), "hair_style": "slick", "top": Color(0.08, 0.1, 0.16), "top_style": "suit", "tie": Color(0.1, 0.12, 0.25), "bottom": Color(0.08, 0.1, 0.16), "height": 1.07, "build": 1.0}
		"whiterose":
			return {"skin": Color(0.9, 0.78, 0.62), "hair": Color(0.06, 0.05, 0.05), "hair_style": "bob", "top": Color(0.3, 0.05, 0.08), "top_style": "suit", "tie": Color(0.8, 0.65, 0.2), "bottom": Color(0.1, 0.05, 0.06), "height": 0.9, "build": 0.9, "glasses": true}
		"krista":
			return {"female": true, "skin": Color(0.93, 0.78, 0.66), "hair": Color(0.3, 0.2, 0.12), "hair_style": "bun", "top": Color(0.65, 0.55, 0.42), "top_style": "coat", "bottom": Color(0.2, 0.18, 0.16), "height": 0.97, "build": 0.95}
		"shayla":
			return {"female": true, "skin": Color(0.8, 0.6, 0.46), "hair": Color(0.1, 0.07, 0.05), "hair_style": "long", "top": Color(0.2, 0.6, 0.6), "top_style": "tshirt", "bottom": Color(0.15, 0.15, 0.2), "height": 0.95, "build": 0.9}
		"vera":
			return {"skin": Color(0.75, 0.55, 0.4), "hair": Color(0.05, 0.04, 0.04), "hair_style": "buzz", "top": Color(0.88, 0.88, 0.85), "top_style": "tshirt", "bottom": Color(0.1, 0.12, 0.2), "chain": true, "height": 1.0, "build": 1.1, "beard": true}
		"gideon":
			return {"skin": Color(0.92, 0.76, 0.64), "hair": Color(0.3, 0.2, 0.12), "hair_style": "short", "top": Color(0.4, 0.45, 0.55), "top_style": "shirt", "bottom": Color(0.25, 0.25, 0.28), "height": 1.0, "build": 0.95, "glasses": false}
		"dipierro":
			return {"female": true, "skin": Color(0.94, 0.8, 0.7), "hair": Color(0.15, 0.1, 0.08), "hair_style": "bun", "top": Color(0.08, 0.1, 0.2), "top_style": "jacket", "shirt": Color(0.8, 0.8, 0.8), "bottom": Color(0.1, 0.1, 0.12), "badge": true, "height": 0.97, "build": 0.95}
		"leon":
			return {"skin": Color(0.42, 0.28, 0.2), "hair": Color(0.05, 0.04, 0.04), "hair_style": "cap", "cap_col": Color(0.2, 0.3, 0.2), "top": Color(0.4, 0.3, 0.2), "top_style": "jacket", "bottom": Color(0.2, 0.2, 0.22), "height": 1.03, "build": 1.1}
		"mobley":
			return {"skin": Color(0.5, 0.34, 0.24), "hair": Color(0.05, 0.04, 0.04), "hair_style": "buzz", "top": Color(0.5, 0.2, 0.15), "top_style": "tshirt", "bottom": Color(0.2, 0.22, 0.3), "glasses": true, "height": 0.98, "build": 1.2}
		"romero":
			return {"skin": Color(0.78, 0.6, 0.45), "hair": Color(0.4, 0.4, 0.4), "hair_style": "bald", "top": Color(0.3, 0.3, 0.3), "top_style": "hoodie", "bottom": Color(0.2, 0.2, 0.2), "beard": true, "height": 1.0, "build": 1.25}
		"trenton":
			return {"female": true, "skin": Color(0.78, 0.6, 0.46), "hair": Color(0.1, 0.07, 0.05), "hair_style": "long", "top": Color(0.2, 0.2, 0.25), "top_style": "hoodie", "bottom": Color(0.1, 0.1, 0.12), "height": 0.95, "build": 0.9, "hat_beanie": true}
		"cisco":
			return {"skin": Color(0.8, 0.62, 0.46), "hair": Color(0.05, 0.04, 0.04), "hair_style": "short", "top": Color(0.15, 0.15, 0.15), "top_style": "jacket", "bottom": Color(0.1, 0.1, 0.1), "height": 1.0, "build": 1.0, "beard": true}
		"ron":
			return {"skin": Color(0.9, 0.74, 0.62), "hair": Color(0.5, 0.45, 0.4), "hair_style": "bald", "top": Color(0.35, 0.25, 0.18), "top_style": "shirt", "bottom": Color(0.2, 0.2, 0.2), "height": 0.98, "build": 1.2, "glasses": true}
		"ollie":
			return {"skin": Color(0.93, 0.78, 0.66), "hair": Color(0.35, 0.25, 0.15), "hair_style": "short", "top": Color(0.3, 0.4, 0.55), "top_style": "shirt", "bottom": Color(0.2, 0.2, 0.25), "height": 1.0, "build": 1.0}
		"lenny":
			return {"skin": Color(0.92, 0.76, 0.64), "hair": Color(0.3, 0.22, 0.14), "hair_style": "short", "top": Color(0.5, 0.15, 0.12), "top_style": "jacket", "bottom": Color(0.2, 0.2, 0.25), "height": 1.02, "build": 1.1, "beard": true}
		"price":
			return {"skin": Color(0.93, 0.78, 0.68), "hair": Color(0.75, 0.75, 0.75), "hair_style": "slick", "top": Color(0.05, 0.05, 0.06), "top_style": "suit", "tie": Color(0.35, 0.05, 0.1), "bottom": Color(0.05, 0.05, 0.06), "height": 1.02, "build": 1.0}
		"colby":
			return {"skin": Color(0.95, 0.8, 0.7), "hair": Color(0.7, 0.68, 0.65), "hair_style": "bald", "top": Color(0.2, 0.2, 0.25), "top_style": "suit", "bottom": Color(0.2, 0.2, 0.25), "height": 0.98, "build": 1.15}
		"joanna":
			return {"female": true, "skin": Color(0.96, 0.84, 0.74), "hair": Color(0.85, 0.75, 0.55), "hair_style": "bun", "top": Color(0.9, 0.9, 0.9), "top_style": "coat", "bottom": Color(0.9, 0.9, 0.9), "height": 1.0, "build": 0.9}
		"harper":
			return {"skin": Color(0.9, 0.74, 0.62), "hair": Color(0.4, 0.3, 0.2), "hair_style": "short", "top": Color(0.45, 0.5, 0.6), "top_style": "shirt", "bottom": Color(0.3, 0.3, 0.3), "height": 1.0, "build": 1.1, "glasses": true}
		"guard_ecorp":
			return {"skin": SKINS[1], "hair": HAIRS[0], "hair_style": "buzz", "top": Color(0.2, 0.22, 0.3), "top_style": "uniform", "bottom": Color(0.1, 0.1, 0.12), "height": 1.02, "build": 1.15, "gun": true}
		"cop":
			return {"skin": SKINS[2], "hair": HAIRS[1], "hair_style": "cap", "cap_col": Color(0.05, 0.08, 0.2), "top": Color(0.08, 0.1, 0.25), "top_style": "uniform", "bottom": Color(0.06, 0.07, 0.15), "badge": true, "height": 1.02, "build": 1.1, "gun": true}
		"fbi":
			return {"skin": SKINS[0], "hair": HAIRS[1], "hair_style": "short", "top": Color(0.06, 0.08, 0.15), "top_style": "jacket", "shirt": Color(0.9, 0.9, 0.9), "bottom": Color(0.1, 0.1, 0.12), "badge": true, "gun": true, "height": 1.02, "build": 1.05}
		"darkarmy":
			return {"skin": SKINS[1], "hair": HAIRS[0], "hair_style": "short", "top": Color(0.04, 0.04, 0.05), "top_style": "jacket", "shirt": Color(0.1, 0.1, 0.1), "bottom": Color(0.04, 0.04, 0.05), "gun": true, "height": 1.0, "build": 1.05}
		"thug":
			return {"skin": SKINS[3], "hair": HAIRS[0], "hair_style": "hood", "top": Color(0.15, 0.15, 0.17), "top_style": "hoodie", "bottom": Color(0.2, 0.22, 0.3), "height": 1.0, "build": 1.1, "club": true}
		"thug_gun":
			return {"skin": SKINS[4], "hair": HAIRS[0], "hair_style": "buzz", "top": Color(0.35, 0.1, 0.1), "top_style": "jacket", "bottom": Color(0.1, 0.1, 0.12), "chain": true, "height": 1.0, "build": 1.15, "gun": true}
		"steel_guard":
			return {"skin": SKINS[0], "hair": HAIRS[2], "hair_style": "short", "top": Color(0.3, 0.32, 0.35), "top_style": "uniform", "bottom": Color(0.15, 0.15, 0.17), "gun": true, "height": 1.0, "build": 1.1}
		"elliot":
			return {"skin": Color(0.93, 0.78, 0.68), "hair": Color(0.1, 0.07, 0.06), "hair_style": "hood", "top": Color(0.08, 0.08, 0.09), "top_style": "hoodie", "bottom": Color(0.1, 0.12, 0.18), "height": 0.98, "build": 0.9}
	return {}
