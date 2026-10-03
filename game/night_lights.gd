class_name NightLights
extends Node
## Streetlamps that actually light the street. The nearest 16 lamps to the
## camera are handed to the world shaders (lamps.gdshaderinc) as point lights:
## one pass, no extra draw calls, so it costs the same on an iGPU as nothing.
## Light pools on the pavement are only a painted circle; this lights walls,
## parked cars and people walking under the lamp.

const MAX := 16
const CELL := 40.0
const HEAD_Y := 5.2
const REACH := 70.0

var _grid: Dictionary = {} # Vector2i -> Array of [Vector3 head, range, Color linear]
var _mats: Array = []
var _t: float = 0.0
var _off: bool = true


func setup(points: Array) -> void:
	_grid.clear()
	for p in points:
		var pos: Vector3 = p[0]
		var rad := float(p[1])
		var col: Color = p[2]
		# Floodlights (big pools) sit higher and reach further.
		var head := Vector3(pos.x, HEAD_Y if rad < 9.0 else 9.0, pos.z)
		var rng := clampf(rad * 2.3, 9.0, 30.0)
		var k := Vector2i(int(floor(pos.x / CELL)), int(floor(pos.z / CELL)))
		if not _grid.has(k):
			_grid[k] = []
		(_grid[k] as Array).append([head, rng, col.srgb_to_linear()])
	_mats = [Mats.facade, Mats.lit, Mats.city_lit, Mats.npc]


func _process(delta: float) -> void:
	_t -= delta
	if _t > 0.0:
		return
	_t = 0.15
	var game := get_parent()
	var cam := get_viewport().get_camera_3d()
	var night := Mats.night
	var interior: bool = game != null and game.get("env_ctl") != null and game.env_ctl.interior
	var bright := float(Settings.get_v("night_bright"))
	if cam == null or night < 0.08 or interior:
		_clear()
		return
	for m in _mats:
		(m as ShaderMaterial).set_shader_parameter("night_lift", night * lerpf(0.4, 1.6, bright))
	var cp := cam.global_position
	var near: Array = []
	var kx := int(floor(cp.x / CELL))
	var kz := int(floor(cp.z / CELL))
	var span := int(ceil(REACH / CELL))
	for dx in range(-span, span + 1):
		for dz in range(-span, span + 1):
			var cell: Array = _grid.get(Vector2i(kx + dx, kz + dz), [])
			for L in cell:
				var d2 := Vector2((L[0] as Vector3).x - cp.x, (L[0] as Vector3).z - cp.z).length_squared()
				if d2 < REACH * REACH:
					near.append([d2, L])
	near.sort_custom(func(a, b): return float(a[0]) < float(b[0]))
	var energy := night * lerpf(0.9, 2.4, bright)
	var pos := PackedVector4Array()
	var col := PackedVector4Array()
	# The Low preset lights the nearest eight; everything else, sixteen.
	var cap := 8 if int(Settings.get_v("detail")) == 0 else MAX
	var n := mini(near.size(), cap)
	for i in MAX:
		if i < n:
			var L: Array = near[i][1]
			var h: Vector3 = L[0]
			# The farthest of the sixteen fade out so lamps don't pop.
			var fade := 1.0 - smoothstep(REACH * 0.7, REACH, sqrt(float(near[i][0])))
			var c: Color = L[2]
			pos.append(Vector4(h.x, h.y, h.z, float(L[1])))
			col.append(Vector4(c.r * energy * fade, c.g * energy * fade, c.b * energy * fade, 0.0))
		else:
			pos.append(Vector4.ZERO)
			col.append(Vector4.ZERO)
	for m in _mats:
		(m as ShaderMaterial).set_shader_parameter("lamp_pos", pos)
		(m as ShaderMaterial).set_shader_parameter("lamp_col", col)
		(m as ShaderMaterial).set_shader_parameter("lamp_n", n)
	_off = false


func _clear() -> void:
	if _off:
		return
	_off = true
	for m in _mats:
		(m as ShaderMaterial).set_shader_parameter("lamp_n", 0)
		(m as ShaderMaterial).set_shader_parameter("night_lift", 0.0)
