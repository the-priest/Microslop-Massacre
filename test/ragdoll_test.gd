extends "res://test/towns_walk.gd"
## Bodies: a pedestrian shot dead falls as a jointed ragdoll, shoved the way
## the shot went, and settles; a shotgun blast to an arm up close can take
## it off; the corpse you loot stays with the body.


func _ready() -> void:
	GameState.region = "nyc"
	await _load_game()
	_day()
	await _enter_world_at(Vector3(-470, 0, 330))
	for i in 40:
		await get_tree().physics_frame
	await _shot_dead()
	await _shotgun_arm()
	if OS.get_environment("SHOT") != "":
		await _picture()
	print("RAGDOLL TEST DONE fails=%d" % fails)
	get_tree().quit()


func _victim() -> Node3D:
	var best: Node3D = null
	var bd := INF
	for p in game.crowd.peds:
		var pd: Node3D = p
		if is_instance_valid(pd) and not bool(pd.get("dead")):
			var d := pd.global_position.distance_to(game.player.global_position)
			if d < bd:
				bd = d
				best = pd
	return best


func _ragdoll_of(n: Node3D) -> Ragdoll:
	for c in n.get_parent().get_children():
		if c is Ragdoll and (c as Ragdoll).follower == n:
			return c
	return null


func _shot_dead() -> void:
	print("PHASE shot dead")
	var v := _victim()
	_ok("someone to shoot", v != null)
	if v == null:
		return
	var p0 := v.global_position
	var dir := Vector3(1, 0, 0)
	v.call("note_hit", p0 + Vector3(0, 1.2, 0), dir, 30.0, "pistol")
	v.call("take_hit", 500.0, game.player, false, false, 0.0)
	await get_tree().physics_frame
	var rd := _ragdoll_of(v)
	_ok("a ragdoll, not a canned fall", rd != null and rd.bodies.size() == 6)
	if rd == null:
		return
	var t0: RigidBody3D = rd.bodies[0]
	for i in 30:
		await get_tree().physics_frame
	_ok("shoved the way the shot went (%.2f m)" % (t0.global_position.x - p0.x), t0.global_position.x > p0.x + 0.2)
	for i in 480:
		await get_tree().physics_frame
	_ok("came to rest on the ground (y %.2f)" % t0.global_position.y, t0.global_position.y < 0.6 and t0.global_position.y > -0.3)
	_ok("and froze there", t0.freeze)
	_ok("the corpse stays with the body", v.global_position.distance_to(Vector3(t0.global_position.x, v.global_position.y, t0.global_position.z)) < 1.0)


func _shotgun_arm() -> void:
	print("PHASE shotgun")
	GameState.perks["bloody_mess"] = 1
	var cut := 0
	for k in 6:
		var v := _victim()
		if v == null:
			break
		var mi: MeshInstance3D = v.get("_mesh")
		var parts := Ragdoll.parts_of(mi.mesh)
		var arm: Vector3 = mi.global_transform * ((parts[4] as Dictionary)["center"] as Vector3)
		game.player.global_position = v.global_position + Vector3(-3, 0, 0)
		v.call("note_hit", arm, Vector3(1, 0, 0), 63.0, "shotgun")
		v.call("take_hit", 500.0, game.player, false, false, 0.0)
		await get_tree().physics_frame
		var rd := _ragdoll_of(v)
		if rd == null:
			continue
		var joints := 0
		for c in rd.get_children():
			if c is ConeTwistJoint3D:
				joints += 1
		if joints == 4:
			cut += 1
		for i in 10:
			await get_tree().physics_frame
	_ok("a shotgun to the arm up close takes it off, sometimes (%d of 6)" % cut, cut >= 1)


func _picture() -> void:
	var v := _victim()
	if v == null:
		return
	var cam := Camera3D.new()
	game.add_child(cam)
	cam.global_position = v.global_position + Vector3(-3.5, 2.2, 2.5)
	cam.look_at(v.global_position + Vector3(1.0, 0.4, 0), Vector3.UP)
	cam.make_current()
	v.call("note_hit", v.global_position + Vector3(0, 1.66, 0), Vector3(1, 0, 0), 80.0, "sniper")
	v.call("take_hit", 500.0, game.player, true, false, 0.0)
	for i in 40:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT"))
