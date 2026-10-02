class_name Props
extends RefCounted
## Props — procedural low-poly street furniture, vehicles and structures.
## Repeated props are built once as prototypes and merged with a transform.

const LAMP_COL := Color(1.0, 0.78, 0.48)
const K_ALWAYS := 0.0
const K_NIGHT := 1.0
const K_TRAFFIC := 2.0
const K_FLICKER := 3.0
const K_BLINK := 4.0

static var _protos: Dictionary = {}

const CAR_COLORS := [
	Color(0.08, 0.08, 0.09), Color(0.6, 0.6, 0.62), Color(0.35, 0.05, 0.06), Color(0.1, 0.16, 0.3),
	Color(0.82, 0.82, 0.8), Color(0.2, 0.22, 0.2), Color(0.3, 0.26, 0.2), Color(0.45, 0.47, 0.5),
]


static func proto(name: String) -> Dictionary:
	if _protos.has(name):
		return _protos[name]
	var lit := MeshBatch.new()
	var glow := MeshBatch.new()
	_build_proto(name, lit, glow)
	var p := {"lit": lit, "glow": glow}
	_protos[name] = p
	return p


static func place(ctx: BuildCtx, name: String, pos: Vector3, rot_y: float = 0.0, scale: float = 1.0) -> void:
	var p := proto(name)
	var xf := Transform3D(Basis(Vector3.UP, rot_y).scaled(Vector3.ONE * scale), pos)
	if not (p["lit"] as MeshBatch).is_empty():
		ctx.props.merge(p["lit"], xf)
	if not (p["glow"] as MeshBatch).is_empty():
		ctx.glow.merge(p["glow"], xf)


static func _build_proto(name: String, b: MeshBatch, g: MeshBatch) -> void:
	var dark := Color(0.1, 0.1, 0.11)
	match name:
		"lamp":
			b.box(Vector3(0, 3.1, 0), Vector3(0.16, 6.2, 0.16), Color(0.14, 0.15, 0.16))
			b.box(Vector3(0, 0.25, 0), Vector3(0.34, 0.5, 0.34), Color(0.12, 0.12, 0.13))
			b.box(Vector3(0, 6.15, 0.8), Vector3(0.1, 0.1, 1.7), Color(0.14, 0.15, 0.16))
			b.box(Vector3(0, 6.1, 1.6), Vector3(0.5, 0.18, 0.7), Color(0.12, 0.12, 0.13))
			g.box(Vector3(0, 5.98, 1.6), Vector3(0.4, 0.06, 0.55), LAMP_COL, 0.0, Vector2(K_NIGHT, 0))
		"park_lamp":
			b.box(Vector3(0, 1.9, 0), Vector3(0.12, 3.8, 0.12), Color(0.08, 0.1, 0.09))
			g.sphere(Vector3(0, 4.0, 0), 0.28, Color(1.0, 0.9, 0.7), 6, 4, Vector2(K_NIGHT, 0))
		"tree_a", "tree_b", "tree_c":
			var cc: Color = {"tree_a": Color(0.12, 0.24, 0.1), "tree_b": Color(0.16, 0.28, 0.12), "tree_c": Color(0.2, 0.22, 0.1)}[name]
			b.box(Vector3(0, 1.4, 0), Vector3(0.28, 2.8, 0.28), Color(0.2, 0.14, 0.09))
			b.sphere(Vector3(0, 3.6, 0), 1.7, cc, 7, 4, Vector2.ZERO, 0.85)
			b.sphere(Vector3(0.6, 4.5, 0.3), 1.2, cc.lightened(0.08), 6, 3, Vector2.ZERO, 0.9)
		"tree_pit":
			b.box(Vector3(0, 1.3, 0), Vector3(0.22, 2.6, 0.22), Color(0.2, 0.14, 0.09))
			b.sphere(Vector3(0, 3.4, 0), 1.4, Color(0.14, 0.24, 0.1), 6, 4, Vector2.ZERO, 0.9)
			b.box(Vector3(0, 0.03, 0), Vector3(1.2, 0.06, 1.2), Color(0.16, 0.12, 0.08))
		"pine":
			b.box(Vector3(0, 1.0, 0), Vector3(0.25, 2.0, 0.25), Color(0.2, 0.14, 0.09))
			b.cyl(Vector3(0, 3.0, 0), 0.0, 1.5, 3.0, Color(0.07, 0.18, 0.1), 6)
			b.cyl(Vector3(0, 4.5, 0), 0.0, 1.0, 2.2, Color(0.08, 0.2, 0.11), 6)
		"bench":
			b.box(Vector3(0, 0.45, 0), Vector3(1.8, 0.08, 0.5), Color(0.28, 0.18, 0.1))
			b.box(Vector3(0, 0.8, 0.22), Vector3(1.8, 0.4, 0.06), Color(0.28, 0.18, 0.1))
			b.box(Vector3(-0.8, 0.22, 0), Vector3(0.08, 0.45, 0.5), dark)
			b.box(Vector3(0.8, 0.22, 0), Vector3(0.08, 0.45, 0.5), dark)
		"hydrant":
			b.cyl(Vector3(0, 0.35, 0), 0.14, 0.16, 0.7, Color(0.7, 0.12, 0.08), 6)
			b.sphere(Vector3(0, 0.72, 0), 0.14, Color(0.7, 0.12, 0.08), 6, 3)
			b.box(Vector3(0, 0.45, 0), Vector3(0.5, 0.1, 0.1), Color(0.65, 0.1, 0.07))
		"trash":
			b.cyl(Vector3(0, 0.45, 0), 0.3, 0.26, 0.9, Color(0.15, 0.25, 0.15), 8)
			b.cyl(Vector3(0, 0.93, 0), 0.32, 0.32, 0.06, Color(0.1, 0.16, 0.1), 8)
		"mailbox":
			b.box(Vector3(0, 0.55, 0), Vector3(0.5, 0.9, 0.5), Color(0.1, 0.18, 0.4))
			b.sphere(Vector3(0, 1.0, 0), 0.25, Color(0.1, 0.18, 0.4), 6, 3, Vector2.ZERO, 0.6)
			b.box(Vector3(0, 0.06, 0), Vector3(0.55, 0.12, 0.55), dark)
		"newsbox":
			b.box(Vector3(0, 0.55, 0), Vector3(0.5, 1.1, 0.45), Color(0.6, 0.12, 0.1))
			b.box(Vector3(0, 0.85, -0.23), Vector3(0.4, 0.3, 0.02), Color(0.7, 0.72, 0.7))
		"phone_booth":
			b.box(Vector3(0, 1.1, 0), Vector3(0.9, 2.2, 0.3), Color(0.25, 0.26, 0.28))
			b.box(Vector3(0, 1.2, -0.16), Vector3(0.4, 0.5, 0.06), Color(0.1, 0.1, 0.1))
			g.box(Vector3(0, 2.05, -0.16), Vector3(0.8, 0.18, 0.02), Color(0.6, 0.8, 1.0), 0.0, Vector2(K_NIGHT, 0))
		"dumpster":
			b.box(Vector3(0, 0.65, 0), Vector3(2.0, 1.3, 1.2), Color(0.12, 0.28, 0.18))
			b.box_xf(Transform3D(Basis(Vector3.RIGHT, -0.15), Vector3(0, 1.36, 0.02)), Vector3(2.04, 0.08, 1.25), Color(0.1, 0.22, 0.14))
		"bags":
			b.sphere(Vector3(0, 0.3, 0), 0.35, Color(0.05, 0.05, 0.05), 6, 3, Vector2.ZERO, 0.8)
			b.sphere(Vector3(0.45, 0.25, 0.2), 0.3, Color(0.07, 0.07, 0.07), 6, 3, Vector2.ZERO, 0.8)
			b.sphere(Vector3(0.2, 0.55, -0.1), 0.25, Color(0.06, 0.06, 0.06), 6, 3, Vector2.ZERO, 0.8)
		"planter":
			b.box(Vector3(0, 0.3, 0), Vector3(1.2, 0.6, 1.2), Color(0.35, 0.33, 0.3))
			b.sphere(Vector3(0, 0.85, 0), 0.55, Color(0.13, 0.25, 0.1), 6, 3)
		"bollard":
			b.cyl(Vector3(0, 0.45, 0), 0.12, 0.12, 0.9, Color(0.3, 0.3, 0.32), 6)
		"bus_shelter":
			b.box(Vector3(-1.9, 1.25, 0), Vector3(0.08, 2.5, 1.4), Color(0.2, 0.22, 0.24))
			b.box(Vector3(1.9, 1.25, 0), Vector3(0.08, 2.5, 1.4), Color(0.2, 0.22, 0.24))
			b.box(Vector3(0, 2.55, 0), Vector3(4.0, 0.12, 1.6), Color(0.18, 0.2, 0.22))
			b.box(Vector3(0, 1.3, 0.66), Vector3(3.6, 2.2, 0.04), Color(0.3, 0.35, 0.4))
			b.box(Vector3(0, 0.5, 0.3), Vector3(2.6, 0.08, 0.4), Color(0.25, 0.26, 0.27))
			g.box(Vector3(-1.9, 1.35, 0), Vector3(0.1, 1.8, 1.2), Color(0.9, 0.85, 0.7), 0.0, Vector2(K_ALWAYS, 0))
		"steam":
			b.cyl(Vector3(0, 0.6, 0), 0.25, 0.3, 1.2, Color(0.8, 0.35, 0.1), 8)
			for i in 4:
				b.box(Vector3(0, 0.3 + float(i) * 0.3, 0), Vector3(0.66, 0.08, 0.66), Color(0.95, 0.95, 0.95))
		"manhole":
			b.cyl(Vector3(0, 0.02, 0), 0.4, 0.4, 0.02, Color(0.08, 0.08, 0.08), 10)
		"water_tank":
			for lx in [-1.0, 1.0]:
				for lz in [-1.0, 1.0]:
					b.box(Vector3(lx, 1.2, lz), Vector3(0.14, 2.4, 0.14), Color(0.12, 0.1, 0.08))
			b.cyl(Vector3(0, 3.6, 0), 1.4, 1.4, 2.6, Color(0.32, 0.22, 0.14), 10)
			b.cyl(Vector3(0, 5.3, 0), 0.0, 1.55, 0.9, Color(0.2, 0.16, 0.12), 10)
		"ac_unit":
			b.box(Vector3(0, 0.6, 0), Vector3(2.4, 1.2, 1.6), Color(0.45, 0.46, 0.47))
			b.cyl(Vector3(0, 1.25, 0), 0.55, 0.55, 0.1, Color(0.2, 0.2, 0.2), 8)
		"antenna":
			b.box(Vector3(0, 6.0, 0), Vector3(0.12, 12.0, 0.12), Color(0.25, 0.25, 0.27))
			for i in 4:
				b.box(Vector3(0, 3.0 + float(i) * 2.5, 0), Vector3(1.6 - float(i) * 0.3, 0.06, 0.06), Color(0.25, 0.25, 0.27))
			g.sphere(Vector3(0, 12.2, 0), 0.2, Color(1.0, 0.1, 0.08), 6, 3, Vector2(K_BLINK, 0))
		"beacon":
			g.sphere(Vector3(0, 0, 0), 0.35, Color(1.0, 0.12, 0.1), 6, 3, Vector2(K_BLINK, 0))
		"tl_ns", "tl_ew":
			# Pole on the corner, arm over the road along +Z (local), signal heads facing -Z and +X.
			var ph := 0.0 if name == "tl_ns" else 0.5
			b.box(Vector3(0, 2.8, 0), Vector3(0.18, 5.6, 0.18), Color(0.12, 0.13, 0.12))
			b.box(Vector3(0, 5.5, 2.4), Vector3(0.12, 0.12, 4.8), Color(0.12, 0.13, 0.12))
			b.box(Vector3(0, 4.9, 4.2), Vector3(0.45, 1.2, 0.4), Color(0.1, 0.1, 0.05))
			for k in 3:
				var cols := [Color(1, 0.1, 0.05), Color(1, 0.7, 0.1), Color(0.1, 1, 0.4)]
				var gy := 5.3 - float(k) * 0.38
				g.box(Vector3(0, gy, 4.0), Vector3(0.26, 0.26, 0.04), cols[k], 0.0, Vector2(K_TRAFFIC, k))
				g.box(Vector3(0, gy, 4.41), Vector3(0.26, 0.26, 0.04), cols[k], 0.0, Vector2(K_TRAFFIC, k))
			# fix phase via uv.x on glow verts
			for i in g.uvs.size():
				g.uvs[i] = Vector2(ph, g.uvs[i].y)
		"fence_seg":
			b.box(Vector3(0, 1.2, 0), Vector3(4.0, 2.4, 0.05), Color(0.3, 0.32, 0.3))
			b.box(Vector3(-2.0, 1.25, 0), Vector3(0.08, 2.5, 0.08), Color(0.2, 0.2, 0.2))
		"container_a", "container_b", "container_c", "container_d":
			var ccol: Color = {"container_a": Color(0.5, 0.18, 0.1), "container_b": Color(0.1, 0.25, 0.45), "container_c": Color(0.2, 0.35, 0.2), "container_d": Color(0.55, 0.45, 0.15)}[name]
			b.box(Vector3(0, 1.3, 0), Vector3(12.0, 2.6, 2.44), ccol)
			for i in 10:
				b.box(Vector3(-5.4 + float(i) * 1.2, 1.3, 1.23), Vector3(0.1, 2.5, 0.04), ccol.darkened(0.25))
				b.box(Vector3(-5.4 + float(i) * 1.2, 1.3, -1.23), Vector3(0.1, 2.5, 0.04), ccol.darkened(0.25))
		"crate":
			b.box(Vector3(0, 0.5, 0), Vector3(1.0, 1.0, 1.0), Color(0.4, 0.3, 0.18))
			b.box(Vector3(0, 0.5, 0.51), Vector3(0.9, 0.12, 0.02), Color(0.32, 0.24, 0.14))
		"pallet":
			b.box(Vector3(0, 0.08, 0), Vector3(1.2, 0.14, 1.0), Color(0.45, 0.35, 0.2))
		"barrel":
			b.cyl(Vector3(0, 0.45, 0), 0.3, 0.3, 0.9, Color(0.2, 0.3, 0.45), 8)
		"gravestone":
			b.box(Vector3(0, 0.45, 0), Vector3(0.6, 0.9, 0.18), Color(0.45, 0.45, 0.44))
			b.box(Vector3(0, 0.05, 0.3), Vector3(0.7, 0.1, 0.7), Color(0.18, 0.2, 0.14))
		"cross":
			b.box(Vector3(0, 0.7, 0), Vector3(0.15, 1.4, 0.15), Color(0.5, 0.5, 0.48))
			b.box(Vector3(0, 1.05, 0), Vector3(0.6, 0.14, 0.15), Color(0.5, 0.5, 0.48))
		"chess_table":
			b.box(Vector3(0, 0.72, 0), Vector3(0.9, 0.08, 0.9), Color(0.5, 0.48, 0.44))
			b.box(Vector3(0, 0.36, 0), Vector3(0.2, 0.72, 0.2), Color(0.4, 0.38, 0.35))
			for i in 4:
				for j in 4:
					if (i + j) % 2 == 0:
						b.box(Vector3(-0.3 + float(i) * 0.2, 0.765, -0.3 + float(j) * 0.2), Vector3(0.2, 0.01, 0.2), Color(0.12, 0.12, 0.12))
			b.box(Vector3(0, 0.25, 0.8), Vector3(0.5, 0.5, 0.4), Color(0.4, 0.38, 0.35))
			b.box(Vector3(0, 0.25, -0.8), Vector3(0.5, 0.5, 0.4), Color(0.4, 0.38, 0.35))
		"rock":
			b.sphere(Vector3(0, 0.3, 0), 1.0, Color(0.35, 0.34, 0.32), 6, 3, Vector2.ZERO, 0.55)
		"bush":
			b.sphere(Vector3(0, 0.5, 0), 0.8, Color(0.1, 0.2, 0.09), 6, 3, Vector2.ZERO, 0.7)
		"food_cart":
			b.box(Vector3(0, 0.75, 0), Vector3(2.0, 1.1, 1.0), Color(0.75, 0.75, 0.72))
			b.box(Vector3(0, 2.2, 0), Vector3(2.4, 0.08, 1.6), Color(0.1, 0.35, 0.6))
			b.box(Vector3(-1.0, 1.4, -0.5), Vector3(0.05, 1.7, 0.05), dark)
			b.box(Vector3(1.0, 1.4, 0.5), Vector3(0.05, 1.7, 0.05), dark)
			b.box(Vector3(-0.6, 0.25, 0), Vector3(0.1, 0.5, 1.0), dark)
			g.box(Vector3(0, 1.45, -0.51), Vector3(1.6, 0.3, 0.02), Color(1.0, 0.8, 0.4), 0.0, Vector2(K_ALWAYS, 0))
		"billboard":
			b.box(Vector3(0, 4.0, 0.3), Vector3(0.3, 8.0, 0.3), dark)
			b.box(Vector3(0, 9.5, 0), Vector3(10.4, 5.4, 0.3), Color(0.08, 0.08, 0.08))
		"scaffold":
			for xx in [-2.0, 0.0, 2.0]:
				b.box(Vector3(xx, 2.0, 0), Vector3(0.08, 4.0, 0.08), Color(0.35, 0.3, 0.1))
				b.box(Vector3(xx, 2.0, -1.2), Vector3(0.08, 4.0, 0.08), Color(0.35, 0.3, 0.1))
			b.box(Vector3(0, 3.1, -0.6), Vector3(4.4, 0.08, 1.4), Color(0.4, 0.3, 0.18))
			b.box(Vector3(0, 4.05, -0.6), Vector3(4.4, 0.1, 1.5), Color(0.18, 0.28, 0.2))
		"rail_car":
			b.box(Vector3(0, 2.0, 0), Vector3(3.0, 3.0, 16.0), Color(0.35, 0.18, 0.1))
			b.box(Vector3(0, 0.45, 0), Vector3(2.4, 0.5, 15.0), Color(0.1, 0.1, 0.1))
		"crane":
			b.box(Vector3(-3, 12, 0), Vector3(0.8, 24, 0.8), Color(0.55, 0.35, 0.1))
			b.box(Vector3(3, 12, 0), Vector3(0.8, 24, 0.8), Color(0.55, 0.35, 0.1))
			b.box(Vector3(0, 24.5, 6), Vector3(7, 1.4, 32), Color(0.55, 0.35, 0.1))
			b.box(Vector3(0, 22, 0), Vector3(6.8, 3, 4), Color(0.5, 0.3, 0.1))
			g.sphere(Vector3(0, 25.5, 21), 0.3, Color(1.0, 0.1, 0.1), 6, 3, Vector2(K_BLINK, 0))
		_:
			if name.begins_with("car_"):
				_car(name, b, g)


## car_<type>_<colorindex>. Types: sedan, taxi, police, van, suv, truck, hatch
static func _car(name: String, b: MeshBatch, g: MeshBatch) -> void:
	var parts := name.split("_")
	var typ := parts[1] if parts.size() > 1 else "sedan"
	var ci := int(parts[2]) if parts.size() > 2 else 0
	var col: Color = CAR_COLORS[ci % CAR_COLORS.size()]
	var glass := Color(0.06, 0.08, 0.1)
	var tire := Color(0.04, 0.04, 0.04)
	var L := 4.4
	var W := 1.8
	var body_h := 0.7
	var cab_len := 2.3
	var cab_h := 0.55
	var cab_off := 0.2
	match typ:
		"taxi":
			col = Color(0.95, 0.72, 0.1)
		"police":
			col = Color(0.9, 0.9, 0.92)
		"suv":
			L = 4.8
			W = 1.95
			body_h = 0.9
			cab_len = 2.9
			cab_h = 0.7
			cab_off = 0.4
			col = Color(0.03, 0.03, 0.035) if ci == 0 else col
		"van":
			L = 5.2
			W = 2.0
			body_h = 1.9
			cab_len = 0.0
			col = Color(0.85, 0.85, 0.85) if ci % 2 == 0 else col
		"truck":
			L = 7.5
			W = 2.3
			body_h = 0.0
		"hatch":
			L = 3.8
			cab_len = 2.0
			cab_off = 0.4
	if typ == "truck":
		b.box(Vector3(0, 1.3, -2.7), Vector3(W, 1.8, 2.0), Color(0.6, 0.1, 0.08))
		b.box(Vector3(0, 1.65, -3.72), Vector3(W - 0.2, 0.7, 0.04), glass)
		b.box(Vector3(0, 1.9, 1.0), Vector3(W + 0.1, 2.9, 5.2), Color(0.8, 0.8, 0.78))
		b.box(Vector3(0, 0.45, 0), Vector3(W - 0.3, 0.3, L), tire)
		for z in [-2.6, 0.6, 2.6]:
			for x in [-1.0, 1.0]:
				b.box(Vector3(x * (W * 0.5 - 0.05), 0.42, z), Vector3(0.3, 0.84, 0.84), tire)
		g.box(Vector3(-0.8, 0.9, -3.72), Vector3(0.3, 0.2, 0.04), Color(1, 0.95, 0.8), 0.0, Vector2(K_NIGHT, 0))
		g.box(Vector3(0.8, 0.9, -3.72), Vector3(0.3, 0.2, 0.04), Color(1, 0.95, 0.8), 0.0, Vector2(K_NIGHT, 0))
		g.box(Vector3(-1.0, 0.7, 3.62), Vector3(0.25, 0.2, 0.04), Color(1, 0.1, 0.05), 0.0, Vector2(K_NIGHT, 0))
		g.box(Vector3(1.0, 0.7, 3.62), Vector3(0.25, 0.2, 0.04), Color(1, 0.1, 0.05), 0.0, Vector2(K_NIGHT, 0))
		return
	var by := 0.35 + body_h * 0.5
	b.box(Vector3(0, by, 0), Vector3(W, body_h, L), col)
	if cab_len > 0.0:
		b.box(Vector3(0, 0.35 + body_h + cab_h * 0.5, cab_off), Vector3(W - 0.15, cab_h, cab_len), col.darkened(0.05))
		# Windows as slightly inset dark panels.
		b.box(Vector3(0, 0.35 + body_h + cab_h * 0.5, cab_off - cab_len * 0.5 - 0.01), Vector3(W - 0.3, cab_h * 0.8, 0.04), glass)
		b.box(Vector3(0, 0.35 + body_h + cab_h * 0.5, cab_off + cab_len * 0.5 + 0.01), Vector3(W - 0.3, cab_h * 0.8, 0.04), glass)
		b.box(Vector3(W * 0.5 - 0.07, 0.35 + body_h + cab_h * 0.5, cab_off), Vector3(0.04, cab_h * 0.75, cab_len - 0.3), glass)
		b.box(Vector3(-W * 0.5 + 0.07, 0.35 + body_h + cab_h * 0.5, cab_off), Vector3(0.04, cab_h * 0.75, cab_len - 0.3), glass)
	else:
		b.box(Vector3(0, 0.35 + body_h * 0.72, -L * 0.5 - 0.01), Vector3(W - 0.3, body_h * 0.3, 0.04), glass)
	for z in [-L * 0.32, L * 0.32]:
		for x in [-1.0, 1.0]:
			b.box(Vector3(x * (W * 0.5 - 0.05), 0.33, z), Vector3(0.26, 0.66, 0.66), tire)
	g.box(Vector3(-W * 0.32, 0.35 + body_h * 0.7, -L * 0.5 - 0.02), Vector3(0.32, 0.14, 0.04), Color(1, 0.95, 0.8), 0.0, Vector2(K_NIGHT, 0))
	g.box(Vector3(W * 0.32, 0.35 + body_h * 0.7, -L * 0.5 - 0.02), Vector3(0.32, 0.14, 0.04), Color(1, 0.95, 0.8), 0.0, Vector2(K_NIGHT, 0))
	g.box(Vector3(-W * 0.35, 0.35 + body_h * 0.7, L * 0.5 + 0.02), Vector3(0.3, 0.14, 0.04), Color(1, 0.08, 0.05), 0.0, Vector2(K_NIGHT, 0))
	g.box(Vector3(W * 0.35, 0.35 + body_h * 0.7, L * 0.5 + 0.02), Vector3(0.3, 0.14, 0.04), Color(1, 0.08, 0.05), 0.0, Vector2(K_NIGHT, 0))
	if typ == "taxi":
		g.box(Vector3(0, 0.35 + body_h + cab_h + 0.12, cab_off), Vector3(0.7, 0.22, 0.3), Color(1, 0.9, 0.5), 0.0, Vector2(K_ALWAYS, 0))
	elif typ == "police":
		b.box(Vector3(0, by, 0), Vector3(W + 0.02, 0.18, L * 0.5), Color(0.1, 0.2, 0.55))
		g.box(Vector3(-0.3, 0.35 + body_h + cab_h + 0.1, cab_off), Vector3(0.5, 0.14, 0.3), Color(1, 0.1, 0.1), 0.0, Vector2(K_BLINK, 0))
		g.box(Vector3(0.3, 0.35 + body_h + cab_h + 0.1, cab_off), Vector3(0.5, 0.14, 0.3), Color(0.1, 0.3, 1), 0.0, Vector2(K_BLINK, 0))


## Standalone mesh for moving vehicles (traffic). Returns [lit_mesh, glow_mesh].
static func car_meshes(name: String) -> Array:
	var key := "mesh_" + name
	if _protos.has(key):
		return _protos[key]
	var p := proto(name)
	var res := [(p["lit"] as MeshBatch).to_mesh(), (p["glow"] as MeshBatch).to_mesh()]
	_protos[key] = res
	return res


# ------------------------------------------------------------------ builders
static func light_pool(ctx: BuildCtx, pos: Vector3, radius: float, col: Color = LAMP_COL) -> void:
	ctx.pool.flat(Vector3(pos.x, 0.04, pos.z), radius * 2.0, radius * 2.0, col)


static func street_lamp(ctx: BuildCtx, pos: Vector3, rot_y: float) -> void:
	place(ctx, "lamp", pos, rot_y)
	var head := pos + Basis(Vector3.UP, rot_y) * Vector3(0, 0, 1.6)
	light_pool(ctx, head, 7.5)
	ctx.solid(pos + Vector3(0, 1.5, 0), Vector3(0.3, 3.0, 0.3))


static func fence_line(ctx: BuildCtx, a: Vector3, b: Vector3, h: float = 2.4, col: Color = Color(0.3, 0.32, 0.3), solid: bool = true) -> void:
	var d := b - a
	var L := d.length()
	if L < 0.1:
		return
	var rot := atan2(d.x, d.z) - PI * 0.5
	var mid := (a + b) * 0.5
	ctx.props.box(mid + Vector3(0, h * 0.5, 0), Vector3(L, h, 0.05), col, rot)
	var n := int(L / 3.0)
	for i in n + 1:
		var p := a + d * (float(i) / float(maxi(1, n)))
		ctx.props.box(p + Vector3(0, h * 0.5 + 0.05, 0), Vector3(0.08, h + 0.1, 0.08), col.darkened(0.4))
	if solid:
		ctx.solid(mid + Vector3(0, h * 0.5, 0), Vector3(L, h, 0.3), rot)


static func fire_escape(ctx: BuildCtx, x0: float, x1: float, z: float, out: float, floors: int, floor_h: float, ground: float) -> void:
	# Facade along X at depth z, outward normal = sign(out) on Z.
	var col := Color(0.08, 0.08, 0.08)
	var w := minf(6.0, x1 - x0 - 1.0)
	var cx := (x0 + x1) * 0.5
	var dz := 0.7 * signf(out)
	for f in range(1, floors):
		var y := ground + float(f) * floor_h - 0.4
		ctx.props.box(Vector3(cx, y, z + dz), Vector3(w, 0.06, 1.3), col)
		ctx.props.box(Vector3(cx, y + 0.5, z + dz * 2.0), Vector3(w, 0.04, 0.04), col)
		ctx.props.box(Vector3(cx, y + 1.0, z + dz * 2.0), Vector3(w, 0.04, 0.04), col)
		for k in 4:
			ctx.props.box(Vector3(cx - w * 0.5 + float(k) * w / 3.0, y + 0.5, z + dz * 2.0), Vector3(0.04, 1.0, 0.04), col)
		# Diagonal stair to the next platform.
		if f < floors - 1:
			var xf := Transform3D(Basis(Vector3.BACK, 0.62), Vector3(cx + w * 0.15, y + floor_h * 0.5, z + dz * 1.4))
			ctx.props.box_xf(xf, Vector3(floor_h * 1.25, 0.05, 0.55), col)


static func awning(ctx: BuildCtx, cx: float, z: float, out: float, w: float, col: Color) -> void:
	var s := signf(out)
	var xf := Transform3D(Basis(Vector3.RIGHT, 0.35 * s), Vector3(cx, 3.2, z + 0.7 * s))
	ctx.props.box_xf(xf, Vector3(w, 0.06, 1.5), col)
	ctx.props.box(Vector3(cx, 2.93, z + 1.4 * s), Vector3(w, 0.3, 0.03), col.darkened(0.2))


static func sign_band(ctx: BuildCtx, pos: Vector3, rot_y: float, w: float, text: String, col: Color, height: float = 0.9, flicker: bool = false) -> void:
	var kind := K_FLICKER if flicker else K_ALWAYS
	ctx.props.panel(pos + Basis(Vector3.UP, rot_y) * Vector3(0, 0, -0.02), w + 0.4, height + 0.2, Color(0.04, 0.04, 0.05), rot_y)
	# Neon outline tube.
	var bs := Basis(Vector3.UP, rot_y)
	var hw := w * 0.5 + 0.1
	var hh := height * 0.5 + 0.05
	ctx.glow.box(pos + bs * Vector3(0, hh, 0.02), Vector3(w + 0.2, 0.05, 0.04), col, rot_y, Vector2(kind, 0))
	ctx.glow.box(pos + bs * Vector3(0, -hh, 0.02), Vector3(w + 0.2, 0.05, 0.04), col, rot_y, Vector2(kind, 0))
	ctx.glow.box(pos + bs * Vector3(hw, 0, 0.02), Vector3(0.05, height + 0.1, 0.04), col, rot_y, Vector2(kind, 0))
	ctx.glow.box(pos + bs * Vector3(-hw, 0, 0.02), Vector3(0.05, height + 0.1, 0.04), col, rot_y, Vector2(kind, 0))
	var fsz := int(clampf(height * 110.0, 40.0, 220.0))
	ctx.label(pos + bs * Vector3(0, 0, 0.06), text, fsz, col.lightened(0.3), rot_y, 240.0, 0.01)


static func subway_entrance(ctx: BuildCtx, rect: Array, face: String) -> void:
	var x0 := float(rect[0])
	var z0 := float(rect[1])
	var x1 := float(rect[2])
	var z1 := float(rect[3])
	var cx := (x0 + x1) * 0.5
	var cz := (z0 + z1) * 0.5
	var out := WorldLayout.face_normal(face)
	var rot := atan2(out.x, out.z)
	var bs := Basis(Vector3.UP, rot)
	var rail := Color(0.12, 0.25, 0.14)
	# Railings on three sides, open on the street side.
	ctx.props.box(Vector3(cx, 0.5, cz) + bs * Vector3(-2.0, 0, -1.0), Vector3(0.08, 1.0, 5.0), rail, rot)
	ctx.props.box(Vector3(cx, 0.5, cz) + bs * Vector3(2.0, 0, -1.0), Vector3(0.08, 1.0, 5.0), rail, rot)
	ctx.props.box(Vector3(cx, 0.5, cz) + bs * Vector3(0, 0, -3.5), Vector3(4.0, 1.0, 0.08), rail, rot)
	# Stairwell hole look: dark slab + steps descending.
	ctx.props.box(Vector3(cx, 0.02, cz) + bs * Vector3(0, 0, -1.0), Vector3(3.8, 0.04, 4.8), Color(0.02, 0.02, 0.02), rot)
	for i in 5:
		ctx.props.box(Vector3(cx, 0.03 - float(i) * 0.001, cz) + bs * Vector3(0, 0, 1.0 - float(i) * 0.9), Vector3(3.4, 0.03, 0.12), Color(0.2, 0.2, 0.2), rot)
	# Green globes.
	for sx in [-2.0, 2.0]:
		var p := Vector3(cx, 0, cz) + bs * Vector3(sx, 0, 1.2)
		ctx.props.box(p + Vector3(0, 1.3, 0), Vector3(0.1, 2.6, 0.1), rail)
		ctx.glow.sphere(p + Vector3(0, 2.75, 0), 0.22, Color(0.2, 1.0, 0.4), 6, 3, Vector2(K_ALWAYS, 0))
	ctx.solid(Vector3(cx, 0.5, cz) + bs * Vector3(-2.0, 0, -1.0), Vector3(0.2, 1.0, 5.0), rot)
	ctx.solid(Vector3(cx, 0.5, cz) + bs * Vector3(2.0, 0, -1.0), Vector3(0.2, 1.0, 5.0), rot)
	ctx.solid(Vector3(cx, 0.5, cz) + bs * Vector3(0, 0, -3.5), Vector3(4.0, 1.0, 0.2), rot)
	ctx.label(Vector3(cx, 2.3, cz) + bs * Vector3(0, 0, 1.3), "SUBWAY", 64, Color(0.9, 1.0, 0.9), rot, 60.0, 0.01)


## A door set into a facade: a light surround, a painted leaf with a lit glass
## panel, a brass handle, a sign plate and a sconce. Everything that marks it
## as a door stays lit day AND night so doors read from down the block.
## kind: house | shop | office | warehouse | landmark
static func door(ctx: BuildCtx, pos: Vector3, out: Vector3, col: Color = Color(0.9, 0.75, 0.45), boarded: bool = false, kind: String = "landmark", leaf: Color = Color(0.4, 0.24, 0.14)) -> void:
	var rot := atan2(out.x, out.z)
	var bs := Basis(Vector3.UP, rot)
	var p := pos + out * 0.02
	var E := Vector2(0, 0.22)
	var frame := Color(0.7, 0.66, 0.58)
	match kind:
		"shop":
			frame = Color(0.2, 0.2, 0.22)
		"office":
			frame = Color(0.6, 0.62, 0.66)
		"warehouse":
			frame = Color(0.5, 0.46, 0.38)
		"landmark":
			frame = Color(0.74, 0.68, 0.58)
	var at := func(x: float, y: float, z: float) -> Vector3: return p + bs * Vector3(x, y, z)
	# Dark recess behind the leaf so the opening reads as depth.
	ctx.props.box(at.call(0, 1.3, 0.0), Vector3(1.5, 2.6, 0.04), Color(0.03, 0.03, 0.03), rot, Vector2.ZERO, 16)
	# Surround: two jambs and a lintel.
	for sx in [-0.8, 0.8]:
		ctx.props.box(at.call(sx, 1.36, 0.1), Vector3(0.2, 2.72, 0.22), frame, rot, E)
	ctx.props.box(at.call(0, 2.8, 0.12), Vector3(1.84, 0.24, 0.26), frame.lightened(0.05), rot, E)
	var lf := leaf if not boarded else Color(0.34, 0.27, 0.17)
	ctx.props.box(at.call(0, 1.22, 0.05), Vector3(1.32, 2.4, 0.06), lf, rot, Vector2(0, 0.2))
	if boarded:
		for i in 3:
			var xf := Transform3D(bs * Basis(Vector3.BACK, 0.3 - 0.3 * float(i)), at.call(0, 0.6 + 0.6 * float(i), 0.12))
			ctx.props.box_xf(xf, Vector3(1.6, 0.2, 0.04), Color(0.45, 0.36, 0.22))
	else:
		if kind == "shop":
			# Glass shop door: the lit interior shows through.
			ctx.glow.box(at.call(0, 1.32, 0.1), Vector3(1.02, 1.9, 0.02), Color(0.66, 0.7, 0.62), rot, Vector2(K_ALWAYS, 0))
			ctx.props.box(at.call(0, 1.05, 0.12), Vector3(1.04, 0.05, 0.03), Color(0.7, 0.7, 0.72), rot, Vector2(0, 0.5))
		elif kind == "warehouse":
			for k in 4:
				ctx.props.box(at.call(0, 0.35 + float(k) * 0.55, 0.09), Vector3(1.24, 0.04, 0.02), lf.darkened(0.3), rot)
			ctx.glow.box(at.call(0, 1.95, 0.1), Vector3(0.4, 0.3, 0.02), Color(0.5, 0.45, 0.32), rot, Vector2(K_ALWAYS, 0))
		else:
			# Lit glass panel in the upper half, raised panels below.
			ctx.glow.box(at.call(0, 1.8, 0.1), Vector3(0.8, 0.62, 0.02), Color(0.6, 0.48, 0.3), rot, Vector2(K_ALWAYS, 0))
			ctx.props.box(at.call(0, 1.8, 0.11), Vector3(0.04, 0.62, 0.02), lf.darkened(0.3), rot)
			ctx.props.box(at.call(-0.26, 0.62, 0.09), Vector3(0.44, 0.8, 0.02), lf.darkened(0.22), rot)
			ctx.props.box(at.call(0.26, 0.62, 0.09), Vector3(0.44, 0.8, 0.02), lf.darkened(0.22), rot)
		ctx.props.box(at.call(0.5, 1.08, 0.13), Vector3(0.06, 0.24, 0.06), Color(0.9, 0.74, 0.36), rot, Vector2(0, 0.7))
	# Sign / address plate over the door.
	ctx.glow.box(at.call(0, 3.04, 0.15), Vector3(1.12, 0.2, 0.03), col, rot, Vector2(K_ALWAYS, 0))
	# Wall sconce.
	ctx.props.box(at.call(1.14, 2.26, 0.12), Vector3(0.16, 0.32, 0.16), Color(0.08, 0.08, 0.08), rot)
	ctx.glow.box(at.call(1.14, 2.22, 0.21), Vector3(0.12, 0.22, 0.03), Color(1.0, 0.84, 0.56), rot, Vector2(K_ALWAYS, 0))
	# Step.
	ctx.props.box(at.call(0, 0.04, 0.42), Vector3(1.9, 0.08, 0.64), Color(0.5, 0.49, 0.46), rot)
	light_pool(ctx, pos + out * 1.5, 3.2, Color(1.0, 0.82, 0.55))


## A street ATM kiosk. Hackable for cash (see LootIndex kind "atm").
static func atm(ctx: BuildCtx, pos: Vector3, rot_y: float) -> void:
	var bs := Basis(Vector3.UP, rot_y)
	ctx.props.box(pos + bs * Vector3(0, 0.8, 0), Vector3(0.8, 1.6, 0.6), Color(0.22, 0.3, 0.42), rot_y, Vector2(0, 0.15))
	ctx.props.box(pos + bs * Vector3(0, 1.72, 0.05), Vector3(0.86, 0.24, 0.7), Color(0.14, 0.18, 0.26), rot_y)
	ctx.glow.box(pos + bs * Vector3(0, 1.22, 0.31), Vector3(0.44, 0.32, 0.02), Color(0.3, 0.75, 1.0), rot_y, Vector2(K_ALWAYS, 0))
	ctx.glow.box(pos + bs * Vector3(0, 1.72, 0.41), Vector3(0.7, 0.14, 0.02), Color(0.35, 1.0, 0.55), rot_y, Vector2(K_ALWAYS, 0))
	ctx.props.box(pos + bs * Vector3(0, 0.95, 0.32), Vector3(0.36, 0.12, 0.06), Color(0.1, 0.1, 0.1), rot_y)
	ctx.solid(pos + Vector3(0, 0.8, 0), Vector3(0.8, 1.6, 0.6), rot_y)
	ctx.label(pos + bs * Vector3(0, 1.72, 0.43), "ATM", 56, Color(0.9, 1.0, 0.9), rot_y, 45.0, 0.01)
