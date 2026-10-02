class_name Furniture
extends RefCounted
## Interior furniture library. Every piece writes into a BuildCtx (lit props,
## glow, collision). Local frame: +Z is the "front" of the piece.

static var _ctx: BuildCtx
static var _p: Vector3
static var _r: float
static var _bs: Basis


static func _at(ctx: BuildCtx, pos: Vector3, rot: float) -> void:
	_ctx = ctx
	_p = pos
	_r = rot
	_bs = Basis(Vector3.UP, rot)


static func B(c: Vector3, s: Vector3, col: Color) -> void:
	_ctx.props.box(_p + _bs * c, s, col, _r)


static func G(c: Vector3, s: Vector3, col: Color, kind: float = 0.0) -> void:
	_ctx.glow.box(_p + _bs * c, s, col, _r, Vector2(kind, 0))


static func S(c: Vector3, s: Vector3) -> void:
	_ctx.solid(_p + _bs * c, s, _r)


static func C(c: Vector3, rt: float, rb: float, h: float, col: Color, seg: int = 8) -> void:
	_ctx.props.cyl(_p + _bs * c, rt, rb, h, col, seg)


static func build(ctx: BuildCtx, type: String, pos: Vector3, rot: float, prm: Dictionary = {}) -> void:
	_at(ctx, pos, rot)
	var wood := Color(0.3, 0.2, 0.12)
	var dark := Color(0.08, 0.08, 0.09)
	var metal := Color(0.4, 0.41, 0.43)
	match type:
		"bed":
			B(Vector3(0, 0.22, 0), Vector3(1.1, 0.3, 2.1), Color(0.12, 0.1, 0.1))
			B(Vector3(0, 0.45, 0), Vector3(1.0, 0.2, 2.0), Color(0.6, 0.6, 0.62))
			B(Vector3(0, 0.56, 0.25), Vector3(1.02, 0.06, 1.4), prm.get("col", Color(0.18, 0.2, 0.28)))
			B(Vector3(0, 0.6, -0.75), Vector3(0.6, 0.12, 0.38), Color(0.8, 0.8, 0.78))
			B(Vector3(0, 0.7, -1.05), Vector3(1.1, 0.9, 0.08), wood)
			S(Vector3(0, 0.4, 0), Vector3(1.1, 0.8, 2.1))
		"bed_double":
			B(Vector3(0, 0.22, 0), Vector3(1.7, 0.3, 2.1), wood)
			B(Vector3(0, 0.45, 0), Vector3(1.6, 0.2, 2.0), Color(0.85, 0.85, 0.82))
			B(Vector3(0, 0.56, 0.3), Vector3(1.62, 0.06, 1.3), prm.get("col", Color(0.5, 0.15, 0.15)))
			B(Vector3(-0.4, 0.6, -0.75), Vector3(0.6, 0.12, 0.38), Color(0.9, 0.9, 0.88))
			B(Vector3(0.4, 0.6, -0.75), Vector3(0.6, 0.12, 0.38), Color(0.9, 0.9, 0.88))
			B(Vector3(0, 0.8, -1.05), Vector3(1.7, 1.1, 0.1), wood)
			S(Vector3(0, 0.4, 0), Vector3(1.7, 0.8, 2.1))
		"mattress":
			B(Vector3(0, 0.1, 0), Vector3(0.95, 0.2, 1.9), Color(0.55, 0.52, 0.45))
			B(Vector3(0, 0.22, 0.3), Vector3(0.9, 0.04, 1.1), Color(0.3, 0.25, 0.2))
		"sofa":
			var sc: Color = prm.get("col", Color(0.3, 0.2, 0.16))
			B(Vector3(0, 0.25, 0), Vector3(2.0, 0.5, 0.85), sc)
			B(Vector3(0, 0.65, -0.35), Vector3(2.0, 0.6, 0.18), sc.darkened(0.1))
			B(Vector3(-0.95, 0.45, 0), Vector3(0.14, 0.4, 0.85), sc.darkened(0.1))
			B(Vector3(0.95, 0.45, 0), Vector3(0.14, 0.4, 0.85), sc.darkened(0.1))
			S(Vector3(0, 0.4, 0), Vector3(2.0, 0.8, 0.85))
		"armchair":
			var ac: Color = prm.get("col", Color(0.35, 0.25, 0.18))
			B(Vector3(0, 0.25, 0), Vector3(0.85, 0.5, 0.8), ac)
			B(Vector3(0, 0.7, -0.33), Vector3(0.85, 0.6, 0.15), ac.darkened(0.1))
			S(Vector3(0, 0.4, 0), Vector3(0.85, 0.8, 0.8))
		"coffee_table":
			B(Vector3(0, 0.4, 0), Vector3(1.1, 0.06, 0.6), wood)
			for sx in [-0.5, 0.5]:
				for sz in [-0.25, 0.25]:
					B(Vector3(sx, 0.2, sz), Vector3(0.05, 0.4, 0.05), wood.darkened(0.3))
			S(Vector3(0, 0.25, 0), Vector3(1.1, 0.5, 0.6))
		"table":
			var tw: float = prm.get("w", 1.4)
			var td: float = prm.get("d", 0.8)
			B(Vector3(0, 0.76, 0), Vector3(tw, 0.06, td), prm.get("col", wood))
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					B(Vector3(sx * (tw * 0.5 - 0.06), 0.38, sz * (td * 0.5 - 0.06)), Vector3(0.06, 0.76, 0.06), wood.darkened(0.3))
			S(Vector3(0, 0.4, 0), Vector3(tw, 0.8, td))
		"chair":
			B(Vector3(0, 0.45, 0), Vector3(0.45, 0.06, 0.45), prm.get("col", wood))
			B(Vector3(0, 0.75, -0.2), Vector3(0.45, 0.55, 0.05), prm.get("col", wood))
			for sx in [-0.19, 0.19]:
				for sz in [-0.19, 0.19]:
					B(Vector3(sx, 0.22, sz), Vector3(0.04, 0.45, 0.04), dark)
		"stool":
			C(Vector3(0, 0.72, 0), 0.2, 0.2, 0.06, Color(0.5, 0.1, 0.1))
			C(Vector3(0, 0.36, 0), 0.03, 0.03, 0.72, metal, 6)
		"desk":
			B(Vector3(0, 0.75, 0), Vector3(1.5, 0.05, 0.7), prm.get("col", wood))
			B(Vector3(-0.68, 0.37, 0), Vector3(0.06, 0.75, 0.66), wood.darkened(0.3))
			B(Vector3(0.5, 0.37, 0), Vector3(0.45, 0.75, 0.66), wood.darkened(0.2))
			S(Vector3(0, 0.4, 0), Vector3(1.5, 0.8, 0.7))
		"desk_pc", "office_desk":
			var dc: Color = Color(0.35, 0.36, 0.38) if type == "office_desk" else wood
			B(Vector3(0, 0.75, 0), Vector3(1.5, 0.05, 0.75), dc)
			B(Vector3(-0.7, 0.37, 0), Vector3(0.05, 0.75, 0.7), dc.darkened(0.3))
			B(Vector3(0.7, 0.37, 0), Vector3(0.05, 0.75, 0.7), dc.darkened(0.3))
			B(Vector3(0, 1.1, -0.2), Vector3(0.6, 0.38, 0.04), dark)
			G(Vector3(0, 1.1, -0.175), Vector3(0.54, 0.32, 0.01), prm.get("screen", Color(0.2, 0.9, 0.5)))
			B(Vector3(0, 0.85, -0.2), Vector3(0.08, 0.2, 0.06), dark)
			B(Vector3(0, 0.79, 0.12), Vector3(0.45, 0.02, 0.15), Color(0.12, 0.12, 0.13))
			if bool(prm.get("tower", true)):
				B(Vector3(0.55, 0.25, -0.1), Vector3(0.2, 0.45, 0.45), dark)
				G(Vector3(0.55, 0.4, 0.13), Vector3(0.02, 0.02, 0.01), Color(0.3, 1.0, 0.4))
			S(Vector3(0, 0.45, 0), Vector3(1.5, 0.9, 0.75))
			build_chair_at(ctx, pos + Basis(Vector3.UP, rot) * Vector3(0, 0, 0.75), rot + PI, Color(0.1, 0.1, 0.12))
		"monitor_wall":
			for i in 3:
				for j in 2:
					B(Vector3(-0.9 + float(i) * 0.9, 1.2 + float(j) * 0.55, 0), Vector3(0.85, 0.5, 0.05), dark)
					G(Vector3(-0.9 + float(i) * 0.9, 1.2 + float(j) * 0.55, 0.03), Vector3(0.78, 0.44, 0.01), [Color(0.2, 0.9, 0.5), Color(0.9, 0.2, 0.3), Color(0.3, 0.6, 1.0)][(i + j) % 3], 3.0)
		"tv":
			B(Vector3(0, 0.3, 0), Vector3(1.2, 0.6, 0.4), wood.darkened(0.2))
			B(Vector3(0, 0.95, -0.05), Vector3(1.1, 0.65, 0.06), dark)
			G(Vector3(0, 0.95, -0.02), Vector3(1.0, 0.56, 0.01), prm.get("screen", Color(0.35, 0.5, 0.9)), 3.0)
			S(Vector3(0, 0.6, 0), Vector3(1.2, 1.2, 0.4))
		"bookshelf":
			B(Vector3(0, 1.0, 0), Vector3(1.2, 2.0, 0.35), wood)
			for k in 4:
				for q in 6:
					B(Vector3(-0.48 + float(q) * 0.19, 0.3 + float(k) * 0.45, 0.02), Vector3(0.12, 0.34, 0.26), [Color(0.5, 0.1, 0.1), Color(0.1, 0.2, 0.4), Color(0.6, 0.55, 0.4), Color(0.15, 0.3, 0.15)][(k * 7 + q * 3) % 4])
			S(Vector3(0, 1.0, 0), Vector3(1.2, 2.0, 0.35))
		"shelf":
			B(Vector3(0, 0.9, 0), Vector3(1.4, 1.8, 0.4), Color(0.55, 0.57, 0.6))
			for k in 4:
				B(Vector3(0, 0.25 + float(k) * 0.45, 0.02), Vector3(1.3, 0.03, 0.38), metal)
				for q in 5:
					B(Vector3(-0.5 + float(q) * 0.25, 0.37 + float(k) * 0.45, 0.02), Vector3(0.18, 0.2, 0.2), [Color(0.7, 0.3, 0.1), Color(0.2, 0.5, 0.7), Color(0.8, 0.8, 0.7), Color(0.6, 0.1, 0.2), Color(0.3, 0.6, 0.2)][(k + q) % 5])
			S(Vector3(0, 0.9, 0), Vector3(1.4, 1.8, 0.4))
		"shelf_industrial":
			B(Vector3(0, 1.5, 0), Vector3(2.4, 3.0, 0.9), Color(0.2, 0.3, 0.5))
			for k in 3:
				B(Vector3(0, 0.3 + float(k) * 1.0, 0), Vector3(2.3, 0.05, 0.85), Color(0.6, 0.35, 0.1))
				B(Vector3(-0.5, 0.6 + float(k) * 1.0, 0), Vector3(0.9, 0.55, 0.7), Color(0.45, 0.35, 0.22))
				B(Vector3(0.6, 0.55 + float(k) * 1.0, 0), Vector3(0.7, 0.45, 0.6), Color(0.4, 0.32, 0.2))
			S(Vector3(0, 1.5, 0), Vector3(2.4, 3.0, 0.9))
		"kitchen":
			var kw: float = prm.get("w", 3.0)
			B(Vector3(0, 0.45, 0), Vector3(kw, 0.9, 0.62), Color(0.75, 0.72, 0.65))
			B(Vector3(0, 0.92, 0), Vector3(kw + 0.04, 0.05, 0.66), Color(0.2, 0.2, 0.22))
			B(Vector3(-kw * 0.3, 0.93, 0.02), Vector3(0.5, 0.02, 0.4), metal)
			B(Vector3(kw * 0.25, 0.94, 0.0), Vector3(0.6, 0.03, 0.5), dark)
			for q in 4:
				C(Vector3(kw * 0.25 - 0.15 + float(q % 2) * 0.3, 0.97, -0.12 + float(q / 2) * 0.24), 0.09, 0.09, 0.02, Color(0.15, 0.15, 0.15), 8)
			B(Vector3(0, 1.9, -0.15), Vector3(kw, 0.7, 0.35), Color(0.7, 0.68, 0.62))
			S(Vector3(0, 0.45, 0), Vector3(kw, 0.9, 0.62))
		"fridge":
			B(Vector3(0, 0.9, 0), Vector3(0.75, 1.8, 0.7), Color(0.85, 0.85, 0.82))
			B(Vector3(0.3, 1.2, 0.36), Vector3(0.03, 0.4, 0.03), metal)
			S(Vector3(0, 0.9, 0), Vector3(0.75, 1.8, 0.7))
		"fridge_glass":
			B(Vector3(0, 1.0, 0), Vector3(1.4, 2.0, 0.7), dark)
			G(Vector3(0, 1.05, 0.33), Vector3(1.3, 1.8, 0.02), Color(0.7, 0.85, 0.95))
			for k in 4:
				for q in 6:
					B(Vector3(-0.55 + float(q) * 0.22, 0.4 + float(k) * 0.42, 0.25), Vector3(0.08, 0.22, 0.08), [Color(0.8, 0.1, 0.1), Color(0.1, 0.5, 0.2), Color(0.9, 0.7, 0.1), Color(0.2, 0.3, 0.8)][(k + q) % 4])
			S(Vector3(0, 1.0, 0), Vector3(1.4, 2.0, 0.7))
		"counter":
			var cw: float = prm.get("w", 3.0)
			B(Vector3(0, 0.5, 0), Vector3(cw, 1.0, 0.7), prm.get("col", Color(0.35, 0.22, 0.14)))
			B(Vector3(0, 1.03, 0), Vector3(cw + 0.1, 0.06, 0.8), Color(0.55, 0.5, 0.45))
			S(Vector3(0, 0.55, 0), Vector3(cw, 1.1, 0.75))
		"register":
			B(Vector3(0, 1.15, 0), Vector3(0.45, 0.22, 0.4), dark)
			G(Vector3(0, 1.32, -0.1), Vector3(0.3, 0.12, 0.02), Color(0.3, 1.0, 0.5))
		"coffee_machine":
			B(Vector3(0, 1.3, 0), Vector3(0.7, 0.5, 0.45), metal)
			B(Vector3(0, 1.1, 0.12), Vector3(0.5, 0.08, 0.2), dark)
			G(Vector3(0.2, 1.45, 0.23), Vector3(0.06, 0.06, 0.01), Color(1.0, 0.3, 0.1))
		"cafe_table":
			C(Vector3(0, 0.74, 0), 0.4, 0.4, 0.04, Color(0.3, 0.2, 0.12), 10)
			C(Vector3(0, 0.37, 0), 0.04, 0.04, 0.74, dark, 6)
			C(Vector3(0, 0.02, 0), 0.25, 0.25, 0.04, dark, 8)
			S(Vector3(0, 0.4, 0), Vector3(0.8, 0.8, 0.8))
			build_chair_at(ctx, pos + Basis(Vector3.UP, rot) * Vector3(0, 0, 0.6), rot + PI, Color(0.25, 0.15, 0.1))
			build_chair_at(ctx, pos + Basis(Vector3.UP, rot) * Vector3(0, 0, -0.6), rot, Color(0.25, 0.15, 0.1))
		"bar_counter":
			var bw: float = prm.get("w", 5.0)
			B(Vector3(0, 0.55, 0), Vector3(bw, 1.1, 0.7), Color(0.2, 0.1, 0.06))
			B(Vector3(0, 1.12, 0), Vector3(bw + 0.1, 0.06, 0.85), Color(0.3, 0.16, 0.08))
			G(Vector3(0, 0.1, 0.36), Vector3(bw, 0.04, 0.02), prm.get("neon", Color(1.0, 0.3, 0.7)))
			S(Vector3(0, 0.55, 0), Vector3(bw, 1.1, 0.75))
		"bar_shelf":
			var bw2: float = prm.get("w", 4.0)
			B(Vector3(0, 1.4, 0), Vector3(bw2, 2.2, 0.35), Color(0.15, 0.08, 0.05))
			G(Vector3(0, 1.4, 0.16), Vector3(bw2 - 0.2, 2.0, 0.01), Color(0.35, 0.2, 0.1))
			for k in 3:
				for q in int(bw2 * 4.0):
					C(Vector3(-bw2 * 0.5 + 0.15 + float(q) * 0.25, 0.75 + float(k) * 0.6, 0.05), 0.04, 0.05, 0.3, [Color(0.3, 0.5, 0.2), Color(0.6, 0.35, 0.1), Color(0.8, 0.8, 0.85), Color(0.5, 0.1, 0.1)][(k + q) % 4], 5)
			S(Vector3(0, 1.4, 0), Vector3(bw2, 2.2, 0.35))
		"pool_table":
			B(Vector3(0, 0.75, 0), Vector3(1.4, 0.1, 2.5), Color(0.1, 0.4, 0.18))
			B(Vector3(0, 0.62, 0), Vector3(1.55, 0.2, 2.65), Color(0.25, 0.14, 0.08))
			for sx in [-0.6, 0.6]:
				for sz in [-1.1, 1.1]:
					B(Vector3(sx, 0.3, sz), Vector3(0.14, 0.6, 0.14), Color(0.2, 0.12, 0.07))
			S(Vector3(0, 0.45, 0), Vector3(1.55, 0.9, 2.65))
		"jukebox":
			B(Vector3(0, 0.8, 0), Vector3(0.9, 1.6, 0.6), Color(0.35, 0.1, 0.08))
			G(Vector3(0, 1.3, 0.31), Vector3(0.7, 0.4, 0.02), Color(1.0, 0.6, 0.2), 3.0)
			G(Vector3(0, 0.7, 0.31), Vector3(0.7, 0.05, 0.02), Color(0.3, 0.8, 1.0))
			S(Vector3(0, 0.8, 0), Vector3(0.9, 1.6, 0.6))
		"booth":
			var bc: Color = prm.get("col", Color(0.45, 0.08, 0.08))
			B(Vector3(0, 0.25, -0.6), Vector3(1.6, 0.5, 0.6), bc)
			B(Vector3(0, 0.75, -0.85), Vector3(1.6, 0.8, 0.15), bc)
			B(Vector3(0, 0.25, 0.6), Vector3(1.6, 0.5, 0.6), bc)
			B(Vector3(0, 0.75, 0.85), Vector3(1.6, 0.8, 0.15), bc)
			B(Vector3(0, 0.74, 0), Vector3(1.4, 0.06, 0.7), Color(0.6, 0.6, 0.6))
			S(Vector3(0, 0.5, 0), Vector3(1.6, 1.0, 1.9))
		"arcade_cab":
			var ac2: Color = prm.get("col", Color(0.1, 0.1, 0.35))
			B(Vector3(0, 0.95, 0), Vector3(0.8, 1.9, 0.75), ac2)
			B(Vector3(0, 1.85, 0.08), Vector3(0.8, 0.3, 0.55), ac2.darkened(0.2))
			G(Vector3(0, 1.85, 0.36), Vector3(0.7, 0.2, 0.01), prm.get("glow", Color(1.0, 0.3, 0.5)))
			B(Vector3(0, 1.35, 0.33), Vector3(0.62, 0.48, 0.03), dark)
			G(Vector3(0, 1.35, 0.35), Vector3(0.56, 0.42, 0.01), prm.get("screen", Color(0.3, 0.9, 0.6)), 3.0)
			B(Vector3(0, 0.98, 0.42), Vector3(0.7, 0.06, 0.28), dark)
			S(Vector3(0, 0.95, 0), Vector3(0.8, 1.9, 0.75))
		"pinball":
			B(Vector3(0, 0.8, 0), Vector3(0.75, 0.2, 1.4), Color(0.4, 0.05, 0.1))
			G(Vector3(0, 0.91, 0), Vector3(0.65, 0.01, 1.3), Color(0.9, 0.5, 0.2), 3.0)
			B(Vector3(0, 1.35, -0.7), Vector3(0.75, 0.9, 0.12), Color(0.4, 0.05, 0.1))
			G(Vector3(0, 1.4, -0.63), Vector3(0.65, 0.7, 0.01), Color(1.0, 0.2, 0.4), 3.0)
			for sx in [-0.3, 0.3]:
				for sz in [-0.6, 0.6]:
					B(Vector3(sx, 0.35, sz), Vector3(0.06, 0.7, 0.06), metal)
			S(Vector3(0, 0.6, 0), Vector3(0.75, 1.2, 1.4))
		"server_rack":
			B(Vector3(0, 1.05, 0), Vector3(0.7, 2.1, 1.0), Color(0.04, 0.05, 0.07))
			for k in 8:
				G(Vector3(-0.2 + float(k % 3) * 0.2, 0.3 + float(k) * 0.22, 0.51), Vector3(0.06, 0.03, 0.01), prm.get("led", Color(0.2, 1.0, 0.4)) if k % 3 != 1 else Color(1.0, 0.5, 0.1), 3.0)
			S(Vector3(0, 1.05, 0), Vector3(0.7, 2.1, 1.0))
		"filing_cabinet":
			B(Vector3(0, 0.65, 0), Vector3(0.5, 1.3, 0.6), Color(0.45, 0.46, 0.48))
			for k in 4:
				B(Vector3(0, 0.2 + float(k) * 0.3, 0.31), Vector3(0.14, 0.03, 0.02), dark)
			S(Vector3(0, 0.65, 0), Vector3(0.5, 1.3, 0.6))
		"locker_row":
			var n: int = prm.get("n", 4)
			for k in n:
				B(Vector3(-float(n - 1) * 0.25 + float(k) * 0.5, 0.95, 0), Vector3(0.48, 1.9, 0.5), Color(0.25, 0.35, 0.45))
				B(Vector3(-float(n - 1) * 0.25 + float(k) * 0.5 + 0.15, 1.0, 0.26), Vector3(0.03, 0.12, 0.02), metal)
			S(Vector3(0, 0.95, 0), Vector3(float(n) * 0.5, 1.9, 0.5))
		"whiteboard":
			B(Vector3(0, 1.5, 0), Vector3(2.0, 1.1, 0.04), Color(0.92, 0.92, 0.9))
			for k in 4:
				B(Vector3(-0.6 + float(k) * 0.35, 1.6 - float(k % 2) * 0.3, 0.025), Vector3(0.3, 0.02, 0.005), [Color(0.1, 0.2, 0.7), Color(0.7, 0.1, 0.1)][k % 2])
		"water_cooler":
			B(Vector3(0, 0.5, 0), Vector3(0.35, 1.0, 0.35), Color(0.85, 0.85, 0.85))
			C(Vector3(0, 1.2, 0), 0.15, 0.15, 0.45, Color(0.4, 0.6, 0.9), 8)
			S(Vector3(0, 0.6, 0), Vector3(0.4, 1.2, 0.4))
		"vending":
			B(Vector3(0, 0.95, 0), Vector3(0.95, 1.9, 0.8), Color(0.6, 0.1, 0.1))
			G(Vector3(-0.12, 1.1, 0.41), Vector3(0.6, 1.3, 0.01), Color(0.9, 0.9, 0.8))
			S(Vector3(0, 0.95, 0), Vector3(0.95, 1.9, 0.8))
		"reception":
			B(Vector3(0, 0.55, 0), Vector3(3.2, 1.1, 0.8), prm.get("col", Color(0.25, 0.26, 0.3)))
			B(Vector3(0, 1.12, 0.1), Vector3(3.3, 0.05, 1.0), Color(0.85, 0.85, 0.88))
			G(Vector3(0, 0.6, 0.41), Vector3(3.0, 0.08, 0.01), prm.get("glow", Color(0.35, 0.55, 1.0)))
			S(Vector3(0, 0.55, 0), Vector3(3.2, 1.1, 0.9))
		"logo_wall":
			B(Vector3(0, 2.0, 0), Vector3(prm.get("w", 4.0), 2.5, 0.1), Color(0.1, 0.1, 0.12))
			G(Vector3(0, 2.0, 0.06), Vector3(float(prm.get("w", 4.0)) - 0.4, 0.12, 0.01), prm.get("glow", Color(0.35, 0.55, 1.0)))
		"elevator":
			B(Vector3(0, 1.25, 0), Vector3(1.8, 2.5, 0.15), metal)
			B(Vector3(0, 1.1, 0.08), Vector3(0.02, 2.2, 0.02), dark)
			G(Vector3(0, 2.6, 0.08), Vector3(0.4, 0.12, 0.01), Color(1.0, 0.6, 0.2))
		"turnstile":
			for k in 3:
				B(Vector3(-1.0 + float(k) * 1.0, 0.5, 0), Vector3(0.25, 1.0, 0.8), metal)
				G(Vector3(-1.0 + float(k) * 1.0, 1.01, 0), Vector3(0.1, 0.01, 0.1), Color(0.2, 1.0, 0.4))
				S(Vector3(-1.0 + float(k) * 1.0, 0.5, 0), Vector3(0.25, 1.0, 0.8))
		"metal_detector":
			B(Vector3(-0.5, 1.05, 0), Vector3(0.15, 2.1, 0.5), Color(0.6, 0.6, 0.62))
			B(Vector3(0.5, 1.05, 0), Vector3(0.15, 2.1, 0.5), Color(0.6, 0.6, 0.62))
			B(Vector3(0, 2.15, 0), Vector3(1.15, 0.15, 0.5), Color(0.6, 0.6, 0.62))
			G(Vector3(0, 2.23, 0.2), Vector3(0.12, 0.05, 0.02), Color(0.2, 1.0, 0.3))
			S(Vector3(-0.5, 1.05, 0), Vector3(0.15, 2.1, 0.5))
			S(Vector3(0.5, 1.05, 0), Vector3(0.15, 2.1, 0.5))
		"conference":
			B(Vector3(0, 0.76, 0), Vector3(4.0, 0.08, 1.4), Color(0.2, 0.12, 0.08))
			B(Vector3(0, 0.38, 0), Vector3(3.6, 0.76, 0.4), Color(0.15, 0.1, 0.07))
			S(Vector3(0, 0.4, 0), Vector3(4.0, 0.8, 1.4))
			for k in 4:
				build_chair_at(ctx, pos + Basis(Vector3.UP, rot) * Vector3(-1.5 + float(k), 0, 1.0), rot + PI, Color(0.1, 0.1, 0.12))
				build_chair_at(ctx, pos + Basis(Vector3.UP, rot) * Vector3(-1.5 + float(k), 0, -1.0), rot, Color(0.1, 0.1, 0.12))
		"plant":
			C(Vector3(0, 0.25, 0), 0.22, 0.18, 0.5, Color(0.5, 0.3, 0.2), 8)
			_ctx.props.sphere(_p + Vector3(0, 0.85, 0), 0.4, Color(0.15, 0.35, 0.12), 6, 4)
			S(Vector3(0, 0.5, 0), Vector3(0.5, 1.0, 0.5))
		"lamp":
			C(Vector3(0, 0.8, 0), 0.03, 0.03, 1.6, dark, 6)
			C(Vector3(0, 0.03, 0), 0.2, 0.2, 0.06, dark, 8)
			_ctx.glow.cyl(_p + Vector3(0, 1.62, 0), 0.18, 0.28, 0.3, prm.get("col", Color(1.0, 0.8, 0.5)), 8, Vector2(0, 0))
		"rug":
			_ctx.props.flat(_p + Vector3(0, 0.012, 0), float(prm.get("w", 2.5)), float(prm.get("d", 1.8)), prm.get("col", Color(0.4, 0.12, 0.1)), _r)
		"fishtank":
			B(Vector3(0, 0.45, 0), Vector3(0.9, 0.9, 0.45), wood.darkened(0.3))
			G(Vector3(0, 1.2, 0), Vector3(0.9, 0.6, 0.42), Color(0.1, 0.35, 0.45))
			B(Vector3(0, 1.52, 0), Vector3(0.92, 0.04, 0.44), dark)
			G(Vector3(-0.1, 1.2, 0.22), Vector3(0.14, 0.07, 0.01), Color(1.0, 0.5, 0.1))
			S(Vector3(0, 0.75, 0), Vector3(0.9, 1.55, 0.45))
		"window":
			B(Vector3(0, 1.6, 0), Vector3(prm.get("w", 1.4) + 0.12, 1.6, 0.06), Color(0.15, 0.13, 0.12))
			G(Vector3(0, 1.6, 0.035), Vector3(prm.get("w", 1.4), 1.5, 0.01), prm.get("col", Color(0.08, 0.1, 0.18)))
			B(Vector3(0, 1.6, 0.05), Vector3(0.05, 1.5, 0.02), Color(0.15, 0.13, 0.12))
		"poster":
			B(Vector3(0, 1.6, 0), Vector3(0.7, 1.0, 0.02), prm.get("col", Color(0.6, 0.1, 0.1)))
			B(Vector3(0, 1.75, 0.012), Vector3(0.5, 0.3, 0.005), Color(0.9, 0.9, 0.85))
		"radiator":
			for k in 8:
				B(Vector3(-0.35 + float(k) * 0.1, 0.4, 0), Vector3(0.05, 0.6, 0.12), Color(0.7, 0.7, 0.68))
		"boxes":
			B(Vector3(0, 0.25, 0), Vector3(0.6, 0.5, 0.5), Color(0.55, 0.42, 0.28))
			B(Vector3(0.1, 0.7, 0.05), Vector3(0.5, 0.4, 0.45), Color(0.5, 0.38, 0.25))
			B(Vector3(0.65, 0.2, 0.1), Vector3(0.45, 0.4, 0.45), Color(0.58, 0.45, 0.3))
			S(Vector3(0.2, 0.45, 0.05), Vector3(1.2, 0.9, 0.6))
		"crate":
			B(Vector3(0, 0.5, 0), Vector3(1.0, 1.0, 1.0), Color(0.42, 0.32, 0.18))
			S(Vector3(0, 0.5, 0), Vector3(1.0, 1.0, 1.0))
		"trash_pile":
			for k in 5:
				_ctx.props.sphere(_p + Vector3(randf_range(-0.6, 0.6), 0.2, randf_range(-0.4, 0.4)), randf_range(0.2, 0.35), Color(0.08, 0.08, 0.08), 6, 3)
		"toilet":
			B(Vector3(0, 0.22, 0.1), Vector3(0.4, 0.44, 0.5), Color(0.9, 0.9, 0.9))
			B(Vector3(0, 0.6, -0.2), Vector3(0.4, 0.4, 0.18), Color(0.9, 0.9, 0.9))
			S(Vector3(0, 0.4, 0), Vector3(0.45, 0.8, 0.7))
		"sink":
			B(Vector3(0, 0.8, 0), Vector3(0.55, 0.15, 0.45), Color(0.9, 0.9, 0.9))
			B(Vector3(0, 0.4, -0.1), Vector3(0.12, 0.8, 0.12), Color(0.9, 0.9, 0.9))
			B(Vector3(0, 1.4, -0.2), Vector3(0.5, 0.6, 0.02), Color(0.6, 0.7, 0.75))
		"bathtub":
			B(Vector3(0, 0.3, 0), Vector3(0.8, 0.6, 1.7), Color(0.9, 0.9, 0.88))
			B(Vector3(0, 0.55, 0), Vector3(0.6, 0.1, 1.5), Color(0.6, 0.7, 0.75))
			S(Vector3(0, 0.3, 0), Vector3(0.8, 0.6, 1.7))
		"wardrobe":
			B(Vector3(0, 1.0, 0), Vector3(1.2, 2.0, 0.6), wood)
			B(Vector3(0, 1.0, 0.31), Vector3(0.02, 1.9, 0.01), wood.darkened(0.4))
			S(Vector3(0, 1.0, 0), Vector3(1.2, 2.0, 0.6))
		"dresser":
			B(Vector3(0, 0.45, 0), Vector3(1.2, 0.9, 0.5), wood)
			for k in 3:
				B(Vector3(0, 0.18 + float(k) * 0.27, 0.26), Vector3(1.0, 0.02, 0.01), wood.darkened(0.4))
			S(Vector3(0, 0.45, 0), Vector3(1.2, 0.9, 0.5))
		"washer":
			for k in int(prm.get("n", 4)):
				var xx := -float(int(prm.get("n", 4)) - 1) * 0.4 + float(k) * 0.8
				B(Vector3(xx, 0.45, 0), Vector3(0.75, 0.9, 0.7), Color(0.88, 0.88, 0.86))
				C(Vector3(xx, 0.5, 0.36), 0.22, 0.22, 0.02, Color(0.3, 0.35, 0.4), 10)
			S(Vector3(0, 0.45, 0), Vector3(float(int(prm.get("n", 4))) * 0.8, 0.9, 0.7))
		"hospital_bed":
			B(Vector3(0, 0.5, 0), Vector3(1.0, 0.15, 2.1), Color(0.85, 0.87, 0.9))
			B(Vector3(0, 0.3, 0), Vector3(0.9, 0.4, 2.0), metal)
			B(Vector3(0, 0.62, -0.7), Vector3(0.6, 0.1, 0.4), Color(0.95, 0.95, 0.95))
			B(Vector3(0.7, 1.2, -0.9), Vector3(0.05, 1.6, 0.05), metal)
			S(Vector3(0, 0.4, 0), Vector3(1.0, 0.8, 2.1))
		"curtain":
			B(Vector3(0, 1.2, 0), Vector3(prm.get("w", 2.2), 2.2, 0.03), Color(0.55, 0.7, 0.75))
		"cell_bars":
			var cw2: float = prm.get("w", 3.0)
			var k2 := 0.0
			while k2 <= cw2:
				C(Vector3(-cw2 * 0.5 + k2, 1.25, 0), 0.025, 0.025, 2.5, metal, 5)
				k2 += 0.18
			B(Vector3(0, 2.5, 0), Vector3(cw2, 0.08, 0.08), metal)
			S(Vector3(0, 1.25, 0), Vector3(cw2, 2.5, 0.1))
		"bench":
			B(Vector3(0, 0.45, 0), Vector3(prm.get("w", 2.0), 0.06, 0.45), prm.get("col", wood))
			B(Vector3(-float(prm.get("w", 2.0)) * 0.45, 0.22, 0), Vector3(0.06, 0.45, 0.4), dark)
			B(Vector3(float(prm.get("w", 2.0)) * 0.45, 0.22, 0), Vector3(0.06, 0.45, 0.4), dark)
		"seats":
			var rows: int = prm.get("rows", 4)
			var cols: int = prm.get("cols", 8)
			for rr in rows:
				for cc in cols:
					var sx := -float(cols - 1) * 0.3 + float(cc) * 0.6
					var sz := float(rr) * 1.0
					B(Vector3(sx, 0.4 + float(rr) * 0.25, sz), Vector3(0.5, 0.1, 0.5), Color(0.45, 0.06, 0.08))
					B(Vector3(sx, 0.75 + float(rr) * 0.25, sz + 0.22), Vector3(0.5, 0.6, 0.08), Color(0.45, 0.06, 0.08))
				B(Vector3(0, float(rr) * 0.125, float(rr) * 1.0), Vector3(float(cols) * 0.6 + 0.4, float(rr) * 0.25 + 0.05, 1.0), Color(0.15, 0.1, 0.08))
				S(Vector3(0, 0.4 + float(rr) * 0.25, float(rr) * 1.0), Vector3(float(cols) * 0.6, 0.8, 0.6))
		"stage":
			B(Vector3(0, 0.5, 0), Vector3(prm.get("w", 8.0), 1.0, prm.get("d", 4.0)), Color(0.25, 0.16, 0.1))
			S(Vector3(0, 0.5, 0), Vector3(prm.get("w", 8.0), 1.0, prm.get("d", 4.0)))
		"tea_table":
			B(Vector3(0, 0.35, 0), Vector3(1.2, 0.06, 0.8), Color(0.2, 0.08, 0.05))
			B(Vector3(0, 0.17, 0), Vector3(1.0, 0.34, 0.6), Color(0.15, 0.06, 0.04))
			C(Vector3(0.2, 0.44, 0), 0.07, 0.08, 0.12, Color(0.85, 0.85, 0.8), 8)
			for sx in [-0.9, 0.9]:
				B(Vector3(sx, 0.08, 0), Vector3(0.5, 0.16, 0.5), Color(0.6, 0.1, 0.1))
			S(Vector3(0, 0.3, 0), Vector3(1.2, 0.6, 0.8))
		"lantern":
			_ctx.glow.sphere(_p + Vector3(0, float(prm.get("y", 2.4)), 0), 0.25, prm.get("col", Color(1.0, 0.2, 0.12)), 6, 4, Vector2(0, 0), 1.3)
			B(Vector3(0, float(prm.get("y", 2.4)) + 0.4, 0), Vector3(0.01, 0.5, 0.01), dark)
		"screen_fold":
			for k in 4:
				_ctx.props.box(_p + _bs * Vector3(-0.75 + float(k) * 0.5, 0.9, 0.1 * float(k % 2)), Vector3(0.48, 1.8, 0.03), Color(0.5, 0.1, 0.08), _r + (0.3 if k % 2 == 0 else -0.3))
			S(Vector3(0, 0.9, 0), Vector3(2.0, 1.8, 0.3))
		"clock":
			C(Vector3(0, float(prm.get("y", 2.0)), 0), 0.3, 0.3, 0.05, Color(0.85, 0.8, 0.6), 12)
			B(Vector3(0, float(prm.get("y", 2.0)) + 0.08, 0.03), Vector3(0.02, 0.18, 0.01), dark)
			B(Vector3(0.05, float(prm.get("y", 2.0)), 0.03), Vector3(0.12, 0.02, 0.01), dark)
		"grandfather_clock":
			B(Vector3(0, 1.0, 0), Vector3(0.6, 2.0, 0.4), Color(0.2, 0.1, 0.05))
			C(Vector3(0, 1.6, 0.21), 0.2, 0.2, 0.02, Color(0.85, 0.8, 0.6), 12)
			S(Vector3(0, 1.0, 0), Vector3(0.6, 2.0, 0.4))
		"tape_library":
			B(Vector3(0, 1.2, 0), Vector3(3.0, 2.4, 1.0), Color(0.15, 0.15, 0.17))
			for k in 20:
				G(Vector3(-1.35 + float(k % 10) * 0.3, 0.6 + float(k / 10) * 1.0, 0.51), Vector3(0.2, 0.6, 0.01), Color(0.3, 0.5, 0.9) if k % 3 else Color(0.2, 0.9, 0.4))
			S(Vector3(0, 1.2, 0), Vector3(3.0, 2.4, 1.0))
		"climate_unit":
			B(Vector3(0, 1.1, 0), Vector3(1.8, 2.2, 1.0), Color(0.55, 0.57, 0.6))
			B(Vector3(0, 1.4, 0.51), Vector3(1.4, 0.8, 0.02), dark)
			G(Vector3(-0.3, 1.5, 0.53), Vector3(0.5, 0.3, 0.01), Color(0.3, 1.0, 0.5))
			G(Vector3(0.4, 1.5, 0.53), Vector3(0.12, 0.12, 0.01), Color(1.0, 0.2, 0.2), 4.0)
			S(Vector3(0, 1.1, 0), Vector3(1.8, 2.2, 1.0))
		"security_desk":
			B(Vector3(0, 0.55, 0), Vector3(2.4, 1.1, 0.8), Color(0.3, 0.3, 0.32))
			for k in 3:
				B(Vector3(-0.8 + float(k) * 0.8, 1.4, -0.2), Vector3(0.6, 0.4, 0.05), dark)
				G(Vector3(-0.8 + float(k) * 0.8, 1.4, -0.17), Vector3(0.55, 0.35, 0.01), Color(0.4, 0.5, 0.6), 3.0)
			S(Vector3(0, 0.55, 0), Vector3(2.4, 1.1, 0.8))
		"subway_platform":
			pass
		"gun_rack":
			B(Vector3(0, 1.3, 0), Vector3(2.0, 1.6, 0.1), wood.darkened(0.3))
			for k in 5:
				B(Vector3(-0.8 + float(k) * 0.4, 1.3, 0.08), Vector3(0.06, 1.2, 0.06), dark)
		"display_case":
			B(Vector3(0, 0.45, 0), Vector3(prm.get("w", 2.0), 0.9, 0.6), Color(0.2, 0.18, 0.16))
			G(Vector3(0, 0.95, 0), Vector3(float(prm.get("w", 2.0)) - 0.1, 0.12, 0.5), Color(0.6, 0.7, 0.75))
			S(Vector3(0, 0.5, 0), Vector3(prm.get("w", 2.0), 1.0, 0.6))
		"altar":
			B(Vector3(0, 0.5, 0), Vector3(2.0, 1.0, 0.8), Color(0.3, 0.05, 0.05))
			for k in 5:
				_ctx.glow.cyl(_p + _bs * Vector3(-0.8 + float(k) * 0.4, 1.1, 0), 0.03, 0.03, 0.2, Color(1.0, 0.75, 0.3), 5, Vector2(3.0, float(k)))
			S(Vector3(0, 0.5, 0), Vector3(2.0, 1.0, 0.8))
		"piano":
			B(Vector3(0, 0.7, 0), Vector3(1.5, 1.4, 0.6), Color(0.04, 0.04, 0.05))
			B(Vector3(0, 0.75, 0.4), Vector3(1.4, 0.06, 0.3), Color(0.9, 0.9, 0.88))
			S(Vector3(0, 0.7, 0), Vector3(1.5, 1.4, 0.9))
		"safe":
			B(Vector3(0, 0.45, 0), Vector3(0.7, 0.9, 0.65), Color(0.16, 0.17, 0.18))
			B(Vector3(0, 0.45, 0.33), Vector3(0.6, 0.8, 0.02), Color(0.22, 0.23, 0.24))
			C(Vector3(0.05, 0.55, 0.35), 0.07, 0.07, 0.03, Color(0.75, 0.7, 0.5), 10)
			B(Vector3(0.22, 0.4, 0.36), Vector3(0.04, 0.16, 0.04), Color(0.7, 0.65, 0.45))
			S(Vector3(0, 0.45, 0), Vector3(0.7, 0.9, 0.65))
		"clothes_rack":
			var rw: float = prm.get("w", 1.6)
			B(Vector3(0, 1.5, 0), Vector3(rw, 0.04, 0.04), metal)
			for sx in [-1.0, 1.0]:
				B(Vector3(sx * rw * 0.5, 0.75, 0), Vector3(0.04, 1.5, 0.04), metal)
				B(Vector3(sx * rw * 0.5, 0.02, 0), Vector3(0.04, 0.04, 0.5), metal)
			var k3 := 0
			var cx := -rw * 0.5 + 0.12
			while cx < rw * 0.5 - 0.08:
				B(Vector3(cx, 1.05, 0), Vector3(0.06, 0.85, 0.42), [Color(0.1, 0.1, 0.12), Color(0.5, 0.1, 0.1), Color(0.15, 0.25, 0.45), Color(0.6, 0.55, 0.45), Color(0.2, 0.35, 0.2)][k3 % 5])
				cx += 0.11
				k3 += 1
			S(Vector3(0, 0.9, 0), Vector3(rw, 1.8, 0.5))
		"duffel":
			B(Vector3(0, 0.17, 0), Vector3(0.8, 0.34, 0.4), Color(0.1, 0.16, 0.1))
			B(Vector3(0, 0.36, 0), Vector3(0.5, 0.05, 0.06), Color(0.05, 0.05, 0.05))
		"trash":
			C(Vector3(0, 0.3, 0), 0.2, 0.17, 0.6, Color(0.25, 0.27, 0.28), 10)
			C(Vector3(0, 0.61, 0), 0.21, 0.21, 0.03, Color(0.2, 0.21, 0.22), 10)
			S(Vector3(0, 0.3, 0), Vector3(0.4, 0.6, 0.4))
		"container_a", "container_b":
			# A 20-foot shipping container, long axis along x.
			var cc: Color = Color(0.55, 0.18, 0.12) if type == "container_a" else Color(0.15, 0.3, 0.45)
			B(Vector3(0, 1.3, 0), Vector3(6.0, 2.6, 2.4), cc)
			for rib in 11:
				B(Vector3(-2.7 + float(rib) * 0.54, 1.3, 1.21), Vector3(0.08, 2.4, 0.02), cc.darkened(0.25))
				B(Vector3(-2.7 + float(rib) * 0.54, 1.3, -1.21), Vector3(0.08, 2.4, 0.02), cc.darkened(0.25))
			B(Vector3(3.01, 1.3, 0), Vector3(0.02, 2.5, 2.3), cc.darkened(0.35))
			for bar in [-0.5, 0.5]:
				B(Vector3(3.03, 1.3, bar), Vector3(0.03, 2.3, 0.05), metal)
			S(Vector3(0, 1.3, 0), Vector3(6.0, 2.6, 2.4))
		"mailbox":
			# A wall bank of brass tenant mailboxes (front faces +z).
			B(Vector3(0, 1.3, 0), Vector3(0.9, 0.9, 0.16), Color(0.45, 0.38, 0.22))
			for mr in 3:
				for mc in 3:
					B(Vector3(-0.28 + float(mc) * 0.28, 1.02 + float(mr) * 0.28, 0.085), Vector3(0.24, 0.22, 0.01), Color(0.62, 0.52, 0.3))
					B(Vector3(-0.2 + float(mc) * 0.28, 1.02 + float(mr) * 0.28, 0.092), Vector3(0.03, 0.03, 0.01), Color(0.15, 0.12, 0.08))
			S(Vector3(0, 1.3, 0), Vector3(0.9, 0.9, 0.16))
		"stairs_up":
			# A flight of stairs climbing toward -z, with a rail.
			for st in 8:
				B(Vector3(0, 0.1 + float(st) * 0.2, 1.4 - float(st) * 0.3), Vector3(1.1, 0.2, 0.3), Color(0.5, 0.48, 0.44))
				B(Vector3(0, float(st) * 0.1 + 0.05, 1.4 - float(st) * 0.3), Vector3(1.1, 0.1 + float(st) * 0.2, 0.3), Color(0.42, 0.4, 0.37))
			B(Vector3(0.58, 1.3, 0.35), Vector3(0.04, 0.04, 2.6), metal)
			for rp in 4:
				B(Vector3(0.58, 0.7 + float(rp) * 0.4, 1.3 - float(rp) * 0.7), Vector3(0.04, 0.9, 0.04), metal)
			S(Vector3(0, 0.8, 0.35), Vector3(1.2, 1.6, 2.6))
		"ac_unit":
			B(Vector3(0, 0.6, 0), Vector3(1.4, 1.2, 1.0), Color(0.62, 0.63, 0.62))
			C(Vector3(0, 1.21, 0), 0.4, 0.4, 0.04, dark, 12)
			for fin in 6:
				B(Vector3(-0.5 + float(fin) * 0.2, 0.6, 0.51), Vector3(0.12, 0.9, 0.01), Color(0.35, 0.36, 0.36))
			S(Vector3(0, 0.6, 0), Vector3(1.4, 1.2, 1.0))
		"lab_bench":
			# A folding table covered in scales, bags and glassware.
			B(Vector3(0, 0.74, 0), Vector3(2.0, 0.05, 0.9), Color(0.55, 0.56, 0.55))
			for lx in [-0.9, 0.9]:
				for lz in [-0.38, 0.38]:
					B(Vector3(lx, 0.36, lz), Vector3(0.04, 0.72, 0.04), metal)
			B(Vector3(-0.6, 0.82, 0.1), Vector3(0.3, 0.1, 0.25), Color(0.2, 0.2, 0.22))
			for bg in 5:
				B(Vector3(-0.1 + float(bg) * 0.15, 0.79, -0.15 + float(bg % 2) * 0.2), Vector3(0.1, 0.04, 0.14), Color(0.92, 0.9, 0.86))
			C(Vector3(0.7, 0.88, 0.2), 0.06, 0.08, 0.22, Color(0.7, 0.85, 0.8), 8)
			C(Vector3(0.55, 0.85, -0.2), 0.05, 0.05, 0.16, Color(0.8, 0.75, 0.6), 8)
			S(Vector3(0, 0.4, 0), Vector3(2.0, 0.8, 0.9))
		"drums":
			for di in 3:
				C(Vector3(-0.6 + float(di) * 0.62, 0.45, 0), 0.29, 0.29, 0.9, [Color(0.2, 0.3, 0.5), Color(0.5, 0.15, 0.1), Color(0.25, 0.3, 0.2)][di], 10)
			S(Vector3(0, 0.45, 0), Vector3(1.9, 0.9, 0.6))
		"candles":
			# A street memorial: candles, flowers, a photo on the wall.
			for ci in 9:
				var ca := float(ci) * 0.7
				C(Vector3(cos(ca) * (0.2 + float(ci % 3) * 0.12), 0.08 + float(ci % 2) * 0.05, sin(ca) * 0.25), 0.04, 0.04, 0.16 + float(ci % 2) * 0.1, Color(0.9, 0.85, 0.7), 6)
				G(Vector3(cos(ca) * (0.2 + float(ci % 3) * 0.12), 0.22 + float(ci % 2) * 0.1, sin(ca) * 0.25), Vector3(0.03, 0.05, 0.03), Color(1.0, 0.7, 0.3), 0.0)
			B(Vector3(0, 1.3, -0.3), Vector3(0.4, 0.5, 0.02), Color(0.85, 0.82, 0.75))
			B(Vector3(0.3, 0.15, 0.2), Vector3(0.3, 0.1, 0.2), Color(0.8, 0.2, 0.3))
		"trophies":
			B(Vector3(0, 0.9, 0), Vector3(1.4, 1.8, 0.35), Color(0.3, 0.22, 0.14))
			for ti in 4:
				C(Vector3(-0.5 + float(ti) * 0.33, 1.5, 0.05), 0.06, 0.04, 0.25, Color(0.85, 0.7, 0.3), 8)
				C(Vector3(-0.5 + float(ti) * 0.33, 0.95, 0.05), 0.05, 0.05, 0.2, Color(0.75, 0.75, 0.78), 8)
			S(Vector3(0, 0.9, 0), Vector3(1.4, 1.8, 0.35))
		"mannequin":
			C(Vector3(0, 0.02, 0), 0.2, 0.2, 0.04, dark, 8)
			C(Vector3(0, 0.55, 0), 0.03, 0.03, 1.1, metal, 6)
			B(Vector3(0, 1.3, 0), Vector3(0.42, 0.6, 0.24), prm.get("col", Color(0.2, 0.2, 0.25)))
			_ctx.props.sphere(_p + Vector3(0, 1.75, 0), 0.12, Color(0.85, 0.82, 0.78), 6, 4)


static func build_chair_at(ctx: BuildCtx, pos: Vector3, rot: float, col: Color) -> void:
	var bs := Basis(Vector3.UP, rot)
	ctx.props.box(pos + bs * Vector3(0, 0.45, 0), Vector3(0.45, 0.06, 0.45), col, rot)
	ctx.props.box(pos + bs * Vector3(0, 0.75, -0.2), Vector3(0.45, 0.55, 0.05), col, rot)
	for sx in [-0.19, 0.19]:
		for sz in [-0.19, 0.19]:
			ctx.props.box(pos + bs * Vector3(sx, 0.22, sz), Vector3(0.04, 0.45, 0.04), Color(0.08, 0.08, 0.08), rot)
