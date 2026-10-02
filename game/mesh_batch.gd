class_name MeshBatch
extends RefCounted
## MeshBatch — accumulates colored primitives into one ArrayMesh surface so a
## whole city chunk (or room) renders in a single draw call per material.
## Vertex color = albedo (sRGB). UV = facade meters. UV2 = shader-specific data.

var verts := PackedVector3Array()
var norms := PackedVector3Array()
var cols := PackedColorArray()
var uvs := PackedVector2Array()
var uv2s := PackedVector2Array()
var idx := PackedInt32Array()


func is_empty() -> bool:
	return idx.is_empty()


func vcount() -> int:
	return verts.size()


func clear() -> void:
	verts = PackedVector3Array()
	norms = PackedVector3Array()
	cols = PackedColorArray()
	uvs = PackedVector2Array()
	uv2s = PackedVector2Array()
	idx = PackedInt32Array()


## Quad a-b-c-d counter-clockwise when seen from the front (normal side).
func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, col: Color,
		uv_a: Vector2 = Vector2.ZERO, uv_c: Vector2 = Vector2.ONE, uv2: Vector2 = Vector2.ZERO) -> void:
	var base := verts.size()
	verts.append(a)
	verts.append(b)
	verts.append(c)
	verts.append(d)
	for i in 4:
		norms.append(n)
		cols.append(col)
		uv2s.append(uv2)
	uvs.append(Vector2(uv_a.x, uv_a.y))
	uvs.append(Vector2(uv_c.x, uv_a.y))
	uvs.append(Vector2(uv_c.x, uv_c.y))
	uvs.append(Vector2(uv_a.x, uv_c.y))
	# Godot front faces are clockwise in screen space -> wind a,c,b / a,d,c
	idx.append(base)
	idx.append(base + 2)
	idx.append(base + 1)
	idx.append(base)
	idx.append(base + 3)
	idx.append(base + 2)


func tri(a: Vector3, b: Vector3, c: Vector3, n: Vector3, col: Color, uv2: Vector2 = Vector2.ZERO) -> void:
	var base := verts.size()
	verts.append(a)
	verts.append(b)
	verts.append(c)
	for i in 3:
		norms.append(n)
		cols.append(col)
		uvs.append(Vector2.ZERO)
		uv2s.append(uv2)
	idx.append(base)
	idx.append(base + 2)
	idx.append(base + 1)


## Axis-aligned (optionally rotated) box. faces bitmask: 1 top, 2 bottom,
## 4 +x, 8 -x, 16 +z, 32 -z. Default: all but bottom.
func box(center: Vector3, size: Vector3, col: Color, rot_y: float = 0.0, uv2: Vector2 = Vector2.ZERO,
		faces: int = 61, shade: bool = true) -> void:
	var h := size * 0.5
	var bs := Basis(Vector3.UP, rot_y) if rot_y != 0.0 else Basis.IDENTITY
	var p := func(x: float, y: float, z: float) -> Vector3: return center + bs * Vector3(x, y, z)
	# Subtle per-face shading so boxes read even in flat ambient light.
	var ct := col
	var cs := col.darkened(0.12) if shade else col
	var cb := col.darkened(0.25) if shade else col
	if faces & 1:
		quad(p.call(-h.x, h.y, h.z), p.call(h.x, h.y, h.z), p.call(h.x, h.y, -h.z), p.call(-h.x, h.y, -h.z), bs * Vector3.UP, ct, Vector2.ZERO, Vector2(size.x, size.z), uv2)
	if faces & 2:
		quad(p.call(-h.x, -h.y, -h.z), p.call(h.x, -h.y, -h.z), p.call(h.x, -h.y, h.z), p.call(-h.x, -h.y, h.z), bs * Vector3.DOWN, cb, Vector2.ZERO, Vector2(size.x, size.z), uv2)
	if faces & 16:
		quad(p.call(-h.x, -h.y, h.z), p.call(h.x, -h.y, h.z), p.call(h.x, h.y, h.z), p.call(-h.x, h.y, h.z), bs * Vector3.BACK, cs, Vector2.ZERO, Vector2(size.x, size.y), uv2)
	if faces & 32:
		quad(p.call(h.x, -h.y, -h.z), p.call(-h.x, -h.y, -h.z), p.call(-h.x, h.y, -h.z), p.call(h.x, h.y, -h.z), bs * Vector3.FORWARD, cs, Vector2.ZERO, Vector2(size.x, size.y), uv2)
	if faces & 4:
		quad(p.call(h.x, -h.y, h.z), p.call(h.x, -h.y, -h.z), p.call(h.x, h.y, -h.z), p.call(h.x, h.y, h.z), bs * Vector3.RIGHT, cb, Vector2.ZERO, Vector2(size.z, size.y), uv2)
	if faces & 8:
		quad(p.call(-h.x, -h.y, -h.z), p.call(-h.x, -h.y, h.z), p.call(-h.x, h.y, h.z), p.call(-h.x, h.y, -h.z), bs * Vector3.LEFT, cb, Vector2.ZERO, Vector2(size.z, size.y), uv2)


## Box under an arbitrary transform (for tilted parts: ramps, fallen things).
func box_xf(xf: Transform3D, size: Vector3, col: Color, uv2: Vector2 = Vector2.ZERO) -> void:
	var h := size * 0.5
	var corners := [
		Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, h.z), Vector3(-h.x, -h.y, h.z),
		Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z),
	]
	var w: Array = []
	for c in corners:
		w.append(xf * c)
	var b := xf.basis.orthonormalized()
	quad(w[7], w[6], w[5], w[4], b * Vector3.UP, col, Vector2.ZERO, Vector2.ONE, uv2)
	quad(w[3], w[2], w[6], w[7], b * Vector3.BACK, col.darkened(0.12), Vector2.ZERO, Vector2.ONE, uv2)
	quad(w[1], w[0], w[4], w[5], b * Vector3.FORWARD, col.darkened(0.12), Vector2.ZERO, Vector2.ONE, uv2)
	quad(w[2], w[1], w[5], w[6], b * Vector3.RIGHT, col.darkened(0.22), Vector2.ZERO, Vector2.ONE, uv2)
	quad(w[0], w[3], w[7], w[4], b * Vector3.LEFT, col.darkened(0.22), Vector2.ZERO, Vector2.ONE, uv2)
	quad(w[0], w[1], w[2], w[3], b * Vector3.DOWN, col.darkened(0.3), Vector2.ZERO, Vector2.ONE, uv2)


## Vertical cylinder (low poly). center = middle of the cylinder.
func cyl(center: Vector3, r_top: float, r_bot: float, height: float, col: Color, seg: int = 8,
		uv2: Vector2 = Vector2.ZERO, caps: bool = true) -> void:
	var y0 := center.y - height * 0.5
	var y1 := center.y + height * 0.5
	for i in seg:
		var a0 := TAU * float(i) / float(seg)
		var a1 := TAU * float(i + 1) / float(seg)
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		var n := (d0 + d1).normalized()
		var shade := col.darkened(0.18 * (0.5 + 0.5 * sin(a0 + 0.7)))
		quad(Vector3(center.x, y0, center.z) + d1 * r_bot, Vector3(center.x, y0, center.z) + d0 * r_bot,
			Vector3(center.x, y1, center.z) + d0 * r_top, Vector3(center.x, y1, center.z) + d1 * r_top, n, shade,
			Vector2.ZERO, Vector2.ONE, uv2)
		if caps and r_top > 0.001:
			tri(Vector3(center.x, y1, center.z), Vector3(center.x, y1, center.z) + d1 * r_top,
				Vector3(center.x, y1, center.z) + d0 * r_top, Vector3.UP, col, uv2)


## Cylinder along an arbitrary axis from a to b.
func tube(a: Vector3, b: Vector3, r: float, col: Color, seg: int = 6, uv2: Vector2 = Vector2.ZERO) -> void:
	var axis := b - a
	var L := axis.length()
	if L < 0.0001:
		return
	var up := axis / L
	var side := up.cross(Vector3.UP)
	if side.length() < 0.01:
		side = up.cross(Vector3.RIGHT)
	side = side.normalized()
	var fwd := side.cross(up).normalized()
	for i in seg:
		var a0 := TAU * float(i) / float(seg)
		var a1 := TAU * float(i + 1) / float(seg)
		var d0 := side * cos(a0) + fwd * sin(a0)
		var d1 := side * cos(a1) + fwd * sin(a1)
		quad(a + d0 * r, a + d1 * r, b + d1 * r, b + d0 * r, (d0 + d1).normalized(), col.darkened(0.15 * float(i % 2)), Vector2.ZERO, Vector2.ONE, uv2)


func sphere(center: Vector3, r: float, col: Color, seg: int = 8, rings: int = 5, uv2: Vector2 = Vector2.ZERO, squash: float = 1.0) -> void:
	for j in rings:
		var t0 := PI * float(j) / float(rings)
		var t1 := PI * float(j + 1) / float(rings)
		for i in seg:
			var a0 := TAU * float(i) / float(seg)
			var a1 := TAU * float(i + 1) / float(seg)
			var p00 := Vector3(sin(t0) * cos(a0), cos(t0) * squash, sin(t0) * sin(a0))
			var p01 := Vector3(sin(t0) * cos(a1), cos(t0) * squash, sin(t0) * sin(a1))
			var p10 := Vector3(sin(t1) * cos(a0), cos(t1) * squash, sin(t1) * sin(a0))
			var p11 := Vector3(sin(t1) * cos(a1), cos(t1) * squash, sin(t1) * sin(a1))
			var n := (p00 + p01 + p10 + p11).normalized()
			var c := col.darkened(0.2 * float(j) / float(rings))
			quad(center + p10 * r, center + p11 * r, center + p01 * r, center + p00 * r, n, c, Vector2.ZERO, Vector2.ONE, uv2)


## Flat horizontal quad (decals, markings, light pools).
func flat(center: Vector3, sx: float, sz: float, col: Color, rot_y: float = 0.0, uv2: Vector2 = Vector2.ZERO) -> void:
	var bs := Basis(Vector3.UP, rot_y)
	var a := center + bs * Vector3(-sx * 0.5, 0, sz * 0.5)
	var b := center + bs * Vector3(sx * 0.5, 0, sz * 0.5)
	var c := center + bs * Vector3(sx * 0.5, 0, -sz * 0.5)
	var d := center + bs * Vector3(-sx * 0.5, 0, -sz * 0.5)
	quad(a, b, c, d, Vector3.UP, col, Vector2.ZERO, Vector2(1, 1), uv2)


## Vertical sign plate facing +Z rotated by rot_y.
func panel(center: Vector3, w: float, h: float, col: Color, rot_y: float = 0.0, uv2: Vector2 = Vector2.ZERO) -> void:
	var bs := Basis(Vector3.UP, rot_y)
	var n := bs * Vector3.BACK
	var a := center + bs * Vector3(-w * 0.5, -h * 0.5, 0)
	var b := center + bs * Vector3(w * 0.5, -h * 0.5, 0)
	var c := center + bs * Vector3(w * 0.5, h * 0.5, 0)
	var d := center + bs * Vector3(-w * 0.5, h * 0.5, 0)
	quad(a, b, c, d, n, col, Vector2.ZERO, Vector2(w, h), uv2)


## Append another batch (with an optional transform).
func merge(other: MeshBatch, xf: Transform3D = Transform3D.IDENTITY) -> void:
	var base := verts.size()
	var nb := xf.basis.orthonormalized()
	for i in other.verts.size():
		verts.append(xf * other.verts[i])
		norms.append(nb * other.norms[i])
	cols.append_array(other.cols)
	uvs.append_array(other.uvs)
	uv2s.append_array(other.uv2s)
	for i in other.idx:
		idx.append(base + i)


func to_mesh() -> ArrayMesh:
	var am := ArrayMesh.new()
	if idx.is_empty():
		return am
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_TEX_UV2] = uv2s
	arrays[Mesh.ARRAY_INDEX] = idx
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return am


func commit(parent: Node, material: Material, vis_end: float = 0.0, name: String = "") -> MeshInstance3D:
	if idx.is_empty():
		return null
	var mi := MeshInstance3D.new()
	if name != "":
		mi.name = name
	mi.mesh = to_mesh()
	mi.material_override = material
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if vis_end > 0.0:
		mi.visibility_range_end = vis_end
		mi.visibility_range_end_margin = 20.0
		mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	parent.add_child(mi)
	return mi
