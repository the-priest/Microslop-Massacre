extends "res://test/story_walk.gd"
## The Respawn arc, played like story_walk plays the main line: Darlene's text,
## Pixel's call, Kenny's badge, Floor 88, the drive to Chicago, the cell, both
## hacks on the Midwest data floor, the drive home, and the epilogue slides.
## Only the starting point (fsociety joined, Steel Mountain done) is scripted.


func _ready() -> void:
	var scene: PackedScene = load("res://game/Game.tscn")
	game = scene.instantiate()
	game.test_mode = true
	game.test_picker = _pick
	add_child(game)
	await _until(func() -> bool: return game.player != null and not game.busy_transition and not game.dialog.is_open() and GameState.quests.has("mq_hello"), 6000)
	game.minigames.auto_result = 1
	GameState.cash = 2000
	for q in ["mq_hello", "mq_rootkit", "mq_fsociety", "mq_steel"]:
		GameState.complete_quest(q)
	GameState.set_flag("joined_fsociety")
	GameState.raise_skill("hacking", 70)
	GameState.game_minutes = GameState.day() * 1440.0 + 13 * 60.0
	await _final_notice()
	await _respawn()
	await _chicago()
	await _home()
	print("RESPAWN WALK DONE fails=%d" % fails)
	get_tree().quit()


func _final_notice() -> void:
	print("PHASE final notice")
	await _enter_door("d_apt")
	await _talk("ortiz", ["Who's on the phone", "Play it", "Don't pay him"])
	_ok("heard the voicemail", GameState.has_flag("ortiz_voicemail"))
	_expect("sq_ortiz", 20)
	GameState.tracked_quest = "sq_ortiz"
	await _follow("sq_ortiz") # -> branch 0419
	await _talk("gary", ["Hector Ortiz", "I've got your voicemail"])
	_ok("gary backed off", GameState.has_flag("ortiz_gary_scared"))
	_expect("sq_ortiz", 30)
	await _follow("sq_ortiz") # -> home
	await _talk("ortiz", [])
	_ok("final notice done", GameState.quest_state("sq_ortiz") == "done")


func _respawn() -> void:
	print("PHASE respawn")
	await _enter_world_at(Vector3(-470, 0, 338))
	_expect("mq_respawn", 10)
	GameState.tracked_quest = "mq_respawn"
	await _follow("mq_respawn") # -> the arcade's back terminal
	await _spot("arcade_pixel", ["I'm listening", "I'm in"])
	_ok("joined respawn", GameState.has_flag("joined_respawn"))
	_expect("mq_respawn", 20)
	_expect("mq_rs1", 10)
	GameState.tracked_quest = "mq_rs1"
	await _follow("mq_rs1") # -> Kenny at The Rabbit Hole
	await _talk("kenny", ["You worked at Rockstarved", "I want to burn"])
	_ok("has badge", GameState.has_item("rs_badge"))
	_expect("mq_rs1", 20)
	await _talk("kenny", [])
	await _follow("mq_rs1") # -> WTC lobby
	_ok("in wtc lobby", GameState.cell == "wtc_lobby")
	await _exit_to("interior:rockstarved_hq:0")
	await _wait_rules()
	_ok("on floor 88", GameState.cell == "rockstarved_hq")
	_expect("mq_rs1", 30)
	await _term("rs_whale", ["Who is the player", "HIGH VALUE"], ["Crash the Shark Card", "Dump Project Whale"])
	_ok("rockstarved done", GameState.quest_state("mq_rs1") == "done" and GameState.has_flag("rs_done"))
	_ok("only one way down", GameState.has_flag("rs_refund") and not GameState.has_flag("rs_press"))
	_expect("mq_rs2", 20)
	GameState.tracked_quest = "mq_rs2"
	await _follow("mq_rs2") # -> Pixel again
	await _spot("arcade_pixel", [])
	_ok("respawn done", GameState.quest_state("mq_respawn") == "done")
	_ok("rs2 done", GameState.quest_state("mq_rs2") == "done")
	_expect("mq_chi1", 10)


func _chicago() -> void:
	print("PHASE chicago")
	GameState.tracked_quest = "mq_chi1"
	await _follow("mq_chi1") # -> the I-80 on-ramp
	await _drive_gate("highway")
	_ok("on the interstate", WorldLayout.region == "highway")
	var hw: Array = Regions.GATES["highway"]["hw_west"]["pos"]
	await _drive_gate("chicago", Vector3(float(hw[0]), 0.3, float(hw[1]) + 5.0))
	_ok("in chicago", WorldLayout.region == "chicago")
	await _wait_rules()
	_expect("mq_chi1", 20)
	game.exit_vehicle(true)
	await _settle()
	await _follow("mq_chi1") # -> the warehouse
	_ok("in the cell", GameState.cell == "chi_safe")
	await _talk("ansel", ["Why do you fight", "loot boxes"])
	_ok("chi1 done", GameState.quest_state("mq_chi1") == "done")
	_expect("mq_chi2", 10)
	GameState.tracked_quest = "mq_chi2"
	GameState.game_minutes = GameState.day() * 1440.0 + 13 * 60.0
	await _follow("mq_chi2") # -> E Corp Midwest
	_ok("midwest lobby allowed by day", not game.cell_restricted("chi_node", "ecorp"))
	await _term("chi_dataterm", ["surprise mechanics", "account authority"], ["Rig the loot-box", "Flip Phony"])
	_ok("loot boxes honest", GameState.has_flag("earse_exposed"))
	_ok("libraries freed", GameState.has_flag("phony_freed"))
	_ok("chi2 done", GameState.quest_state("mq_chi2") == "done")
	_expect("mq_chi3", 20)
	_ok("chi3 waits for the trip home", GameState.quest_state("mq_chi3") != "done")
	await _enter_door("d_chi_safe")
	await _talk("ansel", ["Look after"])
	_ok("said goodbye", GameState.has_flag("ansel_bye"))


func _home() -> void:
	print("PHASE home")
	GameState.tracked_quest = "mq_chi3"
	await _follow("mq_chi3") # -> I-90 east
	await _drive_gate("highway")
	_ok("back on the interstate", WorldLayout.region == "highway")
	var he: Array = Regions.GATES["highway"]["hw_east"]["pos"]
	await _drive_gate("nyc", Vector3(float(he[0]), 0.3, float(he[1]) - 5.0))
	_ok("back in new york", WorldLayout.region == "nyc")
	await _wait_rules()
	_ok("chi3 done at home", GameState.quest_state("mq_chi3") == "done")
	game.exit_vehicle(true)
	await _settle()
	await _enter_door("d_arcade")
	await _spot("arcade_pixel", ["ten thousand", "How do we get in"])
	_ok("pixel unmasked", GameState.has_flag("pixel_home"))
	await _microslop()
	var titles: Array = []
	for s in EndingData.slides("fsociety"):
		titles.append(str((s as Dictionary)["title"]))
	for want in ["ROCKSTARVED", "KENNYQA", "CHICAGO", "RESPAWN", "MICROSLOP", "2B"]:
		_ok("epilogue has " + want, titles.has(want))


func _microslop() -> void:
	print("PHASE microslop")
	_expect("mq_ms", 20)
	GameState.tracked_quest = "mq_ms"
	await _follow("mq_ms") # -> Kenny
	await _talk("kenny", ["reason there isn't one", "Give me the invitation"])
	_ok("has invitation", GameState.has_item("ms_invite"))
	_expect("mq_ms", 30)
	await _follow("mq_ms") # -> WTC lobby
	await _exit_to("interior:ms_floor:0")
	await _wait_rules()
	_ok("on floor 101", GameState.cell == "ms_floor")
	_ok("invited, not trespassing", not game.cell_restricted("ms_floor", "ecorp"))
	_expect("mq_ms", 40)
	await _talk("brad", ["one more thing", "His phone"])
	_ok("library password", GameState.has_flag("ms_pw"))
	await _term("ms_vault", ["Project Sunset", "SlopForge", "launch switch"], ["Give it back", "Flip the switch"])
	_ok("studios returned", GameState.has_flag("ms_returned") and not GameState.has_flag("ms_freed"))
	_expect("mq_ms", 50)
	await _follow("mq_ms") # -> Pixel
	await _spot("arcade_pixel", ["always yours"])
	_ok("microslop done", GameState.quest_state("mq_ms") == "done")


## Drive a car through the travel gate nearest `at` (or the player) and load
## the map on the other side, the way region_test does.
func _drive_gate(want: String, at: Vector3 = Vector3.INF) -> void:
	if at == Vector3.INF:
		at = game.player.global_position
	if game.player.driving == null:
		var v := Vehicle.new().setup("sedan", 2, at + Vector3(0, 0.3, 0), 0.0, game)
		v.locked = false
		game.vehicles_root.add_child(v)
		await _settle()
		game.enter_vehicle(v)
		await _settle()
	else:
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
	game.queue_free()
	for i in 3:
		await get_tree().process_frame
	var scene: PackedScene = load("res://game/Game.tscn")
	game = scene.instantiate()
	game.test_mode = true
	game.test_picker = _pick
	add_child(game)
	await _until(func() -> bool: return game.player != null and not game.busy_transition and game.player.driving != null, 3000)
	game.minigames.auto_result = 1
	for i in 10:
		await get_tree().process_frame
