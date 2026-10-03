class_name Collapse
extends Node
## Bring a building down. A plane that slams into a tall building fast
## enough can drop it: the city's own meshes inside its footprint fall out of
## sight (the facade and prop shaders, Mats.set_collapsed), its collision goes,
## a dust cloud rolls out, debris flies, and a burning rubble pile is left
## where it stood. It stays down for the rest of that playthrough: the save
## remembers, and the city builder leaves it out (CityBuilder.rubble_for).

var game: Node = null
var force := false # tests: every qualifying hit brings the building down
var _session: Array = [] # Vector4 boxes dropped since this map loaded


## Buildings already down on a map (from the save): [[x0, z0, x1, z1, h]].
static func down_in(region: String) -> Array:
	var all: Dictionary = GameState.flags.get("collapsed", {})
	return all.get(region, [])


static func is_down(region: String, r: Rect2) -> bool:
	for b in down_in(region):
		var a: Array = b
		if Rect2(float(a[0]), float(a[1]), float(a[2]) - float(a[0]), float(a[3]) - float(a[1])).grow(-0.5).intersects(r):
			return true
	return false


## The city building at a point, or [] (the map's own records).
func building_at(p: Vector3) -> Array:
	for b in game.city_buildings:
		var a: Array = b
		if a.size() < 7 or not bool(a[6]):
			continue # landmarks and special set pieces stay up
		if p.x >= float(a[0]) - 0.6 and p.x <= float(a[2]) + 0.6 and p.z >= float(a[1]) - 0.6 and p.z <= float(a[3]) + 0.6:
			return a
	return []


## A plane hit something at speed: if it's a tall building, maybe it falls.
## Off until the collision and reload sides are finished (collapse_test).
const ENABLED := false


func plane_hit(a: Aircraft, at: Vector3, spd: float) -> void:
	if not (ENABLED or force) or GameState.cell != "world":
		return
	var b := building_at(at)
	if b.is_empty():
		return
	var h := float(b[4])
	if h < 12.0 or h > 160.0:
		return
	var chance := 0.0
	match a.model:
		"citation":
			chance = 0.75 if spd > 35.0 else 0.25
		"heli":
			chance = 0.12 if spd > 25.0 else 0.0
		_:
			chance = 0.3 if spd > 40.0 else 0.08
	# Smaller buildings give more easily.
	chance *= clampf(1.6 - h / 80.0, 0.5, 1.4)
	if force or randf() < chance:
		bring_down(b, at)


func bring_down(b: Array, at: Vector3) -> void:
	var r := Rect2(float(b[0]), float(b[1]), float(b[2]) - float(b[0]), float(b[3]) - float(b[1]))
	var h := float(b[4])
	if Collapse.is_down(WorldLayout.region, r):
		return
	# Remembered for this playthrough.
	var all: Dictionary = GameState.flags.get("collapsed", {})
	var list: Array = all.get(WorldLayout.region, [])
	list.append([r.position.x, r.position.y, r.end.x, r.end.y, h])
	all[WorldLayout.region] = list
	GameState.flags["collapsed"] = all
	GameState.stat_add("buildings_down")
	# Out of sight, out of the way.
	_session.append(Vector4(r.get_center().x, r.get_center().y, r.size.x * 0.5 + 0.6, r.size.y * 0.5 + 0.6))
	while _session.size() > 8:
		_session.pop_front()
	Mats.set_collapsed(_session)
	_strip(r)
	var c := Vector3(r.get_center().x, 0.0, r.get_center().y)
	# The noise, the shake, the people underneath.
	AudioManager.play_3d("death", c + Vector3(0, 10, 0), 14.0, 0.15)
	AudioManager.play_3d("gun_shotgun", c + Vector3(0, 6, 0), 14.0, 0.2)
	AudioManager.play_3d("thud", c, 14.0, 0.3)
	Pad.rumble(1.0, 1.0, 1.5)
	var pp: Vector3 = game.player.global_position
	if Vector2(pp.x - c.x, pp.z - c.z).length() < maxf(r.size.x, r.size.y) * 0.5 + 12.0 and game.player.driving == null:
		game.player.take_damage(60.0, c)
	for n in game.get_tree().get_nodes_in_group("npc"):
		var o := n as NPC
		if o != null and not o.dead and o.cell == "world" and r.grow(6.0).has_point(Vector2(o.global_position.x, o.global_position.z)):
			o.take_hit(400.0, game.player, false, false, 0.0)
	if game.crowd != null:
		for p in game.crowd.peds:
			if is_instance_valid(p) and not bool(p.get("dead")) and r.grow(6.0).has_point(Vector2((p as Node3D).global_position.x, (p as Node3D).global_position.z)):
				p.call("take_hit", 400.0, game.player, false, false, 0.0)
	game.hud.center("IT'S COMING DOWN", 3.0)
	GameState.set_wanted(600.0)
	GameState.heat = 5
	GameState.adjust_stability(-15)
	_dust(c, r, h)
	_debris(at if at != Vector3.ZERO else c + Vector3(0, h * 0.6, 0), r, h)
	var holder := Node3D.new()
	holder.name = "Rubble"
	game.city_extras.add_child(holder)
	var bc := BuildCtx.new()
	CityBuilder.rubble_for(bc, r, h, hash(Vector2i(int(r.position.x), int(r.position.y))))
	bc.commit(holder, 900.0, 400.0, true)
	_fire(holder, c, r)


## Collision, labels and lit windows inside the footprint go with it.
func _strip(r: Rect2) -> void:
	var rr := r.grow(0.7)
	for ch in game.city_root.get_children():
		for n in (ch as Node).get_children():
			if n is StaticBody3D:
				for cs in (n as Node).get_children():
					if cs is CollisionShape3D and (cs as CollisionShape3D).shape is BoxShape3D:
						var p := (cs as CollisionShape3D).position
						var sz := ((cs as CollisionShape3D).shape as BoxShape3D).size
						if rr.has_point(Vector2(p.x, p.z)) and p.y + sz.y * 0.5 > 1.5:
							(cs as CollisionShape3D).disabled = true
			elif n is Label3D:
				var lp := (n as Label3D).position
				if rr.has_point(Vector2(lp.x, lp.z)) and lp.y > 0.35:
					(n as Label3D).visible = false


func _dust(c: Vector3, r: Rect2, h: float) -> void:
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.62, 0.6, 0.56, 0.75)
	var sb := MeshBatch.new()
	sb.sphere(Vector3.ZERO, 1.0, Color(1, 1, 1), 10, 6)
	var m := sb.to_mesh()
	var R := maxf(r.size.x, r.size.y) * 0.5
	for k in 14:
		var mi := MeshInstance3D.new()
		mi.mesh = m
		mi.material_override = mat
		game.add_child(mi)
		var a := TAU * float(k) / 14.0
		mi.global_position = c + Vector3(cos(a) * R * 0.5, randf_range(2.0, h * 0.5), sin(a) * R * 0.5)
		mi.scale = Vector3.ONE * randf_range(3.0, 6.0)
		var tw := mi.create_tween()
		var out := c + Vector3(cos(a), 0, sin(a)) * (R + randf_range(15.0, 40.0)) + Vector3(0, randf_range(1.0, 12.0), 0)
		tw.tween_property(mi, "global_position", out, 9.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.parallel().tween_property(mi, "scale", Vector3.ONE * randf_range(14.0, 24.0), 9.0)
		tw.tween_callback(mi.queue_free)
	var fade := game.create_tween()
	fade.tween_property(mat, "albedo_color:a", 0.0, 9.0).set_delay(2.0)


func _debris(at: Vector3, r: Rect2, h: float) -> void:
	var col := Color(0.42, 0.38, 0.34)
	for k in 22:
		var rb := RigidBody3D.new()
		rb.collision_layer = 0
		rb.collision_mask = Phys.WORLD
		rb.mass = 40.0
		var s := Vector3(randf_range(0.5, 2.2), randf_range(0.4, 1.4), randf_range(0.5, 2.2))
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = s
		cs.shape = bs
		rb.add_child(cs)
		var mb := MeshBatch.new()
		mb.box(Vector3.ZERO, s, col.darkened(randf_range(0.0, 0.4)))
		var mi := MeshInstance3D.new()
		mi.mesh = mb.to_mesh()
		mi.material_override = Mats.lit
		rb.add_child(mi)
		game.add_child(rb)
		rb.global_position = Vector3(randf_range(r.position.x, r.end.x), randf_range(h * 0.3, h * 0.9), randf_range(r.position.y, r.end.y))
		var out := Vector3(rb.global_position.x - r.get_center().x, 0, rb.global_position.z - r.get_center().y).normalized()
		rb.linear_velocity = out * randf_range(4.0, 14.0) + Vector3(0, randf_range(-2.0, 6.0), 0)
		rb.angular_velocity = Vector3(randf_range(-3, 3), randf_range(-3, 3), randf_range(-3, 3))
		var tw := rb.create_tween()
		tw.tween_interval(8.0)
		tw.tween_callback(func() -> void:
			rb.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
			rb.freeze = true)


## Fires burning on the pile for a while.
func _fire(holder: Node3D, c: Vector3, r: Rect2) -> void:
	var fb := MeshBatch.new()
	for k in 7:
		var p := Vector3(randf_range(r.position.x + 2.0, r.end.x - 2.0), randf_range(1.0, 4.0), randf_range(r.position.y + 2.0, r.end.y - 2.0)) - c
		fb.sphere(p, randf_range(0.8, 1.8), Color(1.0, randf_range(0.35, 0.6), 0.1), 6, 4, Vector2(Props.K_FLICKER, randf()))
	var fm := fb.commit(holder, Mats.glow, 900.0, "RubbleFire")
	if fm != null:
		fm.position = c
		var tw := fm.create_tween()
		tw.tween_interval(90.0)
		tw.tween_callback(fm.queue_free)
	var lt := OmniLight3D.new()
	lt.light_color = Color(1.0, 0.55, 0.2)
	lt.light_energy = 3.0
	lt.omni_range = 30.0
	holder.add_child(lt)
	lt.global_position = c + Vector3(0, 4, 0)
	var tl := lt.create_tween()
	tl.tween_property(lt, "light_energy", 0.0, 90.0)
