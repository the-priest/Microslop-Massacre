class_name Animals
extends Node
## Wildlife, kept around the player: pigeons on city sidewalks that burst
## into the air when you get close or fire a gun, gulls wheeling over the
## water, stray dogs, deer in the fields and woods out of town, and cows on
## the farms. They're shootable (a dead dog in town is a crime; nobody minds
## about the pigeons), and they live only near you.

const SPECIES := {
	"pigeon": {"hp": 4.0, "speed": 1.1, "flee": 6.0, "radius": 0.15, "height": 0.25},
	"gull": {"hp": 6.0, "speed": 9.0, "flee": 0.0, "radius": 0.3, "height": 0.3},
	"dog": {"hp": 30.0, "speed": 2.2, "flee": 7.0, "radius": 0.3, "height": 0.6},
	"deer": {"hp": 55.0, "speed": 1.4, "flee": 11.0, "radius": 0.45, "height": 1.3},
	"cow": {"hp": 120.0, "speed": 0.7, "flee": 2.5, "radius": 0.7, "height": 1.4},
}
const MAX := {"pigeon": 18, "gull": 6, "dog": 2, "deer": 6, "cow": 8}

var game: Node = null
var animals: Array = []
var _tick := 0.0
var _rng := RandomNumberGenerator.new()
static var _meshes: Dictionary = {}


func _ready() -> void:
	_rng.randomize()


func _process(delta: float) -> void:
	if game == null or game.player == null:
		return
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = 1.5
	if GameState.cell != "world":
		for a in animals.duplicate():
			_remove(a)
		return
	var pp: Vector3 = game.player.global_position
	for a in animals.duplicate():
		var an: Animal = a
		if not is_instance_valid(an) or an.global_position.distance_to(pp) > 170.0 or an.gone:
			_remove(an)
	_populate(pp)


func _remove(a: Variant) -> void:
	animals.erase(a)
	if a != null and is_instance_valid(a):
		(a as Node).queue_free()


func count(kind: String) -> int:
	var n := 0
	for a in animals:
		if is_instance_valid(a) and (a as Animal).kind == kind and not (a as Animal).dead:
			n += 1
	return n


## Top up what lives around here: city pigeons and strays, gulls by the
## water, deer and cows in the country.
func _populate(pp: Vector3) -> void:
	var reg := WorldLayout.region
	var day := not GameState.is_night()
	var near_water := _water_near(pp, 260.0)
	var country := Regions.is_country(reg, Vector2(pp.x, pp.z)) or reg == "highway"
	var wants := {
		"pigeon": (MAX["pigeon"] if day else 4) if not country and reg != "island" else 0,
		"dog": MAX["dog"] if not country and reg != "island" else 0,
		"gull": MAX["gull"] if near_water else 0,
		"deer": MAX["deer"] if (country or reg in ["redmont", "township"]) and reg != "island" else 0,
		"cow": MAX["cow"] if reg in ["township", "highway"] else 0,
	}
	for k in wants.keys():
		var have := count(str(k))
		var tries := 0
		while have < int(wants[k]) and tries < 6:
			tries += 1
			if _spawn_group(str(k), pp):
				have = count(str(k))


func _water_near(p: Vector3, r: float) -> bool:
	for d in [Vector2(r, 0), Vector2(-r, 0), Vector2(0, r), Vector2(0, -r), Vector2.ZERO]:
		if Boats.is_water(WorldLayout.region, Vector2(p.x, p.z) + (d as Vector2)):
			return true
	return false


func _spawn_group(kind: String, pp: Vector3) -> bool:
	var ang := _rng.randf() * TAU
	var dist := _rng.randf_range(45.0, 110.0)
	var c := Vector3(pp.x + cos(ang) * dist, 0.0, pp.z + sin(ang) * dist)
	if kind == "gull":
		var g := _make(kind, c + Vector3(0, _rng.randf_range(16.0, 30.0), 0))
		g.circle_c = Vector3(c.x, 0, c.z)
		g.circle_r = _rng.randf_range(12.0, 30.0)
		return true
	if not WorldLayout.in_bounds(c.x, c.z):
		return false
	if Boats.is_water(WorldLayout.region, Vector2(c.x, c.z)):
		return false
	var country := Regions.is_country(WorldLayout.region, Vector2(c.x, c.z)) or WorldLayout.region == "highway"
	if kind in ["deer", "cow"] and not country and WorldLayout.district_at(c.x, c.z) not in ["park", "farm", "tw_field", "rm_shore"]:
		return false
	var n := {"pigeon": _rng.randi_range(4, 8), "dog": 1, "deer": _rng.randi_range(2, 4), "cow": _rng.randi_range(3, 5)}.get(kind, 1) as int
	var made := 0
	for i in n:
		var p := c + Vector3(_rng.randf_range(-3.0, 3.0), 0, _rng.randf_range(-3.0, 3.0))
		if not _free(p, float((SPECIES[kind] as Dictionary)["radius"])):
			continue
		_make(kind, p)
		made += 1
	return made > 0


func _free(p: Vector3, r: float) -> bool:
	var space: PhysicsDirectSpaceState3D = game.get_world_3d().direct_space_state
	var sh := SphereShape3D.new()
	sh.radius = maxf(r, 0.2)
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = sh
	q.transform = Transform3D(Basis.IDENTITY, p + Vector3(0, maxf(r, 0.2) + 0.15, 0))
	q.collision_mask = Phys.WORLD
	return space.intersect_shape(q, 1).is_empty()


func _make(kind: String, p: Vector3) -> Animal:
	var a := Animal.new()
	a.setup(kind, self)
	game.add_child(a)
	a.global_position = p
	a.rotation.y = _rng.randf() * TAU
	animals.append(a)
	return a


## A gunshot (or the player sprinting through): everything nearby bolts.
func startle(p: Vector3, r: float) -> void:
	for a in animals:
		if is_instance_valid(a) and (a as Animal).global_position.distance_to(p) < r:
			(a as Animal).startle(p)


# --------------------------------------------------------------- the animal
class Animal extends CharacterBody3D:
	var kind := "pigeon"
	var spec: Dictionary = {}
	var hp := 4.0
	var dead := false
	var gone := false
	var state := "idle" # idle, walk, flee, fly, circle, dead
	var mgr: Animals = null
	var circle_c := Vector3.ZERO
	var circle_r := 20.0
	var _t := 0.0
	var _ang := 0.0
	var _target := Vector3.ZERO
	var _from := Vector3.ZERO
	var _body: MeshInstance3D
	var _wings: MeshInstance3D
	var _bark_t := 0.0

	func setup(k: String, m: Animals) -> void:
		kind = k
		mgr = m
		spec = Animals.SPECIES[k]
		hp = float(spec["hp"])
		collision_layer = Phys.NPC
		collision_mask = 0
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		var r := float(spec["radius"])
		bs.size = Vector3(r * 1.6, float(spec["height"]), r * 2.6)
		cs.shape = bs
		cs.position = Vector3(0, float(spec["height"]) * 0.5, 0)
		add_child(cs)
		var ms: Array = Animals.meshes(k)
		_body = MeshInstance3D.new()
		_body.mesh = ms[0]
		_body.material_override = Mats.lit
		_body.visibility_range_end = 120.0 if k != "gull" else 400.0
		add_child(_body)
		if (ms[1] as Mesh) != null:
			_wings = MeshInstance3D.new()
			_wings.mesh = ms[1]
			_wings.material_override = Mats.lit
			_wings.visibility_range_end = _body.visibility_range_end
			_wings.position = Vector3(0, float(spec["height"]) * 0.7, 0)
			_wings.visible = k == "gull"
			add_child(_wings)
		state = "circle" if k == "gull" else "idle"
		_t = randf() * 3.0

	func interact_info() -> Dictionary:
		return {}

	func take_hit(dmg: float, attacker: Node, _head: bool, _crit: bool, _stun: float) -> void:
		if dead:
			return
		hp -= dmg
		if mgr != null and mgr.game != null:
			mgr.game.blood(global_position + Vector3(0, float(spec["height"]) * 0.6, 0))
		if hp <= 0.0:
			die(attacker)
		else:
			startle(attacker.global_position if attacker is Node3D else global_position)

	func die(attacker: Node) -> void:
		dead = true
		state = "dead"
		collision_layer = 0
		if _wings != null:
			_wings.visible = false
		var tw := create_tween()
		tw.tween_property(_body, "rotation:z", PI * 0.5, 0.35)
		if kind in ["pigeon", "gull"] and global_position.y > 0.3:
			tw.parallel().tween_property(self, "global_position:y", 0.05, 0.6)
		GameState.stat_add("animals")
		if attacker != null and attacker.is_in_group("player") and mgr != null and mgr.game != null:
			if kind == "dog":
				GameState.add_infamy("locals", 2)
				mgr.game.crime_witnessed(global_position)
			elif kind == "cow":
				GameState.add_infamy("locals", 1)
		AudioManager.play_3d("hurt", global_position, -6.0, 1.8 if kind in ["pigeon", "gull"] else 0.8)

	func startle(from_p: Vector3) -> void:
		if dead:
			return
		_from = from_p
		if kind in ["pigeon"]:
			state = "fly"
			_t = 0.0
			if _wings != null:
				_wings.visible = true
		elif kind != "gull":
			state = "flee"
			_t = 0.0

	func _physics_process(delta: float) -> void:
		if dead:
			return
		_t += delta
		var pp: Vector3 = mgr.game.player.global_position if mgr != null and mgr.game != null and mgr.game.player != null else global_position
		var pd := Vector2(pp.x - global_position.x, pp.z - global_position.z).length()
		match state:
			"idle", "walk":
				var fl := float(spec["flee"])
				if fl > 0.0 and pd < fl and (kind != "dog" or randf() < 0.01):
					startle(pp)
					return
				if kind == "dog" and pd < 9.0:
					_bark_t -= delta
					if _bark_t <= 0.0:
						_bark_t = randf_range(2.0, 5.0)
						AudioManager.play_3d("punch", global_position, -8.0, 2.2)
				if state == "idle":
					# Pecking, grazing, sniffing.
					_body.rotation.x = sin(_t * (6.0 if kind == "pigeon" else 1.2)) * (0.25 if kind == "pigeon" else 0.08)
					if _t > randf_range(2.0, 6.0):
						state = "walk"
						_t = 0.0
						var a2 := randf() * TAU
						_target = global_position + Vector3(cos(a2), 0, sin(a2)) * randf_range(1.0, 6.0 if kind != "pigeon" else 2.0)
				else:
					_walk_to(_target, float(spec["speed"]), delta)
					if global_position.distance_to(_target) < 0.4 or _t > 6.0:
						state = "idle"
						_t = 0.0
			"flee":
				var away := Vector3(global_position.x - _from.x, 0, global_position.z - _from.z).normalized()
				if away.length() < 0.1:
					away = Vector3(1, 0, 0)
				_walk_to(global_position + away * 5.0, float(spec["speed"]) * 4.0, delta)
				_body.position.y = absf(sin(_t * 9.0)) * (0.25 if kind == "deer" else 0.08)
				if _t > (6.0 if kind == "deer" else 4.0):
					state = "idle"
					_t = 0.0
					_body.position.y = 0.0
			"fly":
				var away2 := Vector3(global_position.x - _from.x, 0, global_position.z - _from.z).normalized()
				if away2.length() < 0.1:
					away2 = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
				global_position += (away2 * 6.0 + Vector3(0, 4.0, 0)) * delta
				rotation.y = atan2(-away2.x, -away2.z)
				_wings.rotation.z = sin(_t * 30.0) * 0.6
				if _t > 6.0:
					gone = true
			"circle":
				_ang += delta * float(spec["speed"]) / maxf(circle_r, 1.0)
				var p := circle_c + Vector3(cos(_ang) * circle_r, global_position.y, sin(_ang) * circle_r)
				p.y = global_position.y + sin(_t * 0.5) * 0.02
				var dir := p - global_position
				global_position = p
				if dir.length() > 0.001:
					rotation.y = atan2(-dir.x, -dir.z)
				_wings.rotation.z = sin(_t * 3.0) * 0.25
				_body.rotation.z = -0.25
				if randf() < 0.002:
					AudioManager.play_3d("ricochet", global_position, -12.0, 0.45)

	func _walk_to(t: Vector3, spd: float, delta: float) -> void:
		var d := Vector3(t.x - global_position.x, 0, t.z - global_position.z)
		if d.length() < 0.05:
			return
		var dir := d.normalized()
		# Turn away from walls rather than walking into them.
		var space := get_world_3d().direct_space_state
		var q := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 0.3, 0), global_position + Vector3(0, 0.3, 0) + dir * 1.2, Phys.WORLD)
		if not space.intersect_ray(q).is_empty() or Boats.is_water(WorldLayout.region, Vector2(global_position.x + dir.x, global_position.z + dir.z)):
			dir = dir.rotated(Vector3.UP, PI * 0.6)
			_target = global_position + dir * 3.0
		global_position += dir * spd * delta
		global_position.y = 0.0
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), minf(1.0, delta * 6.0))


# ------------------------------------------------------------------ meshes
## [body, wings or null] for a species.
static func meshes(k: String) -> Array:
	if _meshes.has(k):
		return _meshes[k]
	var b := MeshBatch.new()
	var w: MeshBatch = null
	match k:
		"pigeon":
			var g := Color(0.48, 0.5, 0.55)
			b.box(Vector3(0, 0.12, 0), Vector3(0.14, 0.13, 0.26), g)
			b.box(Vector3(0, 0.2, -0.13), Vector3(0.08, 0.08, 0.08), g.darkened(0.25))
			b.box(Vector3(0, 0.17, -0.1), Vector3(0.09, 0.04, 0.05), Color(0.3, 0.55, 0.45))
			b.box(Vector3(0, 0.19, -0.18), Vector3(0.025, 0.02, 0.04), Color(0.2, 0.2, 0.2))
			b.box(Vector3(0, 0.11, 0.16), Vector3(0.1, 0.03, 0.1), g.darkened(0.15))
			for s in [-1.0, 1.0]:
				b.box(Vector3(0.03 * s, 0.03, 0), Vector3(0.015, 0.06, 0.015), Color(0.8, 0.35, 0.3))
			w = MeshBatch.new()
			w.box(Vector3(0, 0, 0), Vector3(0.5, 0.02, 0.14), g.darkened(0.1))
		"gull":
			b.box(Vector3(0, 0.15, 0), Vector3(0.16, 0.15, 0.4), Color(0.95, 0.95, 0.95))
			b.box(Vector3(0, 0.2, -0.22), Vector3(0.1, 0.1, 0.1), Color(0.97, 0.97, 0.97))
			b.box(Vector3(0, 0.19, -0.3), Vector3(0.03, 0.03, 0.08), Color(0.95, 0.75, 0.2))
			b.box(Vector3(0, 0.16, 0.24), Vector3(0.12, 0.03, 0.12), Color(0.3, 0.3, 0.32))
			w = MeshBatch.new()
			w.box(Vector3(0, 0, 0), Vector3(1.3, 0.025, 0.22), Color(0.6, 0.62, 0.66))
			w.box(Vector3(0.6, 0, 0), Vector3(0.12, 0.03, 0.2), Color(0.1, 0.1, 0.1))
			w.box(Vector3(-0.6, 0, 0), Vector3(0.12, 0.03, 0.2), Color(0.1, 0.1, 0.1))
		"dog":
			var c := Color(0.45, 0.32, 0.18)
			b.box(Vector3(0, 0.42, 0), Vector3(0.26, 0.24, 0.62), c)
			b.box(Vector3(0, 0.55, -0.36), Vector3(0.2, 0.2, 0.22), c)
			b.box(Vector3(0, 0.5, -0.5), Vector3(0.11, 0.1, 0.12), c.darkened(0.2))
			b.box(Vector3(0, 0.52, -0.57), Vector3(0.05, 0.04, 0.03), Color(0.05, 0.05, 0.05))
			for s in [-1.0, 1.0]:
				b.box(Vector3(0.07 * s, 0.68, -0.33), Vector3(0.05, 0.1, 0.04), c.darkened(0.3))
				b.box(Vector3(0.09 * s, 0.16, -0.22), Vector3(0.06, 0.32, 0.06), c.darkened(0.1))
				b.box(Vector3(0.09 * s, 0.16, 0.22), Vector3(0.06, 0.32, 0.06), c.darkened(0.1))
			b.box_xf(Transform3D(Basis(Vector3.RIGHT, -0.7), Vector3(0, 0.55, 0.38)), Vector3(0.04, 0.04, 0.24), c)
		"deer":
			var c2 := Color(0.6, 0.42, 0.25)
			b.box(Vector3(0, 0.95, 0), Vector3(0.36, 0.42, 1.0), c2)
			b.box_xf(Transform3D(Basis(Vector3.RIGHT, 0.6), Vector3(0, 1.25, -0.5)), Vector3(0.16, 0.5, 0.18), c2)
			b.box(Vector3(0, 1.48, -0.66), Vector3(0.16, 0.18, 0.3), c2)
			b.box(Vector3(0, 1.45, -0.83), Vector3(0.08, 0.08, 0.06), Color(0.1, 0.08, 0.06))
			b.box(Vector3(0, 0.95, 0.52), Vector3(0.1, 0.16, 0.06), Color(0.95, 0.95, 0.92))
			for s in [-1.0, 1.0]:
				b.box(Vector3(0.12 * s, 0.38, -0.38), Vector3(0.06, 0.76, 0.06), c2.darkened(0.15))
				b.box(Vector3(0.12 * s, 0.38, 0.38), Vector3(0.06, 0.76, 0.06), c2.darkened(0.15))
				b.box(Vector3(0.06 * s, 1.62, -0.62), Vector3(0.04, 0.12, 0.08), c2.darkened(0.2))
				b.tube(Vector3(0.05 * s, 1.58, -0.6), Vector3(0.18 * s, 1.85, -0.55), 0.015, Color(0.45, 0.38, 0.3))
		"cow":
			var wht := Color(0.92, 0.92, 0.9)
			var blk := Color(0.08, 0.08, 0.08)
			b.box(Vector3(0, 1.0, 0), Vector3(0.7, 0.7, 1.5), wht)
			b.box(Vector3(0.36, 1.05, -0.2), Vector3(0.01, 0.4, 0.5), blk)
			b.box(Vector3(-0.36, 0.95, 0.3), Vector3(0.01, 0.45, 0.55), blk)
			b.box(Vector3(0, 1.36, 0.15), Vector3(0.5, 0.01, 0.6), blk)
			b.box(Vector3(0, 1.15, -0.86), Vector3(0.36, 0.36, 0.42), wht)
			b.box(Vector3(0, 1.05, -1.08), Vector3(0.3, 0.2, 0.08), Color(0.85, 0.6, 0.6))
			b.box(Vector3(0, 0.62, 0.3), Vector3(0.22, 0.14, 0.22), Color(0.9, 0.65, 0.65))
			for s in [-1.0, 1.0]:
				b.box(Vector3(0.24 * s, 0.33, -0.55), Vector3(0.12, 0.66, 0.12), wht.darkened(0.1))
				b.box(Vector3(0.24 * s, 0.33, 0.55), Vector3(0.12, 0.66, 0.12), wht.darkened(0.1))
				b.box(Vector3(0.2 * s, 1.36, -0.86), Vector3(0.14, 0.05, 0.05), Color(0.85, 0.8, 0.7))
	var out := [b.to_mesh(), w.to_mesh() if w != null else null]
	_meshes[k] = out
	return out
