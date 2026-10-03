extends "res://test/towns_walk.gd"
## Planes and buildings: a jet flown into a mid-rise at speed brings it down
## (dust, debris, a burning pile, the collision gone); the save remembers,
## and after a reload the building is rubble and the rest of the city is
## exactly where it was.


func _ready() -> void:
	GameState.region = "nyc"
	await _load_game()
	_day()
	await _enter_world_at(Vector3(-470, 0, 300))
	var target: Array = []
	for b in game.city_buildings:
		var a: Array = b
		var c := Vector2((float(a[0]) + float(a[2])) * 0.5, (float(a[1]) + float(a[3])) * 0.5)
		if a.size() > 6 and float(a[4]) > 20.0 and float(a[4]) < 60.0 and c.distance_to(Vector2(-470, 300)) < 400.0 and float(a[2]) - float(a[0]) > 12.0:
			target = a
			break
	_ok("a mid-rise to aim at", not target.is_empty())
	if target.is_empty():
		_done_now()
		return
	var c3 := Vector3((float(target[0]) + float(target[2])) * 0.5, float(target[4]) * 0.5, (float(target[1]) + float(target[3])) * 0.5)
	var doors_before: int = game.gen_doors.size()
	var roof := Vector3(c3.x, float(target[4]) + 20.0, c3.z)
	var mid := Vector3(c3.x, float(target[4]) * 0.6, c3.z)
	_ok("it's solid before", _blocked(roof, mid))
	# The jet, coming in fast and level from the south.
	game.collapse.force = true
	var a := Aircraft.new().setup_plane("citation", c3 + Vector3(0, 0, float(target[3]) - c3.z + 60.0), 0.0, game)
	a.locked = false
	game.vehicles_root.add_child(a)
	await get_tree().physics_frame
	game.enter_vehicle(a)
	a.airborne = true
	a.speed = 70.0
	a.throttle = 1.0
	for i in 240:
		await get_tree().physics_frame
		if a.dead:
			break
	_ok("the jet hit it", a.dead)
	var down := Collapse.down_in("nyc")
	_ok("the building came down (%d)" % down.size(), down.size() == 1)
	var qd := PhysicsRayQueryParameters3D.create(roof, mid, Phys.WORLD)
	var hd := game.get_world_3d().direct_space_state.intersect_ray(qd)
	if not hd.is_empty():
		var col: CollisionObject3D = hd["collider"]
		var own: Object = col.shape_owner_get_owner(col.shape_find_owner(int(hd["shape"])))
		print("  dbg hit ", hd["position"], " ", col.name, " ", (own as Node3D).position if own is Node3D else "?", " ", ((own as CollisionShape3D).shape as BoxShape3D).size if own is CollisionShape3D else "", " disabled=", (own as CollisionShape3D).disabled if own is CollisionShape3D else "")
	print("  dbg target ", target, " down ", Collapse.down_in("nyc"))
	_ok("and nothing's left standing there", not _blocked(roof, mid))
	_ok("a rubble pile where it stood", game.city_extras.get_node_or_null("Rubble") != null)
	for i in 60:
		await get_tree().physics_frame
	# Reload: rubble, not a building; every other door still where it was.
	game.collapse.force = false
	game.sync_state_for_save()
	if game.player.driving != null:
		game.exit_vehicle(true)
	SaveManager.pending_load = {"state": GameState.to_dict(), "travel": {}}
	await _reload()
	await _settle()
	var still := false
	for b in game.city_buildings:
		var a2: Array = b
		if is_equal_approx(float(a2[0]), float(target[0])) and is_equal_approx(float(a2[1]), float(target[1])):
			still = true
	_ok("after a reload it's still down", not still)
	_ok("rubble you can walk on, not a tower", _blocked(roof, Vector3(c3.x, -0.5, c3.z)) and not _blocked(roof, Vector3(c3.x, 9.0, c3.z)))
	_ok("the rest of the city didn't move (%d -> %d doors, one lost)" % [doors_before, game.gen_doors.size()], game.gen_doors.size() >= doors_before - 1 and game.gen_doors.size() <= doors_before)
	_done_now()


func _done_now() -> void:
	print("COLLAPSE TEST DONE fails=%d" % fails)
	get_tree().quit()


func _blocked(a: Vector3, b: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(a, b, Phys.WORLD)
	return not game.get_world_3d().direct_space_state.intersect_ray(q).is_empty()
