class_name Aircraft
extends Vehicle
## A plane you can steal (or, with Gus's blessing, borrow) and fly. Arcade
## flight: throttle sets the engine, the wings bank you into turns, the nose
## climbs or dives, and slow means falling. No rigid bodies; one ray down and
## move_and_collide() against the world, so it costs about what a car does.
##
##   KEYBOARD   W/S throttle · A/D bank · mouse (or ↑/↓) nose · SPACE wheel brake
##   PAD        RT/LT throttle · left stick bank + nose · LB/RB rudder · X brake
##   Both       E / A get out (on the ground, stopped) · right stick / mouse look

const MODELS := {
	"skyhawk": {"name": "Skyhawk", "vmax": 66.0, "stall": 22.0, "rot": 25.0, "thrust": 5.2,
		"roll_rate": 1.7, "pitch_rate": 0.95, "hp": 140.0, "body": Vector3(1.4, 1.5, 7.6), "body_y": 1.25, "cam": 11.0},
	# Helicopters hover: W/S is the collective (climb, hold, descend), A/D
	# turn on the spot, the nose (mouse or arrows) tilts you forward or back.
	"heli": {"name": "Helicopter", "vmax": 52.0, "stall": 0.0, "rot": 0.0, "thrust": 9.0, "heli": true,
		"roll_rate": 1.6, "pitch_rate": 1.0, "hp": 160.0, "body": Vector3(1.9, 2.0, 5.2), "body_y": 1.3, "cam": 12.0},
	"citation": {"name": "E Corp Citation", "vmax": 128.0, "stall": 40.0, "rot": 45.0, "thrust": 8.5,
		"roll_rate": 2.1, "pitch_rate": 0.8, "hp": 220.0, "body": Vector3(2.0, 2.2, 14.0), "body_y": 1.8, "cam": 17.0},
}
const G := 9.8
const CEILING := 1100.0
## Airspace: the city plus a margin over the water. Past it the plane is
## turned back (it's a game, and there's nothing out there but rendering).
const SKY := Rect2(-1700.0, -2500.0, 4300.0, 3900.0)

var model: String = "skyhawk"
var spec: Dictionary = {}
var throttle: float = 0.0
var pitch: float = 0.0 # nose up +
var bank: float = 0.0 # right wing down +
var heading: float = 0.0 # same sense as rotation.y
var airborne: bool = false
var sink: float = 0.0 # extra vertical speed while stalled
var altitude: float = 0.0 # above whatever is below
var owner_tag: String = "" # "ecorp" for the jet, "gus" for the field's trainers
var slot: String = "" # the airfield parking slot it belongs to
var stalled: bool = false
var warn: String = "" # STALL / PULL UP / TURN BACK, shown by the HUD
var _m_pitch: float = 0.0 # mouse stick (decays back to centre)
var _m_yaw: float = 0.0
var _prop: MeshInstance3D
var _prop_a: float = 0.0
var _ground_y: float = 0.0
var _crash_cool: float = 0.0
var _turn_back_t: float = 0.0
var _crashing: bool = false


func setup_plane(m: String, pos: Vector3, yaw: float, g: Node) -> Aircraft:
	model = m
	spec = MODELS.get(m, MODELS["skyhawk"])
	kind = "plane"
	game = g
	name = "Aircraft_%s" % m
	hp = float(spec["hp"])
	collision_layer = Phys.CAR | Phys.INTERACT
	collision_mask = Phys.WORLD | Phys.CAR
	var meshes := build_meshes(m)
	_mesh = MeshInstance3D.new()
	_mesh.mesh = meshes[0]
	_mesh.material_override = Mats.lit
	_mesh.visibility_range_end = 1600.0
	add_child(_mesh)
	_glow = MeshInstance3D.new()
	_glow.mesh = meshes[1]
	_glow.material_override = Mats.glow
	_glow.visibility_range_end = 2400.0
	add_child(_glow)
	if m == "heli":
		# The main rotor (spins about the mast) and, on the tail, a little one.
		var rb := MeshBatch.new()
		rb.box(Vector3.ZERO, Vector3(10.4, 0.06, 0.32), Color(0.1, 0.1, 0.11))
		rb.box(Vector3.ZERO, Vector3(0.32, 0.06, 10.4), Color(0.1, 0.1, 0.11))
		rb.cyl(Vector3(0, 0.05, 0), 0.25, 0.25, 0.3, Color(0.3, 0.3, 0.32), 8)
		_prop = MeshInstance3D.new()
		_prop.mesh = rb.to_mesh()
		_prop.material_override = Mats.lit
		_prop.position = Vector3(0, 2.75, -0.2)
		add_child(_prop)
	elif m == "skyhawk":
		var pb := MeshBatch.new()
		pb.box(Vector3.ZERO, Vector3(2.0, 0.16, 0.05), Color(0.12, 0.12, 0.12))
		pb.sphere(Vector3(0, 0, -0.12), 0.18, Color(0.85, 0.15, 0.12), 6, 3)
		_prop = MeshInstance3D.new()
		_prop.mesh = pb.to_mesh()
		_prop.material_override = Mats.lit
		_prop.position = Vector3(0, 1.15, -3.2)
		add_child(_prop)
	if m == "citation":
		var lb := Label3D.new()
		lb.text = "E CORP"
		lb.font_size = 72
		lb.pixel_size = 0.012
		lb.modulate = Color(0.9, 0.92, 0.95)
		lb.position = Vector3(1.0, 2.2, -1.0)
		lb.rotation.y = PI * 0.5
		lb.double_sided = false
		add_child(lb)
		var lb2 := lb.duplicate() as Label3D
		lb2.position = Vector3(-1.0, 2.2, -1.0)
		lb2.rotation.y = -PI * 0.5
		add_child(lb2)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = spec["body"]
	cs.shape = bs
	cs.position = Vector3(0, float(spec["body_y"]), 0)
	add_child(cs)
	var sb := MeshBatch.new()
	sb.sphere(Vector3.ZERO, 0.7, Color(0.35, 0.33, 0.32), 6, 3)
	_smoke = MeshInstance3D.new()
	_smoke.mesh = sb.to_mesh()
	_smoke.material_override = Mats.lit
	_smoke.position = Vector3(0, 1.4, -2.2)
	_smoke.visible = false
	add_child(_smoke)
	position = pos
	heading = yaw
	rotation = Vector3(0, yaw, 0)
	return self


func display_name() -> String:
	return str(spec.get("name", "Plane"))


func interact_info() -> Dictionary:
	if dead or driving:
		return {}
	if not locked:
		return {"verb": "Fly", "name": display_name()}
	var ls := GameState.skill("lockpick")
	if ls >= lock_dc:
		return {"verb": "Steal [LOCKPICK %d]" % lock_dc, "name": display_name()}
	return {"verb": "Force the Door & Steal", "name": display_name() + "  (LOCKPICK %d/%d)" % [ls, lock_dc], "locked": true}


func begin_drive() -> void:
	super.begin_drive()
	if _engine != null:
		_engine.volume_db = -9.0
	cam.fov = 72.0
	_m_pitch = 0.0
	_m_yaw = 0.0


## Mouse: a self-centring stick (nose and rudder). Pad: the right stick looks
## around (the left stick flies).
func orbit(dx: float, dy: float) -> void:
	if Pad.using_pad:
		super.orbit(dx, dy)
		return
	var inv := -1.0 if bool(Settings.get_v("invert_y")) else 1.0
	var sens := float(Settings.get_v("mouse_sens"))
	# Mouse back (down) pulls the nose up.
	_m_pitch = clampf(_m_pitch - dy * 0.006 * sens * inv, -1.0, 1.0)
	_m_yaw = clampf(_m_yaw + dx * 0.004 * sens, -1.0, 1.0)


# ------------------------------------------------------------------ flight
func _physics_process(delta: float) -> void:
	if not driving and not airborne and not dead and speed < 0.05 and sink == 0.0:
		return # parked: costs nothing
	_crash_cool = maxf(0.0, _crash_cool - delta)
	_hit_cool = maxf(0.0, _hit_cool - delta)
	_ground_y = _probe_ground()
	if dead:
		_fall_wreck(delta)
		_burn(delta)
		return
	var paused_ui: bool = game != null and game.ui_open()
	var thr_in := 0.0
	var bank_in := 0.0
	var pitch_in := 0.0
	var rud_in := 0.0
	var brake := false
	if driving and not paused_ui:
		if Pad.using_pad:
			thr_in = Pad.trigger(true) - Pad.trigger(false)
			var lx := Input.get_joy_axis(Pad.device, JOY_AXIS_LEFT_X)
			var ly := Input.get_joy_axis(Pad.device, JOY_AXIS_LEFT_Y)
			bank_in = lx if absf(lx) > 0.15 else 0.0
			# pitch_in > 0 pushes the nose down. Stick back (down) = nose up,
			# like every flight stick.
			pitch_in = -ly if absf(ly) > 0.15 else 0.0
			if bool(Settings.get_v("invert_y")):
				pitch_in = -pitch_in
			rud_in = float(Pad.button(JOY_BUTTON_RIGHT_SHOULDER)) - float(Pad.button(JOY_BUTTON_LEFT_SHOULDER))
			brake = Pad.button(JOY_BUTTON_X)
		else:
			thr_in = Input.get_axis("move_back", "move_forward")
			bank_in = Input.get_axis("move_left", "move_right")
			# Arrows like a flight sim: UP pushes the nose down, DOWN pulls it up.
			pitch_in = _m_pitch + float(Input.is_physical_key_pressed(KEY_UP)) - float(Input.is_physical_key_pressed(KEY_DOWN))
			rud_in = _m_yaw
			brake = Input.is_physical_key_pressed(KEY_SPACE)
		pitch_in = clampf(pitch_in, -1.0, 1.0)
	# The mouse "stick" drifts back to centre.
	_m_pitch = move_toward(_m_pitch, 0.0, delta * 1.6)
	_m_yaw = move_toward(_m_yaw, 0.0, delta * 2.5)
	if bool(spec.get("heli", false)):
		_heli(delta, thr_in if driving else -0.4, bank_in + rud_in, pitch_in, brake)
		rotation = Vector3(pitch, heading, -bank)
		_heli_move(delta)
		if driving:
			_check_airspace(delta)
		if _engine != null and _engine.playing:
			_engine.pitch_scale = 0.5 + throttle * 0.7 + absf(speed) / float(spec["vmax"]) * 0.3
		if _prop != null:
			_prop_a += delta * (4.0 + throttle * 26.0 if driving or airborne else 0.0)
			_prop.rotation.y = _prop_a
		_smoke.visible = hp < 50.0
		return
	if not driving:
		thr_in = -1.0
	throttle = clampf(throttle + thr_in * 0.55 * delta, 0.0, 1.0)
	var vmax := float(spec["vmax"]) * (0.6 if hp < 40.0 else 1.0)
	var thrust := float(spec["thrust"])
	# Engine against drag (top speed at full throttle), and gravity along the nose.
	var acc := thrust * throttle * 1.6 - thrust * 1.6 * pow(speed / vmax, 2.0)
	acc -= G * sin(pitch) * 0.85
	if not airborne:
		acc -= 0.8 if speed > 0.1 else 0.0
		if brake or (thr_in < 0.0 and throttle <= 0.01):
			acc -= 7.0
	speed = maxf(0.0, speed + acc * delta)
	if airborne:
		_fly(delta, bank_in, pitch_in, rud_in)
	else:
		_taxi(delta, bank_in, pitch_in)
	rotation = Vector3(pitch, heading, -bank)
	_move(delta)
	if driving:
		if not airborne:
			_run_over(delta)
		_check_airspace(delta)
	# Sound, prop, smoke.
	if _engine != null and _engine.playing:
		_engine.pitch_scale = 0.55 + throttle * 0.9 + speed / vmax * 0.5
	if _prop != null:
		_prop_a += delta * (6.0 + throttle * 60.0)
		_prop.rotation.z = _prop_a
	_smoke.visible = hp < 50.0
	if hp < 50.0:
		_smoke.position.y = 1.4 + sin(Time.get_ticks_msec() * 0.006) * 0.1


func _taxi(delta: float, bank_in: float, pitch_in: float) -> void:
	# Nose-wheel steering: tight when slow, lazy at take-off speed.
	var steer_rate := clampf(1.3 - speed / 40.0, 0.25, 1.3)
	if speed > 0.3:
		heading -= bank_in * steer_rate * delta
	bank = move_toward(bank, 0.0, delta * 2.0)
	sink = 0.0
	stalled = false
	var rot := float(spec["rot"])
	if speed >= rot and pitch_in < -0.15:
		pitch = minf(pitch + float(spec["pitch_rate"]) * -pitch_in * delta, 0.35)
	else:
		pitch = move_toward(pitch, 0.0, delta * 0.6)
	if pitch > 0.07 and speed >= rot:
		airborne = true
		AudioManager.play_3d("door", global_position, -8.0, 0.6)
	warn = ""


func _fly(delta: float, bank_in: float, pitch_in: float, rud_in: float) -> void:
	var stall := float(spec["stall"])
	var lift := clampf(speed / stall, 0.0, 1.0)
	# Bank: input rolls, hands-off rolls back toward level.
	if absf(bank_in) > 0.05:
		bank += bank_in * float(spec["roll_rate"]) * delta
	else:
		bank = move_toward(bank, 0.0, delta * 0.7)
	bank = clampf(bank, -1.35, 1.35)
	# Pitch: authority fades with speed. (pitch_in < 0 is nose up.)
	pitch -= pitch_in * float(spec["pitch_rate"]) * delta * clampf(lift, 0.35, 1.0) * (1.0 - absf(bank) * 0.25)
	pitch = clampf(pitch, -1.25, 1.1)
	# A banked wing turns the plane (coordinated turn), and costs a little nose.
	var turn := G * tan(clampf(bank, -1.3, 1.3)) / maxf(speed, 18.0)
	heading -= (turn + rud_in * 0.35) * delta
	pitch -= absf(sin(bank)) * 0.05 * delta
	# Too slow: the wing lets go. Nose drops, the plane sinks.
	stalled = speed < stall
	if stalled:
		sink = move_toward(sink, -(1.0 - lift) * 22.0 - 2.0, delta * 9.0)
		pitch = move_toward(pitch, -0.45, delta * (1.0 - lift) * 0.9)
		if driving:
			Pad.rumble(0.25, 0.0, 0.1)
	else:
		sink = move_toward(sink, 0.0, delta * 6.0)
	if global_position.y > CEILING:
		pitch = move_toward(pitch, -0.2, delta * 0.8)
	altitude = global_position.y - _ground_y
	var descent := -(-global_transform.basis.z * speed + Vector3(0, sink, 0)).y
	if stalled:
		warn = "STALL"
	elif altitude < 70.0 and descent > 12.0:
		warn = "PULL UP"
	elif not Regions.sky(WorldLayout.region).has_point(Vector2(global_position.x, global_position.z)):
		warn = "LEAVING AIRSPACE"
	else:
		warn = ""


# ------------------------------------------------------------------ rotors
## Collective, yaw and cyclic. Near the ground the air cushions you (ground
## effect), so easing down onto a pad or a roof is a landing, not a crash.
func _heli(delta: float, coll: float, yaw_in: float, pitch_in: float, brake: bool) -> void:
	altitude = global_position.y - _ground_y
	var want_vy := coll * (8.0 if coll > 0.0 else 7.0)
	if airborne and altitude < 10.0 and want_vy < -2.5:
		want_vy = -2.5
	sink = move_toward(sink, want_vy, delta * 9.0)
	throttle = clampf(0.55 + sink / 16.0, 0.0, 1.0)
	if not airborne:
		speed = move_toward(speed, 0.0, delta * 8.0)
		pitch = move_toward(pitch, 0.0, delta * 2.0)
		bank = move_toward(bank, 0.0, delta * 2.0)
		if coll > 0.05:
			heading -= yaw_in * 1.2 * delta
		if sink > 0.6:
			airborne = true
			AudioManager.play_3d("door", global_position, -8.0, 0.5)
		warn = ""
		return
	heading -= yaw_in * 1.5 * delta
	pitch = move_toward(pitch, -clampf(pitch_in, -1.0, 1.0) * 0.35, delta * 1.6)
	bank = move_toward(bank, clampf(yaw_in, -1.0, 1.0) * 0.22 * clampf(absf(speed) / 20.0, 0.0, 1.0), delta * 1.5)
	var vmax := float(spec["vmax"]) * (0.6 if hp < 40.0 else 1.0)
	speed = clampf(speed + (-pitch * 42.0 - speed * 0.26) * delta, -14.0, vmax)
	if brake:
		speed = move_toward(speed, 0.0, delta * 14.0)
	if global_position.y > CEILING:
		sink = minf(sink, 0.0)
	var descent := -sink
	if altitude < 40.0 and descent > 6.0:
		warn = "PULL UP"
	elif not Regions.sky(WorldLayout.region).has_point(Vector2(global_position.x, global_position.z)):
		warn = "LEAVING AIRSPACE"
	else:
		warn = ""


func _heli_move(delta: float) -> void:
	var fwd := Vector3(-sin(heading), 0.0, -cos(heading))
	var vel := fwd * speed + Vector3(0, sink if airborne else 0.0, 0)
	var col := move_and_collide(vel * delta)
	if col != null:
		var shp := col.get_collider_shape() as Node
		if shp != null and str(shp.get_meta("tag", "")) == "bounds":
			global_position += col.get_remainder()
			col = null
	if col != null:
		var n := col.get_normal()
		var impact := absf(vel.dot(n))
		var other := col.get_collider()
		if other is Vehicle and other != self:
			(other as Vehicle).damage(impact * 2.0)
		if n.y > 0.7 and not airborne:
			pass # resting on the pad
		elif n.y > 0.7 and impact < 6.0 and absf(speed) < 14.0:
			# Settled onto something flat: a roof, a container, a truck.
			_heli_land(impact)
		elif impact > 9.0 and _crash_cool <= 0.0:
			_crash(vel.length())
			return
		else:
			speed *= 0.4
			damage(impact * 1.2)
			global_position += n * 0.08
	if not airborne:
		global_position.y = _ground_y
		if _over_water():
			_crash(12.0)
	elif global_position.y <= _ground_y + 0.05 and sink <= 0.0:
		if -sink < 6.0 and absf(speed) < 14.0 and not _over_water():
			_heli_land(-sink)
		else:
			_crash(vel.length())


func _heli_land(descent: float) -> void:
	airborne = false
	global_position.y = _ground_y
	sink = 0.0
	speed *= 0.3
	AudioManager.play_3d("thud", global_position, 0.0, 0.6)
	if driving:
		Pad.rumble(0.3, 0.4, 0.2)
	if descent > 4.0:
		damage(descent * 2.5)


func _move(delta: float) -> void:
	var fwd := -global_transform.basis.z
	var vel := fwd * speed + Vector3(0, sink, 0)
	if not airborne:
		vel.y = 0.0
	var col := move_and_collide(vel * delta)
	if col != null:
		var shp := col.get_collider_shape() as Node
		if shp != null and str(shp.get_meta("tag", "")) == "bounds":
			# The city's invisible edge walls stop people and cars, not planes.
			global_position += col.get_remainder()
			col = null
	if col != null:
		var n := col.get_normal()
		var impact := absf(vel.dot(n))
		var other := col.get_collider()
		if other is Vehicle and other != self:
			(other as Vehicle).damage(impact * 2.0)
		if not airborne and impact < 6.0:
			speed *= 0.3 # nudged a hangar wall or a car while taxiing
			damage(impact * 1.5)
		elif impact > 3.0 and _crash_cool <= 0.0:
			_crash(vel.length())
			return
		else:
			global_position += n * 0.05
	# Ground: wheels stay on it while taxiing; touching it in the air is a
	# landing if gentle and level, a crash if not.
	if not airborne:
		global_position.y = _ground_y
		if _over_water():
			_crash(maxf(speed, 20.0))
	elif global_position.y <= _ground_y + 0.05:
		var descent := -vel.y
		var gentle := descent < 6.5 and absf(bank) < 0.4 and pitch > -0.2 and pitch < 0.45 and not _over_water()
		if gentle:
			airborne = false
			global_position.y = _ground_y
			pitch = maxf(pitch, 0.0)
			sink = 0.0
			AudioManager.play_3d("thud", global_position, 0.0, 0.7)
			if driving:
				Pad.rumble(0.4, 0.5, 0.25)
			if descent > 4.0:
				damage(descent * 3.0)
		else:
			_crash(vel.length())


## The ground (or roof) under the plane. Nothing below: open water.
func _probe_ground() -> float:
	var from := global_position + Vector3(0, 3.0, 0)
	var q := PhysicsRayQueryParameters3D.create(from, from - Vector3(0, 4000.0, 0), Phys.WORLD)
	q.exclude = [get_rid()]
	var res := get_world_3d().direct_space_state.intersect_ray(q)
	if res.is_empty():
		return -0.4
	return (res["position"] as Vector3).y


func _over_water() -> bool:
	var p := global_position
	return p.x < -WorldLayout.WORLD_X or p.x > WorldLayout.WORLD_XE or p.z < WorldLayout.WORLD_ZN - 2.0 or p.z > WorldLayout.BEACH_Z1 + 2.0 and (p.x < WorldLayout.PIER_X0 or p.x > WorldLayout.PIER_X1)


## Past the edge of the map: fly on into the next one if it borders here,
## otherwise the plane banks itself back toward the city.
func _check_airspace(delta: float) -> void:
	if not airborne:
		return
	var p := Vector2(global_position.x, global_position.z)
	var sky := Regions.sky(WorldLayout.region)
	if sky.has_point(p):
		_turn_back_t = 0.0
		return
	if driving and game != null and game.has_method("airspace_exit"):
		if game.airspace_exit(self):
			return
	_turn_back_t += delta
	var to_c := sky.get_center() - p
	var want := atan2(-to_c.x, -to_c.y)
	heading = lerp_angle(heading, want, minf(1.0, delta * 0.6 * minf(_turn_back_t, 3.0)))
	bank = move_toward(bank, 0.6 * signf(wrapf(heading - want, -PI, PI)), delta)


func _crash(spd: float) -> void:
	if dead:
		return
	_crash_cool = 1.0
	Pad.rumble(1.0, 1.0, 0.8)
	var was_driving := driving
	var pp: Vector3 = global_position
	_crashing = true
	explode()
	if was_driving and game != null:
		# Survivable only at a crawl. FNV rules: it's your own fault.
		game.player.take_damage(clampf((spd - 8.0) * 3.2, 15.0, 600.0), pp)
		GameState.stat_add("plane_crashes")


func explode() -> void:
	if dead:
		return
	dead = true
	hp = 0.0
	_burn_t = 20.0
	_glow.visible = false
	_smoke.visible = true
	_smoke.scale = Vector3(3.0, 3.0, 3.0)
	speed = 0.0
	throttle = 0.0
	AudioManager.play_3d("death", global_position, 8.0, 0.35)
	AudioManager.play_3d("gun_shotgun", global_position, 10.0, 0.3)
	if game != null:
		game.impact(global_position + Vector3(0, 1.5, 0), Vector3.UP)
		game.impact(global_position + Vector3(2, 1.0, 1), Vector3.UP)
		if not driving and game.player.global_position.distance_to(global_position) < 10.0:
			game.player.take_damage(40.0, global_position)
		elif driving and not _crashing:
			game.player.take_damage(50.0, global_position)
		if driving:
			game.exit_vehicle(true)
	for n in get_tree().get_nodes_in_group("npc"):
		var o := n as NPC
		if o != null and not o.dead and o.global_position.distance_to(global_position) < 9.0:
			o.take_hit(120.0, game.player if game != null else null, false, false, 0.0)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.08, 0.07, 0.07)
	_mesh.material_override = dark
	if _prop != null:
		_prop.visible = false


func _fall_wreck(delta: float) -> void:
	# A wreck in the air falls; on the ground it just burns.
	if global_position.y > _ground_y + 0.05:
		sink -= G * delta
		global_position.y = maxf(_ground_y, global_position.y + sink * delta)
	else:
		sink = 0.0
		bank = move_toward(bank, 0.0, delta)
		pitch = move_toward(pitch, 0.0, delta)
		rotation = Vector3(pitch, heading, -bank)


func damage(d: float) -> void:
	if dead:
		return
	hp -= d
	if hp <= 0.0:
		if airborne:
			# Shot down: the engine dies and gravity takes over.
			hp = 0.0
			throttle = 0.0
			speed *= 0.6
			sink = -8.0
			_crash_cool = 0.0
			var pp := global_position
			explode()
			if game != null and game.player.global_position.distance_to(pp) < 4.0:
				game.player.take_damage(400.0, pp)
		else:
			explode()


# ------------------------------------------------------------------ camera
func _process(delta: float) -> void:
	if not driving or cam == null:
		return
	var b := global_transform.basis
	# Behind the plane by heading (not by nose: a steep climb mustn't swing the
	# camera underneath), lifted a little with the nose so you still see ahead.
	var back := Vector3(sin(heading), 0.0, cos(heading)).rotated(Vector3.UP, cam_yaw)
	var dist := float(spec["cam"]) + speed * 0.04
	var up := Vector3.UP * (2.6 + dist * 0.18 + _cam_pitch * 4.0 - sin(pitch) * dist * 0.45)
	var want := global_position + back * dist * cos(pitch * 0.5) + up
	var look := global_position + Vector3(0, float(spec["body_y"]) + 0.6, 0) - b.z * 6.0
	if not airborne:
		var q := PhysicsRayQueryParameters3D.create(look, want, Phys.WORLD)
		q.exclude = [get_rid()]
		var res := get_world_3d().direct_space_state.intersect_ray(q)
		if not res.is_empty():
			want = (res["position"] as Vector3) + (look - want).normalized() * 0.5
	cam.global_position = cam.global_position.lerp(want, minf(1.0, delta * 6.0))
	if cam.global_position.distance_to(look) > 0.1:
		cam.look_at(look, Vector3.UP.lerp(b.y, 0.35).normalized())
	cam.fov = lerpf(cam.fov, 70.0 + speed * 0.12, minf(1.0, delta * 2.0))
	# Up high you can see the next city on the horizon.
	cam.far = 7000.0 if global_position.y > 40.0 else Settings.view_far()
	# A far plane kilometres out needs a near plane further than a few
	# centimetres, or the fields z-fight with the ground under them.
	cam.near = clampf(global_position.y * 0.01, 0.1, 2.0)
	if speed > 15.0:
		cam_yaw = lerp_angle(cam_yaw, 0.0, minf(1.0, delta * 1.0))


# ------------------------------------------------------------------ meshes
static var _mesh_cache: Dictionary = {}


static func build_meshes(m: String) -> Array:
	if _mesh_cache.has(m):
		return _mesh_cache[m]
	var b := MeshBatch.new()
	var g := MeshBatch.new()
	var dark := Color(0.12, 0.12, 0.13)
	var glass := Color(0.08, 0.12, 0.16)
	if m == "heli":
		var body := Color(0.12, 0.3, 0.55)
		var white := Color(0.9, 0.9, 0.88)
		b.box(Vector3(0, 1.35, -0.3), Vector3(1.8, 1.6, 3.2), body, 0.0, Vector2.ZERO, 63)
		b.box(Vector3(0, 1.45, -2.1), Vector3(1.6, 1.3, 0.9), glass)
		b.box(Vector3(0, 1.1, -2.2), Vector3(1.5, 0.5, 0.8), body)
		b.box(Vector3(0, 1.75, -1.0), Vector3(1.84, 0.7, 1.4), glass)
		b.box(Vector3(0, 1.0, -0.3), Vector3(1.84, 0.16, 3.2), white)
		b.box(Vector3(0, 2.3, 0.2), Vector3(1.0, 0.6, 1.8), body)
		b.box(Vector3(0, 2.6, -0.2), Vector3(0.3, 0.3, 0.3), dark)
		b.box(Vector3(0, 1.6, 3.4), Vector3(0.4, 0.45, 4.2), body)
		b.box(Vector3(0, 2.3, 5.3), Vector3(0.12, 1.4, 0.8), body)
		b.box(Vector3(0, 1.6, 5.0), Vector3(1.6, 0.08, 0.5), body)
		b.box(Vector3(0.2, 2.3, 5.4), Vector3(0.05, 1.4, 0.18), dark)
		b.box(Vector3(0.2, 2.3, 5.4), Vector3(0.05, 0.18, 1.4), dark)
		for s in [-1.0, 1.0]:
			b.box(Vector3(0.85 * s, 0.12, -0.3), Vector3(0.12, 0.12, 3.6), dark)
			b.tube(Vector3(0.85 * s, 0.12, -1.2), Vector3(0.7 * s, 0.6, -1.2), 0.05, dark)
			b.tube(Vector3(0.85 * s, 0.12, 0.6), Vector3(0.7 * s, 0.6, 0.6), 0.05, dark)
		g.box(Vector3(0, 0.6, -0.3), Vector3(0.14, 0.1, 0.14), Color(1.0, 0.15, 0.1), 0.0, Vector2(Props.K_BLINK, 0))
		g.box(Vector3(0, 3.05, 5.7), Vector3(0.12, 0.12, 0.12), Color(1, 1, 1), 0.0, Vector2(Props.K_BLINK, 0.5))
		g.box(Vector3(0.95, 1.2, -0.6), Vector3(0.04, 0.1, 0.2), Color(0.1, 1.0, 0.2), 0.0, Vector2(Props.K_ALWAYS, 0))
		g.box(Vector3(-0.95, 1.2, -0.6), Vector3(0.04, 0.1, 0.2), Color(1.0, 0.1, 0.1), 0.0, Vector2(Props.K_ALWAYS, 0))
		g.box(Vector3(0, 0.9, -2.55), Vector3(0.3, 0.12, 0.05), Color(1.0, 0.95, 0.8), 0.0, Vector2(Props.K_NIGHT, 0))
	elif m == "skyhawk":
		var white := Color(0.88, 0.88, 0.85)
		var stripe := Color(0.75, 0.16, 0.12)
		b.box(Vector3(0, 1.3, -0.7), Vector3(1.2, 1.4, 3.2), white, 0.0, Vector2.ZERO, 63)
		b.box(Vector3(0, 1.62, -0.9), Vector3(1.24, 0.5, 1.7), glass)
		b.box(Vector3(0, 1.62, -2.0), Vector3(1.0, 0.45, 0.5), glass)
		b.box(Vector3(0, 1.15, -2.65), Vector3(1.0, 0.95, 1.0), white, 0.0, Vector2.ZERO, 63)
		b.box(Vector3(0, 1.0, -0.7), Vector3(1.24, 0.14, 3.2), stripe)
		b.box(Vector3(0, 1.4, 2.3), Vector3(0.55, 0.75, 3.8), white, 0.0, Vector2.ZERO, 63)
		b.box(Vector3(0, 1.4, 2.3), Vector3(0.58, 0.12, 3.8), stripe)
		b.box(Vector3(0, 2.08, -0.8), Vector3(11.0, 0.14, 1.5), white, 0.0, Vector2.ZERO, 63)
		b.box(Vector3(-5.3, 2.08, -0.8), Vector3(0.4, 0.16, 1.52), stripe)
		b.box(Vector3(5.3, 2.08, -0.8), Vector3(0.4, 0.16, 1.52), stripe)
		for s in [-1.0, 1.0]:
			b.tube(Vector3(0.55 * s, 0.95, -0.6), Vector3(2.7 * s, 2.0, -0.7), 0.04, dark)
			b.tube(Vector3(0.5 * s, 0.7, -0.3), Vector3(1.2 * s, 0.25, -0.3), 0.05, dark)
			b.box(Vector3(1.25 * s, 0.25, -0.3), Vector3(0.18, 0.5, 0.5), dark)
		b.tube(Vector3(0, 0.75, -2.6), Vector3(0, 0.25, -2.65), 0.05, dark)
		b.box(Vector3(0, 0.25, -2.65), Vector3(0.16, 0.45, 0.45), dark)
		b.box(Vector3(0, 1.5, 4.15), Vector3(3.6, 0.1, 0.9), white)
		b.box(Vector3(0, 2.2, 4.2), Vector3(0.1, 1.6, 1.0), white)
		b.box(Vector3(0, 2.55, 4.3), Vector3(0.12, 0.5, 0.8), stripe)
		g.box(Vector3(-5.55, 2.08, -0.8), Vector3(0.1, 0.12, 0.2), Color(1.0, 0.1, 0.1), 0.0, Vector2(Props.K_ALWAYS, 0))
		g.box(Vector3(5.55, 2.08, -0.8), Vector3(0.1, 0.12, 0.2), Color(0.1, 1.0, 0.2), 0.0, Vector2(Props.K_ALWAYS, 0))
		g.box(Vector3(0, 3.0, 4.6), Vector3(0.12, 0.12, 0.12), Color(1, 1, 1), 0.0, Vector2(Props.K_BLINK, 0))
		g.box(Vector3(-1.8, 2.0, -1.56), Vector3(0.3, 0.08, 0.04), Color(1.0, 0.95, 0.8), 0.0, Vector2(Props.K_NIGHT, 0))
	else:
		var body := Color(0.2, 0.21, 0.24)
		var trim := Color(0.75, 0.78, 0.82)
		b.box(Vector3(0, 1.85, -0.3), Vector3(1.8, 1.9, 11.0), body, 0.0, Vector2.ZERO, 63)
		b.box(Vector3(0, 1.2, -0.3), Vector3(1.82, 0.2, 11.0), trim)
		b.box(Vector3(0, 1.75, -6.4), Vector3(1.4, 1.4, 1.6), body, 0.0, Vector2.ZERO, 63)
		b.box(Vector3(0, 1.6, -7.4), Vector3(0.8, 0.8, 0.6), body, 0.0, Vector2.ZERO, 63)
		b.box(Vector3(0, 2.35, -5.6), Vector3(1.5, 0.5, 1.2), glass)
		for i in 6:
			b.box(Vector3(0, 2.15, -3.6 + float(i) * 1.2), Vector3(1.84, 0.34, 0.45), glass)
		b.box(Vector3(0, 2.0, 6.0), Vector3(1.2, 1.3, 1.8), body, 0.0, Vector2.ZERO, 63)
		for s in [-1.0, 1.0]:
			b.box(Vector3(3.6 * s, 1.15, 0.7), Vector3(6.0, 0.2, 2.2), body, -0.28 * s)
			b.box(Vector3(6.4 * s, 1.5, 1.5), Vector3(0.12, 0.8, 1.0), trim)
			b.tube(Vector3(1.55 * s, 2.35, 3.2), Vector3(1.55 * s, 2.35, 5.8), 0.5, trim, 8)
			b.box(Vector3(1.2 * s, 2.35, 4.4), Vector3(0.5, 0.25, 0.6), body)
			b.tube(Vector3(1.4 * s, 1.0, 0.8), Vector3(1.4 * s, 0.35, 0.8), 0.07, dark)
			b.box(Vector3(1.4 * s, 0.35, 0.8), Vector3(0.25, 0.7, 0.7), dark)
			g.box(Vector3(6.47 * s, 1.5, 1.5), Vector3(0.06, 0.12, 0.2), Color(0.1, 1.0, 0.2) if s > 0 else Color(1.0, 0.1, 0.1), 0.0, Vector2(Props.K_ALWAYS, 0))
		b.tube(Vector3(0, 1.0, -5.6), Vector3(0, 0.35, -5.6), 0.07, dark)
		b.box(Vector3(0, 0.35, -5.6), Vector3(0.22, 0.6, 0.6), dark)
		b.box(Vector3(0, 3.6, 6.2), Vector3(0.2, 2.8, 1.8), body)
		b.box(Vector3(0, 4.95, 6.6), Vector3(4.6, 0.12, 1.1), body)
		b.box(Vector3(0, 3.6, 6.2), Vector3(0.22, 0.4, 1.6), trim)
		g.box(Vector3(0, 5.1, 7.1), Vector3(0.14, 0.14, 0.14), Color(1, 1, 1), 0.0, Vector2(Props.K_BLINK, 0))
		g.box(Vector3(0, 0.95, -0.3), Vector3(0.14, 0.1, 0.14), Color(1.0, 0.15, 0.1), 0.0, Vector2(Props.K_BLINK, 0))
	var out := [b.to_mesh(), g.to_mesh()]
	_mesh_cache[m] = out
	return out
