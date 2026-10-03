class_name Pedestrian
extends AnimatableBody3D
## One ambient walker. Follows the sidewalk lane around its block (a rectangle),
## sometimes crossing to the next block at corners. Can be talked to, robbed,
## or hurt (which has consequences).

var crowd: Crowd
var rect: Rect2
var s: float = 0.0
var dir: float = 1.0
var speed: float = 1.3
var lane_off: float = 0.0
var mesh_res: Mesh
var dead: bool = false
var hp: float = 25.0
var display_name: String = "Pedestrian"
var loot: Dictionary = {}
var loot_cash: int = 0
var picked: bool = false
var _mesh: MeshInstance3D
var _phase: float = 0.0
var _cross_from: Vector3
var _cross_to: Vector3
var _cross_t: float = -1.0
var _cross_rect: Rect2
var _cross_s: float = 0.0
var _flee_t: float = 0.0
var _flee_dir: Vector3
var _wait_t: float = 0.0
var _flash: float = 0.0


func _ready() -> void:
	add_to_group("pedestrian")
	collision_layer = Phys.NPC
	collision_mask = 0
	sync_to_physics = false
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.28
	cap.height = 1.7
	cs.shape = cap
	cs.position = Vector3(0, 0.85, 0)
	add_child(cs)
	_mesh = MeshInstance3D.new()
	_mesh.mesh = mesh_res
	_mesh.material_override = Mats.npc
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mesh.visibility_range_end = 150.0
	add_child(_mesh)
	var r := randi() % 100
	display_name = ["Pedestrian", "Commuter", "Local", "Tourist", "Night Owl"][r % 5]
	loot_cash = randi_range(0, 18)
	if randf() < 0.35:
		loot[["cigarettes", "smartphone", "watch", "coffee", "hot_dog", "bobby_pin", "usb_drive"][randi() % 7]] = 1


static func lane_point(r: Rect2, s_: float) -> Vector3:
	var w := r.size.x
	var h := r.size.y
	var per := 2.0 * (w + h)
	var t := fposmod(s_, per)
	if t < w:
		return Vector3(r.position.x + t, 0, r.position.y)
	t -= w
	if t < h:
		return Vector3(r.end.x, 0, r.position.y + t)
	t -= h
	if t < w:
		return Vector3(r.end.x - t, 0, r.end.y)
	t -= w
	return Vector3(r.position.x, 0, r.end.y - t)


static func lane_s_of_corner(r: Rect2, c: Vector2) -> float:
	var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	var ss := [0.0, r.size.x, r.size.x + r.size.y, 2.0 * r.size.x + r.size.y]
	var best := 0
	var bd := INF
	for i in 4:
		var d := (corners[i] as Vector2).distance_to(c)
		if d < bd:
			bd = d
			best = i
	return float(ss[best])


func interact_info() -> Dictionary:
	if dead:
		return {"verb": "Search", "name": display_name}
	if not picked and crowd != null and crowd.game != null and crowd.game.player != null and crowd.game.player.crouching:
		return {"verb": "Pickpocket", "name": display_name, "locked": true}
	return {"verb": "Talk", "name": display_name}


var _last_hit: Dictionary = {}


func note_hit(pos: Vector3, dir: Vector3, dmg: float, model: String) -> void:
	_last_hit = {"pos": pos, "dir": dir, "dmg": dmg, "model": model, "t": Time.get_ticks_msec()}


func take_hit(dmg: float, attacker: Node, _head: bool, _crit: bool, stun: float) -> void:
	if dead:
		return
	hp -= dmg
	_flash = 1.0
	if attacker != null and attacker.is_in_group("player") and crowd != null and crowd.game != null:
		crowd.game.crime_witnessed(global_position)
		GameState.add_infamy("locals", 1)
	if hp <= 0.0:
		die(attacker)
	else:
		flee_from(attacker.global_position if attacker is Node3D else global_position)


func die(attacker: Node) -> void:
	dead = true
	collision_layer = Phys.INTERACT
	_mesh.set_instance_shader_parameter("amt", 0.0)
	# A ragdoll, shoved by whatever did it (see Ragdoll); maybe in pieces.
	var fresh := not _last_hit.is_empty() and Time.get_ticks_msec() - int(_last_hit["t"]) < 1500
	var dir := Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	var dmg := 20.0
	var model := ""
	var limb := 0
	if fresh:
		dir = _last_hit["dir"]
		dmg = float(_last_hit["dmg"])
		model = str(_last_hit["model"])
		limb = Ragdoll.limb_near(_mesh.mesh, _mesh.global_transform.affine_inverse() * (_last_hit["pos"] as Vector3))
	elif attacker is Node3D:
		dir = (global_position - (attacker as Node3D).global_position).normalized()
	var dist := (attacker as Node3D).global_position.distance_to(global_position) if attacker is Node3D else 10.0
	var cut := Ragdoll.cuts_for(limb, dmg, model, dist)
	var rd := Ragdoll.spawn(get_parent(), _mesh.mesh, _mesh.global_transform, Ragdoll.push_for(dir, dmg, model), limb, cut, self)
	if rd != null:
		_mesh.visible = false
		tree_exiting.connect(rd.queue_free)
		if not cut.is_empty():
			GameState.stat_add("limbs")
	else:
		var tw := create_tween()
		tw.tween_property(_mesh, "rotation:x", -PI * 0.5, 0.5)
		tw.parallel().tween_property(_mesh, "position:y", 0.2, 0.5)
	AudioManager.play_3d("death", global_position, -3.0)
	if attacker != null and attacker.is_in_group("player"):
		GameState.stat_add("kills")
		GameState.unlock("first_kill")
		GameState.adjust_stability(-10)
		GameState.add_infamy("locals", 4)
		GameState.stat_add("innocents")
		GameState.last_innocent = {"day": GameState.day(), "hour": GameState.hour(), "cell": "world"}


func flee_from(p: Vector3) -> void:
	if dead:
		return
	_flee_t = 10.0
	var d := global_position - p
	d.y = 0
	_flee_dir = d.normalized() if d.length() > 0.1 else Vector3(1, 0, 0)


func _physics_process(delta: float) -> void:
	if dead:
		return
	_flash = maxf(0.0, _flash - delta * 4.0)
	_mesh.set_instance_shader_parameter("flash", _flash)
	var pos := global_position
	var mv := 0.0
	var player: Node3D = crowd.game.player if crowd != null and crowd.game != null else null
	if _flee_t > 0.0:
		_flee_t -= delta
		pos += _flee_dir * 5.2 * delta
		mv = 5.2
		_face(_flee_dir)
		if _flee_t <= 0.0:
			# Rejoin the nearest lane point by re-snapping.
			s = _closest_s(pos)
	elif _cross_t >= 0.0:
		_cross_t += delta * speed / maxf(1.0, _cross_from.distance_to(_cross_to))
		pos = _cross_from.lerp(_cross_to, minf(_cross_t, 1.0))
		mv = speed
		_face(_cross_to - _cross_from)
		if _cross_t >= 1.0:
			_cross_t = -1.0
			rect = _cross_rect
			s = _cross_s
	else:
		# Pause for the player standing right in the way.
		var blocked := false
		if player != null:
			var to := player.global_position - pos
			to.y = 0.0
			if to.length() < 1.3:
				var fwd := (Pedestrian.lane_point(rect, s + dir) - Pedestrian.lane_point(rect, s)).normalized()
				if fwd.dot(to.normalized()) > 0.3:
					blocked = true
		if blocked:
			_wait_t += delta
			if _wait_t > 1.5:
				dir = -dir
				_wait_t = 0.0
		else:
			_wait_t = 0.0
			var old_seg := _segment(s)
			s += dir * speed * delta
			var new_seg := _segment(s)
			if old_seg != new_seg and randf() < 0.35 and crowd != null:
				_start_crossing()
			var lp := Pedestrian.lane_point(rect, s)
			var ahead := Pedestrian.lane_point(rect, s + dir * 0.5)
			var fdir := (ahead - lp).normalized()
			var side := fdir.cross(Vector3.UP)
			pos = lp + side * lane_off
			mv = speed
			_face(fdir)
	global_position = Vector3(pos.x, 0.0, pos.z)
	_phase += delta * mv * 3.2
	_mesh.set_instance_shader_parameter("phase", _phase)
	_mesh.set_instance_shader_parameter("amt", clampf(mv / 2.0, 0.0, 1.0))


func _segment(ss: float) -> int:
	var per := 2.0 * (rect.size.x + rect.size.y)
	var t := fposmod(ss, per)
	if t < rect.size.x:
		return 0
	if t < rect.size.x + rect.size.y:
		return 1
	if t < 2.0 * rect.size.x + rect.size.y:
		return 2
	return 3


func _start_crossing() -> void:
	var here := Pedestrian.lane_point(rect, s)
	var nr := crowd.neighbor_rect(rect, Vector2(here.x, here.z))
	if nr == rect:
		return
	var ns := Pedestrian.lane_s_of_corner(nr, Vector2(here.x, here.z))
	var there := Pedestrian.lane_point(nr, ns)
	if here.distance_to(there) > 30.0:
		return
	_cross_from = here
	_cross_to = there
	_cross_rect = nr
	_cross_s = ns
	_cross_t = 0.0


func _closest_s(p: Vector3) -> float:
	var best := 0.0
	var bd := INF
	var per := 2.0 * (rect.size.x + rect.size.y)
	var k := 0.0
	while k < per:
		var d := Pedestrian.lane_point(rect, k).distance_to(p)
		if d < bd:
			bd = d
			best = k
		k += 2.0
	return best


func _face(d: Vector3) -> void:
	if d.length() < 0.01:
		return
	rotation.y = lerp_angle(rotation.y, atan2(-d.x, -d.z), 0.2)
