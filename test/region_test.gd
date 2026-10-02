extends Node
## Regions: drive out of New York's travel gate onto the interstate, through it
## to Chicago (with the same car), fly a plane out of Chicago's airspace back to
## New York, and check each map builds, has its doors and keeps you in a car.

var game
var fails := 0


func _ready() -> void:
	await _boot()
	await _until(func() -> bool: return GameState.quests.has("mq_hello"), 6000)
	GameState.game_minutes = GameState.day() * 1440.0 + 13 * 60.0
	_ok("starts in nyc", WorldLayout.region == "nyc")
	await game.enter_cell("world", Vector3(-390, 0.2, -1600), PI, false, true)
	await _frames(10)
	var v := Vehicle.new().setup("sedan", 3, Vector3(-390, 0.3, -1630), PI, game)
	v.locked = false
	game.vehicles_root.add_child(v)
	await _frames(3)
	game.enter_vehicle(v)
	await _frames(3)
	for i in 4:
		game._update_gates()
	_ok("nyc gate asks for the highway", game.region_requested == "highway")
	await _reload()
	_ok("on the highway", WorldLayout.region == "highway" and GameState.region == "highway")
	_ok("arrived driving", game.player.driving != null)
	_ok("highway doors exist", WorldLayout.all_doors().has("d_hw_diner"))
	print("  highway pos ", game.player.global_position)
	game.player.driving.global_position = Vector3(0, 0.3, -1755)
	await _frames(3)
	for i in 4:
		game._update_gates()
	_ok("highway west gate asks for chicago", game.region_requested == "chicago")
	await _reload()
	_ok("in chicago", WorldLayout.region == "chicago")
	_ok("chicago doors", WorldLayout.all_doors().has("d_chi_node"))
	_ok("arrived driving in chicago", game.player.driving != null)
	print("  chicago pos ", game.player.global_position, " district ", WorldLayout.district_at(game.player.global_position.x, game.player.global_position.z))
	# Enter and leave a Chicago interior.
	game.exit_vehicle(true)
	await _frames(5)
	# Fly out: a plane past the airspace edge, choose New York.
	var a := Aircraft.new().setup_plane("citation", Vector3(1800, 200, 0), 0.0, game)
	a.locked = false
	game.vehicles_root.add_child(a)
	await _frames(3)
	game.enter_vehicle(a)
	a.airborne = true
	await _frames(2)
	game.test_picker = func(chs: Array) -> int:
		for i in chs.size():
			if str((chs[i] as Dictionary)["text"]).contains("New York"):
				return i
		return 0
	game.airspace_exit(a)
	await _until(func() -> bool: return game.region_requested == "nyc", 600)
	_ok("flight to new york requested", game.region_requested == "nyc")
	await _reload()
	_ok("back in nyc", WorldLayout.region == "nyc")
	_ok("arrived flying", game.player.driving is Aircraft and (game.player.driving as Aircraft).airborne)
	print("REGION TEST DONE fails=%d" % fails)
	get_tree().quit()


func _boot() -> void:
	var scene: PackedScene = load("res://game/Game.tscn")
	game = scene.instantiate()
	game.test_mode = true
	game.test_picker = func(c): return 0
	add_child(game)
	await _until(func() -> bool: return game.player != null and not game.busy_transition, 6000)


func _reload() -> void:
	game.queue_free()
	await _frames(3)
	var scene: PackedScene = load("res://game/Game.tscn")
	game = scene.instantiate()
	game.test_mode = true
	game.test_picker = func(c): return 0
	add_child(game)
	await _until(func() -> bool: return game.player != null and not game.busy_transition and game.player.driving != null, 3000)
	await _frames(10)


func _ok(what: String, c: bool) -> void:
	print(("OK   " if c else "FAIL ") + what)
	if not c:
		fails += 1


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _until(f: Callable, max_frames: int) -> void:
	var i := 0
	while not f.call() and i < max_frames:
		await get_tree().process_frame
		i += 1
