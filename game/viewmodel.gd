class_name Viewmodel
extends RefCounted
## First-person hands + weapon meshes, camera space (-Z forward).

static var _cache: Dictionary = {}


static func mesh_for(model: String, sleeve: Color) -> ArrayMesh:
	var key := model + sleeve.to_html(false)
	if _cache.has(key):
		return _cache[key]
	var b := MeshBatch.new()
	var skin := Color(0.93, 0.78, 0.68)
	var gun := Color(0.07, 0.07, 0.08)
	var steel := Color(0.35, 0.36, 0.38)
	var E := Vector2(0, 0.35) # slight self-glow so it reads at night
	match model:
		"fists":
			for s in [-1.0, 1.0]:
				b.box(Vector3(0.2 * s, -0.24, -0.42), Vector3(0.09, 0.09, 0.11), skin, 0.0, E)
				b.box(Vector3(0.21 * s, -0.27, -0.28), Vector3(0.1, 0.1, 0.24), sleeve, 0.0, E)
		"knife":
			b.box(Vector3(0.2, -0.24, -0.4), Vector3(0.08, 0.09, 0.1), skin, 0.0, E)
			b.box(Vector3(0.21, -0.27, -0.26), Vector3(0.1, 0.1, 0.24), sleeve, 0.0, E)
			b.box(Vector3(0.2, -0.2, -0.47), Vector3(0.025, 0.03, 0.08), Color(0.15, 0.1, 0.08), 0.0, E)
			b.box(Vector3(0.2, -0.2, -0.56), Vector3(0.01, 0.025, 0.12), steel, 0.0, E)
		"knuckles":
			for s in [-1.0, 1.0]:
				b.box(Vector3(0.2 * s, -0.24, -0.42), Vector3(0.09, 0.09, 0.11), skin, 0.0, E)
				b.box(Vector3(0.21 * s, -0.27, -0.28), Vector3(0.1, 0.1, 0.24), sleeve, 0.0, E)
			b.box(Vector3(0.2, -0.215, -0.475), Vector3(0.1, 0.035, 0.03), Color(0.75, 0.62, 0.3), 0.0, Vector2(0, 0.6))
		"machete", "katana":
			b.box(Vector3(0.2, -0.24, -0.4), Vector3(0.08, 0.09, 0.1), skin, 0.0, E)
			b.box(Vector3(0.21, -0.27, -0.26), Vector3(0.1, 0.1, 0.24), sleeve, 0.0, E)
			var L := 0.42 if model == "machete" else 0.62
			b.box(Vector3(0.2, -0.2, -0.45), Vector3(0.03, 0.035, 0.1), Color(0.12, 0.08, 0.06) if model == "machete" else Color(0.1, 0.05, 0.05), 0.0, E)
			if model == "katana":
				b.box(Vector3(0.2, -0.2, -0.505), Vector3(0.06, 0.05, 0.015), Color(0.7, 0.6, 0.3), 0.0, E)
			b.box_xf(Transform3D(Basis(Vector3.RIGHT, 0.25), Vector3(0.2, -0.15, -0.52 - L * 0.5)), Vector3(0.01, 0.045 if model == "machete" else 0.03, L), Color(0.75, 0.76, 0.78), Vector2(0, 0.6))
		"pipe", "bat", "baton", "axe", "sledge":
			var col := Color(0.4, 0.28, 0.16) if model in ["bat", "axe", "sledge"] else steel
			if model == "baton":
				col = Color(0.08, 0.08, 0.09)
			var r := 0.03 if model == "bat" else 0.018
			b.box(Vector3(0.2, -0.26, -0.4), Vector3(0.08, 0.09, 0.1), skin, 0.0, E)
			b.box(Vector3(0.21, -0.29, -0.26), Vector3(0.1, 0.1, 0.24), sleeve, 0.0, E)
			var shaft := Transform3D(Basis(Vector3.RIGHT, 1.1), Vector3(0.2, -0.05, -0.55))
			b.box_xf(shaft, Vector3(r * 2.0, 0.62, r * 2.0), col, E)
			if model == "axe":
				b.box_xf(shaft * Transform3D(Basis.IDENTITY, Vector3(0.0, 0.28, 0.06)), Vector3(0.02, 0.14, 0.16), Color(0.7, 0.1, 0.08), E)
			elif model == "sledge":
				b.box_xf(shaft * Transform3D(Basis.IDENTITY, Vector3(0.0, 0.3, 0.0)), Vector3(0.08, 0.08, 0.22), Color(0.25, 0.26, 0.28), E)
		"pistol", "pistol_sil", "revolver", "taser", "pistol45", "magnum":
			var body := gun
			if model == "taser":
				body = Color(0.8, 0.7, 0.1)
			elif model == "magnum":
				body = Color(0.55, 0.56, 0.6)
			elif model == "pistol45":
				body = Color(0.12, 0.11, 0.1)
			b.box(Vector3(0.16, -0.22, -0.38), Vector3(0.08, 0.09, 0.1), skin, 0.0, E)
			b.box(Vector3(0.18, -0.26, -0.24), Vector3(0.1, 0.1, 0.24), sleeve, 0.0, E)
			b.box(Vector3(0.16, -0.2, -0.36), Vector3(0.035, 0.1, 0.05), body, 0.0, E)
			b.box(Vector3(0.16, -0.155, -0.43), Vector3(0.04, 0.045, 0.2), body, 0.0, E)
			if model == "revolver" or model == "magnum":
				b.cyl(Vector3(0.16, -0.155, -0.41), 0.035 if model == "magnum" else 0.03, 0.03, 0.05, steel, 6, E)
				b.box(Vector3(0.16, -0.15, -0.54 if model == "magnum" else -0.52), Vector3(0.026, 0.026, 0.18 if model == "magnum" else 0.12), steel, 0.0, E)
			elif model == "pistol45":
				b.box(Vector3(0.16, -0.155, -0.45), Vector3(0.046, 0.05, 0.24), body, 0.0, E)
			elif model == "pistol_sil":
				b.box(Vector3(0.16, -0.155, -0.6), Vector3(0.03, 0.03, 0.16), Color(0.15, 0.15, 0.15), 0.0, E)
			# Left hand supporting.
			b.box(Vector3(0.11, -0.25, -0.36), Vector3(0.08, 0.08, 0.09), skin, 0.0, E)
			b.box(Vector3(0.02, -0.3, -0.24), Vector3(0.1, 0.1, 0.24), sleeve, 0.0, E)
		"smg", "shotgun", "rifle", "carbine", "smg_sil", "sawed", "ar", "sniper":
			var L := {"smg": 0.36, "shotgun": 0.7, "rifle": 0.8, "carbine": 0.6, "smg_sil": 0.36, "sawed": 0.36, "ar": 0.66, "sniper": 0.95}[model] as float
			var stock := Color(0.35, 0.22, 0.12) if model in ["shotgun", "rifle", "sawed"] else gun
			if model == "smg_sil":
				b.box(Vector3(0.14, -0.2, -0.28 - L - 0.1), Vector3(0.04, 0.04, 0.2), Color(0.15, 0.15, 0.15), 0.0, E)
			elif model == "sawed":
				b.box(Vector3(0.155, -0.2, -0.28 - L * 0.5), Vector3(0.03, 0.035, L), gun, 0.0, E)
			elif model == "ar" or model == "sniper":
				b.box(Vector3(0.14, -0.135, -0.36), Vector3(0.03, 0.04, 0.22 if model == "sniper" else 0.1), Color(0.05, 0.05, 0.05), 0.0, E)
				if model == "ar":
					b.box(Vector3(0.14, -0.29, -0.42), Vector3(0.035, 0.14, 0.06), gun, 0.0, E)
			b.box(Vector3(0.14, -0.2, -0.28 - L * 0.5), Vector3(0.05, 0.07, L), gun, 0.0, E)
			b.box(Vector3(0.14, -0.23, -0.2), Vector3(0.06, 0.08, 0.26), stock, 0.0, E)
			if model == "rifle":
				b.cyl(Vector3(0.14, -0.14, -0.4), 0.025, 0.025, 0.02, gun, 6, E)
				b.box(Vector3(0.14, -0.145, -0.4), Vector3(0.035, 0.035, 0.2), gun, 0.0, E)
			if model in ["smg", "carbine", "smg_sil"]:
				b.box(Vector3(0.14, -0.28, -0.4), Vector3(0.035, 0.12, 0.05), gun, 0.0, E)
			b.box(Vector3(0.16, -0.26, -0.24), Vector3(0.08, 0.09, 0.1), skin, 0.0, E)
			b.box(Vector3(0.18, -0.3, -0.12), Vector3(0.1, 0.1, 0.2), sleeve, 0.0, E)
			b.box(Vector3(0.1, -0.24, -0.28 - L * 0.6), Vector3(0.08, 0.08, 0.1), skin, 0.0, E)
			b.box(Vector3(0.02, -0.3, -0.3 - L * 0.4), Vector3(0.1, 0.1, 0.3), sleeve, 0.0, E)
	var m := b.to_mesh()
	_cache[key] = m
	return m


## Muzzle position in camera space for flash effects.
static func muzzle(model: String) -> Vector3:
	match model:
		"pistol", "revolver", "taser", "pistol45":
			return Vector3(0.16, -0.155, -0.56)
		"magnum":
			return Vector3(0.16, -0.15, -0.64)
		"smg_sil":
			return Vector3(0.14, -0.2, -0.86)
		"sawed":
			return Vector3(0.14, -0.2, -0.66)
		"ar":
			return Vector3(0.14, -0.2, -0.96)
		"sniper":
			return Vector3(0.14, -0.2, -1.25)
		"pistol_sil":
			return Vector3(0.16, -0.155, -0.7)
		"smg":
			return Vector3(0.14, -0.2, -0.66)
		"shotgun":
			return Vector3(0.14, -0.2, -1.0)
		"rifle":
			return Vector3(0.14, -0.2, -1.1)
		"carbine":
			return Vector3(0.14, -0.2, -0.9)
	return Vector3(0.2, -0.2, -0.5)
