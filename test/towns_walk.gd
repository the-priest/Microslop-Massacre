extends "res://test/story_walk.gd"
## The towns off I-80, played like story_walk: Going Home, Night Shift, Paper
## Rain (flown through its rings and landed), Pre-Existing Condition, Small
## Town Cop, Air Mail (flown town to town across two airspace borders and
## landed), No Fishing, The Light, the whole Project arc (the night freight
## truck driven from the port to the plant), and The Box in the Closet
## carried home to Angela in New York. Only the starting point is scripted.


func _ready() -> void:
	GameState.region = "township"
	await _load_game()
	GameState.cash = 2000
	GameState.raise_skill("hacking", 70)
	GameState.raise_skill("speech", 50)
	GameState.raise_skill("lockpick", 50)
	GameState.game_minutes = GameState.day() * 1440.0 + 13 * 60.0
	await _going_home()
	await _night_shift()
	await _paper_rain()
	await _bev()
	await _sheriff()
	await _moss_house()
	await _air_mail()
	await _no_fishing()
	await _the_light()
	await _air_freight_job()
	await _project()
	await _home_to_angela()
	var titles: Array = []
	for s in EndingData.slides("quiet"):
		titles.append(str((s as Dictionary)["title"]))
	for want in ["PAPER RAIN", "THE SHERIFF", "THE TOWNSHIP DINER", "THE BOX", "TUESDAYS", "PORT RAMSEY", "RAMSEY POINT", "THE PROJECT"]:
		_ok("epilogue has " + want, titles.has(want))
	print("TOWNS WALK DONE fails=%d" % fails)
	get_tree().quit()


func _load_game() -> void:
	var scene: PackedScene = load("res://game/Game.tscn")
	game = scene.instantiate()
	game.test_mode = true
	game.test_picker = _pick
	add_child(game)
	await _until(func() -> bool: return game.player != null and not game.busy_transition and not game.dialog.is_open() and GameState.quests.has("mq_hello"), 6000)
	game.minigames.auto_result = 1


func _reload() -> void:
	game.queue_free()
	for i in 3:
		await get_tree().process_frame
	var scene: PackedScene = load("res://game/Game.tscn")
	game = scene.instantiate()
	game.test_mode = true
	game.test_picker = _pick
	add_child(game)
	await _until(func() -> bool: return game.player != null and not game.busy_transition, 3000)
	game.minigames.auto_result = 1
	for i in 10:
		await get_tree().process_frame


func _travel(region: String, gate: String) -> void:
	if game.player.driving != null:
		game.exit_vehicle(true)
		await _settle()
	await _enter_world_at(Vector3(0, 0, 0))
	game.go_region(region, gate, false)
	await _reload()
	await _settle()
	_ok("arrived in " + region, WorldLayout.region == region)


func _day() -> void:
	GameState.game_minutes = GameState.day() * 1440.0 + 13 * 60.0


func _night() -> void:
	GameState.game_minutes = GameState.day() * 1440.0 + 23.5 * 60.0


# ------------------------------------------------------------ the township
func _going_home() -> void:
	print("PHASE going home")
	_ok("in washington township", WorldLayout.region == "township")
	await _enter_world_at(Vector3(620, 0, 0))
	_expect("sq_tw1", 20)
	GameState.tracked_quest = "sq_tw1"
	await _follow("sq_tw1") # -> the memorial
	await _spot("ws_tw_wall", ["Find the name"])
	_expect("sq_tw1", 30)
	await _follow("sq_tw1") # -> Walt on the bench
	await _talk("walt", ["You knew my dad", "trucks come at night", "I'll go tonight"])
	_ok("going home done", GameState.quest_state("sq_tw1") == "done")
	_expect("sq_tw2", 10)
	_expect("sq_moss", 10)


func _night_shift() -> void:
	print("PHASE night shift")
	GameState.tracked_quest = "sq_tw2"
	_night()
	await _follow("sq_tw2") # -> Retention Pond 3, after dark
	await _wait_rules()
	_expect("sq_tw2", 20)
	_ok("pond sample", GameState.has_item("pond_sample"))
	_day()
	await _follow("sq_tw2") # -> the plant office
	_expect("sq_tw2", 30)
	await _term("plant_term", ["Discharge log", "Community relations", "Retiree benefits", "Freight elevator"], [])
	_ok("have the logs", GameState.has_item("discharge_logs"))
	_expect("sq_tw2", 40)
	_expect("sq_brandt", 10)
	await _follow("sq_tw2") # -> Walt at the hangar
	await _talk("walt", [])
	_ok("night shift done", GameState.quest_state("sq_tw2") == "done")
	_expect("sq_tw3", 10)


func _paper_rain() -> void:
	print("PHASE paper rain")
	GameState.tracked_quest = "sq_tw3"
	await _follow("sq_tw3") # -> Margaret Hale
	await _talk("hale", ["Walt wants the whole town"])
	_expect("sq_tw3", 20)
	_ok("walt's plane is ours to fly", GameState.has_flag("walt_plane_ok"))
	# Out to the strip, into a plane, and through the rings.
	await _enter_world_at(Vector3(-504, 0, 0))
	var a := await _board_plane(Vector3(-520, 0.5, 60))
	a.airborne = true
	var pts: Array = (game.COURSES["paper"] as Dictionary)["rings"]
	for p in pts:
		a.global_position = p
		await get_tree().physics_frame
		game._plane_rings_tick()
	_ok("flew every ring", GameState.has_flag("paper_rings_done"))
	await _wait_rules()
	_expect("sq_tw3", 30)
	await _land(a)
	await _wait_rules()
	_expect("sq_tw3", 40)
	game.exit_vehicle(true)
	await _settle()
	await _follow("sq_tw3") # -> Walt
	await _talk("walt", [])
	_ok("paper rain done", GameState.quest_state("sq_tw3") == "done" and GameState.has_flag("tw_paper_rain"))


func _bev() -> void:
	print("PHASE pre-existing condition")
	await _enter_door("d_tw_diner")
	await _talk("bev", ["hard week", "Where does the denial"])
	_expect("sq_bev", 10)
	GameState.tracked_quest = "sq_bev"
	await _follow("sq_bev") # -> the plant terminal
	await _term("plant_term", [], ["Overturn claim"])
	_ok("hank approved", GameState.has_flag("hank_approved"))
	_expect("sq_bev", 30)
	await _follow("sq_bev") # -> Bev
	await _talk("bev", [])
	_ok("bev done", GameState.quest_state("sq_bev") == "done")


func _sheriff() -> void:
	print("PHASE small town cop")
	GameState.tracked_quest = "sq_brandt"
	await _follow("sq_brandt") # -> the sheriff's office
	await _talk("brandt", ["Twenty-five hundred", "Then look now"])
	_ok("sheriff testifies", GameState.quest_state("sq_brandt") == "done" and GameState.has_flag("brandt_testifies"))


func _moss_house() -> void:
	print("PHASE the box in the closet")
	GameState.tracked_quest = "sq_moss"
	await _follow("sq_moss") # -> the Moss house
	_expect("sq_moss", 20)
	await _container("moss_closet")
	_ok("have angela's box", GameState.has_item("moss_box"))
	_expect("sq_moss", 30)


## Sit in a fresh plane at `p` (local to this map) and take the controls.
func _board_plane(p: Vector3) -> Aircraft:
	if game.player.driving != null:
		game.exit_vehicle(true)
		await _settle()
	var a := Aircraft.new().setup_plane("skyhawk", p, 0.0, game)
	a.locked = false
	a.owner_tag = "player"
	game.vehicles_root.add_child(a)
	await _settle()
	game.enter_vehicle(a)
	await _settle()
	return a


## Put the plane down on this map's runway and stop.
func _land(a: Aircraft) -> void:
	a.global_position = Vector3(WorldLayout.RUNWAY_X, 0.6, (WorldLayout.RUNWAY_Z0 + WorldLayout.RUNWAY_Z1) * 0.5)
	a.airborne = false
	a.speed = 0.0
	for i in 3:
		await get_tree().physics_frame
	game._check_wings_landing()


## Fly from this map into the next one toward `target`: put the plane just
## over the airspace border, heading that way, and let the game hand it over.
func _fly_toward(target: String) -> void:
	var a: Aircraft = game.player.driving
	var here := WorldLayout.region
	var sky: Rect2 = Regions.SKY[here]
	var tw := Regions.to_world(target, (Regions.SKY[target] as Rect2).get_center())
	var hw := Regions.to_world(here, sky.get_center())
	var east := tw.x > hw.x
	var lp := Vector3(sky.end.x + 6.0 if east else sky.position.x - 6.0, 160.0, 0.0)
	game.region_requested = ""
	a.global_position = lp
	a.heading = -PI * 0.5 if east else PI * 0.5
	a.airborne = true
	a.speed = 50.0
	# The plane notices it's left the airspace on its own next physics tick.
	for i in 3:
		await get_tree().physics_frame
	if game.region_requested == "":
		game.airspace_exit(a)
	_ok("airspace border hands over (%s -> %s)" % [here, game.region_requested], game.region_requested != "")
	if game.region_requested == "":
		return
	var want: String = game.region_requested
	await _reload()
	_ok("flew into " + want, WorldLayout.region == want)
	var nv: Vehicle = game.player.driving
	_ok("still flying in " + want, nv is Aircraft and (nv as Aircraft).airborne)


func _air_mail() -> void:
	print("PHASE air mail")
	await _enter_door("d_tw_hangar")
	await _talk("walt", ["Need anything flown"])
	_expect("sq_airmail", 10)
	_ok("have the crate", GameState.has_item("rx_crate"))
	GameState.tracked_quest = "sq_airmail"
	await _enter_world_at(Vector3(-504, 0, 0))
	await _board_plane(Vector3(-520, 0.5, 60))
	await _fly_toward("port") # township -> I-80
	_ok("over the interstate", WorldLayout.region == "highway")
	await _fly_toward("port") # I-80 -> Port Ramsey
	_ok("over port ramsey", WorldLayout.region == "port")
	await _wait_rules()
	_expect("sq_airmail", 20)
	await _land(game.player.driving)
	_ok("landed at ramsey field", GameState.has_flag("airmail_landed"))
	await _wait_rules()
	_expect("sq_airmail", 30)
	game.exit_vehicle(true)
	await _settle()
	await _follow("sq_airmail") # -> Marisol
	await _talk("marisol", [])
	_ok("air mail done", GameState.quest_state("sq_airmail") == "done")


# ------------------------------------------------------------- the port
func _no_fishing() -> void:
	print("PHASE no fishing")
	await _enter_door("d_pt_bar")
	await _talk("ruthie", ["Was?", "Where's Grieco's office"])
	_expect("sq_ruthie", 10)
	GameState.tracked_quest = "sq_ruthie"
	await _follow("sq_ruthie") # -> the harbormaster's computer
	await _term("harbor_pc", ["Fishing licenses", "consulting", "night berth"], ["Reinstate every fishing license"])
	_ok("licenses back", GameState.has_flag("licenses_back"))
	_expect("sq_ruthie", 30)
	await _follow("sq_ruthie") # -> Ruthie
	await _talk("ruthie", [])
	_ok("no fishing done", GameState.quest_state("sq_ruthie") == "done")


func _the_light() -> void:
	print("PHASE the light")
	await _enter_door("d_pt_lighthouse")
	await _spot("keeper_log", [])
	await _talk("silas", ["I thought lighthouses", "Who controls the box"])
	_expect("sq_keeper", 10)
	GameState.tracked_quest = "sq_keeper"
	await _follow("sq_keeper") # -> the lamp room
	await _term("beacon_ctl", ["Beacon schedule"], ["manual"])
	_ok("light on manual", GameState.has_flag("silas_lamp"))
	_expect("sq_keeper", 30)
	await _follow("sq_keeper") # -> Silas
	await _talk("silas", [])
	_ok("the light done", GameState.quest_state("sq_keeper") == "done" and GameState.has_item("lighthouse_log"))


func _air_freight_job() -> void:
	print("PHASE air freight")
	await _enter_world_at(Vector3(-685, 0, -300))
	var r := RandomNumberGenerator.new()
	r.seed = 7
	var off: Dictionary = game.jobs._make_offer("air", r, {})
	_ok("air freight offer", not off.is_empty() and str(off.get("region", "")) != "port")
	game.jobs.board().append(off)
	var cash0 := GameState.cash
	_ok("accept air freight", game.jobs.accept(str(off["id"])))
	_ok("carrying air cargo", GameState.has_item("air_cargo"))
	game.jobs.on_landed(str(off["region"]))
	_ok("air freight paid", GameState.cash > cash0 and not GameState.has_item("air_cargo"))
	var haul: Dictionary = game.jobs._make_offer("haul", r, {})
	_ok("long haul offer", not haul.is_empty() and str(haul.get("region", "")) != "port")


# ---------------------------------------------------------- the project
func _project() -> void:
	print("PHASE bill of lading")
	_day()
	GameState.complete_quest("mq_darkarmy")
	GameState.game_minutes += 3 * 1440.0
	await _enter_world_at(Vector3(0, 0, -60))
	await _wait_rules()
	_expect("mq_pr1", 10)
	GameState.tracked_quest = "mq_pr1"
	await _follow("mq_pr1") # -> Leon at the Barnacle
	await _talk("leon", ["What's in the boxes"])
	_expect("mq_pr1", 20)
	await _follow("mq_pr1") # -> the manifest terminal
	await _term("pt_manifest", ["Everbright", "Customs exceptions", "Night berth"], ["Copy the manifest"])
	_ok("manifest copied", GameState.has_item("bill_of_lading"))
	_expect("mq_pr1", 30)
	await _follow("mq_pr1") # -> the cannery
	_ok("in the cannery", GameState.cell == "pt_cannery")
	await _spot("cannery_rack", [])
	await _spot("cannery_board", [])
	_expect("mq_pr1", 50)
	await _follow("mq_pr1") # -> Leon
	await _talk("leon", [])
	_ok("bill of lading done", GameState.quest_state("mq_pr1") == "done")
	_expect("mq_pr2", 10)
	print("PHASE night freight")
	GameState.tracked_quest = "mq_pr2"
	_night()
	await _follow("mq_pr2") # -> the cannery yard
	for i in 8:
		await get_tree().create_timer(0.3).timeout
		if game._night_truck != null and is_instance_valid(game._night_truck):
			break
	_ok("the night freight is waiting", game._night_truck != null and is_instance_valid(game._night_truck))
	if game._night_truck == null:
		return
	game.enter_vehicle(game._night_truck)
	await get_tree().create_timer(1.3).timeout
	_expect("mq_pr2", 20)
	var pw: Array = Regions.GATES["port"]["pt_west"]["pos"]
	await _drive_gate("highway", Vector3(float(pw[0]), 0.4, float(pw[1])))
	var ht: Array = Regions.GATES["highway"]["hw_tw"]["pos"]
	await _drive_gate("township", Vector3(float(ht[0]), 0.4, float(ht[1])))
	_ok("drove the truck to the township", WorldLayout.region == "township" and game.player.driving != null and game.player.driving.kind == "truck")
	game.player.driving.global_position = Vector3(-225, 0.4, -250)
	for i in 5:
		await get_tree().physics_frame
	await _wait_rules()
	_expect("mq_pr2", 30)
	game.exit_vehicle(true)
	await _settle()
	_day()
	await _follow("mq_pr2") # -> the plant
	await _exit_to("interior:tw_b2:0")
	await _wait_rules()
	_ok("down in B2", GameState.cell == "tw_b2")
	_expect("mq_pr2", 40)
	await _spot("b2_machine", [])
	_expect("mq_pr2", 50)
	await _talk("whiterose_n", ["What is this", "brings them back"])
	_ok("night freight done", GameState.quest_state("mq_pr2") == "done")
	_expect("mq_pr3", 10)
	print("PHASE the machine")
	GameState.tracked_quest = "mq_pr3"
	await _term("b2_console", ["What the machine does", "Power budget"], ["Open the pond"])
	_ok("machine drowned", GameState.has_flag("pr_machine_drowned"))
	_expect("mq_pr3", 20)
	var dp: Vector3 = WorldLayout.door_world("d_tw_plant")["pos"]
	await _enter_world_at(dp + Vector3(0, 0, 4))
	await _wait_rules()
	_ok("the machine done", GameState.quest_state("mq_pr3") == "done")


## Drive whatever you're in through the travel gate at `at` and load the map
## on the other side, the way region_test does.
func _drive_gate(want: String, at: Vector3) -> void:
	game.player.driving.global_position = at
	for i in 5:
		await get_tree().physics_frame
	_close_modals()
	game.region_requested = ""
	for i in 4:
		game._update_gates()
	_ok("gate asks for " + want, game.region_requested == want)
	if game.region_requested != want:
		return
	await _reload()
	await _until(func() -> bool: return game.player.driving != null, 600)


func _home_to_angela() -> void:
	print("PHASE home to angela")
	GameState.tracked_quest = "sq_moss"
	_ok("marker points at the road home", game._marker_target("npc:angela_n").get("cell", "") == "world")
	await _travel("highway", "hw_tw")
	await _travel("nyc", "nyc_west")
	_day()
	await _follow("sq_moss") # -> Angela
	await _talk("angela_n", ["Your mom's name"])
	_ok("the box done", GameState.quest_state("sq_moss") == "done")
