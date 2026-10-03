extends "res://test/towns_walk.gd"
## Repeatable activities: a taxi fare picked up and dropped off (and one
## abandoned), a paramedic call delivered to Mercy General, a vigilante
## takedown (and a suspect who gets away), a respray, hidden masks, the Bronx and Long Island City side
## stories (Rent Is Due, The Cloud), the news radio, then a street race won
## on every map that has one.


func _ready() -> void:
	GameState.region = "nyc"
	await _load_game()
	GameState.cash = 1000
	GameState.raise_skill("hacking", 50)
	_day()
	await _taxi()
	await _paramedic()
	await _vigilante()
	await _respray()
	await _masks()
	await _rent_is_due()
	await _cloud()
	await _radio()
	for id in ["lakeshore", "interstate", "mainstreet", "quay", "broadway", "campus"]:
		await _race(id)
		await _masks()
		await _clinic()
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


func _paramedic() -> void:
	print("PHASE paramedic")
	await _enter_world_at(Vector3(-300, 0, 300))
	var amb := Vehicle.new().setup("ambulance", 0, Vector3(-260.0, 0.4, 300.0), 0.0, game)
	amb.locked = false
	game.vehicles_root.add_child(amb)
	await _settle()
	game.enter_vehicle(amb)
	for i in 40:
		await get_tree().create_timer(0.2).timeout
		if game.emergency.state == "pickup":
			break
	_ok("dispatch sends the ambulance to someone", game.emergency.mode == "medic" and game.emergency.state == "pickup")
	_ok("the hud says paramedic", game.emergency.status().begins_with("PARAMEDIC"))
	_ok("the patient has a marker", game.emergency.marker_positions().size() == 1)
	amb.global_position = game.emergency.call_pos + Vector3(2.0, 0.4, 0)
	amb.speed = 0.0
	for i in 20:
		await get_tree().create_timer(0.1).timeout
		if game.emergency.state == "ride":
			break
	_ok("the patient's loaded", game.emergency.state == "ride")
	var cash0 := GameState.cash
	var h: Array = Emergency.HOSPITALS["nyc"]
	amb.global_position = Vector3(float(h[1]), 0.4, float(h[2]) + 3.0)
	amb.speed = 0.0
	for i in 20:
		await get_tree().create_timer(0.1).timeout
		if game.emergency.state == "":
			break
	_ok("delivered to mercy general and paid", GameState.cash > cash0 and game.emergency.level == 1 and int(GameState.flags.get("medic_calls", 0)) == 1)
	game.exit_vehicle(true)
	for i in 5:
		await get_tree().create_timer(0.2).timeout
	_ok("getting out ends the shift", game.emergency.mode == "" and game.emergency.level == 0)


func _vigilante() -> void:
	print("PHASE vigilante")
	GameState.clear_wanted()
	await _enter_world_at(Vector3(-300, 0, 300))
	var cop := Vehicle.new().setup("police", 0, Vector3(-260.0, 0.4, 300.0), 0.0, game)
	cop.locked = false
	game.vehicles_root.add_child(cop)
	await _settle()
	game.enter_vehicle(cop)
	await _settle()
	GameState.clear_wanted()
	for i in 40:
		await get_tree().create_timer(0.2).timeout
		if game.emergency.state == "chase":
			break
	_ok("dispatch calls in a suspect", game.emergency.mode == "cop" and game.emergency.state == "chase" and is_instance_valid(game.emergency.suspect))
	_ok("the suspect is running", game.emergency.suspect != null and game.emergency.suspect.ai_target != null)
	var cash0 := GameState.cash
	if game.emergency.suspect != null:
		game.emergency.suspect.damage(70.0)
	for i in 20:
		await get_tree().create_timer(0.1).timeout
		if game.emergency.state == "":
			break
	_ok("suspect down, paid", GameState.cash > cash0 and game.emergency.level == 1 and int(GameState.flags.get("suspects_down", 0)) == 1)
	for i in 40:
		await get_tree().create_timer(0.2).timeout
		if game.emergency.state == "chase":
			break
	_ok("another call", game.emergency.state == "chase")
	if is_instance_valid(game.emergency.suspect):
		game.emergency.suspect.global_position = cop.global_position + Vector3(0, 0, 700.0)
	for i in 20:
		await get_tree().create_timer(0.1).timeout
		if game.emergency.state == "":
			break
	_ok("a suspect who gets far enough away is gone", game.emergency.state == "" and game.emergency.level == 0)
	game.exit_vehicle(true)
	await _settle()


func _respray() -> void:
	print("PHASE respray")
	var shop: Dictionary = RegionContent.BODY_SHOPS["nyc"][1]
	var bp: Array = shop["pos"]
	await _enter_world_at(Vector3(float(bp[0]) + 30.0, 0, float(bp[1])))
	var car := Vehicle.new().setup("sedan", 2, Vector3(float(bp[0]) + 20.0, 0.4, float(bp[1])), PI * 0.5, game)
	car.locked = false
	game.vehicles_root.add_child(car)
	await _settle()
	game.enter_vehicle(car)
	await _settle()
	GameState.set_wanted(240.0)
	GameState.heat = 2
	GameState.cash = 1000
	car.hp = 55.0
	car.global_position = Vector3(float(bp[0]), 0.4, float(bp[1]))
	car.speed = 0.0
	prefs = ["Do it"]
	game._spray_asked = false
	await game._spray_offer(car, shop)
	await _settle()
	_ok("resprayed: the heat is off", not GameState.is_wanted() and GameState.heat == 0)
	_ok("paid for the respray", GameState.cash == 1000 - (100 + 50 * 2))
	_ok("car fixed too", car.hp >= 99.0)
	car.hp = 40.0
	prefs = ["Fix it"]
	await game._spray_offer(car, shop)
	await _settle()
	_ok("repaired for $60", car.hp >= 99.0 and GameState.cash == 1000 - 200 - 60)
	game.exit_vehicle(true)
	await _settle()


func _masks() -> void:
	var spots: Array = game.hidden_mask_spots(WorldLayout.region)
	_ok("%d hidden masks on %s" % [spots.size(), WorldLayout.region], spots.size() == int(game.MASKS_PER[WorldLayout.region]))
	if spots.is_empty():
		return
	var md: Dictionary = spots[0]
	await _enter_world_at((md["pos"] as Vector3) + Vector3(0, 0, -3.0))
	var have := GameState.count("hidden_mask")
	await _pickup(str(md["id"]))
	_ok("picked up mask " + str(md["id"]), GameState.count("hidden_mask") == have + 1)


func _rent_is_due() -> void:
	print("PHASE rent is due")
	_day()
	await _enter_world_at(Vector3(50, 0, -1360))
	_expect("sq_rent", 10)
	GameState.tracked_quest = "sq_rent"
	await _follow("sq_rent") # -> Ms. Alvarez on the sidewalk
	await _talk("alvarez", ["What's RentTrack", "Where's Carbone's office"])
	_expect("sq_rent", 20)
	await _follow("sq_rent") # -> Carbone Realty's back office
	await _talk("carbone", ["freezing", "Never mind"])
	await _term("renttrack", ["Amenity fees", "Maintenance tickets", "Churn risk"], ["Turn the heat"])
	_ok("heat back on", GameState.has_flag("rent_heat"))
	_expect("sq_rent", 30)
	await _follow("sq_rent") # -> Ms. Alvarez
	await _talk("alvarez", [])
	_ok("rent is due done", GameState.quest_state("sq_rent") == "done")


func _cloud() -> void:
	print("PHASE the cloud")
	GameState.set_flag("joined_fsociety")
	GameState.complete_quest("mq_steel")
	GameState.game_minutes = maxf(3.0, float(GameState.day())) * 1440.0 + 13 * 60.0
	GameState.cash = 1000
	await _enter_world_at(Vector3(1000, 0, 60))
	_expect("sq_cloud", 10)
	GameState.tracked_quest = "sq_cloud"
	await _follow("sq_cloud") # -> Raj at the Court Square Tavern
	await _talk("raj", ["data center", "Three hundred"])
	_expect("sq_cloud", 20)
	_ok("bought raj's badge", GameState.has_item("dc_badge") and GameState.cash == 700)
	_ok("no badge, no cameras: the cloud is off limits", game.cell_restricted("dc_floor", "ecorp"))
	await _follow("sq_cloud") # -> the junction box on the avenue
	_night()
	await _wait_rules()
	await _term("ws_dc_junction", ["Camera map"], ["Loop every camera"])
	_ok("cameras looped", GameState.has_flag("dc_cams"))
	_ok("badge plus looped cameras gets you in", not game.cell_restricted("dc_floor", "ecorp"))
	_expect("sq_cloud", 30)
	await _follow("sq_cloud") # -> the server hall
	await _term("cloud_console", ["Retention policy", "ALDERSON"], ["Tell everyone"])
	_ok("told everyone", GameState.has_flag("cloud_told"))
	_expect("sq_cloud", 40)
	_day()
	await _follow("sq_cloud") # -> Trenton at the arcade
	await _talk("trenton_n", [])
	_ok("the cloud done", GameState.quest_state("sq_cloud") == "done")
	var titles: Array = []
	for sl in EndingData.slides("quiet"):
		titles.append(str((sl as Dictionary)["title"]))
	_ok("the epilogue remembers the cloud", titles.any(func(t: Variant) -> bool: return str(t).contains("CLOUD")))


func _radio() -> void:
	print("PHASE radio")
	AudioManager.radio_play("news")
	await _settle()
	game._radio_t = 1.0
	game._radio_tick()
	_ok("the news reports Rent Is Due", GameState.flags.keys().any(func(k: Variant) -> bool: return str(k).begins_with("news:")))
	game._radio_t = 1.0
	game._radio_tick()
	AudioManager.radio_stop()


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


## The town's clinic: in, patched up at triage, and out the one door that
## leads back onto this map's street.
func _clinic() -> void:
	var did := ""
	for k in WorldLayout.DOORS.keys():
		if str(k).ends_with("_clinic"):
			did = str(k)
	if did == "":
		return
	var amb := 0
	for v in game.vehicles_root.get_children():
		if v is Vehicle and (v as Vehicle).kind == "ambulance" and v.has_meta("service"):
			amb += 1
	_ok("an ambulance parked outside on " + WorldLayout.region, amb >= 1)
	await _enter_door(did)
	_ok("in the ER on " + WorldLayout.region, GameState.cell == "clinic_er")
	GameState.hp = 20.0
	GameState.cash = maxi(GameState.cash, 100)
	var cash0 := GameState.cash
	await _spot("er_triage", [])
	_ok("patched up for $40", GameState.hp >= float(GameState.max_hp()) - 0.5 and GameState.cash == cash0 - 40)
	var outs: Array = []
	var stack: Array = [game]
	while not stack.is_empty():
		var nd: Node = stack.pop_back()
		if nd is Interactable and (nd as Interactable).kind == "exit" and (nd as Node3D).is_visible_in_tree() and not (nd as Interactable).interact_info().is_empty():
			outs.append(nd)
		for c in nd.get_children():
			stack.append(c)
	_ok("one way out of the ER on " + WorldLayout.region, outs.size() == 1)
	if outs.size() == 1:
		await game.interact(outs[0])
		await _settle()
	var dw := WorldLayout.door_world(did)
	_ok("back on the street outside " + did, GameState.cell == "world" and game.player.global_position.distance_to(dw["pos"] as Vector3) < 12.0)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
