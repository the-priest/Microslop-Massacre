class_name InteriorBuilder
extends RefCounted
## Builds an interior "cell" from InteriorData at a far-away origin.
## Rooms are rectangles; walls are inset so neighbouring rooms never share a
## coplanar face; doorways cut gaps into any wall they touch.

const WALL_T := 0.16
const DOOR_H := 2.25


static func origin_for(index: int) -> Vector3:
	return Vector3(20000.0 + float(index % 10) * 300.0, 0.0, 20000.0 + float(index / 10) * 300.0)


static func build(id: String, def: Dictionary, origin: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "Interior_" + id.replace(":", "_")
	root.position = origin
	var ctx := BuildCtx.new()
	var rooms: Array = def.get("rooms", [])
	var doors: Array = def.get("doors", [])
	var exits: Array = def.get("exits", [])
	for r in rooms:
		_room(ctx, root, r, doors, exits)
	for f in def.get("furn", []):
		var fa: Array = f
		var prm: Dictionary = fa[4] if fa.size() > 4 and fa[4] is Dictionary else {}
		Furniture.build(ctx, str(fa[0]), Vector3(float(fa[1]), 0.0, float(fa[2])), deg_to_rad(float(fa[3])) if fa.size() > 3 else 0.0, prm)
	# Exit doors (visual; interactables are added by the Game). Drawn on the
	# wall's INNER face (walls are WALL_T thick) so they're actually visible:
	# frame, door leaf, handle, a lit EXIT sign with the destination, a mat.
	for e in exits:
		var ed: Dictionary = e
		var p: Array = ed["pos"]
		var out := WorldLayout.face_normal(str(ed.get("face", "s")))
		var dp := Vector3(float(p[0]), 0, float(p[1]))
		var rot := atan2(out.x, out.z) + PI # the door faces into the room
		var bs := Basis(Vector3.UP, rot)
		var face := dp - out * (WALL_T + 0.004)
		var at := func(x: float, y: float, z: float) -> Vector3: return face + bs * Vector3(x, y, z)
		var E := Vector2(0, 0.25)
		var trim := Color(0.78, 0.74, 0.66)
		for sx in [-0.72, 0.72]:
			ctx.props.box(at.call(sx, 1.18, 0.05), Vector3(0.14, 2.36, 0.1), trim, rot, E)
		ctx.props.box(at.call(0, 2.4, 0.05), Vector3(1.58, 0.14, 0.1), trim, rot, E)
		ctx.props.box(at.call(0, 1.12, 0.03), Vector3(1.3, 2.24, 0.05), Color(0.48, 0.32, 0.19), rot, Vector2(0, 0.18))
		ctx.props.box(at.call(-0.27, 1.55, 0.06), Vector3(0.46, 0.8, 0.02), Color(0.4, 0.26, 0.15), rot)
		ctx.props.box(at.call(0.27, 1.55, 0.06), Vector3(0.46, 0.8, 0.02), Color(0.4, 0.26, 0.15), rot)
		ctx.props.box(at.call(-0.27, 0.55, 0.06), Vector3(0.46, 0.7, 0.02), Color(0.4, 0.26, 0.15), rot)
		ctx.props.box(at.call(0.27, 0.55, 0.06), Vector3(0.46, 0.7, 0.02), Color(0.4, 0.26, 0.15), rot)
		ctx.props.box(at.call(0.5, 1.05, 0.09), Vector3(0.06, 0.22, 0.06), Color(0.92, 0.76, 0.36), rot, Vector2(0, 0.7))
		# Lit EXIT sign and where it goes.
		ctx.props.box(at.call(0, 2.72, 0.06), Vector3(0.7, 0.26, 0.1), Color(0.1, 0.1, 0.1), rot)
		ctx.glow.box(at.call(0, 2.72, 0.115), Vector3(0.62, 0.2, 0.01), Color(0.25, 1.0, 0.45), rot, Vector2(0, 0))
		ctx.label(at.call(0, 2.72, 0.13), "EXIT", 48, Color(0.05, 0.2, 0.08), rot, 60.0, 0.006)
		var dest := str(ed.get("label", "Exit")).to_upper()
		if dest != "EXIT":
			ctx.label(at.call(0, 2.98, 0.08), dest, 40, Color(0.9, 0.95, 0.9), rot, 40.0, 0.006)
		# Doormat.
		ctx.props.box(at.call(0, 0.012, 0.75), Vector3(1.1, 0.02, 0.7), Color(0.3, 0.2, 0.14), rot)
	ctx.commit(root, 200.0, 200.0, true)
	# Room lights.
	for r in rooms:
		var rd: Dictionary = r
		var rr: Array = rd["r"]
		var h := float(rd.get("h", 3.0))
		var lc: Color = rd.get("light", Color(1.0, 0.85, 0.65))
		var en := float(rd.get("energy", 1.0))
		var lights: Array = rd.get("lights", [])
		if lights.is_empty():
			lights = [[(float(rr[0]) + float(rr[2])) * 0.5, h - 0.4, (float(rr[1]) + float(rr[3])) * 0.5]]
		var span := maxf(float(rr[2]) - float(rr[0]), float(rr[3]) - float(rr[1]))
		for l in lights:
			var la: Array = l
			if en <= 0.0:
				continue
			var ol := OmniLight3D.new()
			ol.position = Vector3(float(la[0]), float(la[1]), float(la[2]))
			ol.light_color = lc
			ol.light_energy = en
			ol.omni_range = clampf(span * 0.9, 7.0, 22.0)
			ol.omni_attenuation = 0.6
			ol.shadow_enabled = false
			root.add_child(ol)
	return root


static func _room(ctx: BuildCtx, root: Node3D, rd: Dictionary, doors: Array, exits: Array) -> void:
	var r: Array = rd["r"]
	var x0 := float(r[0])
	var z0 := float(r[1])
	var x1 := float(r[2])
	var z1 := float(r[3])
	var h := float(rd.get("h", 3.0))
	var wall: Color = rd.get("wall", Color(0.45, 0.42, 0.38))
	var flo: Color = rd.get("floor", Color(0.3, 0.22, 0.15))
	var ceil_c: Color = rd.get("ceil", Color(0.55, 0.55, 0.53))
	var cx := (x0 + x1) * 0.5
	var cz := (z0 + z1) * 0.5
	var w := x1 - x0
	var d := z1 - z0
	# Floor + plank/tile lines.
	ctx.props.box(Vector3(cx, -0.05, cz), Vector3(w, 0.1, d), flo, 0.0, Vector2(1, 0), 1)
	var fk := str(rd.get("floor_kind", "plank"))
	if fk == "plank":
		var x := x0 + 0.9
		while x < x1:
			ctx.props.flat(Vector3(x, 0.004, cz), 0.03, d, flo.darkened(0.25))
			x += 0.9
	elif fk == "tile":
		var tx := x0 + 1.0
		while tx < x1:
			ctx.props.flat(Vector3(tx, 0.004, cz), 0.03, d, flo.darkened(0.2))
			tx += 1.0
		var tz := z0 + 1.0
		while tz < z1:
			ctx.props.flat(Vector3(cx, 0.004, tz), w, 0.03, flo.darkened(0.2))
			tz += 1.0
	ctx.solid(Vector3(cx, -0.25, cz), Vector3(w, 0.5, d))
	# Ceiling.
	if not bool(rd.get("open_sky", false)):
		ctx.props.box(Vector3(cx, h + 0.05, cz), Vector3(w, 0.1, d), ceil_c, 0.0, Vector2.ZERO, 2)
	# Four walls, inset by half thickness.
	var t := WALL_T
	# North (z0) and south (z1): along X.
	_wall_x(ctx, x0, x1, z0 + t * 0.5, h, wall, doors, exits, Vector3.BACK)
	_wall_x(ctx, x0, x1, z1 - t * 0.5, h, wall, doors, exits, Vector3.FORWARD)
	_wall_z(ctx, z0, z1, x0 + t * 0.5, h, wall.darkened(0.06), doors, exits, Vector3.RIGHT)
	_wall_z(ctx, z0, z1, x1 - t * 0.5, h, wall.darkened(0.06), doors, exits, Vector3.LEFT)
	# Baseboards.
	var trim: Color = rd.get("trim", wall.darkened(0.4))
	ctx.props.box(Vector3(cx, 0.06, z0 + t + 0.01), Vector3(w - t * 2.0, 0.12, 0.02), trim)
	ctx.props.box(Vector3(cx, 0.06, z1 - t - 0.01), Vector3(w - t * 2.0, 0.12, 0.02), trim)
	# Ceiling light fixtures (glow).
	var lights: Array = rd.get("lights", [])
	if lights.is_empty():
		lights = [[cx, h - 0.4, cz]]
	if float(rd.get("energy", 1.0)) > 0.0 and not bool(rd.get("open_sky", false)):
		for l in lights:
			var la: Array = l
			ctx.glow.box(Vector3(float(la[0]), h - 0.03, float(la[2])), Vector3(0.6, 0.04, 0.6), rd.get("light", Color(1.0, 0.85, 0.65)), 0.0, Vector2(0, 0))


static func _gaps_on_x(z: float, x0: float, x1: float, doors: Array, exits: Array) -> Array:
	# Returns [[a, b, is_exit]] gaps along X for a wall at z.
	var out: Array = []
	for dd in doors:
		var da: Array = dd
		var px := float(da[0])
		var pz := float(da[1])
		var dw := float(da[2]) if da.size() > 2 else 1.2
		if absf(pz - z) < 0.5 and px > x0 and px < x1:
			out.append([px - dw * 0.5, px + dw * 0.5])
	return out


static func _gaps_on_z(x: float, z0: float, z1: float, doors: Array, exits: Array) -> Array:
	var out: Array = []
	for dd in doors:
		var da: Array = dd
		var px := float(da[0])
		var pz := float(da[1])
		var dw := float(da[2]) if da.size() > 2 else 1.2
		if absf(px - x) < 0.5 and pz > z0 and pz < z1:
			out.append([pz - dw * 0.5, pz + dw * 0.5])
	return out


static func _wall_x(ctx: BuildCtx, x0: float, x1: float, z: float, h: float, col: Color, doors: Array, exits: Array, n: Vector3) -> void:
	var gaps := _gaps_on_x(z, x0, x1, doors, exits)
	gaps.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var cur := x0
	for g in gaps:
		var a := float(g[0])
		var b := float(g[1])
		if a > cur:
			_wall_seg(ctx, Vector3((cur + a) * 0.5, h * 0.5, z), Vector3(a - cur, h, WALL_T), col)
		# Header over the doorway.
		_wall_seg(ctx, Vector3((a + b) * 0.5, (DOOR_H + h) * 0.5, z), Vector3(b - a, h - DOOR_H, WALL_T), col)
		ctx.props.box(Vector3(a, DOOR_H * 0.5, z), Vector3(0.08, DOOR_H, WALL_T + 0.06), col.darkened(0.4))
		ctx.props.box(Vector3(b, DOOR_H * 0.5, z), Vector3(0.08, DOOR_H, WALL_T + 0.06), col.darkened(0.4))
		cur = b
	if cur < x1:
		_wall_seg(ctx, Vector3((cur + x1) * 0.5, h * 0.5, z), Vector3(x1 - cur, h, WALL_T), col)


static func _wall_z(ctx: BuildCtx, z0: float, z1: float, x: float, h: float, col: Color, doors: Array, exits: Array, n: Vector3) -> void:
	var gaps := _gaps_on_z(x, z0, z1, doors, exits)
	gaps.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var cur := z0
	for g in gaps:
		var a := float(g[0])
		var b := float(g[1])
		if a > cur:
			_wall_seg(ctx, Vector3(x, h * 0.5, (cur + a) * 0.5), Vector3(WALL_T, h, a - cur), col)
		_wall_seg(ctx, Vector3(x, (DOOR_H + h) * 0.5, (a + b) * 0.5), Vector3(WALL_T, h - DOOR_H, b - a), col)
		ctx.props.box(Vector3(x, DOOR_H * 0.5, a), Vector3(WALL_T + 0.06, DOOR_H, 0.08), col.darkened(0.4))
		ctx.props.box(Vector3(x, DOOR_H * 0.5, b), Vector3(WALL_T + 0.06, DOOR_H, 0.08), col.darkened(0.4))
		cur = b
	if cur < z1:
		_wall_seg(ctx, Vector3(x, h * 0.5, (cur + z1) * 0.5), Vector3(WALL_T, h, z1 - cur), col)


static func _wall_seg(ctx: BuildCtx, c: Vector3, s: Vector3, col: Color) -> void:
	if s.x <= 0.01 or s.y <= 0.01 or s.z <= 0.01:
		return
	ctx.props.box(c, s, col, 0.0, Vector2.ZERO, 61, false)
	ctx.solid(c, s)


## Where the player stands after coming in through exit `i`.
static func exit_spawn(def: Dictionary, i: int) -> Dictionary:
	var exits: Array = def.get("exits", [])
	if exits.is_empty():
		return {"pos": Vector3(0, 0, 0), "yaw": 0.0}
	var e: Dictionary = exits[clampi(i, 0, exits.size() - 1)]
	var p: Array = e["pos"]
	var out := WorldLayout.face_normal(str(e.get("face", "s")))
	var pos := Vector3(float(p[0]), 0.0, float(p[1])) - out * 1.3
	return {"pos": pos, "yaw": atan2(out.x, out.z)}
