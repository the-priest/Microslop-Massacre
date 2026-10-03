extends "res://test/towns_walk.gd"
## Air races: the Harbor Lap started from Marisol's board, flown and landed for
## gold; The Reservoir from Port Ramsey up across the border into Redmont,
## over the data center and Microslop's roof; The Lakefront from Gary across the airspace border into Chicago, its
## clock and rings carried over the handover, landed at the Chicago field;
## then The Ore Run abandoned by climbing out of the plane.


func _ready() -> void:
	GameState.region = "port"
	await _load_game()
	GameState.cash = 2000
	_day()
	await _harbor()
	await _crossing()
	await _reservoir()
	await _lakefront()
	await _bail()
	print("AIR RACE TEST DONE fails=%d" % fails)
	get_tree().quit()


func _harbor() -> void:
	print("PHASE harbor lap")
	_ok("in port", WorldLayout.region == "port")
	await _enter_world_at(AirRaces.board_pos() + Vector3(0, 0, -6.0))
	_ok("the board is on the apron", _find_it("air_board") != null)
	await _spot("air_board", ["Harbor Lap"])
	await _frames(10)
	_ok("harbor started in a loaner", game.air_races.active() == "harbor" and game.player.driving is Aircraft and GameState.cash == 2000 - 60)
	await _wait_countdown()
	var a: Aircraft = game.player.driving
	_ok("the hud shows the race", game.air_races.status().begins_with("AIR RACE"))
	_ok("the compass points at the ring", game.air_races.marker_positions().size() == 1)
	await _fly_rings(a)
	_ok("every harbor ring", int(GameState.flags.get("ar_ring", 0)) == (AirRaces.RACES["harbor"]["rings"] as Array).size())
	await _touch_down(a)
	_ok("harbor lap gold", int(GameState.flags.get("ar_medal_harbor", 0)) == 3 and not game.air_races.is_racing() and GameState.cash == 2000 - 60 + 500)
	_ok("best time kept", float(GameState.flags.get("ar_best_harbor", 0.0)) > 0.0)


func _crossing() -> void:
	print("PHASE the crossing")
	await _reload_keeping_state_at("port")
	await _enter_world_at(AirRaces.board_pos() + Vector3(0, 0, -6.0))
	await _spot("air_board", ["The Crossing"])
	await _frames(10)
	_ok("crossing started", game.air_races.active() == "crossing")
	await _wait_countdown()
	var a: Aircraft = game.player.driving
	await _fly_rings(a)
	_ok("port's rings flown", int(GameState.flags.get("ar_ring", 0)) == 2)
	await _fly_border("island")
	a = game.player.driving
	await _fly_rings(a)
	_ok("every crossing ring", int(GameState.flags.get("ar_ring", 0)) == (AirRaces.RACES["crossing"]["rings"] as Array).size())
	await _touch_down(a)
	_ok("crossing gold on price's strip", int(GameState.flags.get("ar_medal_crossing", 0)) == 3 and not game.air_races.is_racing())
	game.exit_vehicle(true)
	await _settle()
	await _reload_keeping_state_at("port")


func _reload_keeping_state_at(region: String) -> void:
	if game.player.driving != null:
		game.exit_vehicle(true)
		await _settle()
	GameState.region = region
	GameState.cell = "world"
	await _reload_keeping_state()


func _reservoir() -> void:
	print("PHASE the reservoir")
	if game.player.driving != null:
		game.exit_vehicle(true)
	await _enter_world_at(AirRaces.board_pos() + Vector3(0, 0, -6.0))
	var cash0 := GameState.cash
	await _spot("air_board", ["The Reservoir"])
	await _frames(10)
	_ok("reservoir started", game.air_races.active() == "reservoir" and GameState.cash == cash0 - 60)
	await _wait_countdown()
	var a: Aircraft = game.player.driving
	await _fly_rings(a)
	_ok("port's ring flown", int(GameState.flags.get("ar_ring", 0)) == 1)
	await _fly_border("redmont")
	_ok("still racing over redmont", game.air_races.active() == "reservoir")
	a = game.player.driving
	await _fly_rings(a)
	_ok("every reservoir ring", int(GameState.flags.get("ar_ring", 0)) == (AirRaces.RACES["reservoir"]["rings"] as Array).size())
	await _touch_down(a)
	_ok("reservoir gold at microslop field", int(GameState.flags.get("ar_medal_reservoir", 0)) == 3 and not game.air_races.is_racing())
	game.exit_vehicle(true)
	await _settle()
	_ok("redmont has a race board too", _find_it("air_board") != null)


func _lakefront() -> void:
	print("PHASE the lakefront")
	GameState.region = "gary"
	GameState.cell = "world"
	if game.player.driving != null:
		game.exit_vehicle(true)
	await _reload_keeping_state()
	_ok("in gary", WorldLayout.region == "gary")
	await _enter_world_at(AirRaces.board_pos() + Vector3(0, 0, -6.0))
	var cash0 := GameState.cash
	await _spot("air_board", ["Lakefront"])
	await _frames(10)
	_ok("lakefront started", game.air_races.active() == "lakefront" and GameState.cash == cash0 - 100)
	await _wait_countdown()
	var a: Aircraft = game.player.driving
	await _fly_rings(a)
	_ok("gary's rings flown", int(GameState.flags.get("ar_ring", 0)) == 2)
	_ok("the hud says the next ring is over chicago", game.air_races.status().contains("CHICAGO"))
	var t0 := float(GameState.flags.get("ar_t", 0.0))
	await _fly_toward("chicago")
	_ok("still racing over chicago", game.air_races.active() == "lakefront" and int(GameState.flags.get("ar_ring", 0)) == 2)
	_ok("the clock came too", float(GameState.flags.get("ar_t", 0.0)) >= t0)
	a = game.player.driving
	await _fly_rings(a)
	_ok("every lakefront ring", int(GameState.flags.get("ar_ring", 0)) == (AirRaces.RACES["lakefront"]["rings"] as Array).size())
	await _touch_down(a)
	_ok("lakefront gold", int(GameState.flags.get("ar_medal_lakefront", 0)) == 3 and not game.air_races.is_racing())


func _bail() -> void:
	print("PHASE bail out")
	GameState.region = "gary"
	GameState.cell = "world"
	if game.player.driving != null:
		game.exit_vehicle(true)
	await _reload_keeping_state()
	await _enter_world_at(AirRaces.board_pos() + Vector3(0, 0, -6.0))
	await _spot("air_board", ["Ore Run"])
	await _frames(10)
	_ok("ore run started", game.air_races.active() == "ore_run")
	await _wait_countdown()
	game.exit_vehicle(true)
	for i in 30:
		await get_tree().create_timer(0.1).timeout
		if not game.air_races.is_racing():
			break
	_ok("getting out ends the race", not game.air_races.is_racing() and not GameState.flags.has("ar_t"))


## Reload onto the map in GameState.region the way a save loads: same state.
func _reload_keeping_state() -> void:
	GameState.pos_local = false
	GameState.player_pos = Vector3.ZERO
	SaveManager.pending_load = {"state": GameState.to_dict(), "travel": {}}
	await _reload()


func _wait_countdown() -> void:
	for i in 600:
		if game.air_races.countdown <= 0.0:
			break
		await get_tree().physics_frame
	await get_tree().physics_frame


## Fly through every ring that's over this map, in order.
func _fly_rings(a: Aircraft) -> void:
	var rings: Array = AirRaces.RACES[game.air_races.active()]["rings"]
	for guard in rings.size():
		var ri := int(GameState.flags.get("ar_ring", 0))
		if ri >= rings.size():
			return
		var lp: Variant = AirRaces.ring_local(rings[ri], WorldLayout.region)
		if lp == null:
			return
		for f in 3:
			a.global_position = lp
			a.airborne = true
			await get_tree().physics_frame
		_ok("ring %d" % (ri + 1), int(GameState.flags.get("ar_ring", 0)) == ri + 1)


func _touch_down(a: Aircraft) -> void:
	for f in 4:
		a.global_position = Vector3(WorldLayout.RUNWAY_X, 0.6, (WorldLayout.RUNWAY_Z0 + WorldLayout.RUNWAY_Z1) * 0.5)
		a.airborne = false
		a.speed = 0.0
		await get_tree().physics_frame
	await _frames(5)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
