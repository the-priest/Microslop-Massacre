extends "res://test/towns_walk.gd"
## Stunt jumps: every map's ramps are where they should be and clear to drive
## at; Coney Island's beach ramp hit at speed (the launch, the slow motion,
## the landing, the pay); a ramp taken too slowly; and Microslop Field's.


func _ready() -> void:
	GameState.region = "nyc"
	await _load_game()
	_day()
	GameState.cash = 500
	_ok("ramps on coney island and bowery bay (%d)" % game.stunts.jumps.size(), game.stunts.jumps.size() == 4)
	var sum := 0
	for r in ["nyc", "chicago", "township", "port", "gary", "redmont", "highway"]:
		WorldLayout.set_region(r)
		sum += StuntJumps.spots(r).size()
	WorldLayout.set_region("nyc")
	_ok("%d jumps across the world" % sum, sum == StuntJumps.total())
	await _jump("nyc_beach_w", 30.0, true)
	await _jump("nyc_field_n", 9.0, false)
	await _jump("nyc_field_s", 30.0, true)
	await _jump("nyc_beach_e", 30.0, true)
	_ok("three jumps landed, paid three times", int(GameState.flags.get("jumps_done", 0)) == 3 and GameState.cash == 500 + 3 * StuntJumps.PAY)
	# Redmont's field.
	GameState.region = "redmont"
	GameState.cell = "world"
	GameState.pos_local = false
	GameState.player_pos = Vector3.ZERO
	SaveManager.pending_load = {"state": GameState.to_dict(), "travel": {}}
	await _reload()
	_ok("ramps at microslop field (%d)" % game.stunts.jumps.size(), game.stunts.jumps.size() == 2)
	await _jump("redmont_field_n", 30.0, true)
	_ok("time runs normally again", is_equal_approx(Engine.time_scale, 1.0))
	for r in ["chicago", "township", "port", "gary"]:
		GameState.region = r
		GameState.cell = "world"
		GameState.player_pos = Vector3.ZERO
		SaveManager.pending_load = {"state": GameState.to_dict(), "travel": {}}
		await _reload()
		_ok("two ramps on %s" % r, game.stunts.jumps.size() == 2)
		for j in game.stunts.jumps:
			var jd: Dictionary = j
			var yaw := float(jd["yaw"])
			var f := Vector3(-sin(yaw), 0, -cos(yaw))
			var start: Vector3 = jd["start"]
			await _enter_world_at(start - f * 50.0)
			var q := PhysicsShapeQueryParameters3D.new()
			var bs := BoxShape3D.new()
			bs.size = Vector3(4.0, 2.0, 100.0)
			q.shape = bs
			q.collision_mask = Phys.WORLD
			q.transform = Transform3D(Basis.looking_at(f, Vector3.UP), start + f * 20.0 + Vector3(0, 1.6, 0))
			var hits: Array = game.get_world_3d().direct_space_state.intersect_shape(q, 4)
			# The ramp itself is the only thing in the way.
			var others := hits.filter(func(h: Variant) -> bool: return not str(((h as Dictionary)["collider"] as Node).name).begins_with("Ramp_"))
			_ok("run-up and landing clear at %s" % str(jd["id"]), others.is_empty())
	print("STUNT TEST DONE fails=%d" % fails)
	get_tree().quit()


func _jump(id: String, spd: float, expect: bool) -> void:
	print("PHASE jump " + id)
	var jd: Dictionary = {}
	for j in game.stunts.jumps:
		if str((j as Dictionary)["id"]) == id:
			jd = j
	if jd.is_empty():
		_ok("ramp %s exists" % id, false)
		return
	var yaw := float(jd["yaw"])
	var f := Vector3(-sin(yaw), 0, -cos(yaw))
	var start: Vector3 = jd["start"]
	# The run-up and the landing are clear of anything solid.
	var q := PhysicsShapeQueryParameters3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(4.0, 2.0, 60.0)
	q.shape = bs
	q.collision_mask = Phys.WORLD
	q.transform = Transform3D(Basis.looking_at(f, Vector3.UP), start + f * (StuntJumps.RAMP_L + 32.0) + Vector3(0, 1.6, 0))
	await _enter_world_at(start - f * 50.0)
	var hits: Array = game.get_world_3d().direct_space_state.intersect_shape(q, 4)
	_ok("landing zone past %s is clear (%d hits)" % [id, hits.size()], hits.is_empty())
	var car := Vehicle.new().setup("sedan", 3, start - f * 40.0 + Vector3(0, 0.4, 0), yaw, game)
	car.locked = false
	game.vehicles_root.add_child(car)
	await _settle()
	game.enter_vehicle(car)
	await _settle()
	car.global_position = start - f * (30.0 if spd > 20.0 else 6.0) + Vector3(0, 0.4, 0)
	car.rotation = Vector3(0, yaw, 0)
	car.speed = spd
	var cash0 := GameState.cash
	var had := GameState.has_flag("jump_" + id)
	var launched := false
	var slowed := false
	var top := 0.0
	if spd > 20.0:
		Input.action_press("move_forward")
	for i in 600:
		await get_tree().physics_frame
		if car.launched:
			launched = true
		if Engine.time_scale < 0.9:
			slowed = true
		top = maxf(top, car.global_position.y)
		if launched and not car.launched and car.is_on_floor() and game.stunts._jump_id == "":
			break
		if not launched and Vector2(car.global_position.x - start.x, car.global_position.z - start.z).length() > 80.0:
			break
	Input.action_release("move_forward")
	var flew := Vector2(car.global_position.x - start.x, car.global_position.z - start.z).length()
	print("  %s: launched %s, top %.1f m, %.0f m from the ramp" % [id, str(launched), top, flew])
	if expect:
		_ok("launched off " + id, launched and top > StuntJumps.RAMP_H + 0.5)
		_ok("the world slowed down", slowed)
		_ok("landed it: " + id, GameState.has_flag("jump_" + id) and (had or GameState.cash == cash0 + StuntJumps.PAY))
		_ok("still in one piece", not car.dead)
	else:
		_ok("too slow doesn't count", not GameState.has_flag("jump_" + id))
	for i in 5:
		await get_tree().physics_frame
	game.exit_vehicle(true)
	await _settle()
