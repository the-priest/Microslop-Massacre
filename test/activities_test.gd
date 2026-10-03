extends "res://test/towns_walk.gd"
## Repeatable activities: a taxi fare picked up and dropped off (and one
## abandoned), then a street race won on every map that has one.


func _ready() -> void:
	GameState.region = "nyc"
	await _load_game()
	GameState.cash = 1000
	_day()
	await _taxi()
	for id in ["lakeshore", "interstate", "mainstreet", "quay", "broadway"]:
		await _race(id)
	print("ACTIVITIES DONE fails=%d" % fails)
	get_tree().quit()


func _taxi() -> void:
	print("PHASE taxi")
	await _enter_world_at(Vector3(-300, 0, 300))
	var cab := Vehicle.new().setup("taxi", 0, Vector3(-260.0, 0.4, 300.0), 0.0, game)
	cab.locked = false
	game.vehicles_root.add_child(cab)
	await _settle()
	game.enter_vehicle(cab)
	for i in 30:
		await get_tree().create_timer(0.2).timeout
		if game.taxi.state == "pickup":
			break
	_ok("dispatch finds a fare", game.taxi.state == "pickup")
	_ok("the fare has a marker", game.taxi.marker_positions().size() == 1)
	_ok("the hud says so", game.taxi.status().begins_with("TAXI"))
	cab.global_position = game.taxi.fare_pos + Vector3(2.0, 0.4, 0)
	cab.speed = 0.0
	for i in 20:
		await get_tree().create_timer(0.1).timeout
		if game.taxi.state == "ride":
			break
	_ok("the fare gets in", game.taxi.state == "ride" and game.taxi.dest_name != "")
	var cash0 := GameState.cash
	cab.global_position = game.taxi.dest_pos + Vector3(0, 0.4, 0)
	cab.speed = 0.0
	for i in 20:
		await get_tree().create_timer(0.1).timeout
		if game.taxi.state == "":
			break
	_ok("the fare pays at the door", GameState.cash > cash0 and int(GameState.flags.get("taxi_fares", 0)) == 1)
	_ok("streak counts", game.taxi.streak == 1)
	for i in 40:
		await get_tree().create_timer(0.2).timeout
		if game.taxi.state == "pickup":
			break
	game.exit_vehicle(true)
	for i in 5:
		await get_tree().create_timer(0.2).timeout
	_ok("leaving the cab loses the fare", game.taxi.state == "" and game.taxi.streak == 0)


func _race(id: String) -> void:
	var R: Dictionary = Races.RACES[id]
	var reg := str(R["region"])
	print("PHASE race " + id + " (" + reg + ")")
	if WorldLayout.region != reg:
		GameState.region = reg
		GameState.cell = "world"
		var st: Array = R["start"]
		GameState.player_pos = Vector3(float(st[0]) + 20.0, 0.2, float(st[1]))
		await _reload()
	_ok("on the map for " + id, WorldLayout.region == reg)
	await _enter_world_at(Vector3(float((R["start"] as Array)[0]) + 20.0, 0, float((R["start"] as Array)[1])))
	GameState.cash = 1000
	game.races.start(id)
	await _frames(5)
	_ok(id + " started", game.races.is_racing() and game.player.driving == game.races.car and GameState.cash == 1000 - int(R["bet"]))
	for i in 900:
		if game.races.countdown <= 0.0:
			break
		await get_tree().physics_frame
	var pts: Array = R["points"]
	for l in int(R["laps"]):
		for pt in pts:
			if not game.races.is_racing():
				break
			game.races.car.global_position = Vector3(float(pt[0]), 0.4, float(pt[1]))
			for f in 3:
				await get_tree().physics_frame
	await _frames(5)
	_ok(id + " won", not game.races.is_racing() and GameState.has_flag("race_won_" + id) and GameState.cash == 1000 + int(R["bet"]))
	game.exit_vehicle(true)
	await _settle()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
