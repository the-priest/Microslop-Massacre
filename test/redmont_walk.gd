extends "res://test/towns_walk.gd"
## Redmont, played like story_walk: up Route 9 from Port Ramsey, Company
## Scrip (Dana and the payroll terminal), Dry County (Marta and the East-1
## pump house), Copilot for Mayor (Edie and the council's clerk), Day One
## Patch (Priya's build server, Ines's plane, a flight across three borders
## to Bowery Bay and Gus), Total Recall (Hector, HQ after dark, the archive),
## and the epilogue slides they earn.


func _ready() -> void:
	GameState.region = "port"
	await _load_game()
	GameState.cash = 3000
	GameState.raise_skill("hacking", 70)
	GameState.raise_skill("speech", 60)
	GameState.raise_skill("lockpick", 60)
	_day()
	await _route_9()
	await _company_scrip()
	await _dry_county()
	await _copilot()
	await _day_one_patch()
	await _total_recall()
	var titles: Array = []
	for sl in EndingData.slides("quiet"):
		titles.append(str((sl as Dictionary)["title"]))
	for want in ["REDMONT", "THE RESERVOIR", "COPILOT FOR MAYOR", "DAY ONE PATCH", "TOTAL RECALL"]:
		_ok("epilogue has " + want, titles.has(want))
	print("REDMONT WALK DONE fails=%d" % fails)
	get_tree().quit()


func _route_9() -> void:
	print("PHASE route 9")
	_ok("in port ramsey", WorldLayout.region == "port")
	await _enter_world_at(Vector3(20, 0, -560))
	var v := Vehicle.new().setup("sedan", 1, Vector3(4, 0.4, -560), 0.0, game)
	v.locked = false
	game.vehicles_root.add_child(v)
	await _settle()
	game.enter_vehicle(v)
	await _settle()
	var g: Array = Regions.GATES["port"]["pt_north"]["pos"]
	await _drive_gate("redmont", Vector3(float(g[0]), 0.4, float(g[1])))
	_ok("drove up route 9 into redmont", WorldLayout.region == "redmont")
	game.exit_vehicle(true)
	await _settle()
	await _wait_rules()
	_expect("sq_rm1", 10)
	_expect("sq_rm2", 10)
	# And back down to the port, and up again.
	var g2: Array = Regions.GATES["redmont"]["rm_south"]["pos"]
	game.enter_vehicle(game.player_car if game.player_car != null else v)
	await _settle()
	if game.player.driving != null:
		await _drive_gate("port", Vector3(float(g2[0]), 0.4, float(g2[1])))
		_ok("drove back down to the port", WorldLayout.region == "port")
		await _drive_gate("redmont", Vector3(float(g[0]), 0.4, float(g[1])))
		_ok("and up again", WorldLayout.region == "redmont")
		game.exit_vehicle(true)
		await _settle()


func _company_scrip() -> void:
	print("PHASE company scrip")
	GameState.tracked_quest = "sq_rm1"
	await _follow("sq_rm1") # -> Dana at SlopMart
	await _talk("dana", ["Store credit", "Somebody at this store"])
	_expect("sq_rm1", 20)
	_ok("dana gave up the password", GameState.has_flag("rm_payroll_pw"))
	await _follow("sq_rm1") # -> the payroll office
	await _term("payroll_term", ["Scrip ledger", "Conversion fee", "retention pool"], ["Convert every balance"])
	_ok("credits are dollars", GameState.has_flag("scrip_cashed"))
	_expect("sq_rm1", 30)
	await _talk("dana", [])
	_ok("company scrip done", GameState.quest_state("sq_rm1") == "done")


func _dry_county() -> void:
	print("PHASE dry county")
	_day()
	GameState.tracked_quest = "sq_rm2"
	await _follow("sq_rm2") # -> Marta at the boat launch
	await _talk("marta", ["Where's it going", "Can you prove it"])
	_expect("sq_rm2", 20)
	await _follow("sq_rm2") # -> the pump house
	_expect("sq_rm2", 30)
	await _spot("rm_pumps", [])
	await _term("pump_term", ["Intake log", "County permit", "drought messaging"], ["Throttle the intake"])
	_ok("the pumps are throttled", GameState.has_flag("rm_throttled") and GameState.has_flag("rm_logs"))
	_expect("sq_rm2", 40)
	await _follow("sq_rm2") # -> Marta
	await _talk("marta", [])
	_ok("dry county done", GameState.quest_state("sq_rm2") == "done")


func _copilot() -> void:
	print("PHASE copilot for mayor")
	await _enter_world_at(Vector3(-212, 0, -12))
	await _enter_door("d_rm_hall")
	await _wait_rules()
	_expect("sq_rm3", 10)
	GameState.tracked_quest = "sq_rm3"
	await _spot("rm_mayors", [])
	await _talk("edie", ["What happened to the mayors", "These things run on a system prompt"])
	_expect("sq_rm3", 20)
	await _follow("sq_rm3") # -> the clerk's desk
	await _term("copilot_term", ["System prompt", "Vote history", "Telemetry"], ["Print the system prompt"])
	_ok("the prompt is on the water bills", GameState.has_flag("copilot_public"))
	_expect("sq_rm3", 30)
	await _talk("edie", [])
	_ok("copilot for mayor done", GameState.quest_state("sq_rm3") == "done")


func _day_one_patch() -> void:
	print("PHASE day one patch")
	await _enter_world_at(Vector3(340, 0, -236))
	await _wait_rules()
	_expect("sq_rm4", 10)
	GameState.tracked_quest = "sq_rm4"
	await _follow("sq_rm4") # -> Priya at Studio Redmont
	await _talk("priya", ["Closed the day after", "Then I'll get it"])
	_expect("sq_rm4", 20)
	await _follow("sq_rm4") # -> the server closet
	await _spot("rm_countdown", [])
	await _term("build_term", ["patch notes", "Wipe order"], ["Copy the patch"])
	_ok("have the drive", GameState.has_item("patch_drive"))
	_expect("sq_rm4", 30)
	# Ines lends a plane.
	await _enter_door("d_rm_hangar")
	await _talk("ines", ["Priya from Studio Redmont"])
	_ok("ines said yes", GameState.has_flag("rm_plane_ok"))
	await _enter_world_at(Vector3(590, 0, 300))
	var a: Aircraft = null
	for k in game.planes.keys():
		if str(k).begins_with("redmont_") and is_instance_valid(game.planes[k]):
			a = game.planes[k]
			break
	_ok("ines's plane is on the apron", a != null)
	if a == null:
		return
	for i in 20:
		await get_tree().physics_frame
		if not a.locked:
			break
	_ok("and it's unlocked for you", not a.locked)
	game.player.global_position = a.global_position + Vector3(3, 0, 0)
	game.enter_vehicle(a)
	await _settle()
	_ok("in ines's plane", game.player.driving == a)
	await _fly_border("port")
	await _fly_border("highway")
	await _fly_border("nyc")
	var p: Aircraft = game.player.driving
	_ok("flying into new york", p != null and WorldLayout.region == "nyc")
	if p == null:
		return
	await _land(p)
	await _wait_rules()
	_ok("landed at bowery bay", GameState.has_flag("patch_landed"))
	_expect("sq_rm4", 40)
	game.exit_vehicle(true)
	await _settle()
	await _follow("sq_rm4") # -> Gus
	await _talk("gus", [])
	_ok("the patch is out", GameState.has_flag("patch_released") and not GameState.has_item("patch_drive"))
	_ok("day one patch done", GameState.quest_state("sq_rm4") == "done")


func _total_recall() -> void:
	print("PHASE total recall")
	await _travel("redmont", "rm_south")
	await _wait_rules()
	_expect("sq_rm5", 10)
	GameState.tracked_quest = "sq_rm5"
	_night()
	await _follow("sq_rm5") # -> Hector at the Copilot Diner
	await _spot("rm_menu", [])
	await _talk("hector", ["I'll have the soup", "waiting eleven years"])
	_ok("hector's keycard", GameState.has_item("rm_keycard"))
	_expect("sq_rm5", 20)
	await _follow("sq_rm5") # -> Microslop HQ
	_ok("allowed in with the card, after dark", not game.cell_restricted("rm_hq", "microslop"))
	_expect("sq_rm5", 30)
	await _exit_to("interior:rm_hq:2") # the service elevator
	await _spot("rm_hq_wall", [])
	await _term("recall_term", ["Archive size", "Access log"], ["Delete the archive"])
	await _wait_rules()
	_ok("recall is gone", GameState.has_flag("recall_deleted"))
	_ok("total recall done", GameState.quest_state("sq_rm5") == "done")
	await _exit_to("interior:rm_hq:1")
	await _exit_to("world:d_rm_hq")
	_ok("back out on the campus", GameState.cell == "world")
