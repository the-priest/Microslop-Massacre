extends "res://test/story_walk.gd"
## The out-of-town side stories, played like story_walk: Last Load on I-80
## (Dolores, her locked rig, the insulin run to Lennox) and Five Stars in
## Chicago (Lou, the tablet, Trevor's review farm). Only the start is scripted.


func _ready() -> void:
	GameState.region = "highway"
	await _load_game()
	GameState.cash = 2000
	GameState.raise_skill("hacking", 50)
	GameState.game_minutes = GameState.day() * 1440.0 + 13 * 60.0
	await _last_load()
	await _travel("chicago", "chi_south")
	await _five_stars()
	var titles: Array = []
	for s in EndingData.slides("quiet"):
		titles.append(str((s as Dictionary)["title"]))
	for want in ["LOU'S RED HOTS", "LENNOX"]:
		_ok("epilogue has " + want, titles.has(want))
	print("ROADS WALK DONE fails=%d" % fails)
	get_tree().quit()


func _load_game() -> void:
	var scene: PackedScene = load("res://game/Game.tscn")
	game = scene.instantiate()
	game.test_mode = true
	game.test_picker = _pick
	add_child(game)
	await _until(func() -> bool: return game.player != null and not game.busy_transition and not game.dialog.is_open() and GameState.quests.has("mq_hello"), 6000)
	game.minigames.auto_result = 1


func _travel(region: String, gate: String) -> void:
	await _enter_world_at(Vector3(0, 0, 0))
	game.go_region(region, gate, false)
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
	await _settle()
	_ok("arrived in " + region, WorldLayout.region == region)


func _last_load() -> void:
	print("PHASE last load")
	_ok("on I-80", WorldLayout.region == "highway")
	await _enter_door("d_hw_diner")
	await _talk("dolores", ["Your truck locked you out", "I'll get you moving"])
	_expect("sq_rig", 20)
	GameState.tracked_quest = "sq_rig"
	await _follow("sq_rig") # -> the rig on the shoulder
	await _spot("ws_rig", ["insulin cooler"])
	_ok("carrying the insulin", GameState.has_item("insulin_cooler"))
	_expect("sq_rig", 30)
	await _follow("sq_rig") # -> Ruth in Lennox
	await _talk("ruth", [])
	_ok("insulin delivered", not GameState.has_item("insulin_cooler") and GameState.has_flag("ruth_thanked"))
	_expect("sq_rig", 40)
	await _follow("sq_rig") # -> back to Dolores
	await _talk("dolores", [])
	_ok("last load done", GameState.quest_state("sq_rig") == "done")


func _five_stars() -> void:
	print("PHASE five stars")
	await _enter_door("d_chi_diner")
	await _talk("lou", ["Slow day", "Can I see the reviews"])
	_expect("sq_lou", 10)
	GameState.tracked_quest = "sq_lou"
	await _spot("lou_tablet", [])
	_expect("sq_lou", 20)
	await _follow("sq_lou") # -> Skyway Motel, Room 14
	await _wait_rules()
	_expect("sq_lou", 30)
	await _talk("trevor", ["about Lou's", "Give me the laptop password"])
	await _term("review_farm", ["Client brief", "other clients"], ["Delete every fake review"])
	_ok("reviews gone", GameState.has_flag("lou_truth"))
	_expect("sq_lou", 40)
	await _follow("sq_lou") # -> Lou
	await _talk("lou", [])
	_ok("five stars done", GameState.quest_state("sq_lou") == "done")
