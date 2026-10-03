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
var _headlights: SpotLight3D
## Police pursuit AI (Game spawns these when the heat is up). ai_target is
## the player, or the car they're driving; on_arrive fires once when the car
## pulls up next to a target on foot (the officers get out).
var ai_target: Node3D = null
var ai_on_arrive: Callable
var ai_speed_mul: float = 0.92
## Racing: the target is a checkpoint to drive through, not someone to stop beside.
var ai_race: bool = false
var _ai_stuck_t: float = 0.0
var _ai_rev_t: float = 0.0
var _ai_arrived: bool = false
var _ai_last_pos := Vector3.ZERO
var _ai_turn_at := Vector3.INF # the next corner it has to turn at, if routing
var _hit_cool: float = 0.0
var _burn_t: float = 0.0
var _last_hit_ped: float = 0.0
var launched := false # flying off a ramp (lighter gravity until the wheels come down)
var air_time := 0.0
var _ramp_n := Vector3.UP # the last slope you drove up, remembered for a moment
var _ramp_t := 0.0
var _was_floor := true
## The meshes and lights hang off `vis`, which is drawn part-way between the
## last two physics ticks, so the car glides at any frame rate instead of
## stepping sixty times a second while the camera moves every frame.
var vis: Node3D
var _xf_prev := Transform3D()
var _xf_ok := false
var _lean := Vector2.ZERO # body roll (x) and pitch (y), eased per frame
var _lean_want := Vector2.ZERO
var _cam_dist := -1.0 # how far back the chase camera may sit (walls pull it in)

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
	_make_vis()
	var meshes := Props.car_meshes("car_%s_%d" % [k, ci])
	_mesh = MeshInstance3D.new()
	_mesh.mesh = meshes[0]
	_mesh.material_override = Mats.lit
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_mesh.visibility_range_end = 300.0
	vis.add_child(_mesh)
	_glow = MeshInstance3D.new()
	_glow.mesh = meshes[1]
	_glow.material_override = Mats.glow
	_glow.visibility_range_end = 400.0
	vis.add_child(_glow)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	var big := k in ["van", "truck", "ambulance"]
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
	vis.add_child(_smoke)
	position = pos
	rotation.y = yaw
	vis.transform = transform
	return self


func _make_vis() -> void:
	if vis != null:
		return
	vis = Node3D.new()
	vis.name = "Vis"
	vis.top_level = true
	add_child(vis)


func _enter_tree() -> void:
	if not get_tree().physics_frame.is_connected(_tick_start):
		get_tree().physics_frame.connect(_tick_start)
	_xf_ok = false


func _exit_tree() -> void:
	if get_tree().physics_frame.is_connected(_tick_start):
		get_tree().physics_frame.disconnect(_tick_start)


## Where the body was when this physics tick began.
func _tick_start() -> void:
	_xf_prev = global_transform
	_xf_ok = true


## The body's transform as it should be drawn this frame: between where it
## was a tick ago and where it is now. A jump of more than 20 m is a teleport.
func vis_xf() -> Transform3D:
	var cur := global_transform
	if not _xf_ok or _xf_prev.origin.distance_squared_to(cur.origin) > 400.0:
		return cur
	return _xf_prev.interpolate_with(cur, clampf(Engine.get_physics_interpolation_fraction(), 0.0, 1.0))


func _update_vis() -> void:
	if vis != null and is_inside_tree():
		vis.global_transform = vis_xf()


## Snap the drawn car to the body (after moving it by hand).
func snap_vis() -> void:
	_xf_prev = global_transform
	_update_vis()


func display_name() -> String:
	var n: String = {"sedan": "Sedan", "hatch": "Hatchback", "suv": "SUV", "van": "Van", "taxi": "Taxi", "police": "NYPD Cruiser", "truck": "Box Truck", "ambulance": "Ambulance"}.get(kind, "Car")
	if kind == "police" and WorldLayout.region != "nyc":
		n = {"chicago": "CPD Cruiser", "township": "Sheriff's Cruiser", "highway": "State Trooper"}.get(WorldLayout.region, "Police Cruiser")
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
	_cam_dist = -1.0
	if _engine == null:
		_engine = AudioStreamPlayer3D.new()
		_engine.stream = _engine_loop()
		_engine.volume_db = -14.0
		_engine.unit_size = 8.0
		_engine.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
		add_child(_engine)
	_engine.play()
	# Headlights: one real light for the car you're driving (the glow mesh
	# already paints the lamps themselves), on when it's dark.
	if _headlights == null:
		_headlights = SpotLight3D.new()
		_headlights.light_color = Color(1.0, 0.95, 0.85)
		_headlights.light_energy = 4.0
		_headlights.spot_range = 48.0
		_headlights.spot_angle = 34.0
		_headlights.spot_attenuation = 0.7
		_headlights.shadow_enabled = false
		_headlights.position = Vector3(0, 0.9, -2.4)
		_headlights.rotation.x = -0.09
		vis.add_child(_headlights)
	_headlights.visible = false


func end_drive() -> void:
	driving = false
	if _headlights != null:
		_headlights.visible = false
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
		velocity.y -= GRAVITY * (0.62 if launched else 1.0) * delta
		air_time += delta
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
	if not driving and ai_target != null and not paused_ui:
		var ai := _ai_drive(delta)
		throttle = ai.x
		steer_in = ai.y
		hb = ai.z > 0.5
	elif driving and not paused_ui:
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
	speed = clampf(speed, -MAX_REV, MAX_FWD * (0.55 if hp < 25.0 else 1.0) * (ai_speed_mul if ai_target != null and not driving else 1.0))
	# Steering: none at a standstill, sharp at city speed, a bit lazier flat out.
	steer = move_toward(steer, steer_in, 3.5 * delta)
	var sp := absf(speed)
	var grip := clampf(sp / 4.0, 0.0, 1.0) * lerpf(1.9, 0.95, clampf(sp / MAX_FWD, 0.0, 1.0))
	if hb:
		grip *= 1.7
	rotation.y += steer * grip * signf(speed) * delta
	var spd0 := speed
	_move(delta)
	# The body leans out of turns and squats or dips with the throttle.
	var turn_rate := steer * grip * signf(speed)
	var accel := (speed - spd0) / maxf(delta, 0.001)
	_lean_want = Vector2(clampf(-turn_rate * sp * 0.006, -0.07, 0.07), clampf(accel * 0.004, -0.05, 0.035))
	if driving:
		_run_over(delta)
	if _engine != null and _engine.playing:
		_engine.pitch_scale = 0.7 + sp / MAX_FWD * 1.5 + absf(throttle) * 0.1
	_smoke.visible = hp < 40.0
	if hp < 40.0:
		_smoke.position.y = 1.2 + sin(Time.get_ticks_msec() * 0.006) * 0.08


## Where to steer for `tp`: straight at it when the way is clear, else the
## next corner on an L-shaped route along the avenues and streets.
func _ai_route(tp: Vector3) -> Vector3:
	var space := get_world_3d().direct_space_state
	var eye := global_position + Vector3(0, 1.0, 0)
	var q := PhysicsRayQueryParameters3D.create(eye, tp + Vector3(0, 1.0, 0), Phys.WORLD)
	q.exclude = [get_rid()]
	_ai_turn_at = Vector3.INF
	if space.intersect_ray(q).is_empty():
		return tp
	var p := global_position
	var ic := clampi(roundi((p.x - WorldLayout.AX0) / WorldLayout.AXS), 0, WorldLayout.NA - 1)
	var jc := clampi(roundi((p.z - WorldLayout.SZ0) / WorldLayout.SZS), 0, WorldLayout.NS - 1)
	var it := clampi(roundi((tp.x - WorldLayout.AX0) / WorldLayout.AXS), 0, WorldLayout.NA - 1)
	var jt := clampi(roundi((tp.z - WorldLayout.SZ0) / WorldLayout.SZS), 0, WorldLayout.NS - 1)
	var on_ave := absf(p.x - WorldLayout.ax(ic)) < WorldLayout.AVE_HW + 2.0
	var on_st := absf(p.z - WorldLayout.sz(jc)) < WorldLayout.ST_HW + 2.0
	var corner := Vector3(WorldLayout.ax(ic), 0, WorldLayout.sz(jc))
	if on_ave and on_st:
		# In an intersection: turn onto whichever road closes the bigger gap.
		if it != ic and (jt == jc or absf(tp.x - p.x) > absf(tp.z - p.z)):
			return Vector3(WorldLayout.ax(it), 0, WorldLayout.sz(jc))
		return Vector3(WorldLayout.ax(ic), 0, WorldLayout.sz(jt))
	if on_ave:
		# Down the avenue (a point ahead on its centre line, so the car keeps
		# off the parked cars) to the target's street, or to this corner.
		var gz := WorldLayout.sz(jt) if jt != jc else corner.z
		_ai_turn_at = Vector3(corner.x, 0, gz)
		return Vector3(WorldLayout.ax(ic), 0, p.z + clampf(gz - p.z, -13.0, 13.0))
	if on_st:
		var gx := WorldLayout.ax(it) if it != ic else corner.x
		_ai_turn_at = Vector3(gx, 0, corner.z)
		return Vector3(p.x + clampf(gx - p.x, -13.0, 13.0), 0, WorldLayout.sz(jc))
	# Off the grid (a lot, a park): back to the nearest corner.
	return corner


## Pursuit driving: head for the target, look ahead for walls and steer to
## the clearer side, back out when stuck, pull up beside a target on foot.
## Returns (throttle, steer, handbrake).
func _ai_drive(delta: float) -> Vector3:
	if not is_instance_valid(ai_target):
		ai_target = null
		return Vector3.ZERO
	var tp := ai_target.global_position
	var to := tp - global_position
	to.y = 0.0
	var dist := to.length()
	var on_foot := not (ai_target is Vehicle) and not ai_race
	# No clear line to the target: follow the street grid instead (along this
	# road to the target's avenue or street, then turn), like a real driver.
	var aim := _ai_route(tp)
	var to_aim := aim - global_position
	to_aim.y = 0.0
	if on_foot and dist < 13.0:
		if not _ai_arrived and absf(speed) < 2.0:
			_ai_arrived = true
			if ai_on_arrive.is_valid():
				ai_on_arrive.call(self)
		return Vector3(0, 0, 1)
	if dist > 30.0:
		_ai_arrived = false
	var want := atan2(-to_aim.x, -to_aim.z)
	var diff := wrapf(want - rotation.y, -PI, PI)
	var steer_v := clampf(diff * 2.2, -1.0, 1.0)
	# Look ahead: a wall in front? steer to whichever side is open.
	var fwd := -global_transform.basis.z
	var space := get_world_3d().direct_space_state
	var eye := global_position + Vector3(0, 0.8, 0)
	var look := clampf(absf(speed) * 0.6, 6.0, 16.0)
	var q := PhysicsRayQueryParameters3D.create(eye, eye + fwd * look, Phys.WORLD)
	q.exclude = [get_rid()]
	if not space.intersect_ray(q).is_empty():
		var l := fwd.rotated(Vector3.UP, 0.7)
		var r := fwd.rotated(Vector3.UP, -0.7)
		var ql := PhysicsRayQueryParameters3D.create(eye, eye + l * look, Phys.WORLD)
		ql.exclude = [get_rid()]
		var qr := PhysicsRayQueryParameters3D.create(eye, eye + r * look, Phys.WORLD)
		qr.exclude = [get_rid()]
		var lfree := space.intersect_ray(ql).is_empty()
		var rfree := space.intersect_ray(qr).is_empty()
		if lfree and not rfree:
			steer_v = 1.0
		elif rfree and not lfree:
			steer_v = -1.0
	# Stuck against something: reverse a moment with the wheel the other way.
	if _ai_rev_t > 0.0:
		_ai_rev_t -= delta
		return Vector3(-1.0, -steer_v, 0)
	# Judge "stuck" by distance actually covered, not by the speedometer
	# (pushing against a parked car reads as moving).
	_ai_stuck_t += delta
	if _ai_stuck_t > 1.5:
		var moved := global_position.distance_to(_ai_last_pos)
		_ai_last_pos = global_position
		_ai_stuck_t = 0.0
		if moved < 2.0 and dist > 14.0:
			_ai_rev_t = 1.2
	var thr := 1.0
	if absf(diff) > 1.4:
		thr = 0.35
	elif absf(diff) > 0.5 and speed > 12.0:
		thr = 0.0 # don't floor it mid-turn
	# Brake for the corner: a 90-degree turn at full speed ends in a parked car.
	if _ai_turn_at != Vector3.INF:
		var cd := Vector2(_ai_turn_at.x - global_position.x, _ai_turn_at.z - global_position.z).length()
		if cd < maxf(speed * 1.4, 10.0) and speed > 10.0:
			thr = -1.0
	if on_foot and dist < 30.0:
		thr = clampf((dist - 10.0) / 20.0, 0.0, 1.0)
		if speed > dist * 0.8:
			thr = -1.0
	return Vector3(thr, steer_v, 0)


func _move(delta: float) -> void:
	var fwd := -global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var vy := velocity.y
	velocity = fwd * speed
	velocity.y = vy
	var before := speed
	move_and_slide()
	# Off the top of a ramp: keep the climb the slope gave you, and fly.
	_ramp_t = maxf(0.0, _ramp_t - delta)
	if is_on_floor():
		var fn := get_floor_normal()
		if fn.y < 0.985 and fwd.dot(fn) < -0.05:
			_ramp_n = fn # climbing a slope
			_ramp_t = 0.3
		_was_floor = true
		if launched and air_time > 0.05:
			launched = false
		air_time = 0.0
	elif _was_floor:
		_was_floor = false
		if _ramp_t > 0.0 and speed > 4.0:
			var along := (fwd - _ramp_n * fwd.dot(_ramp_n)).normalized()
			if along.y > 0.05:
				velocity.y = maxf(velocity.y, speed * along.y * 1.05)
				launched = true
				air_time = 0.0
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
	_update_vis()
	if _mesh != null and not dead:
		_lean = _lean.lerp(_lean_want if is_on_floor() else Vector2.ZERO, 1.0 - exp(-6.0 * delta))
		_mesh.rotation = Vector3(_lean.y, 0.0, _lean.x)
		_glow.rotation = _mesh.rotation
	if not driving or cam == null:
		return
	_camera(delta)


## Chase camera: behind the car, swings with the mouse, pulled in by walls
## (not by every lamp post it passes), and eased out again once clear.
func _camera(delta: float) -> void:
	if _headlights != null:
		var night := Mats.night
		_headlights.visible = night > 0.2 or GameState.weather == "rain"
	var xf := vis.global_transform if vis != null else global_transform
	var back := xf.basis.z
	back.y = 0.0
	back = back.normalized().rotated(Vector3.UP, cam_yaw)
	var dist := 7.0 + absf(speed) * 0.06
	var look := xf.origin + Vector3(0, 1.3, 0)
	var off := back * dist * cos(_cam_pitch) + Vector3(0, 0.1 + dist * sin(_cam_pitch), 0)
	var allowed := chase_clear(look, off, [get_rid()])
	if _cam_dist < 0.0:
		_cam_dist = allowed
	elif allowed < _cam_dist:
		_cam_dist = lerpf(_cam_dist, allowed, 1.0 - exp(-25.0 * delta))
	else:
		_cam_dist = lerpf(_cam_dist, allowed, 1.0 - exp(-2.5 * delta))
	var want := look + off * _cam_dist
	cam.global_position = cam.global_position.lerp(want, 1.0 - exp(-10.0 * delta))
	if cam.global_position.distance_to(look) > 0.1:
		cam.look_at(look, Vector3.UP)
	cam.fov = lerpf(cam.fov, 70.0 + absf(speed) * 0.35, 1.0 - exp(-3.0 * delta))
	# Let cam_yaw drift back behind the car when you're driving forward.
	if absf(speed) > 6.0:
		cam_yaw = lerp_angle(cam_yaw, 0.0, 1.0 - exp(-1.2 * delta))


## How much of `off` (0..1) the camera can have from `look` before a wall gets
## in the way. Three rays side by side: a thin pole only ever blocks one of
## them, so it's ignored; a wall blocks them all. The edge-of-map walls don't
## count.
func chase_clear(look: Vector3, off: Vector3, exclude: Array) -> float:
	var space := get_world_3d().direct_space_state
	var side := off.cross(Vector3.UP).normalized() * 0.7
	var frac := [1.0, 1.0, 1.0]
	var blocked := 0
	for i in 3:
		var o: Vector3 = side * float(i - 1)
		var q := PhysicsRayQueryParameters3D.create(look + o * 0.3, look + off + o, Phys.WORLD)
		q.exclude = exclude
		var res := space.intersect_ray(q)
		if res.is_empty():
			continue
		var col := res["collider"] as CollisionObject3D
		if col != null:
			var own: Object = col.shape_owner_get_owner(col.shape_find_owner(int(res["shape"])))
			if own != null and str(own.get_meta("tag", "")) == "bounds":
				continue
		var d := (look + o * 0.3).distance_to(res["position"])
		frac[i] = clampf((d - 0.5) / maxf(off.length(), 0.01), 0.12, 1.0)
		blocked += 1
	if blocked >= 2:
		return minf(float(frac[1]), minf(float(frac[0]), float(frac[2])))
	return 1.0


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
