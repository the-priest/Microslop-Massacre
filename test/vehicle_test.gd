extends Node
## Cars: parked stealable cars appear, you can steal one, drive it, steer,
## crash it, get out; traffic cars can be carjacked. Driven with real input
## actions so the controls are exercised too.

var game
var fails := 0


func _ready() -> void:
	var scene: PackedScene = load("res://game/Game.tscn")
	game = scene.instantiate()
	game.test_mode = true
	game.test_picker = func(c): return 0
	add_child(game)
	await _until(func() -> bool: return game.player != null and not game.busy_transition and GameState.cell == "krista_office" and not game.dialog.is_open() and GameState.quests.has("mq_hello"), 6000)
	GameState.game_minutes = GameState.day() * 1440.0 + 13 * 60.0
	await game.enter_cell("world", Vector3(-466, 0.2, 320), PI * 0.5, false, true)
	await _frames(30)
	# Parked cars get placed around us within a few slow ticks.
	for i in 12:
		game._update_parked()
	var n: int = game.parked_cars.size()
	_ok("parked stealable cars spawned (%d)" % n, n >= 4)
	var bad := 0
	for c in game.parked_cars:
		var v: Vehicle = c
		for e in game.loot_index.near(v.global_position, 3.0):
			if str((e as Dictionary).get("kind", "")) in ["car", "taxi"]:
				bad += 1
	_ok("no parked car spawned on top of a static one", bad == 0)
	if n == 0:
		_done()
		return
	var car: Vehicle = game.parked_cars[0]
	GameState.base_skills["lockpick"] = 100
	game.player.global_position = car.global_position + car.global_transform.basis.x * 2.2
	await _frames(5)
	var info: Dictionary = car.interact_info()
	_ok("car prompt: %s" % str(info), str(info.get("verb", "")).begins_with("Steal") or str(info.get("verb", "")) == "Drive")
	await game.interact(car)
	await _frames(5)
	_ok("driving", game.player.driving == car)
	_ok("chase cam current", get_viewport().get_camera_3d() == car.cam)
	# Out of the parking spot and onto an open avenue lane, pointing north.
	car.global_position = Vector3(WorldLayout.ax(2) + 2.2, 0.3, 250.0)
	car.rotation.y = 0.0
	car.speed = 0.0
	await _frames(10)
	var p0: Vector3 = car.global_position
	Input.action_press("move_forward")
	await _secs(2.5)
	Input.action_release("move_forward")
	var moved: float = car.global_position.distance_to(p0)
	_ok("car drove forward (%.1f m, %.1f m/s, hp %d)" % [moved, car.speed, int(car.hp)], moved > 6.0)
	_ok("player rides along", game.player.global_position.distance_to(car.global_position) < 1.5)
	Input.action_press("move_left")
	Input.action_press("move_forward")
	var y0: float = car.rotation.y
	await _secs(1.2)
	Input.action_release("move_left")
	Input.action_release("move_forward")
	_ok("steering turns the car (%.2f rad)" % absf(wrapf(car.rotation.y - y0, -PI, PI)), absf(wrapf(car.rotation.y - y0, -PI, PI)) > 0.2)
	Input.action_press("move_back")
	await _secs(2.0)
	Input.action_release("move_back")
	await _secs(1.0)
	game.exit_vehicle()
	await _frames(5)
	_ok("got out", game.player.driving == null and get_viewport().get_camera_3d() == game.player.cam)
	_ok("player collides again", game.player.collision_layer == Phys.PLAYER)
	# Damage and explosion.
	car.damage(150.0)
	await _frames(5)
	_ok("car wrecked", car.dead)
	# Carjack: park a traffic car next to us.
	await _secs(1.0)
	var tc = null
	for c in game.traffic.cars:
		tc = c
		break
	if tc == null:
		for i in 60:
			await _frames(10)
			if not game.traffic.cars.is_empty():
				tc = game.traffic.cars[0]
				break
	_ok("traffic exists", tc != null)
	if tc != null:
		tc.speed = 0.0
		var ci: Dictionary = tc.interact_info()
		_ok("carjack prompt: %s" % str(ci), str(ci.get("verb", "")) == "Carjack")
		game.interact(tc)
		await _frames(5)
		_ok("carjacked and driving", game.player.driving != null)
		_ok("traffic car removed", not game.traffic.cars.has(tc))
		game.exit_vehicle(true)
	# Any of the city's own parked cars can be stolen.
	await game.enter_cell("world", Vector3(-466, 0.2, 320), PI * 0.5, false, true)
	await _frames(20)
	var best: Dictionary = {}
	var bd := 9999.0
	for e in game.loot_index.near(game.player.global_position, 80.0):
		if (e as Dictionary).has("car") and not (e as Dictionary).has("gone"):
			var d: float = ((e["p"] as Vector3) - game.player.global_position).length()
			if d < bd:
				bd = d
				best = e
	_ok("city parked car nearby (%.0f m)" % bd, not best.is_empty())
	if not best.is_empty():
		var cp: Vector3 = best["p"]
		var side := Vector3(3.0, 0, 0) if (best["he"] as Vector3).z > (best["he"] as Vector3).x else Vector3(0, 0, 3.0)
		game.player.global_position = Vector3(cp.x, 0.1, cp.z) + side
		await _frames(3)
		game.player.look_toward(Vector3(cp.x, 0.9, cp.z))
		var cam: Camera3D = game.player.cam
		game.player.cam.make_current()
		await _frames(6)
		var shot_xf: Transform3D = cam.global_transform
		var img0 := get_viewport().get_texture().get_image()
		img0.save_png(_out("steal_before.png"))
		var vi = game.loot_pick(cam.global_position, -cam.global_transform.basis.z, 6.0)
		_ok("parked car prompt: %s %s" % [vi.verb if vi != null else "-", vi.title if vi != null else "-"], vi != null and vi.kind == "parked_car")
		GameState.base_skills["lockpick"] = 100
		if vi != null:
			await game.interact(vi)
			await _frames(5)
		_ok("driving the stolen parked car", game.player.driving != null)
		_ok("merged car hidden", best.has("gone") and int(Mats.city_lit.get_shader_parameter("hide_n")) >= 1)
		var q := PhysicsRayQueryParameters3D.create(Vector3(cp.x, 3.0, cp.z), Vector3(cp.x, 0.3, cp.z), Phys.WORLD)
		await _frames(2)
		_ok("its static collider is gone", get_viewport().get_world_3d().direct_space_state.intersect_ray(q).is_empty())
		var v: Vehicle = game.player.driving
		if v != null:
			v.global_position = Vector3(WorldLayout.ax(2) + 2.2, 0.3, 250.0)
			game.exit_vehicle(true)
			await _frames(3)
			var dc := Camera3D.new()
			game.add_child(dc)
			dc.global_transform = shot_xf
			dc.make_current()
			await _frames(6)
			get_viewport().get_texture().get_image().save_png(_out("steal_after.png"))
	_done()


func _done() -> void:
	print("VEHICLE TEST DONE fails=%d" % fails)
	get_tree().quit()


func _ok(what: String, cond: bool) -> void:
	print(("  ok   " if cond else "  FAIL ") + what)
	if not cond:
		fails += 1


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _secs(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _until(c: Callable, limit: int) -> void:
	var t := 0
	while not c.call() and t < limit:
		await get_tree().process_frame
		t += 1


## Screenshots go to $OUT if set, else the user data folder.
func _out(f: String) -> String:
	var d := OS.get_environment("OUT")
	return (d.trim_suffix("/") + "/" + f) if d != "" else "user://" + f
