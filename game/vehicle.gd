class_name Vehicle
extends CharacterBody3D
## A car the player can steal and drive. Cheap kinematic arcade handling (no
## rigid-body sim): throttle, brake/reverse, steering that tightens at speed,
## a handbrake for slides. Crashes hurt the car; hitting people is a crime.

const MAX_FWD := 31.0 # m/s (~110 km/h)
const MAX_REV := 8.0
const ACCEL := 10.5
const BRAKE := 24.0
const GRAVITY := 20.0

var game: Node = null
var kind: String = "sedan"
var color_idx: int = 0
var speed: float = 0.0
var steer: float = 0.0
var hp: float = 100.0
var dead: bool = false
var locked: bool = true
var lock_dc: int = 30
var stolen: bool = false
var driving: bool = false
var cam: Camera3D
var cam_yaw: float = 0.0 # mouse orbit offset around the car
var _cam_pitch: float = 0.28
var _mesh: MeshInstance3D
var _glow: MeshInstance3D
var _smoke: MeshInstance3D
var _engine: AudioStreamPlayer3D
var _hit_cool: float = 0.0
var _burn_t: float = 0.0
var _last_hit_ped: float = 0.0

static var _engine_stream: AudioStreamWAV = null


func setup(k: String, ci: int, pos: Vector3, yaw: float, g: Node) -> Vehicle:
	kind = k
	color_idx = ci
	game = g
	name = "Vehicle_%s" % k
	collision_layer = Phys.CAR | Phys.INTERACT
	collision_mask = Phys.WORLD | Phys.CAR
	floor_snap_length = 0.5
	floor_max_angle = deg_to_rad(40.0)
	var meshes := Props.car_meshes("car_%s_%d" % [k, ci])
	_mesh = MeshInstance3D.new()
	_mesh.mesh = meshes[0]
	_mesh.material_override = Mats.lit
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_mesh.visibility_range_end = 300.0
	add_child(_mesh)
	_glow = MeshInstance3D.new()
	_glow.mesh = meshes[1]
	_glow.material_override = Mats.glow
	_glow.visibility_range_end = 400.0
	add_child(_glow)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	var big := k in ["van", "truck"]
	bs.size = Vector3(1.95, 1.5, 4.5) if not big else Vector3(2.1, 2.2, 5.3)
	cs.shape = bs
	cs.position = Vector3(0, 0.85 if not big else 1.2, 0)
	add_child(cs)
	# Smoke/fire puff shown when the car is hurt (a cheap glowing blob).
	var sb := MeshBatch.new()
	sb.sphere(Vector3.ZERO, 0.45, Color(0.35, 0.33, 0.32), 6, 3)
	_smoke = MeshInstance3D.new()
	_smoke.mesh = sb.to_mesh()
	_smoke.material_override = Mats.lit
	_smoke.position = Vector3(0, 1.2, -1.6)
	_smoke.visible = false
	add_child(_smoke)
	position = pos
	rotation.y = yaw
	return self


func display_name() -> String:
	var n: String = {"sedan": "Sedan", "hatch": "Hatchback", "suv": "SUV", "van": "Van", "taxi": "Taxi", "police": "NYPD Cruiser", "truck": "Box Truck"}.get(kind, "Car")
	return n


func interact_info() -> Dictionary:
	if dead or driving:
		return {}
	if not locked:
		return {"verb": "Drive", "name": display_name()}
	var ls := GameState.skill("lockpick")
	if ls >= lock_dc:
		return {"verb": "Steal [LOCKPICK %d]" % lock_dc, "name": display_name()}
	return {"verb": "Smash Window & Steal", "name": display_name() + "  (LOCKPICK %d/%d)" % [ls, lock_dc], "locked": true}


# ---------------------------------------------------------------- driving
func begin_drive() -> void:
	driving = true
	locked = false
	if cam == null:
		cam = Camera3D.new()
		cam.near = 0.1
		cam.far = Settings.view_far()
		cam.fov = 70.0
		game.add_child(cam)
	cam.global_position = global_position + global_transform.basis.z * 7.0 + Vector3(0, 2.6, 0)
	cam.make_current()
	cam_yaw = 0.0
	if _engine == null:
		_engine = AudioStreamPlayer3D.new()
		_engine.stream = _engine_loop()
		_engine.volume_db = -14.0
		_engine.unit_size = 8.0
		_engine.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
		add_child(_engine)
	_engine.play()


func end_drive() -> void:
	driving = false
	if _engine != null:
		_engine.stop()
	if cam != null:
		cam.queue_free()
		cam = null


func orbit(dx: float, dy: float) -> void:
	cam_yaw = wrapf(cam_yaw - dx * 0.004, -PI, PI)
	_cam_pitch = clampf(_cam_pitch + dy * 0.003, 0.05, 0.9)


func _physics_process(delta: float) -> void:
	_hit_cool = maxf(0.0, _hit_cool - delta)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -0.5
	if dead:
		speed = move_toward(speed, 0.0, 12.0 * delta)
		_move(delta)
		_burn(delta)
		return
	var paused_ui: bool = game != null and game.ui_open()
	var throttle := 0.0
	var steer_in := 0.0
	var hb := false
	if driving and not paused_ui:
		throttle = Input.get_axis("move_back", "move_forward")
		# Triggers are analog gas and brake on a pad.
		if Pad.using_pad:
			# On a pad the triggers are gas and brake; the stick only steers.
			throttle = Pad.trigger(true) - Pad.trigger(false)
		steer_in = Input.get_axis("move_right", "move_left")
		hb = Input.is_physical_key_pressed(KEY_SPACE) or Pad.button(JOY_BUTTON_X)
		if Input.is_physical_key_pressed(KEY_G) and _hit_cool <= 0.0:
			_hit_cool = 0.6
			AudioManager.play_3d("horn", global_position, -2.0)
			_scatter_peds(18.0)
	# Engine and brakes.
	if throttle > 0.0:
		if speed < -0.5:
			speed = move_toward(speed, 0.0, BRAKE * delta)
		else:
			speed += ACCEL * throttle * (1.0 - clampf(speed / MAX_FWD, 0.0, 1.0) * 0.85) * delta
	elif throttle < 0.0:
		if speed > 0.5:
			speed = move_toward(speed, 0.0, BRAKE * delta)
		else:
			speed -= 6.0 * delta
	else:
		speed = move_toward(speed, 0.0, 2.6 * delta)
	if hb:
		speed = move_toward(speed, 0.0, 13.0 * delta)
	speed = clampf(speed, -MAX_REV, MAX_FWD * (0.55 if hp < 25.0 else 1.0))
	# Steering: none at a standstill, sharp at city speed, a bit lazier flat out.
	steer = move_toward(steer, steer_in, 3.5 * delta)
	var sp := absf(speed)
	var grip := clampf(sp / 4.0, 0.0, 1.0) * lerpf(1.9, 0.95, clampf(sp / MAX_FWD, 0.0, 1.0))
	if hb:
		grip *= 1.7
	rotation.y += steer * grip * signf(speed) * delta
	_move(delta)
	if driving:
		_run_over(delta)
	if _engine != null and _engine.playing:
		_engine.pitch_scale = 0.7 + sp / MAX_FWD * 1.5 + absf(throttle) * 0.1
	_smoke.visible = hp < 40.0
	if hp < 40.0:
		_smoke.position.y = 1.2 + sin(Time.get_ticks_msec() * 0.006) * 0.08


func _move(delta: float) -> void:
	var fwd := -global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var vy := velocity.y
	velocity = fwd * speed
	velocity.y = vy
	var before := speed
	move_and_slide()
	# Crashes: speed into a wall or another car hurts both.
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var n := c.get_normal()
		if n.y > 0.6:
			continue
		var impact := absf(before) * absf(fwd.dot(n))
		if impact > 4.0 and _hit_cool <= 0.0:
			_hit_cool = 0.35
			damage(impact * 1.4)
			AudioManager.play_3d("thud", global_position, 0.0, 0.6)
			if driving:
				Pad.rumble(0.6, clampf(impact / 20.0, 0.3, 1.0), 0.3)
			speed = -before * 0.18
			if driving and impact > 14.0 and game != null:
				game.player.take_damage((impact - 14.0) * 1.5, global_position)
			var other := c.get_collider()
			if other is Vehicle and other != self:
				(other as Vehicle).damage(impact)
			elif other != null and other.get_class() == "AnimatableBody3D" and driving and impact > 8.0 and game != null:
				game.crime_witnessed(global_position)
			break
	if global_position.y < -20.0:
		global_position.y = 1.0
		velocity = Vector3.ZERO


## People in front of a moving car get hit. It's a crime, and it's on you.
func _run_over(delta: float) -> void:
	_last_hit_ped = maxf(0.0, _last_hit_ped - delta)
	var sp := absf(speed)
	if sp < 5.0 or game == null:
		return
	var fwd := -global_transform.basis.z * signf(speed)
	var front := global_position + fwd * 2.4
	if game.crowd != null:
		for p in game.crowd.peds:
			var ped = p
			if not is_instance_valid(ped) or ped.dead:
				continue
			var d: Vector3 = ped.global_position - front
			d.y = 0.0
			if d.length() < 1.6:
				ped.die(game.player)
				AudioManager.play_3d("thud", ped.global_position, 2.0)
				game.blood(ped.global_position + Vector3(0, 0.8, 0))
				game.crime_witnessed(ped.global_position)
				speed *= 0.85
	for n in get_tree().get_nodes_in_group("npc"):
		var o := n as NPC
		if o == null or o.dead or o.cell != GameState.cell or GameState.companions.has(o.id):
			continue
		var d2 := o.global_position - front
		d2.y = 0.0
		if d2.length() < 1.7 and _last_hit_ped <= 0.0:
			_last_hit_ped = 0.3
			o.take_hit(sp * 5.5, game.player, false, false, 1.2)
			AudioManager.play_3d("thud", o.global_position, 2.0)
			speed *= 0.8


func _scatter_peds(r: float) -> void:
	if game == null or game.crowd == null:
		return
	for p in game.crowd.peds:
		var ped = p
		if is_instance_valid(ped) and not ped.dead and ped.global_position.distance_to(global_position) < r:
			ped.flee_from(global_position)


## Bullets hurt cars too (half damage: they're mostly metal).
func take_hit(dmg: float, _attacker: Node, _head: bool, _crit: bool, _stun: float) -> void:
	damage(dmg * 0.5)
	AudioManager.play_3d("ricochet", global_position + Vector3(0, 1, 0), -6.0)


func damage(d: float) -> void:
	if dead:
		return
	hp -= d
	if hp <= 0.0:
		explode()


func explode() -> void:
	dead = true
	hp = 0.0
	_burn_t = 12.0
	_glow.visible = false
	_smoke.visible = true
	_smoke.scale = Vector3(2.2, 2.2, 2.2)
	AudioManager.play_3d("death", global_position, 6.0, 0.4)
	AudioManager.play_3d("gun_shotgun", global_position, 8.0, 0.35)
	if game != null:
		game.impact(global_position + Vector3(0, 1.0, 0), Vector3.UP)
		if game.player.global_position.distance_to(global_position) < 7.0:
			game.player.take_damage(55.0 if driving else 30.0, global_position)
		if driving:
			game.exit_vehicle(true)
	for n in get_tree().get_nodes_in_group("npc"):
		var o := n as NPC
		if o != null and not o.dead and o.global_position.distance_to(global_position) < 6.0:
			o.take_hit(80.0, game.player if game != null else null, false, false, 0.0)
	# Burned-out wrecks are dark and dead.
	_mesh.mesh = Props.car_meshes("car_%s_%d" % [kind, 0])[0]
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.08, 0.07, 0.07)
	_mesh.material_override = dark


func _burn(delta: float) -> void:
	if _burn_t <= 0.0:
		return
	_burn_t -= delta
	_smoke.position.y = 1.4 + sin(Time.get_ticks_msec() * 0.01) * 0.1
	if _burn_t <= 0.0:
		_smoke.visible = false


func _process(delta: float) -> void:
	if not driving or cam == null:
		return
	# Chase camera: behind the car, swings with the mouse, never inside a wall.
	var back := global_transform.basis.z
	back.y = 0.0
	back = back.normalized().rotated(Vector3.UP, cam_yaw)
	var dist := 7.0 + absf(speed) * 0.06
	var want := global_position + back * dist * cos(_cam_pitch) + Vector3(0, 1.4 + dist * sin(_cam_pitch), 0)
	var look := global_position + Vector3(0, 1.3, 0)
	var q := PhysicsRayQueryParameters3D.create(look, want, Phys.WORLD)
	q.exclude = [get_rid()]
	var res := get_world_3d().direct_space_state.intersect_ray(q)
	if not res.is_empty():
		want = (res["position"] as Vector3) + (look - want).normalized() * 0.4
	cam.global_position = cam.global_position.lerp(want, minf(1.0, delta * 8.0))
	if cam.global_position.distance_to(look) > 0.1:
		cam.look_at(look, Vector3.UP)
	cam.fov = lerpf(cam.fov, 70.0 + absf(speed) * 0.35, minf(1.0, delta * 3.0))
	# Let cam_yaw drift back behind the car when you're driving forward.
	if absf(speed) > 6.0:
		cam_yaw = lerp_angle(cam_yaw, 0.0, minf(1.0, delta * 1.2))


## A looping engine hum, synthesized once.
static func _engine_loop() -> AudioStreamWAV:
	if _engine_stream != null:
		return _engine_stream
	var rate := 22050
	var n := rate / 2
	var data := PackedByteArray()
	data.resize(n * 2)
	var f := 56.0 # 28 whole cycles in the half-second loop: no click
	for i in n:
		var t := float(i) / float(rate)
		var v := 0.45 * sin(TAU * f * t) + 0.25 * sin(TAU * f * 2.0 * t) + 0.12 * sin(TAU * f * 3.0 * t + 0.4)
		v += (fmod(t * f * 4.0, 1.0) - 0.5) * 0.12
		v *= 0.8 + 0.2 * sin(TAU * 12.0 * t)
		var s := int(clampf(v * 0.6, -1.0, 1.0) * 32000.0)
		data.encode_s16(i * 2, s)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = n
	_engine_stream = w
	return w
