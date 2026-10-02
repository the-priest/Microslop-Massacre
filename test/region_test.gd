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
	game.player.driving.global_position = Vector3(0, 0.3, -855)
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
	# Fly home the long way: south out of Chicago's airspace, across I-80, into
	# New York, in one plane, without a menu.
	var a := Aircraft.new().setup_plane("skyhawk", Vector3(0, 150, 1400), PI, game)
	a.locked = false
	game.vehicles_root.add_child(a)
	await _frames(3)
	game.enter_vehicle(a)
	a.airborne = true
	a.heading = PI
	a.speed = 50.0
	await _frames(2)
	a.global_position = Vector3(0, 150, 1520)
	_ok("leaving chicago's airspace crosses over", game.airspace_exit(a))
	_ok("next is the interstate", game.region_requested == "highway")
	await _reload()
	_ok("over I-80", WorldLayout.region == "highway")
	var ac: Aircraft = game.player.driving as Aircraft
	_ok("still flying", ac != null and ac.airborne)
	if ac != null:
		print("  arrived over I-80 at ", ac.global_position, " speed ", ac.speed)
		_ok("same height", absf(ac.global_position.y - 150.0) < 20.0)
		_ok("came in at the north edge", ac.global_position.z < -700.0)
		_ok("kept its speed", absf(ac.speed - 50.0) < 6.0)
		ac.global_position = Vector3(ac.global_position.x, 150, 930)
		_ok("leaving I-80 to the south crosses over", game.airspace_exit(ac))
		_ok("next is new york", game.region_requested == "nyc")
		await _reload()
	_ok("back in nyc", WorldLayout.region == "nyc")
	_ok("arrived flying", game.player.driving is Aircraft and (game.player.driving as Aircraft).airborne)
	if game.player.driving != null:
		print("  arrived over new york at ", game.player.driving.global_position)
		_ok("came in over the north edge", game.player.driving.global_position.z < -2300.0)
	# The far side of New York borders nothing: no crossing, the plane turns back.
	var b: Aircraft = game.player.driving as Aircraft
	if b != null:
		b.global_position = Vector3(0, 150, 1500)
		_ok("open ocean: no crossing", not game.airspace_exit(b))
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
