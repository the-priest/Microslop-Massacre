extends Node
## The heat (and where stolen cars go): crimes raise stars, waves of officers scale with them, cruisers
## chase you and pull up to let officers out, four stars puts roadblocks
## ahead of your car, five brings the FBI, and staying out of sight (faster
## indoors) loses them.

var game
var fails := 0


func _ready() -> void:
	var scene: PackedScene = load("res://game/Game.tscn")
	game = scene.instantiate()
	game.test_mode = true
	game.test_picker = func(c): return 0
	add_child(game)
	await _until(func() -> bool: return game.player != null and not game.busy_transition and not game.dialog.is_open() and GameState.quests.has("mq_hello"), 6000)
	GameState.game_minutes = GameState.day() * 1440.0 + 13 * 60.0
	await game.enter_cell("world", Vector3(-466, 0.2, 316), PI, false, true)
	await _frames(20)
	set_process(true)

	# One crime: one star. Another while wanted: two.
	GameState.set_wanted(60.0)
	_ok("one star", GameState.heat == 1 and GameState.is_wanted())
	GameState.set_wanted(60.0)
	_ok("two stars", GameState.heat == 2)
	game._cop_t = 0.0
	game._heat_tick()
	await _frames(5)
	_ok("officers respond (%d)" % _police(), _police() >= 1 and _police() <= 3)

	# In a car with two stars: a cruiser comes after you.
	var v := Vehicle.new().setup("sedan", 1, Vector3(-466, 0.3, 312), PI * 0.5, game)
	v.locked = false
	game.vehicles_root.add_child(v)
	await _frames(3)
	game.enter_vehicle(v)
	await _frames(3)
	seed(20261003) # same spawn every run: this checks the driving, not the dice
	game._update_pursuit()
	_ok("a cruiser joins the pursuit", game.pursuit.size() == 1)
	if not game.pursuit.is_empty():
		var c: Vehicle = game.pursuit[0]
		var d0: float = c.global_position.distance_to(v.global_position)
		var d1 := d0
		for i in 720:
			await get_tree().physics_frame
			if is_instance_valid(c):
				d1 = minf(d1, c.global_position.distance_to(v.global_position))
		print("  cruiser %.0f m -> closest %.0f m" % [d0, d1])
		_ok("the cruiser closes in along the streets", d1 < d0 - 25.0)
		_ok("it's chasing your car", c.ai_target == v)

	# Four stars, driving: roadblock ahead.
	GameState.add_heat(2)
	_ok("four stars", GameState.heat == 4)
	var blocked := false
	for spot in [[Vector3(-466, 0.3, 316), PI * 0.5], [Vector3(-466, 0.3, 316), -PI * 0.5], [Vector3(-400, 0.3, 322), PI * 0.5], [Vector3(-339, 0.3, 300), PI]]:
		v.global_position = spot[0]
		v.rotation.y = spot[1]
		v.speed = 20.0
		await _frames(2)
		game._spawn_roadblock()
		await _frames(2)
		if _count_meta("roadblock") > 0:
			blocked = true
			break
	_ok("roadblock across the road (%d cruisers)" % _count_meta("roadblock"), blocked)
	v.speed = 0.0

	# Five stars: the Bureau.
	GameState.add_heat(1)
	for i in 8:
		game._spawn_officer(game.player.global_position + Vector3(20, 0.05, 0))
	var fbi := 0
	for n in get_tree().get_nodes_in_group("npc"):
		if (n as NPC) != null and str((n as NPC).id).begins_with("fbi_resp_"):
			fbi += 1
	_ok("five stars brings the FBI (%d agents)" % fbi, GameState.heat == 5 and fbi > 0)

	# Lose them: nobody watching, long enough.
	_clear_police()
	game.exit_vehicle(true)
	await _frames(5)
	game.player.global_position = Vector3(-466, 0.2, 316)
	var need: float = game.heat_lose_time()
	game.unseen_t = 0.0
	game._cop_t = 9999.0 # dispatch already sent everyone; hide from what's out there
	game._pursuit_t = 9999.0
	var ticks := 0
	while GameState.is_wanted() and ticks < 200:
		game._heat_tick()
		ticks += 1
	print("  lost five stars in %d unseen seconds (needs %.0f)" % [ticks, need])
	_ok("out of sight long enough: lost them", not GameState.is_wanted() and GameState.heat == 0 and ticks >= int(need) - 1)

	# Indoors it cools twice as fast.
	GameState.set_wanted(120.0)
	_ok("two stars again", GameState.heat == 2)
	_clear_police()
	await _frames(3)
	await game.enter_cell("bodega", Vector3(3, 0, 6), 0.0, false, false)
	await _frames(10)
	game.unseen_t = 0.0
	game._cop_t = 9999.0
	game._pursuit_t = 9999.0
	ticks = 0
	while GameState.is_wanted() and ticks < 200:
		game._heat_tick()
		ticks += 1
	_ok("indoors loses them faster (%d s vs %.0f)" % [ticks, game.heat_lose_time() if GameState.heat > 0 else 26.0], ticks <= 14)

	# Rafi's chop shop: a stolen car in the bay sells; your own car doesn't.
	GameState.clear_wanted()
	await game.enter_cell("world", game.CHOP_POS + Vector3(0, 0.2, 12), PI, false, true)
	await _frames(20)
	game.test_picker = func(chs: Array) -> int:
		for i in chs.size():
			if str((chs[i] as Dictionary)["text"]).contains("Sell"):
				return i
		return 0
	game.dialog.auto_advance = true
	var car := Vehicle.new().setup("suv", 2, game.CHOP_POS + Vector3(0, 0.3, 0), 0.0, game)
	car.locked = false
	game.vehicles_root.add_child(car)
	await _frames(3)
	game.enter_vehicle(car)
	await _frames(3)
	var cash0: int = GameState.cash
	var price: int = game.chop_price(car)
	await game._chop_offer(car)
	await _frames(5)
	print("  rafi paid $%d (offer $%d, wanted model today: %s)" % [GameState.cash - cash0, price, game.chop_wanted_model()])
	_ok("sold the car to Rafi", GameState.cash - cash0 == price and price > 0 and not is_instance_valid(car))
	var mine := Vehicle.new().setup("sedan", 1, game.CHOP_POS + Vector3(0, 0.3, 0), 0.0, game)
	mine.locked = false
	mine.set_meta("owned", true)
	game.vehicles_root.add_child(mine)
	await _frames(3)
	game.enter_vehicle(mine)
	await _frames(3)
	cash0 = GameState.cash
	await game._chop_offer(mine)
	await _frames(5)
	_ok("Rafi won't buy your own car", GameState.cash == cash0 and is_instance_valid(mine))

	# Street race: Dez's Hunts Point loop. Win by hitting every corner twice.
	game.exit_vehicle(true)
	await _frames(3)
	GameState.cash = 1000
	game.races.start("hunts")
	await _frames(5)
	_ok("race started in Dez's loaner", game.races.is_racing() and game.player.driving == game.races.car and GameState.cash == 800)
	for i in 900:
		if game.races.countdown <= 0.0 and game.races.is_racing():
			break
		await get_tree().physics_frame
	var pts: Array = game.races.def["points"]
	for l in 2:
		for pt in pts:
			game.races.car.global_position = Vector3(float(pt[0]), 0.4, float(pt[1]))
			for f in 3:
				await get_tree().physics_frame
	await _frames(5)
	_ok("won the race: $400 back", not game.races.is_racing() and GameState.cash == 1200 and GameState.has_flag("race_won_hunts"))
	# And lose one: the rival gets round first.
	game.races.start("hunts")
	await _frames(5)
	for i in 900:
		if game.races.countdown <= 0.0 and game.races.is_racing():
			break
		await get_tree().physics_frame
	var r: Vehicle = game.races.rival
	for l in 2:
		for pt in pts:
			if game.races.is_racing() and is_instance_valid(r):
				r.global_position = Vector3(float(pt[0]), 0.4, float(pt[1]))
				for f in 3:
					await get_tree().physics_frame
	await _frames(5)
	_ok("lost a race: the bet's gone", not game.races.is_racing() and GameState.cash == 1000)

	print("HEAT TEST DONE fails=%d" % fails)
	get_tree().quit()


func _process(_d: float) -> void:
	if game != null:
		GameState.hp = 5000.0


func _police() -> int:
	var n := 0
	for o in get_tree().get_nodes_in_group("npc"):
		var p := o as NPC
		if p != null and not p.dead and (p.faction in ["nypd", "fbi"]):
			n += 1
	return n


func _count_meta(m: String) -> int:
	var n := 0
	for c in game.vehicles_root.get_children():
		if c.has_meta(m):
			n += 1
	return n


func _clear_police() -> void:
	for o in get_tree().get_nodes_in_group("npc"):
		var p := o as NPC
		if p != null and (p.faction in ["nypd", "fbi"]):
			p.queue_free()
	for c in game.vehicles_root.get_children():
		if c.has_meta("pursuit") or c.has_meta("roadblock"):
			c.queue_free()
	game.pursuit = []


func _ok(what: String, c: bool) -> void:
	print(("  ok   " if c else "  FAIL ") + what)
	if not c:
		fails += 1


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _until(f: Callable, limit: int) -> void:
	var i := 0
	while not f.call() and i < limit:
		await get_tree().process_frame
		i += 1
