extends Node
## Rides: a car you drove and parked stays where you left it (across a save
## round trip), towed only when you've left more than RIDES_LOOSE elsewhere;
## the jet Gus signs over is yours, unlocked, and taking it is not a crime.

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
	# A car: drive it, park it outside the building, get out.
	var v := Vehicle.new().setup("sedan", 2, Vector3(-470, 0.2, 316), 0.0, game)
	v.locked = false
	game.vehicles_root.add_child(v)
	await _frames(5)
	game.enter_vehicle(v)
	await _frames(10)
	v.global_position = Vector3(-462, 0.2, 316)
	v.speed = 0.0
	await _frames(5)
	game.exit_vehicle(true)
	await _frames(5)
	_ok("ride remembered", GameState.rides.size() == 1)
	var rec: Dictionary = GameState.rides[0] if GameState.rides.size() > 0 else {}
	_ok("parked at home", bool(rec.get("home", false)))
	# Save round trip: the node goes away, the record comes back as a car.
	var d := GameState.to_dict()
	GameState.from_dict(JSON.parse_string(JSON.stringify(d)))
	v.queue_free()
	game.ride_nodes.clear()
	await _frames(3)
	game._update_rides()
	await _frames(3)
	var back: Vehicle = game.ride_nodes.get(int(rec.get("uid", -1)))
	_ok("car respawned after load", back != null and is_instance_valid(back))
	if back != null:
		_ok("same place (%.1f m off)" % back.global_position.distance_to(Vector3(-462, 0.2, 316)), back.global_position.distance_to(Vector3(-462, 0.2, 316)) < 1.5)
		_ok("unlocked and yours", not back.locked and not back.stolen)
	# Five loose rides elsewhere: only the four newest stay, home car stays.
	for i in 5:
		var c := Vehicle.new().setup("hatch", i, Vector3(-300 - i * 12, 0.2, 316), 0.0, game)
		c.locked = false
		game.vehicles_root.add_child(c)
		await _frames(2)
		game.enter_vehicle(c)
		await _frames(2)
		game.exit_vehicle(true)
		await _frames(2)
	var homes := 0
	for r in GameState.rides:
		if bool((r as Dictionary).get("home", false)):
			homes += 1
	_ok("4 loose + 1 home kept (%d)" % GameState.rides.size(), GameState.rides.size() == 5 and homes == 1)
	# The jet.
	GameState.flags["jet_owned"] = true
	var a: Aircraft = game._spawn_plane("ecorp_jet_test", "citation", Vector3(1395, 0.1, -1150), 0.0)
	_ok("owned jet unlocked", not a.locked and a.owner_tag == "player")
	var wanted_before := GameState.wanted_until
	game._use_vehicle(a)
	await _frames(5)
	_ok("taking your own jet is not a crime", GameState.wanted_until <= maxf(wanted_before, GameState.game_minutes))
	_ok("no stolen-jet flag", not GameState.flags.has("ecorp_jet_gone"))
	_done()


func _ok(what: String, c: bool) -> void:
	print(("OK   " if c else "FAIL ") + what)
	if not c:
		fails += 1


func _done() -> void:
	print("RIDE TEST DONE fails=%d" % fails)
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _until(f: Callable, max_frames: int) -> void:
	var i := 0
	while not f.call() and i < max_frames:
		await get_tree().process_frame
		i += 1
