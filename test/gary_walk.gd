extends "res://test/towns_walk.gd"
## Gary, Indiana, played like story_walk: Ghost Fleet (Marcus, the FreightOS
## control tower), The Banner (the Gary Works office), Who's Driving? (the
## banner tow flown through its rings and landed), The Training Set (the
## SlopForge cluster, then Kenny in New York), and the roads: I-90 east into
## Chicago, State Road 912 south into the township, and a flight across the
## Gary/township airspace border.


func _ready() -> void:
	GameState.region = "gary"
	await _load_game()
	GameState.cash = 2000
	GameState.raise_skill("hacking", 70)
	GameState.raise_skill("speech", 50)
	GameState.raise_skill("lockpick", 60)
	_day()
	await _ghost_fleet()
	await _the_banner()
	await _whos_driving()
	await _training_set()
	await _roads_out()
	var titles: Array = []
	for s in EndingData.slides("quiet"):
		titles.append(str((s as Dictionary)["title"]))
	for want in ["GARY", "THE BANNER", "WHO'S DRIVING?", "SLOPFORGE"]:
		_ok("epilogue has " + want, titles.has(want))
	print("GARY WALK DONE fails=%d" % fails)
	get_tree().quit()


func _ghost_fleet() -> void:
	print("PHASE ghost fleet")
	_ok("in gary", WorldLayout.region == "gary")
	await _enter_world_at(Vector3(730, 0, 0))
	_expect("sq_gy1", 10)
	GameState.tracked_quest = "sq_gy1"
	await _follow("sq_gy1") # -> Marcus at the union hall
	await _talk("marcus", ["What's Local 1014", "Show me"])
	_expect("sq_gy1", 20)
	await _follow("sq_gy1") # -> the control tower
	_expect("sq_gy1", 30)
	await _spot("gy_ops_board", [])
	await _talk("toby", ["blinks"])
	await _term("fleet_term", ["Operator telemetry", "Pay sheet", "Investor deck"], ["Pause the whole fleet"])
	_ok("the fleet stopped", GameState.has_flag("gy_strike"))
	_expect("sq_gy1", 40)
	await _follow("sq_gy1") # -> Marcus
	await _talk("marcus", [])
	_ok("ghost fleet done", GameState.quest_state("sq_gy1") == "done")
	_expect("sq_gy2", 10)
	_expect("sq_gy4", 10)


func _the_banner() -> void:
	print("PHASE the banner")
	GameState.tracked_quest = "sq_gy2"
	await _follow("sq_gy2") # -> the mill office
	_expect("sq_gy2", 20)
	await _spot("gy_millofc_clock", [])
	await _container("gy_banner_case")
	_ok("have the banner", GameState.has_item("union_banner"))
	_expect("sq_gy2", 30)
	await _follow("sq_gy2") # -> Marcus
	await _talk("marcus", [])
	_ok("the banner done", GameState.quest_state("sq_gy2") == "done")


func _whos_driving() -> void:
	print("PHASE who's driving")
	GameState.tracked_quest = "sq_gy4"
	await _follow("sq_gy4") # -> Lena at the airport
	await _talk("lena", ["Marcus at the union hall"])
	_expect("sq_gy4", 20)
	await _enter_world_at(Vector3(606, 0, -300))
	var a := await _board_plane(Vector3(590, 0.5, -200))
	a.airborne = true
	for p in (game.COURSES["banner"] as Dictionary)["rings"]:
		a.global_position = p
		await get_tree().physics_frame
		game._plane_rings_tick()
	_ok("flew the banner route", GameState.has_flag("banner_rings_done"))
	await _wait_rules()
	_expect("sq_gy4", 30)
	await _land(a)
	await _wait_rules()
	_expect("sq_gy4", 40)
	game.exit_vehicle(true)
	await _settle()
	await _follow("sq_gy4") # -> Lena
	await _talk("lena", [])
	_ok("who's driving done", GameState.quest_state("sq_gy4") == "done")


func _training_set() -> void:
	print("PHASE the training set")
	GameState.complete_quest("mq_ms")
	GameState.set_flag("ms_done")
	await _enter_world_at(Vector3(-300, 0, 100))
	await _wait_rules()
	_expect("sq_gy3", 10)
	GameState.tracked_quest = "sq_gy3"
	await _follow("sq_gy3") # -> the SlopForge cluster
	_expect("sq_gy3", 20)
	await _term("slop_console", ["Training set manifest", "Output samples"], ["Give every closed studio"])
	_ok("studios got their work back", GameState.has_flag("slop_returned"))
	_expect("sq_gy3", 30)


func _roads_out() -> void:
	print("PHASE roads out")
	# I-90 east to Chicago and back.
	await _enter_world_at(Vector3(730, 0, 0))
	var v := Vehicle.new().setup("sedan", 1, Vector3(735, 0.4, 0), PI * 0.5, game)
	v.locked = false
	game.vehicles_root.add_child(v)
	await _settle()
	game.enter_vehicle(v)
	await _settle()
	var ge: Array = Regions.GATES["gary"]["gy_east"]["pos"]
	await _drive_gate("chicago", Vector3(float(ge[0]), 0.4, float(ge[1])))
	_ok("drove into chicago", WorldLayout.region == "chicago")
	var cw: Array = Regions.GATES["chicago"]["chi_west"]["pos"]
	await _drive_gate("gary", Vector3(float(cw[0]), 0.4, float(cw[1])))
	_ok("drove back to gary", WorldLayout.region == "gary")
	# State Road 912 south to the township.
	var gs: Array = Regions.GATES["gary"]["gy_south"]["pos"]
	await _drive_gate("township", Vector3(float(gs[0]), 0.4, float(gs[1])))
	_ok("drove to the township", WorldLayout.region == "township")
	# Fly from the township north across the border into Gary.
	await _board_plane(Vector3(-520, 0.5, 60))
	var a: Aircraft = game.player.driving
	var sky: Rect2 = Regions.SKY["township"]
	game.region_requested = ""
	a.global_position = Vector3(-200.0, 150.0, sky.position.y - 6.0)
	a.heading = 0.0
	a.airborne = true
	a.speed = 50.0
	for i in 3:
		await get_tree().physics_frame
	if game.region_requested == "":
		game.airspace_exit(a)
	_ok("township airspace hands over to gary", game.region_requested == "gary")
	if game.region_requested == "gary":
		await _reload()
		_ok("flying over gary", WorldLayout.region == "gary" and game.player.driving is Aircraft)
	# Home to Kenny.
	await _travel("chicago", "chi_west")
	await _travel("highway", "hw_west")
	await _travel("nyc", "nyc_west")
	await _follow("sq_gy3") # -> Kenny at The Rabbit Hole
	await _talk("kenny", [])
	_ok("the training set done", GameState.quest_state("sq_gy3") == "done")
