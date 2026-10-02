class_name Player
extends CharacterBody3D
## Elliot, first person. Movement, sneak, weapons (hitscan + melee), aiming,
## reload, flashlight, and the interaction ray. The Game decides when the
## player is frozen (menus, dialogue, cinematics).

signal fired(weapon_id: String)

const WALK := 4.2
const RUN := 5.6
const SPRINT := 8.4
const CROUCH := 2.4
const JUMP_V := 5.2
const GRAVITY := 20.0

var game: Node = null
var frozen: bool = false
var cam: Camera3D
var crouching: bool = false
var sprinting: bool = false
var aiming: bool = false
var detection: int = 0 # 0 hidden, 1 caution, 2 danger (set by NPCs)
var interact_target: Object = null
var driving: Vehicle = null # the car we're in, if any
var yaw: float = 0.0
var pitch: float = 0.0

var _col: CollisionShape3D
var _shape: CapsuleShape3D
var _lamp: SpotLight3D
var _lamp_on: bool = false
var _vm_root: Node3D
var _vm: MeshInstance3D
var _vm_model: String = ""
var _flash: MeshInstance3D
var _flash_t: float = 0.0
var _cool: float = 0.0
var _reload_t: float = 0.0
var _swing_t: float = 0.0
var _recoil: float = 0.0
var _bob_t: float = 0.0
var _step_t: float = 0.0
var _want_jump: bool = false
var _hurt_t: float = 0.0
var _fire_held: bool = false
var _fire_edge: bool = false
var _base_fov: float = 75.0
var _last_weapon: String = ""
var _noise: float = 0.0
var _sway: Vector2 = Vector2.ZERO
var _land_dip: float = 0.0
var _was_air: bool = false
var _fall_start_y: float = 0.0
var _move_amount: float = 0.0


func _ready() -> void:
	add_to_group("player")
	collision_layer = Phys.PLAYER
	collision_mask = Phys.WORLD | Phys.NPC | Phys.CAR
	floor_snap_length = 0.35
	floor_max_angle = deg_to_rad(50.0)
	_col = CollisionShape3D.new()
	_shape = CapsuleShape3D.new()
	_shape.radius = 0.32
	_shape.height = 1.75
	_col.shape = _shape
	_col.position = Vector3(0, 0.875, 0)
	add_child(_col)
	cam = Camera3D.new()
	cam.position = Vector3(0, 1.62, 0)
	cam.near = 0.05
	cam.far = Settings.view_far()
	_base_fov = float(Settings.get_v("fov"))
	cam.fov = _base_fov
	add_child(cam)
	cam.make_current()
	_lamp = SpotLight3D.new()
	_lamp.position = Vector3(0.1, -0.05, 0.0)
	_lamp.light_color = Color(1.0, 0.95, 0.85)
	_lamp.light_energy = 3.4
	_lamp.spot_range = 34.0
	_lamp.spot_angle = 38.0
	_lamp.spot_attenuation = 0.8
	_lamp.visible = false
	cam.add_child(_lamp)
	_vm_root = Node3D.new()
	cam.add_child(_vm_root)
	_vm = MeshInstance3D.new()
	_vm.material_override = Mats.lit
	_vm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_vm_root.add_child(_vm)
	_flash = MeshInstance3D.new()
	var fb := MeshBatch.new()
	fb.sphere(Vector3.ZERO, 0.06, Color(1.0, 0.8, 0.4), 6, 3)
	fb.box(Vector3.ZERO, Vector3(0.18, 0.02, 0.02), Color(1.0, 0.9, 0.5))
	fb.box(Vector3.ZERO, Vector3(0.02, 0.18, 0.02), Color(1.0, 0.9, 0.5))
	_flash.mesh = fb.to_mesh()
	_flash.material_override = Mats.glow
	_flash.visible = false
	_vm_root.add_child(_flash)
	GameState.equipment_changed.connect(_refresh_viewmodel)
	_refresh_viewmodel()
	Settings.applied.connect(func() -> void:
		cam.far = Settings.view_far()
		_base_fov = float(Settings.get_v("fov")))


## Move without it counting as a fall (cell changes, elevators, leaving a car).
func teleport(p: Vector3) -> void:
	global_position = p
	velocity = Vector3.ZERO
	_was_air = false
	_fall_start_y = p.y


func set_look(y: float, p: float = 0.0) -> void:
	yaw = y
	pitch = clampf(p, -1.45, 1.45)
	rotation.y = yaw
	cam.rotation.x = pitch


func look_toward(point: Vector3, weight: float = 1.0) -> void:
	var from := cam.global_position
	var d := point - from
	if d.length() < 0.01:
		return
	var ty := atan2(-d.x, -d.z)
	var tp := atan2(d.y, Vector2(d.x, d.z).length())
	var ny := lerp_angle(yaw, ty, weight)
	var np := lerpf(pitch, tp, weight)
	set_look(ny, np)


func _unhandled_input(event: InputEvent) -> void:
	if frozen or get_tree().paused:
		return
	if driving != null:
		# In a car the mouse swings the chase camera; everything else is the car's.
		if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			var mm := event as InputEventMouseMotion
			driving.orbit(mm.relative.x, mm.relative.y)
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var m := event as InputEventMouseMotion
		var sens := 0.0022 * float(Settings.get_v("mouse_sens"))
		if aiming:
			sens *= 0.6
		var inv := -1.0 if bool(Settings.get_v("invert_y")) else 1.0
		set_look(yaw - m.relative.x * sens, pitch - m.relative.y * sens * inv)
		_sway += Vector2(m.relative.x, m.relative.y) * 0.0006
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_fire_held = mb.pressed
			if mb.pressed:
				_fire_edge = true
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			aiming = mb.pressed
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_cycle_weapon(-1)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_cycle_weapon(1)
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k := (event as InputEventKey).physical_keycode
		match k:
			KEY_SPACE:
				_want_jump = true
			KEY_CTRL, KEY_C:
				crouching = not crouching
			KEY_R:
				start_reload()
			KEY_F:
				_lamp_on = not _lamp_on
				_lamp.visible = _lamp_on
				AudioManager.play_key()
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8:
				var idx := int(k - KEY_1)
				var wid := str(GameState.hotkeys[idx]) if idx < GameState.hotkeys.size() else ""
				if wid != "" and (wid == "fists" or GameState.has_item(wid)):
					GameState.equip(wid)


func _cycle_weapon(dir: int) -> void:
	var list: Array = ["fists"]
	for id in GameState.inventory.keys():
		if str(DB.item(str(id)).get("type", "")) == "weapon":
			list.append(str(id))
	var cur := list.find(str(GameState.equipped["weapon"]))
	var nxt := (cur + dir + list.size()) % list.size()
	GameState.equip(str(list[nxt]))


func _physics_process(delta: float) -> void:
	if driving != null:
		interact_target = null
		velocity = Vector3.ZERO
		if is_instance_valid(driving):
			global_position = driving.global_position + Vector3(0, 0.4, 0)
			yaw = driving.rotation.y
		_move_amount = 0.0
		_noise = 0.8
		return
	_update_interact()
	if frozen:
		velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 30.0 * delta)
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		else:
			velocity.y = 0.0
		move_and_slide()
		_want_jump = false
		_move_amount = 0.0
		return
	var ix := Input.get_axis("move_left", "move_right")
	var iz := Input.get_axis("move_forward", "move_back")
	var dir := (transform.basis * Vector3(ix, 0, iz))
	dir.y = 0.0
	if dir.length() > 1.0:
		dir = dir.normalized()
	sprinting = (Input.is_physical_key_pressed(KEY_SHIFT) or Pad.button(JOY_BUTTON_LEFT_STICK)) and iz < 0.0 and not aiming
	if sprinting and crouching:
		crouching = false
	var spd := RUN
	if crouching:
		spd = CROUCH
	elif sprinting:
		spd = SPRINT
	elif aiming:
		spd = WALK * 0.8
	# Low health / low stability drag your feet.
	if GameState.hp < GameState.max_hp() * 0.2:
		spd *= 0.85
	var target := dir * spd
	var accel := 40.0 if is_on_floor() else 8.0
	velocity.x = move_toward(velocity.x, target.x, accel * delta)
	velocity.z = move_toward(velocity.z, target.z, accel * delta)
	if is_on_floor():
		if _was_air:
			var fall := _fall_start_y - global_position.y
			_land_dip = clampf(fall * 0.05, 0.0, 0.15)
			if fall > 5.5:
				take_damage((fall - 5.5) * 12.0, global_position)
			AudioManager.play_step()
		_was_air = false
		if _want_jump:
			velocity.y = JUMP_V
			crouching = false
	else:
		if not _was_air:
			_fall_start_y = global_position.y
		_was_air = true
		velocity.y -= GRAVITY * delta
	_want_jump = false
	move_and_slide()
	if global_position.y < -20.0:
		# Fell out of the world somehow: put us back on the street.
		global_position = Vector3(global_position.x, 2.0, global_position.z)
		velocity = Vector3.ZERO
	# Capsule + eye height for crouch.
	var eye := 1.0 if crouching else 1.62
	_shape.height = 1.1 if crouching else 1.75
	_col.position.y = _shape.height * 0.5
	_move_amount = Vector2(velocity.x, velocity.z).length()
	if _move_amount > 0.5 and is_on_floor():
		_bob_t += delta * (_move_amount * 1.9)
		_step_t += delta
		var step_int := 0.28 if sprinting else (0.55 if crouching else 0.4)
		if _step_t > step_int:
			_step_t = 0.0
			if not crouching:
				AudioManager.play_step()
	var bob := sin(_bob_t) * 0.04 * minf(1.0, _move_amount / RUN)
	_land_dip = move_toward(_land_dip, 0.0, delta * 0.6)
	cam.position.y = lerpf(cam.position.y, eye + bob - _land_dip, 0.25)
	# Noise: sprinting loud, crouch quiet.
	if crouching:
		_noise = 0.15
	elif sprinting:
		_noise = 0.4 if GameState.has_perk("silent_running") else 1.0
	elif _move_amount > 0.5:
		_noise = 0.5
	else:
		_noise = 0.1


func _process(delta: float) -> void:
	# Mouse capture follows UI state.
	var want_capture := not frozen and not get_tree().paused
	if want_capture and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif not want_capture and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if frozen or driving != null:
		_fire_held = false
		_fire_edge = false
		aiming = false
	# Right stick: look (or swing the chase camera in a car).
	if not frozen and not get_tree().paused:
		var lv := Pad.look_vector()
		if lv != Vector2.ZERO:
			var ps := float(Settings.get_v("pad_sens"))
			if driving != null:
				driving.orbit(lv.x * delta * 900.0 * ps, lv.y * delta * 500.0 * ps)
			else:
				var aimslow := 0.45 if aiming else 1.0
				# A little aim friction over a target, like Fallout on a pad.
				if game != null and game.aim_target() != null:
					aimslow *= 0.6
				var inv := -1.0 if bool(Settings.get_v("invert_y")) else 1.0
				set_look(yaw - lv.x * delta * 2.9 * ps * aimslow, pitch - lv.y * delta * 2.1 * ps * aimslow * inv)
	if driving != null:
		return
	var wid := str(GameState.equipped["weapon"])
	if wid != _last_weapon:
		_last_weapon = wid
		_refresh_viewmodel()
		_cool = 0.3
		_reload_t = 0.0
	var w := DB.item(wid)
	# FOV: aim zoom, sprint push.
	var tfov := _base_fov
	if aiming:
		tfov = _base_fov / float(w.get("zoom", 1.3))
	elif sprinting and _move_amount > 1.0:
		tfov = _base_fov + 6.0
	cam.fov = lerpf(cam.fov, tfov, minf(1.0, delta * 12.0))
	_cool = maxf(0.0, _cool - delta)
	_hurt_t = maxf(0.0, _hurt_t - delta)
	if _reload_t > 0.0:
		_reload_t -= delta
		if _reload_t <= 0.0:
			_finish_reload()
	if not frozen:
		var auto := bool(w.get("auto", false))
		if (_fire_edge or (auto and _fire_held)) and _cool <= 0.0 and _reload_t <= 0.0:
			attack()
	_fire_edge = false
	_animate_viewmodel(delta, w)
	if _flash_t > 0.0:
		_flash_t -= delta
		_flash.visible = _flash_t > 0.0


func _animate_viewmodel(delta: float, w: Dictionary) -> void:
	_recoil = move_toward(_recoil, 0.0, delta * 4.0)
	_sway = _sway.lerp(Vector2.ZERO, minf(1.0, delta * 8.0))
	var bob := sin(_bob_t * 0.5) * 0.012 * minf(1.0, _move_amount / RUN)
	var bobx := cos(_bob_t * 0.5) * 0.01 * minf(1.0, _move_amount / RUN)
	var pos := Vector3(bobx - _sway.x, bob + _sway.y, _recoil * 0.08)
	var rot := Vector3(_recoil * 0.35, 0, 0)
	if aiming and w.has("mag"):
		pos += Vector3(-0.14, 0.05, 0.05)
	if sprinting and _move_amount > 1.0:
		pos += Vector3(0.03, -0.06, 0)
		rot += Vector3(-0.3, 0.4, 0)
	if _reload_t > 0.0:
		var t := 1.0 - _reload_t / maxf(0.1, float(w.get("reload", 1.5)))
		var dip := sin(t * PI)
		pos += Vector3(0, -0.18 * dip, 0)
		rot += Vector3(-0.6 * dip, 0, 0.3 * dip)
	if _swing_t > 0.0:
		_swing_t = maxf(0.0, _swing_t - delta)
		var s := sin((1.0 - _swing_t / 0.35) * PI)
		pos += Vector3(-0.12 * s, 0.06 * s, -0.18 * s)
		rot += Vector3(-0.5 * s, 0.6 * s, 0)
	_vm_root.position = _vm_root.position.lerp(pos, minf(1.0, delta * 18.0))
	_vm_root.rotation = _vm_root.rotation.lerp(rot, minf(1.0, delta * 18.0))


func _refresh_viewmodel() -> void:
	var wid := str(GameState.equipped["weapon"])
	var model := str(DB.item(wid).get("model", "fists"))
	var body := str(GameState.equipped.get("body", ""))
	var sleeve := Color(0.08, 0.08, 0.09)
	match str(DB.item(body).get("look", "hoodie")):
		"office": sleeve = Color(0.75, 0.8, 0.88)
		"leather": sleeve = Color(0.12, 0.08, 0.06)
		"suit": sleeve = Color(0.1, 0.1, 0.14)
		"vest": sleeve = Color(0.15, 0.17, 0.12)
		"guard": sleeve = Color(0.2, 0.22, 0.3)
		"darkarmy": sleeve = Color(0.04, 0.04, 0.05)
		"coveralls": sleeve = Color(0.3, 0.35, 0.45)
		"robot": sleeve = Color(0.28, 0.3, 0.2)
	_vm_model = model
	_vm.mesh = Viewmodel.mesh_for(model, sleeve)
	_flash.position = Viewmodel.muzzle(model)


# ------------------------------------------------------------------ combat
func weapon() -> Dictionary:
	return DB.item(str(GameState.equipped["weapon"]))


func is_melee(w: Dictionary) -> bool:
	return not w.has("mag")


func start_reload() -> void:
	var wid := str(GameState.equipped["weapon"])
	var w := DB.item(wid)
	if is_melee(w) or _reload_t > 0.0:
		return
	var mag := int(w.get("mag", 0))
	var have := int(GameState.mags.get(wid, 0))
	if have >= mag:
		return
	if GameState.count(str(w.get("ammo", ""))) <= 0:
		if game != null:
			game.hud_msg("No %s" % DB.item_name(str(w.get("ammo", ""))))
		return
	_reload_t = float(w.get("reload", 1.5))
	AudioManager.play_reload()


func _finish_reload() -> void:
	var wid := str(GameState.equipped["weapon"])
	var w := DB.item(wid)
	var mag := int(w.get("mag", 0))
	var have := int(GameState.mags.get(wid, 0))
	var ammo := str(w.get("ammo", ""))
	var need := mag - have
	var got := GameState.take(ammo, need, true)
	GameState.mags[wid] = have + got


func spread_deg(w: Dictionary) -> float:
	var s := float(w.get("spread", 1.0))
	var sk := float(GameState.skill(str(w.get("skill", "guns"))))
	s *= 1.7 - sk / 100.0
	if aiming:
		s *= 0.45
	if crouching:
		s *= 0.75
	if _move_amount > 1.0:
		s *= 1.0 + minf(1.0, _move_amount / RUN) * 0.8
	if GameState.has_trait("heavy_handed"):
		s *= 1.3
	if GameState.has_trait("trigger_discipline"):
		s *= 0.75
	if GameState.has_trait("spray_and_pray"):
		s *= 1.25
	return s


func fire_interval(w: Dictionary) -> float:
	var r := float(w.get("rate", 1.0))
	if GameState.has_trait("trigger_discipline"):
		r *= 0.8
	if GameState.has_trait("spray_and_pray") and not is_melee(w):
		r *= 1.2
	return 1.0 / maxf(0.1, r)


## Returns the damage multiplier from skill for a weapon.
func skill_mult(w: Dictionary) -> float:
	var sk := float(GameState.skill(str(w.get("skill", "guns"))))
	var m := 0.7 + sk * 0.006
	if is_melee(w):
		if GameState.has_perk("bruiser"):
			m *= 1.25
		if GameState.has_trait("heavy_handed"):
			m *= 1.25
	return m


func attack(forced_target: Node = null, forced_point: Vector3 = Vector3.INF, exploit_hit: int = -1) -> void:
	var wid := str(GameState.equipped["weapon"])
	var w := DB.item(wid)
	if is_melee(w):
		_melee(w, forced_target, exploit_hit)
		return
	var loaded := int(GameState.mags.get(wid, 0))
	if loaded > 0:
		Pad.rumble(0.25, 0.35 if float(w.get("dmg", 5.0)) > 30.0 else 0.15, 0.08)
	if loaded <= 0:
		AudioManager.play_dry()
		_cool = 0.3
		start_reload()
		return
	GameState.mags[wid] = loaded - 1
	_cool = fire_interval(w)
	_recoil = minf(1.0, _recoil + 0.35)
	_flash_t = 0.05
	_flash.visible = true
	AudioManager.play_gunshot(str(w.get("model", "pistol")), bool(w.get("silent", false)))
	emit_signal("fired", wid)
	if game != null:
		game.noise(global_position, 12.0 if bool(w.get("silent", false)) else 60.0, true)
	var pellets := int(w.get("pellets", 1))
	var from := cam.global_position
	for i in pellets:
		var dir: Vector3
		if forced_point != Vector3.INF:
			dir = (forced_point - from).normalized()
		else:
			dir = -cam.global_transform.basis.z
			var sp := deg_to_rad(spread_deg(w))
			var r1 := randf() * TAU
			var r2 := sqrt(randf()) * sp
			var right := cam.global_transform.basis.x
			var up := cam.global_transform.basis.y
			dir = (dir + right * cos(r1) * tan(r2) + up * sin(r1) * tan(r2)).normalized()
		_hitscan(from, dir, float(w.get("range", 50.0)), w, forced_target, exploit_hit)
	if int(GameState.mags.get(wid, 0)) <= 0 and GameState.count(str(w.get("ammo", ""))) > 0:
		start_reload()


func _hitscan(from: Vector3, dir: Vector3, rng: float, w: Dictionary, forced_target: Node, exploit_hit: int) -> void:
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * rng, Phys.WORLD | Phys.NPC | Phys.CAR)
	q.exclude = [get_rid()]
	var res := space.intersect_ray(q)
	# EXPLOIT mode: a hit roll already happened; force the hit on the target.
	if exploit_hit == 1 and forced_target != null and is_instance_valid(forced_target):
		_damage_npc(forced_target, w, forced_target.call("head_pos") if forced_target.has_method("head_pos") else forced_target.global_position, true)
		return
	if exploit_hit == 0:
		# A miss: bullet goes wide.
		if not res.is_empty() and game != null:
			game.impact(res["position"], res.get("normal", Vector3.UP))
		return
	if res.is_empty():
		return
	var col: Object = res["collider"]
	if col != null and col.has_method("take_hit"):
		_damage_npc(col, w, res["position"], false)
	elif game != null:
		game.impact(res["position"], res.get("normal", Vector3.UP))


func _damage_npc(npc: Object, w: Dictionary, hit_pos: Vector3, exploit: bool) -> void:
	var dmg := float(w.get("dmg", 5.0)) * skill_mult(w)
	var head := false
	if npc.has_method("is_head_hit"):
		head = bool(npc.call("is_head_hit", hit_pos))
	if exploit and npc.has_method("head_pos"):
		head = hit_pos.distance_to(npc.call("head_pos")) < 0.3
	var crit := false
	var crit_chance := 0.05 + (0.1 if GameState.has_perk("finesse") else 0.0)
	if detection == 0 and crouching:
		crit = true # sneak attack
	elif randf() < crit_chance:
		crit = true
	if head:
		dmg *= 2.0
	if crit:
		dmg *= 2.0 * (1.25 if GameState.has_perk("better_criticals") else 1.0)
	if exploit:
		dmg *= 1.15
	var stun := float(w.get("stun", 0.0))
	npc.call("take_hit", dmg, self, head, crit, stun)
	if game != null:
		game.hit_marker(head or crit)


func _melee(w: Dictionary, forced_target: Node, exploit_hit: int) -> void:
	_cool = fire_interval(w)
	_swing_t = 0.35
	AudioManager.play_swing()
	if game != null:
		game.noise(global_position, 6.0, false)
	await get_tree().create_timer(0.12, false).timeout
	if not is_instance_valid(self):
		return
	var reach := float(w.get("range", 2.2)) + 0.3
	var target: Object = null
	var hit_pos := Vector3.ZERO
	if forced_target != null and is_instance_valid(forced_target):
		if exploit_hit == 1 and forced_target.global_position.distance_to(global_position) < reach + 1.5:
			target = forced_target
			hit_pos = forced_target.call("head_pos") if forced_target.has_method("head_pos") else forced_target.global_position
	else:
		var from := cam.global_position
		var dir := -cam.global_transform.basis.z
		var q := PhysicsRayQueryParameters3D.create(from, from + dir * reach, Phys.WORLD | Phys.NPC)
		q.exclude = [get_rid()]
		var res := get_world_3d().direct_space_state.intersect_ray(q)
		if not res.is_empty() and (res["collider"] as Object).has_method("take_hit"):
			target = res["collider"]
			hit_pos = res["position"]
		elif game != null:
			# Aim assist: closest NPC in a narrow cone.
			var best: Object = null
			var best_d := reach
			for n in get_tree().get_nodes_in_group("npc"):
				var nn := n as Node3D
				if nn == null or not n.has_method("take_hit") or bool(n.get("dead")):
					continue
				var to := (nn.global_position + Vector3(0, 1.2, 0)) - from
				var d := to.length()
				if d < best_d and dir.dot(to.normalized()) > 0.85:
					best = n
					best_d = d
			if best != null:
				target = best
				hit_pos = (best as Node3D).global_position + Vector3(0, 1.2, 0)
			elif not res.is_empty():
				AudioManager.play_thud()
	if target != null:
		AudioManager.play_punch()
		_damage_npc(target, w, hit_pos, exploit_hit == 1)


func take_damage(amount: float, from_pos: Vector3) -> void:
	if GameState.hp <= 0.0:
		return
	var dt := GameState.damage_threshold()
	var dmg := maxf(amount * 0.2, amount - dt)
	GameState.damage(dmg)
	_hurt_t = 0.4
	Pad.rumble(0.5, 0.8 if dmg > 20.0 else 0.4, 0.25)
	AudioManager.play_hurt()
	if game != null:
		game.on_player_hurt(dmg, from_pos)


func noise_level() -> float:
	return _noise


func is_sneaking() -> bool:
	return crouching


func eye_pos() -> Vector3:
	return cam.global_position


# -------------------------------------------------------------- interaction
func _update_interact() -> void:
	interact_target = null
	if frozen or cam == null:
		return
	var from := cam.global_position
	var to := from - cam.global_transform.basis.z * 3.0
	var q := PhysicsRayQueryParameters3D.create(from, to, Phys.WORLD | Phys.NPC | Phys.INTERACT)
	q.collide_with_areas = true
	q.exclude = [get_rid()]
	var res := get_world_3d().direct_space_state.intersect_ray(q)
	var max_t := 3.0
	if not res.is_empty():
		var c: Object = res["collider"]
		if c != null and c.has_method("interact_info"):
			var info: Dictionary = c.call("interact_info")
			if not info.is_empty():
				interact_target = c
				return
		max_t = minf(3.0, from.distance_to(res["position"]) + 0.35)
	# Nothing with a node of its own: ask the city's prop index (dumpsters,
	# parked cars, newsboxes, ATMs, generic doors...).
	if game != null and game.has_method("loot_pick"):
		var v: Object = game.loot_pick(from, -cam.global_transform.basis.z, max_t)
		if v != null:
			interact_target = v
