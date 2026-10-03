class_name Boat
extends Vehicle
## A boat: it floats on the water plane (y = WATER_Y) and only goes where
## Boats.is_water says there is water, so it can't climb a beach or a quay.
## The hull slides (its velocity swings round to the heading, not at once),
## it leans out of turns and lifts its nose under power. Like a plane, it
## carries on across a map border when the next map has water on the other
## side (Game.seaspace_exit). You get in and out at docks (Boats.DOCKS).

const WATER_Y := -0.4
const MODELS := {
	"speedboat": {"name": "Speedboat", "vmax": 30.0, "accel": 9.0, "turn": 1.3, "len": 6.4, "wid": 2.3, "hp": 120.0, "hull": Color(0.93, 0.93, 0.9), "trim": Color(0.78, 0.12, 0.1)},
	"skiff": {"name": "Fishing Skiff", "vmax": 17.0, "accel": 6.0, "turn": 1.55, "len": 5.2, "wid": 2.0, "hp": 160.0, "hull": Color(0.22, 0.36, 0.5), "trim": Color(0.92, 0.9, 0.84)},
	"patrol": {"name": "Harbor Patrol Boat", "vmax": 28.0, "accel": 8.5, "turn": 1.15, "len": 7.6, "wid": 2.6, "hp": 220.0, "hull": Color(0.12, 0.16, 0.24), "trim": Color(0.95, 0.95, 0.95)},
	"tender": {"name": "Yacht Tender", "vmax": 27.0, "accel": 8.5, "turn": 1.3, "len": 6.0, "wid": 2.3, "hp": 120.0, "hull": Color(0.96, 0.96, 0.96), "trim": Color(0.1, 0.12, 0.18)},
}

var model: String = "speedboat"
var spec: Dictionary = {}
var slot: String = "" # the dock mooring it belongs to (Boats), "" once it's a ride
var _vel := Vector2.ZERO # how the hull is actually moving (x, z)
var _wake: MeshInstance3D
var _bob_t := 0.0
var _edge_warn_t := 0.0

static var _mesh_cache: Dictionary = {}


func setup_boat(m: String, pos: Vector3, yaw: float, g: Node) -> Boat:
	model = m if MODELS.has(m) else "speedboat"
	spec = MODELS[model]
	kind = "boat"
	game = g
	name = "Boat_%s" % model
	hp = float(spec["hp"])
	collision_layer = Phys.CAR | Phys.INTERACT
	collision_mask = Phys.WORLD | Phys.CAR
	_make_vis()
	var meshes := build_meshes(model)
	_mesh = MeshInstance3D.new()
	_mesh.mesh = meshes[0]
	_mesh.material_override = Mats.lit
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_mesh.visibility_range_end = 700.0
	vis.add_child(_mesh)
	_glow = MeshInstance3D.new()
	_glow.mesh = meshes[1]
	_glow.material_override = Mats.glow
	_glow.visibility_range_end = 900.0
	vis.add_child(_glow)
	# White water off the stern, longer the faster you go.
	var wb := MeshBatch.new()
	wb.flat(Vector3(0, 0.02, 0.5), 1.0, 1.0, Color(0.92, 0.95, 0.97))
	wb.flat(Vector3(-0.9, 0.015, 0.35), 0.35, 0.8, Color(0.85, 0.9, 0.93), 0.35)
	wb.flat(Vector3(0.9, 0.015, 0.35), 0.35, 0.8, Color(0.85, 0.9, 0.93), -0.35)
	_wake = MeshInstance3D.new()
	_wake.mesh = wb.to_mesh()
	_wake.material_override = Mats.glow
	_wake.position = Vector3(0, 0.36, float(spec["len"]) * 0.5)
	_wake.visible = false
	vis.add_child(_wake)
	# The hull sits in the water, but the box that bumps into things rides
	# just above the ground under the sea (it's at y 0), or it'd scrape it.
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(float(spec["wid"]), 0.7, float(spec["len"]))
	cs.shape = bs
	cs.position = Vector3(0, 0.95, 0)
	add_child(cs)
	var sb := MeshBatch.new()
	sb.sphere(Vector3.ZERO, 0.45, Color(0.35, 0.33, 0.32), 6, 3)
	_smoke = MeshInstance3D.new()
	_smoke.mesh = sb.to_mesh()
	_smoke.material_override = Mats.lit
	_smoke.position = Vector3(0, 1.4, float(spec["len"]) * 0.35)
	_smoke.visible = false
	vis.add_child(_smoke)
	position = Vector3(pos.x, WATER_Y, pos.z)
	rotation.y = yaw
	vis.transform = transform
	return self


func display_name() -> String:
	return str(spec.get("name", "Boat"))


func interact_info() -> Dictionary:
	if dead or driving:
		return {}
	if not locked:
		return {"verb": "Take the wheel", "name": display_name()}
	var ls := GameState.skill("lockpick")
	if ls >= lock_dc:
		return {"verb": "Hotwire [LOCKPICK %d]" % lock_dc, "name": display_name()}
	return {"verb": "Break the Ignition & Steal", "name": display_name() + "  (LOCKPICK %d/%d)" % [ls, lock_dc], "locked": true}


# ------------------------------------------------------------------ driving
func _physics_process(delta: float) -> void:
	_hit_cool = maxf(0.0, _hit_cool - delta)
	_edge_warn_t = maxf(0.0, _edge_warn_t - delta)
	if dead:
		# A wreck burns, then goes under.
		_vel = _vel.lerp(Vector2.ZERO, 1.0 - exp(-1.5 * delta))
		global_position.y -= delta * 0.25
		_burn(delta)
		if global_position.y < -4.0 and not driving:
			queue_free()
		return
	var paused_ui: bool = game != null and game.ui_open()
	var thr := 0.0
	var st := 0.0
	var brake := false
	if driving and not paused_ui:
		thr = Input.get_axis("move_back", "move_forward")
		if Pad.using_pad:
			thr = Pad.trigger(true) - Pad.trigger(false)
		st = Input.get_axis("move_right", "move_left")
		brake = Input.is_physical_key_pressed(KEY_SPACE) or Pad.button(JOY_BUTTON_X)
		if Input.is_physical_key_pressed(KEY_G) and _hit_cool <= 0.0:
			_hit_cool = 0.8
			AudioManager.play_3d("horn", global_position, 2.0, 0.55)
	elif not driving:
		_vel = _vel.lerp(Vector2.ZERO, 1.0 - exp(-0.8 * delta))
		speed = move_toward(speed, 0.0, 3.0 * delta)
	var vmax := float(spec["vmax"]) * (0.55 if hp < 30.0 else 1.0)
	var acc := float(spec["accel"])
	if thr > 0.0:
		speed = move_toward(speed, vmax * thr, acc * delta * (1.6 if speed < 0.0 else 1.0))
	elif thr < 0.0:
		speed = move_toward(speed, -vmax * 0.3, acc * 0.8 * delta)
	else:
		speed = move_toward(speed, 0.0, 2.4 * delta) # the water slows you
	if brake:
		speed = move_toward(speed, 0.0, 9.0 * delta)
	steer = move_toward(steer, st, 2.6 * delta)
	# The rudder bites harder with way on; prop wash turns her a little at rest.
	var sp := absf(speed)
	var turn := steer * float(spec["turn"]) * clampf(0.3 + sp / 9.0, 0.3, 1.0) * (1.0 if speed >= -0.2 else -1.0)
	rotation.y += turn * delta
	var fwd := Vector2(-sin(rotation.y), -cos(rotation.y))
	_vel = _vel.lerp(fwd * speed, 1.0 - exp(-2.0 * delta))
	var v0 := speed
	_move_on_water(delta)
	_lean_want = Vector2(clampf(-turn * sp * 0.012, -0.16, 0.16), clampf((speed - v0) / maxf(delta, 0.001) * -0.004 - sp / maxf(vmax, 1.0) * 0.07, -0.12, 0.05))
	if _engine != null and _engine.playing:
		_engine.pitch_scale = 0.5 + sp / maxf(vmax, 1.0) * 1.1 + absf(thr) * 0.15
	_smoke.visible = hp < 40.0


## Move, but only over water: run aground and you stop (and it hurts at
## speed); cross the map's edge and the next map takes over, if it can.
func _move_on_water(delta: float) -> void:
	var step := Vector3(_vel.x, 0.0, _vel.y) * delta
	if step.length_squared() < 0.000001:
		global_position.y = WATER_Y
		return
	var nxt := global_position + step
	if not hull_on_water(nxt, rotation.y):
		var impact := _vel.length()
		if impact > 5.0 and _hit_cool <= 0.0:
			_hit_cool = 0.5
			damage(impact * 1.1)
			AudioManager.play_3d("thud", global_position, 2.0, 0.5)
			if driving:
				Pad.rumble(0.6, clampf(impact / 20.0, 0.3, 1.0), 0.3)
		_vel = -_vel * 0.2
		speed = -speed * 0.15
		return
	var lp := Vector2(nxt.x, nxt.z)
	if not Regions.sky(WorldLayout.region).has_point(lp):
		if driving and game != null and game.has_method("seaspace_exit") and game.seaspace_exit(self):
			return
		_vel = Vector2.ZERO
		speed = 0.0
		return
	var col := move_and_collide(step)
	if col != null:
		var shp := col.get_collider_shape() as Node
		if shp != null and str(shp.get_meta("tag", "")) == "bounds":
			# The edge-of-town walls stop people and cars, not boats.
			global_position += col.get_remainder()
			col = null
	if col != null:
		var n := col.get_normal()
		var n2 := Vector2(n.x, n.z).normalized()
		var impact := absf(_vel.dot(n2))
		if impact > 4.0 and _hit_cool <= 0.0:
			_hit_cool = 0.4
			damage(impact * 1.3)
			AudioManager.play_3d("thud", global_position, 0.0, 0.6)
			if driving:
				Pad.rumble(0.5, clampf(impact / 20.0, 0.3, 1.0), 0.25)
			var other := col.get_collider()
			if other is Vehicle and other != self:
				(other as Vehicle).damage(impact)
		# Glance off along whatever you hit.
		_vel = (_vel - n2 * _vel.dot(n2)) * 0.6
		speed *= 0.5
	global_position.y = WATER_Y


## Bow, stern and both sides of a hull at `p` heading `yaw` all over water.
func hull_on_water(p: Vector3, yaw: float) -> bool:
	var f := Vector2(-sin(yaw), -cos(yaw))
	var r := Vector2(f.y, -f.x)
	var c := Vector2(p.x, p.z)
	var hl := float(spec["len"]) * 0.48
	var hw := float(spec["wid"]) * 0.5
	for o in [f * hl, -f * hl, r * hw, -r * hw]:
		if not Boats.water_at(WorldLayout.region, c + (o as Vector2)):
			return false
	return true


func _run_over(_delta: float) -> void:
	pass # nobody swims here


func explode() -> void:
	if dead:
		return
	dead = true
	hp = 0.0
	_burn_t = 14.0
	_glow.visible = false
	_wake.visible = false
	_smoke.visible = true
	_smoke.scale = Vector3(2.2, 2.2, 2.2)
	AudioManager.play_3d("death", global_position, 6.0, 0.4)
	AudioManager.play_3d("gun_shotgun", global_position, 8.0, 0.35)
	if game != null:
		game.impact(global_position + Vector3(0, 1.0, 0), Vector3.UP)
		if driving:
			game.player.take_damage(40.0, global_position)
			game.exit_vehicle(true)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.08, 0.07, 0.07)
	_mesh.material_override = dark


# ------------------------------------------------------------------ visuals
func _process(delta: float) -> void:
	_update_vis()
	if _mesh != null:
		# Riding the swell: a slow bob and roll, more of it at rest; lean out of
		# turns and lift the bow under power.
		_bob_t += delta
		var calm := clampf(1.0 - absf(speed) / 12.0, 0.25, 1.0)
		var bob := sin(_bob_t * 1.3 + position.x * 0.1) * 0.06 * calm
		var roll := sin(_bob_t * 0.9 + position.z * 0.1) * 0.035 * calm
		_lean = _lean.lerp(_lean_want, 1.0 - exp(-4.0 * delta))
		_mesh.position.y = bob
		_mesh.rotation = Vector3(_lean.y, 0.0, _lean.x + roll)
		_glow.position.y = bob
		_glow.rotation = _mesh.rotation
		var sp := absf(speed)
		_wake.visible = sp > 2.5 and not dead
		if _wake.visible:
			var L := clampf(sp * 0.45, 1.0, 12.0)
			_wake.scale = Vector3(1.0 + sp * 0.04, 1.0, L)
			_wake.position.z = float(spec["len"]) * 0.5 + L * 0.5 - 0.2
	if not driving or cam == null:
		return
	_camera(delta)


# ------------------------------------------------------------------- meshes
static func build_meshes(m: String) -> Array:
	if _mesh_cache.has(m):
		return _mesh_cache[m]
	var s: Dictionary = MODELS.get(m, MODELS["speedboat"])
	var L := float(s["len"])
	var W := float(s["wid"])
	var hull: Color = s["hull"]
	var trim: Color = s["trim"]
	var b := MeshBatch.new()
	var g := MeshBatch.new()
	var dark := Color(0.1, 0.1, 0.11)
	var glass := Color(0.12, 0.2, 0.28)
	var deck := Color(0.55, 0.45, 0.32) if m != "patrol" else Color(0.3, 0.32, 0.34)
	# Hull: a body, a narrowing bow in two steps, a stripe and the boot top
	# just at the waterline (origin = the water's surface).
	b.box(Vector3(0, 0.25, L * 0.12), Vector3(W, 0.9, L * 0.76), hull)
	b.box(Vector3(0, 0.3, -L * 0.33), Vector3(W * 0.78, 0.8, L * 0.18), hull)
	b.box(Vector3(0, 0.36, -L * 0.45), Vector3(W * 0.42, 0.66, L * 0.1), hull)
	b.box(Vector3(0, 0.5, L * 0.04), Vector3(W + 0.04, 0.14, L * 0.9), trim)
	b.box(Vector3(0, -0.12, L * 0.04), Vector3(W + 0.02, 0.12, L * 0.92), Color(0.55, 0.12, 0.1) if m != "tender" else Color(0.1, 0.12, 0.18))
	b.box(Vector3(0, 0.71, L * 0.12), Vector3(W - 0.3, 0.04, L * 0.7), deck)
	# Gunwales along both sides.
	for sx in [-1.0, 1.0]:
		b.box(Vector3(float(sx) * (W * 0.5 - 0.06), 0.82, L * 0.08), Vector3(0.12, 0.2, L * 0.8), trim.darkened(0.1))
	match m:
		"skiff":
			# An open boat: a bench, a tiller outboard, a net bin, a little mast light.
			b.box(Vector3(0, 0.95, 0.2), Vector3(W - 0.4, 0.12, 0.4), deck.darkened(0.2))
			b.box(Vector3(0, 0.85, -L * 0.15), Vector3(W - 0.5, 0.25, 0.8), Color(0.3, 0.5, 0.35))
			b.box(Vector3(0, 0.9, L * 0.5 + 0.1), Vector3(0.4, 0.8, 0.45), dark)
			b.box(Vector3(0, 0.4, L * 0.5 + 0.15), Vector3(0.14, 0.7, 0.14), dark)
			b.tube(Vector3(0, 0.75, L * 0.25), Vector3(0, 2.4, L * 0.25), 0.04, dark)
			g.sphere(Vector3(0, 2.45, L * 0.25), 0.08, Color(1, 1, 1), 4, 3, Vector2(Props.K_NIGHT, 0))
		"patrol":
			# A wheelhouse with windows, a light bar and a lettered hull.
			b.box(Vector3(0, 1.45, -L * 0.05), Vector3(W - 0.5, 1.4, L * 0.32), Color(0.92, 0.92, 0.92))
			b.box(Vector3(0, 1.75, -L * 0.21 - 0.02), Vector3(W - 0.6, 0.55, 0.06), glass)
			for sx in [-1.0, 1.0]:
				b.box(Vector3(float(sx) * (W * 0.5 - 0.24), 1.75, -L * 0.05), Vector3(0.05, 0.5, L * 0.26), glass)
			b.box(Vector3(0, 2.2, -L * 0.05), Vector3(W - 0.4, 0.1, L * 0.36), dark)
			b.box(Vector3(0, 0.95, L * 0.5 + 0.12), Vector3(0.5, 0.9, 0.5), dark)
			b.box(Vector3(0.35, 0.95, L * 0.5 + 0.12), Vector3(0.5, 0.9, 0.5), dark)
			g.box(Vector3(-0.35, 2.32, -L * 0.05), Vector3(0.5, 0.14, 0.2), Color(1.0, 0.1, 0.1), 0.0, Vector2(Props.K_BLINK, 0.0))
			g.box(Vector3(0.35, 2.32, -L * 0.05), Vector3(0.5, 0.14, 0.2), Color(0.15, 0.35, 1.0), 0.0, Vector2(Props.K_BLINK, 0.5))
		_:
			# Speedboat / tender: a console with a raked windshield, two seats,
			# a sundeck aft and a big outboard.
			b.box(Vector3(0, 1.05, -L * 0.08), Vector3(W * 0.5, 0.6, 0.7), trim)
			b.box_xf(Transform3D(Basis(Vector3.RIGHT, -0.55), Vector3(0, 1.45, -L * 0.08 - 0.42)), Vector3(W * 0.62, 0.5, 0.04), glass)
			for sx in [-0.45, 0.45]:
				b.box(Vector3(float(sx), 1.0, L * 0.08), Vector3(0.55, 0.5, 0.55), Color(0.9, 0.88, 0.82))
				b.box(Vector3(float(sx), 1.35, L * 0.08 + 0.25), Vector3(0.55, 0.6, 0.12), Color(0.9, 0.88, 0.82))
			b.box(Vector3(0, 0.82, L * 0.36), Vector3(W - 0.4, 0.2, L * 0.2), Color(0.9, 0.88, 0.82))
			b.box(Vector3(0, 0.95, L * 0.5 + 0.12), Vector3(0.5, 0.95, 0.5), dark)
			b.box(Vector3(0, 0.35, L * 0.5 + 0.2), Vector3(0.16, 0.8, 0.16), dark)
	# Running lights: red to port, green to starboard, white at the stern.
	g.box(Vector3(-W * 0.5 - 0.03, 0.85, -L * 0.3), Vector3(0.04, 0.1, 0.18), Color(1.0, 0.1, 0.1), 0.0, Vector2(Props.K_ALWAYS, 0))
	g.box(Vector3(W * 0.5 + 0.03, 0.85, -L * 0.3), Vector3(0.04, 0.1, 0.18), Color(0.1, 1.0, 0.2), 0.0, Vector2(Props.K_ALWAYS, 0))
	g.box(Vector3(0, 1.1, L * 0.47), Vector3(0.12, 0.12, 0.12), Color(1, 1, 1), 0.0, Vector2(Props.K_NIGHT, 0))
	var out := [b.to_mesh(), g.to_mesh()]
	_mesh_cache[m] = out
	return out
