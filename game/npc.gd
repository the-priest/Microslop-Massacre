class_name NPC
extends CharacterBody3D
## A named or templated character: talks, trades, follows, fights, dies.
## Configured from NPCData. Thinking is throttled by distance to the player.

signal died(npc: NPC)

var id: String = ""
var def: Dictionary = {}
var display_name: String = ""
var faction: String = ""
var hp: float = 50.0
var max_hp: float = 50.0
var dt: float = 0.0
var weapon: String = ""
var accuracy: float = 0.5
var aggro: String = "neutral" # neutral | hostile | guard | coward | companion
var essential: bool = false
var dead: bool = false
var cell: String = "world"
var home_pos: Vector3
var home_yaw: float = 0.0
var mode: String = "idle" # idle wander follow combat flee stunned talk dead goto
var target: Node3D = null
var game: Node = null
var restricted: bool = false # guards: player is trespassing in this cell
var picked: bool = false # already had their pocket picked
var generic: bool = false

var _mesh: MeshInstance3D
var _gun_flash: MeshInstance3D
var _col: CollisionShape3D
var _phase: float = 0.0
var _think_t: float = 0.0
var _detect: float = 0.0
var _alert_t: float = 0.0
var _lost_t: float = 0.0
var _last_seen: Vector3 = Vector3.INF
var _atk_cool: float = 1.0
var _strafe: float = 0.0
var _strafe_t: float = 0.0
var _stuck_t: float = 0.0
var _unstick_dir: Vector3 = Vector3.ZERO
var _unstick_t: float = 0.0
var _stun_t: float = 0.0
var _flash_hit: float = 0.0
var _wander_t: float = 0.0
var _wander_to: Vector3 = Vector3.INF
var _goto: Vector3 = Vector3.INF
var _bark_t: float = 0.0
var _warned: bool = false
var _sleeping: bool = false
var _talking: bool = false
var _knocked: bool = false
var loot: Dictionary = {} # items for generic NPCs (named use GameState.containers)
var loot_cash: int = 0


func setup(npc_id: String, d: Dictionary, pos: Vector3, yaw: float, in_cell: String, g: Node) -> void:
	id = npc_id
	def = d
	game = g
	cell = in_cell
	display_name = str(d.get("name", "Stranger"))
	faction = str(d.get("faction", ""))
	max_hp = float(d.get("hp", 40.0))
	hp = max_hp
	dt = float(d.get("dt", 0.0))
	weapon = str(d.get("weapon", ""))
	accuracy = float(d.get("acc", 0.45))
	aggro = str(d.get("aggro", "neutral"))
	essential = bool(d.get("essential", false))
	generic = bool(d.get("generic", false))
	home_pos = pos
	home_yaw = yaw
	position = pos
	rotation.y = yaw


func _ready() -> void:
	add_to_group("npc")
	collision_layer = Phys.NPC
	collision_mask = Phys.WORLD | Phys.NPC | Phys.PLAYER
	floor_snap_length = 0.4
	_col = CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.75
	_col.shape = cap
	_col.position = Vector3(0, 0.875, 0)
	add_child(_col)
	_mesh = MeshInstance3D.new()
	var look: Variant = def.get("look", {})
	var ld: Dictionary = {}
	if look is String:
		ld = PersonMesh.preset(str(look))
	elif look is Dictionary:
		ld = (look as Dictionary).duplicate()
	if ld.is_empty():
		var r := RandomNumberGenerator.new()
		r.seed = hash(id)
		ld = PersonMesh.random_look(r)
	if weapon != "" and not ld.has("gun") and DB.item(weapon).has("mag"):
		ld["gun"] = true
	elif weapon != "" and not DB.item(weapon).has("mag") and weapon != "fists":
		ld["club"] = true
	_mesh.mesh = PersonMesh.mesh(ld)
	_mesh.material_override = Mats.npc
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_mesh.visibility_range_end = 160.0
	add_child(_mesh)
	_gun_flash = MeshInstance3D.new()
	var fb := MeshBatch.new()
	fb.sphere(Vector3.ZERO, 0.08, Color(1.0, 0.85, 0.4), 6, 3)
	_gun_flash.mesh = fb.to_mesh()
	_gun_flash.material_override = Mats.glow
	_gun_flash.position = Vector3(0.28, 1.35, -0.55)
	_gun_flash.visible = false
	add_child(_gun_flash)
	_atk_cool = randf_range(0.6, 1.4)
	_think_t = randf() * 0.3
	if aggro == "companion":
		mode = "follow"


func head_pos() -> Vector3:
	return global_position + Vector3(0, 1.66, 0)


func chest_pos() -> Vector3:
	return global_position + Vector3(0, 1.25, 0)


func is_head_hit(p: Vector3) -> bool:
	return p.y > global_position.y + 1.52


func is_hostile_to_player() -> bool:
	if dead or aggro == "companion":
		return false
	if GameState.companions.has(id):
		return false
	if GameState.hostile.has(id):
		return true
	if aggro == "hostile":
		return true
	if faction != "" and GameState.faction_hostile(faction):
		# Disguises fool the rank and file.
		return GameState.disguise() != faction
	if aggro == "guard" and restricted:
		return GameState.disguise() != faction
	return false


func interact_info() -> Dictionary:
	if dead:
		return {"verb": "Search", "name": display_name}
	if mode == "combat" or _knocked or mode == "stunned":
		return {}
	if is_hostile_to_player():
		return {}
	if generic and can_pickpocket() and game != null and game.player != null and game.player.crouching:
		return {"verb": "Pickpocket", "name": display_name, "locked": true}
	return {"verb": "Talk", "name": display_name}


func can_pickpocket() -> bool:
	return not dead and not picked and not essential and aggro in ["coward", "neutral"] and mode != "combat" and mode != "flee" and not is_hostile_to_player()


func set_talking(on: bool) -> void:
	_talking = on
	if on:
		mode = "talk"
		velocity = Vector3.ZERO
	elif mode == "talk":
		mode = "follow" if GameState.companions.has(id) else "idle"


func face(p: Vector3, weight: float = 1.0) -> void:
	var d := p - global_position
	d.y = 0.0
	if d.length() < 0.05:
		return
	var ty := atan2(-d.x, -d.z)
	rotation.y = lerp_angle(rotation.y, ty, weight)


# ------------------------------------------------------------------ physics
func _physics_process(delta: float) -> void:
	if dead:
		return
	var p := _player()
	if p == null:
		return
	var dp := global_position.distance_to(p.global_position)
	# Sleep far away (unless following or fighting).
	var awake := dp < 90.0 or mode == "combat" or mode == "follow" or mode == "goto"
	if not awake:
		if not _sleeping:
			_sleeping = true
			velocity = Vector3.ZERO
			_mesh.set_instance_shader_parameter("amt", 0.0)
		return
	_sleeping = false
	_atk_cool -= delta
	_flash_hit = maxf(0.0, _flash_hit - delta * 4.0)
	_mesh.set_instance_shader_parameter("flash", _flash_hit)
	if _gun_flash.visible:
		_gun_flash.visible = false
	_think_t -= delta
	if _think_t <= 0.0:
		_think_t = 0.25
		_think(p, dp)
	var move := Vector3.ZERO
	var speed := 0.0
	match mode:
		"talk":
			face(p.global_position, minf(1.0, delta * 6.0))
		"stunned":
			_stun_t -= delta
			if _stun_t <= 0.0:
				_recover()
		"idle":
			if _alert_t > 0.0 and _last_seen != Vector3.INF:
				face(_last_seen, delta * 3.0)
			else:
				rotation.y = lerp_angle(rotation.y, home_yaw, delta * 2.0)
				if global_position.distance_to(home_pos) > 1.2:
					move = _dir_to(home_pos)
					speed = 1.4
				elif float(def.get("wander", 0.0)) > 0.0:
					_wander(delta)
					if _wander_to != Vector3.INF:
						move = _dir_to(_wander_to)
						speed = 1.1
						if global_position.distance_to(_wander_to) < 0.6:
							_wander_to = Vector3.INF
		"goto":
			if _goto != Vector3.INF:
				move = _dir_to(_goto)
				speed = 3.0
				if global_position.distance_to(_goto) < 0.8:
					home_pos = _goto
					_goto = Vector3.INF
					mode = "idle"
		"follow":
			# Riding along in your car or plane: tucked inside, out of the way.
			if p.get("driving") != null:
				if visible:
					visible = false
					collision_layer = 0
					collision_mask = 0
				global_position = p.global_position
				velocity = Vector3.ZERO
				return
			if not visible:
				visible = true
				collision_layer = Phys.NPC
				collision_mask = Phys.WORLD | Phys.NPC | Phys.PLAYER
				global_position = p.global_position + p.global_transform.basis.x * 1.6 + Vector3(0, 0.1, 0)
			var fd := global_position.distance_to(p.global_position)
			if fd > 45.0:
				# Catch up off-screen.
				global_position = p.global_position + p.global_transform.basis.z * 2.5 + p.global_transform.basis.x * 1.2
			elif fd > 3.5:
				move = _dir_to(p.global_position)
				speed = 5.8 if fd > 8.0 else 3.2
			else:
				face(p.global_position, delta * 3.0)
		"flee":
			var away := global_position - p.global_position
			away.y = 0.0
			move = away.normalized()
			speed = 6.0
		"combat":
			var res := _combat(delta, p)
			move = res[0]
			speed = res[1]
	# Unstick.
	if _unstick_t > 0.0:
		_unstick_t -= delta
		move = _unstick_dir
		speed = maxf(speed, 2.5)
	var hv := move * speed
	velocity.x = move_toward(velocity.x, hv.x, 20.0 * delta)
	velocity.z = move_toward(velocity.z, hv.z, 20.0 * delta)
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = -0.5
	move_and_slide()
	var real := Vector2(velocity.x, velocity.z).length()
	if speed > 0.5 and real < 0.3:
		_stuck_t += delta
		if _stuck_t > 0.8:
			_stuck_t = 0.0
			_unstick_t = 0.7
			var side := move.cross(Vector3.UP).normalized() * (1.0 if randf() < 0.5 else -1.0)
			_unstick_dir = (side + move * -0.3).normalized()
	else:
		_stuck_t = 0.0
	if real > 0.2 and mode != "combat":
		face(global_position + Vector3(velocity.x, 0, velocity.z), minf(1.0, delta * 8.0))
	_phase += delta * real * 3.2
	_mesh.set_instance_shader_parameter("phase", _phase)
	_mesh.set_instance_shader_parameter("amt", clampf(real / 2.5, 0.0, 1.0))
	_mesh.set_instance_shader_parameter("talk", 1.0 if _talking else 0.0)
	_mesh.set_instance_shader_parameter("pose", 1.0 if (mode == "combat" and DB.item(weapon).has("mag")) else 0.0)
	if global_position.y < -20.0:
		global_position = home_pos + Vector3(0, 1, 0)


func _dir_to(t: Vector3) -> Vector3:
	var d := t - global_position
	d.y = 0.0
	return d.normalized() if d.length() > 0.01 else Vector3.ZERO


func _wander(delta: float) -> void:
	_wander_t -= delta
	if _wander_t <= 0.0 and _wander_to == Vector3.INF:
		_wander_t = randf_range(4.0, 10.0)
		var r := float(def.get("wander", 3.0))
		_wander_to = home_pos + Vector3(randf_range(-r, r), 0, randf_range(-r, r))


func _player() -> Node3D:
	if game != null and game.get("player") != null:
		return game.get("player")
	return get_tree().get_first_node_in_group("player") as Node3D


# ------------------------------------------------------------------ thinking
func _think(p: Node3D, dp: float) -> void:
	_alert_t = maxf(0.0, _alert_t - 0.25)
	if mode == "stunned" or mode == "talk":
		return
	if GameState.companions.has(id):
		if mode != "combat" and mode != "follow":
			mode = "follow"
		if p.get("driving") != null:
			mode = "follow" # no fighting from the back seat
			target = null
			return
		if mode == "follow" or mode == "combat":
			var foe := _nearest_foe(p, 28.0)
			if foe != null:
				target = foe
				mode = "combat"
			elif mode == "combat":
				target = null
				mode = "follow"
		return
	if mode == "combat":
		if target == null or not is_instance_valid(target) or (target.get("dead") != null and bool(target.get("dead"))):
			target = p
		if target == p and not is_hostile_to_player() and not GameState.hostile.has(id):
			mode = "idle"
		return
	if mode == "flee":
		if dp > 40.0:
			mode = "idle"
		return
	if not is_hostile_to_player():
		_detect = 0.0
		# Guards warn trespassers once.
		if aggro == "guard" and restricted and GameState.disguise() == faction and dp < 3.0 and not _warned:
			_warned = true
			if game != null:
				game.bark(self, "Badge looks fine. Keep moving.")
		# Barks.
		_bark_t -= 0.25
		if dp < 3.5 and _bark_t <= 0.0 and def.has("barks") and game != null and mode != "talk":
			_bark_t = randf_range(18.0, 30.0)
			var b: Array = def["barks"]
			if b.size() > 0:
				game.bark(self, str(b[randi() % b.size()]))
		return
	# Hostile: perception.
	var seen := _can_see_player(p, dp)
	if seen > 0.0:
		var rate := seen * 3.2
		if GameState.has_perk("ghost_protocol"):
			rate *= 0.75
		if GameState.has_trait("paranoid"):
			rate *= 0.85
		_detect += rate * 0.25
		_last_seen = p.global_position
		_alert_t = 12.0
		if _detect >= 1.0:
			_enter_combat(p)
	else:
		_detect = maxf(0.0, _detect - 0.08)
	if game != null:
		game.report_detection(self, _detect, false)


func _nearest_foe(p: Node3D, r: float) -> Node3D:
	var best: Node3D = null
	var bd := r
	for n in get_tree().get_nodes_in_group("npc"):
		var o := n as NPC
		if o == null or o == self or o.dead:
			continue
		if o.mode != "combat" or not o.is_hostile_to_player():
			continue
		var d := o.global_position.distance_to(p.global_position)
		if d < bd:
			bd = d
			best = o
	return best


func _can_see_player(p: Node3D, dp: float) -> float:
	var interior := cell != "world"
	var rng := 16.0 if interior else (14.0 if GameState.is_night() else 24.0)
	var pl := p as Player
	var sneaking := pl != null and pl.is_sneaking()
	var noise := pl.noise_level() if pl != null else 0.5
	var sk := float(GameState.skill("sneak"))
	if sneaking:
		rng *= 0.62 - sk / 400.0
	else:
		rng *= 1.0 + noise * 0.3
	if pl != null and pl.get("_lamp_on") == true:
		rng *= 1.35
	# Hearing, any direction.
	var hear := noise * 10.0
	if dp < hear:
		return clampf(1.0 - dp / maxf(hear, 0.1), 0.2, 1.0)
	if dp > rng:
		return 0.0
	var fwd := -global_transform.basis.z
	var to := (p.global_position - global_position)
	to.y = 0.0
	var ang := rad_to_deg(fwd.angle_to(to.normalized()))
	var fov_mult := 1.0
	if ang > 110.0:
		return 0.0
	elif ang > 55.0:
		fov_mult = 0.5
	if dp > rng * fov_mult:
		return 0.0
	if not _los(head_pos(), (p as Player).eye_pos() if pl != null else p.global_position + Vector3(0, 1.5, 0)):
		return 0.0
	return clampf(1.0 - dp / (rng * fov_mult), 0.15, 1.0)


func _los(a: Vector3, b: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(a, b, Phys.WORLD)
	var res := get_world_3d().direct_space_state.intersect_ray(q)
	return res.is_empty()


func _enter_combat(p: Node3D) -> void:
	if mode == "combat":
		return
	mode = "combat"
	target = p
	_detect = 1.0
	AudioManager.play_3d("alert", global_position, -6.0)
	if game != null:
		game.report_detection(self, 1.0, true)
		if def.has("combat_bark"):
			game.bark(self, str(def["combat_bark"]))
		elif aggro == "guard":
			game.bark(self, ["Hey! You can't be here!", "Stop right there!", "Intruder!"][randi() % 3])
	# Allies join.
	for n in get_tree().get_nodes_in_group("npc"):
		var o := n as NPC
		if o == null or o == self or o.dead or o.mode == "combat":
			continue
		if o.faction == faction and faction != "" and o.global_position.distance_to(global_position) < 30.0 and o.aggro != "companion":
			o.alarm(p)


func alarm(p: Node3D) -> void:
	if dead or GameState.companions.has(id):
		return
	if aggro == "coward" or (aggro == "neutral" and not DB.item(weapon).has("mag") and weapon == ""):
		mode = "flee"
		return
	GameState.hostile[id] = true
	_enter_combat(p)


func noise_heard(pos: Vector3, loud: bool) -> void:
	# Gunshots make civilians scatter and hostiles investigate.
	if dead or GameState.companions.has(id):
		return
	if is_hostile_to_player():
		_last_seen = pos
		_alert_t = 15.0
		_detect = maxf(_detect, 0.6 if loud else 0.3)
	elif loud and (aggro == "neutral" or aggro == "coward") and mode != "talk" and weapon == "":
		mode = "flee"


func _combat(delta: float, p: Node3D) -> Array:
	var t := target if (target != null and is_instance_valid(target)) else p
	var tpos := t.global_position
	var d := global_position.distance_to(tpos)
	var tgt_eye := tpos + Vector3(0, 1.4, 0)
	var los := _los(head_pos(), tgt_eye)
	if los:
		_lost_t = 0.0
		_last_seen = tpos
	else:
		_lost_t += delta
		if _lost_t > 10.0 and t == p:
			# Lost them: go back home, stay alert.
			mode = "idle"
			_detect = 0.4
			_alert_t = 20.0
			return [Vector3.ZERO, 0.0]
	face(tpos, minf(1.0, delta * 8.0))
	var w := DB.item(weapon) if weapon != "" else DB.item("fists")
	var ranged := w.has("mag")
	# Cowards and badly hurt enemies run.
	if (aggro == "coward" or hp < max_hp * 0.2) and not essential and aggro != "guard" and randf() < 0.004:
		mode = "flee"
		return [Vector3.ZERO, 0.0]
	var move := Vector3.ZERO
	var speed := 0.0
	if ranged:
		var want := clampf(float(w.get("range", 40.0)) * 0.3, 6.0, 16.0)
		_strafe_t -= delta
		if _strafe_t <= 0.0:
			_strafe_t = randf_range(1.0, 2.2)
			_strafe = [-1.0, 0.0, 1.0][randi() % 3]
		var to := _dir_to(tpos)
		var side := to.cross(Vector3.UP) * _strafe
		if not los or d > want + 4.0:
			move = to
			speed = 4.2
		elif d < want - 3.0:
			move = (-to + side * 0.5).normalized()
			speed = 2.5
		else:
			move = side
			speed = 1.8
		if los and _atk_cool <= 0.0 and d < float(w.get("range", 40.0)):
			_shoot(t, w, d)
	else:
		var reach := float(w.get("range", 2.0))
		if d > reach * 0.8:
			move = _dir_to(tpos)
			speed = 5.2
		if d < reach + 0.4 and _atk_cool <= 0.0:
			_atk_cool = 1.0 / maxf(0.4, float(w.get("rate", 1.0))) + randf_range(0.2, 0.5)
			_melee_hit(t, w)
	return [move, speed]


func _shoot(t: Node3D, w: Dictionary, d: float) -> void:
	_atk_cool = 1.0 / maxf(0.3, float(w.get("rate", 1.0))) * randf_range(1.4, 2.2)
	if bool(w.get("auto", false)):
		_atk_cool *= 0.5
	_gun_flash.visible = true
	AudioManager.play_3d(AudioManager.gun_sound(str(w.get("model", "pistol")), bool(w.get("silent", false))), global_position + Vector3(0, 1.4, 0), 0.0, randf_range(0.95, 1.05))
	var chance := accuracy * (1.0 - clampf(d / float(w.get("range", 40.0)), 0.0, 1.0) * 0.55)
	if t is Player:
		var pl := t as Player
		if pl.is_sneaking():
			chance *= 0.85
		if pl._move_amount > 4.0:
			chance *= 0.75
	if randf() < chance:
		var dmg := float(w.get("dmg", 10.0)) * float(def.get("dmg_mult", 1.0)) * float(w.get("pellets", 1)) * 0.7
		if t.has_method("take_damage"):
			t.call("take_damage", dmg, global_position)
		elif t.has_method("take_hit"):
			t.call("take_hit", dmg, self, false, false, float(w.get("stun", 0.0)))
	elif game != null:
		game.impact(t.global_position + Vector3(randf_range(-1, 1), randf_range(0.2, 2.0), randf_range(-1, 1)), Vector3.UP)
	if game != null:
		game.tracer(global_position + Vector3(0.28, 1.35, 0) , t.global_position + Vector3(0, 1.2, 0))


func _melee_hit(t: Node3D, w: Dictionary) -> void:
	AudioManager.play_3d("swing", global_position, -4.0)
	var dmg := float(w.get("dmg", 6.0)) * float(def.get("dmg_mult", 1.0))
	if t.global_position.distance_to(global_position) < float(w.get("range", 2.0)) + 0.6:
		AudioManager.play_3d("punch", global_position, -2.0)
		if t.has_method("take_damage"):
			t.call("take_damage", dmg, global_position)
		elif t.has_method("take_hit"):
			t.call("take_hit", dmg, self, false, false, 0.0)


# ------------------------------------------------------------------- damage
func take_hit(dmg: float, attacker: Node, head: bool, crit: bool, stun: float) -> void:
	if dead:
		return
	var d := maxf(dmg * 0.2, dmg - dt)
	hp -= d
	_flash_hit = 1.0
	AudioManager.play_3d("hit", global_position + Vector3(0, 1.2, 0), -3.0)
	if game != null:
		game.blood(global_position + Vector3(0, 1.66 if head else 1.2, 0))
	var by_player := attacker != null and attacker.is_in_group("player")
	if by_player:
		_on_attacked_by_player()
	if hp <= 0.0:
		if essential:
			_knock_down()
		else:
			die(attacker)
		return
	if stun > 0.0:
		mode = "stunned"
		_stun_t = stun
		_mesh.rotation.x = -0.6
		velocity = Vector3.ZERO
		return
	if mode != "combat" and mode != "flee" and attacker != null:
		if aggro == "coward" or (weapon == "" and aggro == "neutral"):
			mode = "flee"
		else:
			target = attacker as Node3D
			mode = "combat"


func _on_attacked_by_player() -> void:
	if GameState.companions.has(id):
		return
	var was_hostile := is_hostile_to_player()
	if not was_hostile:
		GameState.hostile[id] = true
		if faction != "" and faction != "civilian":
			GameState.add_infamy(faction, 3)
		if faction in ["", "civilian", "locals", "coney", "nypd"] and game != null:
			game.crime_witnessed(global_position)
		# Nearby friends of the same faction take it personally.
		for n in get_tree().get_nodes_in_group("npc"):
			var o := n as NPC
			if o != null and o != self and not o.dead and o.faction == faction and faction != "" and o.global_position.distance_to(global_position) < 25.0:
				o.alarm(get_tree().get_first_node_in_group("player"))


func _knock_down() -> void:
	_knocked = true
	mode = "stunned"
	_stun_t = 8.0
	hp = max_hp * 0.35
	var tw := create_tween()
	tw.tween_property(_mesh, "rotation:x", -PI * 0.5, 0.4)
	tw.parallel().tween_property(_mesh, "position:y", 0.25, 0.4)


func _recover() -> void:
	if _knocked and essential:
		# Story characters can't die; a beating ends the fight rather than locking
		# their quests behind permanent hostility.
		GameState.hostile.erase(id)
		target = null
	_knocked = false
	var tw := create_tween()
	tw.tween_property(_mesh, "rotation:x", 0.0, 0.4)
	tw.parallel().tween_property(_mesh, "position:y", 0.0, 0.4)
	mode = "combat" if is_hostile_to_player() else ("follow" if GameState.companions.has(id) else "idle")


## restoring: a corpse re-placed from a save — lie down quietly, no loot roll,
## no death events (they already happened).
func die(attacker: Node = null, restoring: bool = false) -> void:
	if dead:
		return
	var was_hostile := is_hostile_to_player()
	dead = true
	mode = "dead"
	velocity = Vector3.ZERO
	collision_layer = Phys.INTERACT
	collision_mask = Phys.WORLD
	_col.shape.set("height", 0.6)
	_col.position = Vector3(0, 0.3, -0.6)
	if restoring:
		_mesh.set_instance_shader_parameter("amt", 0.0)
		_mesh.set_instance_shader_parameter("pose", 0.0)
		_mesh.rotation.x = -PI * 0.5
		_mesh.position.y = 0.2
		return
	AudioManager.play_3d("death", global_position, -2.0)
	_mesh.set_instance_shader_parameter("amt", 0.0)
	_mesh.set_instance_shader_parameter("pose", 0.0)
	_mesh.set_instance_shader_parameter("flash", 0.0)
	var tw := create_tween()
	tw.tween_property(_mesh, "rotation:x", -PI * 0.5, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_mesh, "position:y", 0.2, 0.5)
	var by_player := attacker != null and attacker.is_in_group("player")
	# A companion's kill counts as yours for XP and for clearing places (FNV rules).
	var by_comp := attacker is NPC and GameState.companions.has((attacker as NPC).id)
	if by_comp:
		GameState.add_xp(int(def.get("xp", 12)))
	if by_player:
		GameState.stat_add("kills")
		GameState.unlock("first_kill")
		GameState.add_xp(int(def.get("xp", 12)))
		GameState.adjust_stability(-2 if was_hostile else -8)
		# Civilians who never fight back: the Monster path counts these.
		if str(def.get("aggro", "")) == "coward" and not bool(def.get("not_innocent", false)):
			GameState.stat_add("innocents")
			GameState.last_innocent = {"day": GameState.day(), "hour": GameState.hour(), "cell": cell}
	if not generic:
		GameState.mark_dead(id)
		GameState.dead_npc_pos[id] = [global_position.x, global_position.y, global_position.z, cell]
	_generate_loot()
	emit_signal("died", self)
	if game != null:
		game.on_npc_died(self, by_player or by_comp)


func _generate_loot() -> void:
	var key := "npc:" + id
	if not generic and GameState.containers.has(key):
		return
	var items := {}
	var L: Dictionary = def.get("loot", {})
	var r := RandomNumberGenerator.new()
	r.randomize()
	var cash := 0
	if L.has("cash"):
		var c: Array = L["cash"]
		cash = r.randi_range(int(c[0]), int(c[1]))
	if GameState.has_perk("walking_wallet"):
		cash = int(float(cash) * 1.3)
	if weapon != "" and weapon != "fists" and not bool(def.get("no_weapon_drop", false)):
		items[weapon] = 1
		var ammo := str(DB.item(weapon).get("ammo", ""))
		if ammo != "":
			items[ammo] = r.randi_range(3, 12)
	for k in (L.get("items", {}) as Dictionary).keys():
		var v: Variant = L["items"][k]
		var n := 1
		if v is Array:
			n = r.randi_range(int(v[0]), int(v[1]))
		else:
			n = int(v)
		if n > 0:
			items[str(k)] = int(items.get(str(k), 0)) + n
	if generic:
		loot = items
		loot_cash = cash
	else:
		GameState.containers[key] = {"items": items, "cash": cash}


func walk_to(p: Vector3) -> void:
	_goto = p
	mode = "goto"


func set_home(p: Vector3, yaw: float) -> void:
	home_pos = p
	home_yaw = yaw
