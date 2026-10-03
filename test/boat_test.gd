extends "res://test/towns_walk.gd"
## Boats: a speedboat off the Coney Island pier, out into the Atlantic, no
## running up the beach, no stepping off in open water, round into the East
## River and off at the landing; the harbor patrol boat is a crime to take;
## Chicago's lakefront sailed straight into Redmont's reservoir and off on
## the pier; Port Ramsey's harbor out to Price Island's dock; and a boat left
## at a dock is still there when you come back.


func _ready() -> void:
	GameState.region = "nyc"
	await _load_game()
	GameState.raise_skill("lockpick", 30)
	_day()
	await _coney()
	await _patrol()
	await _the_lake()
	await _the_island()
	print("BOAT TEST DONE fails=%d" % fails)
	get_tree().quit()


func _dock_it(id: String) -> Interactable:
	return _find_it(id)


func _board(id: String) -> Boat:
	await _enter_world_at(Boats.land_pos(id) + Vector3(0, 0, -3.0))
	await _settle()
	var it := _dock_it(id)
	_ok("dock %s is there" % id, it != null)
	if it == null:
		return null
	_ok("a boat is tied up at %s" % id, game.boats_ctl.boat_at(id) != null)
	await game.interact(it)
	await _settle()
	var b: Variant = game.player.driving
	_ok("aboard at %s" % id, b is Boat)
	return b as Boat if b is Boat else null


func _throttle(secs: float, steer: String = "") -> void:
	Input.action_press("move_forward")
	if steer != "":
		Input.action_press(steer)
	var t := 0.0
	while t < secs:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	Input.action_release("move_forward")
	if steer != "":
		Input.action_release(steer)


func _coney() -> void:
	print("PHASE coney")
	var b := await _board("nyc_coney")
	if b == null:
		return
	var p0 := b.global_position
	await _throttle(3.0)
	_ok("under way (%.0f m)" % b.global_position.distance_to(p0), b.global_position.distance_to(p0) > 15.0)
	_ok("afloat", absf(b.global_position.y - Boat.WATER_Y) < 0.05)
	_ok("on the water", Boats.is_water("nyc", Vector2(b.global_position.x, b.global_position.z)))
	# Head for the beach: she runs aground at the waterline, never past it.
	b.global_position = Vector3(300.0, Boat.WATER_Y, 830.0)
	b.rotation.y = 0.0
	b.speed = 0.0
	b.snap_vis()
	await _throttle(4.0)
	_ok("stopped at the beach (z %.0f)" % b.global_position.z, b.global_position.z > 794.0)
	# No stepping off in open water.
	b.global_position = Vector3(500.0, Boat.WATER_Y, 1100.0)
	b.speed = 0.0
	b._vel = Vector2.ZERO
	await _settle()
	game.exit_vehicle()
	await _settle()
	_ok("can't get off in open water", game.player.driving == b)
	# Round to the East River landing and off.
	var wp := Boats.water_pos("nyc_east")
	b.global_position = Vector3(wp.x, Boat.WATER_Y, wp.z + 18.0)
	b.speed = 0.0
	b._vel = Vector2.ZERO
	b.snap_vis()
	await _settle()
	game.exit_vehicle()
	await _settle()
	_ok("off at the East River landing", game.player.driving == null and game.player.global_position.distance_to(Boats.land_pos("nyc_east")) < 3.0)


func _patrol() -> void:
	print("PHASE harbor patrol")
	GameState.clear_wanted()
	var pb: Boat = null
	for v in game.vehicles_root.get_children():
		if v is Boat and (v as Boat).model == "patrol":
			pb = v
	_ok("the harbor patrol boat is tied up", pb != null)
	if pb == null:
		return
	_ok("and locked", pb.locked)
	game.player.global_position = Boats.land_pos("nyc_east")
	await game._use_vehicle(pb)
	await _settle()
	_ok("stole it", game.player.driving == pb)
	game.exit_vehicle(true)
	await _settle()


func _the_lake() -> void:
	print("PHASE the lake")
	await _travel("chicago", "")
	var b := await _board("chi_harbor")
	if b == null:
		return
	# Out to the east edge of Chicago's waters, heading for Redmont.
	var sky: Rect2 = Regions.SKY["chicago"]
	game.region_requested = ""
	b.global_position = Vector3(sky.end.x - 20.0, Boat.WATER_Y, 0.0)
	b.rotation.y = -PI * 0.5
	b.speed = 20.0
	b._vel = Vector2(20.0, 0.0)
	b.snap_vis()
	await _throttle(3.0)
	_ok("the lake hands over to Redmont", game.region_requested == "redmont")
	if game.region_requested != "redmont":
		return
	await _reload()
	_ok("sailing on the reservoir", WorldLayout.region == "redmont" and game.player.driving is Boat)
	var rb: Boat = game.player.driving as Boat
	if rb == null:
		return
	_ok("on Redmont's water", Boats.is_water("redmont", Vector2(rb.global_position.x, rb.global_position.z)))
	var wp := Boats.water_pos("rm_launch")
	rb.global_position = Vector3(wp.x - 10.0, Boat.WATER_Y, wp.z)
	rb.speed = 0.0
	rb._vel = Vector2.ZERO
	rb.snap_vis()
	await _settle()
	game.exit_vehicle()
	await _settle()
	_ok("off on the reservoir pier", game.player.driving == null and game.player.global_position.distance_to(Boats.land_pos("rm_launch")) < 8.0)
	# The pier runs back to town through a gap in the edge wall, and its
	# railings keep you off the mud.
	_ok("a gap in the wall where the pier meets the shore", not _blocked(Vector3(-748, 1, 300), Vector3(-734, 1, 300)))
	_ok("the wall either side of it", _blocked(Vector3(-748, 1, 320), Vector3(-734, 1, 320)))
	_ok("railings along the pier", _blocked(Vector3(-820, 1, 300), Vector3(-820, 1, 310)))


func _the_island() -> void:
	print("PHASE the island")
	await _travel("port", "")
	var b := await _board("pt_harbor")
	if b == null:
		return
	var sky: Rect2 = Regions.SKY["port"]
	game.region_requested = ""
	b.global_position = Vector3(sky.end.x - 20.0, Boat.WATER_Y, 0.0)
	b.rotation.y = -PI * 0.5
	b.speed = 20.0
	b._vel = Vector2(20.0, 0.0)
	b.snap_vis()
	await _throttle(3.0)
	_ok("the harbor hands over to Price Island", game.region_requested == "island")
	if game.region_requested != "island":
		return
	await _reload()
	var ib: Boat = game.player.driving as Boat
	_ok("at sea off Price Island", WorldLayout.region == "island" and ib != null)
	if ib == null:
		return
	var wp := Boats.water_pos("isl_dock")
	ib.global_position = Vector3(wp.x, Boat.WATER_Y, wp.z - 12.0)
	ib.speed = 0.0
	ib._vel = Vector2.ZERO
	ib.snap_vis()
	await _settle()
	game.exit_vehicle()
	await _settle()
	_ok("off at Price's dock", game.player.driving == null and game.player.global_position.distance_to(Boats.land_pos("isl_dock")) < 8.0)
	# Leave it; come back; it's still there.
	var kept := false
	for r in GameState.rides:
		if str((r as Dictionary).get("kind", "")) == "boat" and str((r as Dictionary).get("region", "")) == "island":
			kept = true
	_ok("the boat you left is remembered", kept)
	await _reload_keeping()
	var found := false
	for v in game.vehicles_root.get_children():
		if v is Boat and (v as Boat).has_meta("ride_uid") and (v as Boat).global_position.distance_to(wp) < 30.0:
			found = true
	_ok("and still at the dock when you come back", found)


func _reload_keeping() -> void:
	game.sync_state_for_save()
	SaveManager.pending_load = {"state": GameState.to_dict(), "travel": {}}
	await _reload()
	await _settle()
	for i in 10:
		game._update_rides()
		await get_tree().physics_frame


func _blocked(a: Vector3, b: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(a, b, Phys.WORLD)
	return not game.get_world_3d().direct_space_state.intersect_ray(q).is_empty()
