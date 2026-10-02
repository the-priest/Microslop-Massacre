extends Node
## Headless playthrough: boots Game in test mode and drives the whole main
## quest to an ending by scripting flags/effects and walking cells, asserting
## the critical path stays traversable. Not a substitute for play, but catches
## dead-ends and broken transitions.

var game: Node
var fails: int = 0
var log: Array = []


func _ready() -> void:
	var scene: PackedScene = load("res://game/Game.tscn")
	game = scene.instantiate()
	game.test_mode = true
	game.test_picker = func(chs: Array) -> int: return 0
	add_child(game)
	await get_tree().process_frame
	await _until(func() -> bool: return game.player != null and not game.busy_transition and GameState.cell == "krista_office" and not game.dialog.is_open() and GameState.quests.has("mq_hello"), 4000)
	_ok("boot in krista_office", GameState.cell == "krista_office")
	_ok("intro completed", GameState.quests.has("mq_hello") and not game.dialog.is_open())
	# ACT 1: to the street.
	await _enter("world:d_krista")
	_ok("into world", GameState.cell == "world")
	GameState.set_flag("act1_start", true)
	# Simulate: go to Ron's, do the rootkit chain via effects.
	await _run("quest mq_hello 10")
	await _visit_door("d_ron", "ron_coffee")
	await _run("set found_ron_code ; set knows_ron_secret ; quest sq_ron 20 ; give stalker_db 1 ; quest sq_ron 30 ; quest sq_ron 50 ; set rootkit_planted ; quest mq_rootkit 40 ; quest mq_rootkit 50 ; quest mq_rootkit done ; quest mq_fsociety 10")
	_ok("rootkit done", GameState.has_flag("rootkit_planted") and GameState.quest_state("mq_rootkit") == "done")
	game.minigames.auto_result = 1
	# ACT 2: fsociety.
	await _run("set joined_fsociety ; quest mq_fsociety 40 ; quest mq_steel 10 ; quest mq_darkarmy 10")
	_ok("joined fsociety", GameState.has_flag("joined_fsociety"))
	game.minigames.auto_result = 1
	await _visit_door("d_arcade", "arcade")
	# Steel Mountain.
	GameState.give("steel_coveralls"); GameState.equip("steel_coveralls")
	_ok("steel disguise", GameState.disguise() == "steel")
	await _run("give raspberry_pi 1")
	await _visit_door("d_steel", "steel_mountain")
	await _run("set steel_rigged ; quest mq_steel 40 ; quest mq_steel 50")
	_ok("steel done", GameState.quest_state("mq_steel") == "done")
	# Dark Army.
	await _visit_door("d_rose", "rose_garden")
	await _run("quest mq_darkarmy 20 ; quest mq_darkarmy 40 ; set ally_secured ; fame darkarmy 5")
	_ok("darkarmy allied", GameState.quest_stage("mq_darkarmy") >= 30)
	# E Corp.
	await _run("quest mq_ecorp 10 ; set met_tyrell_invite ; set ecorp_door_tyrell ; quest mq_ecorp 30 ; set ecorp_foothold ; quest mq_ecorp 50")
	_ok("ecorp door", GameState.has_flag("ecorp_door_tyrell"))
	# Personal (for overlap).
	await _run("trust darlene 8 ; set darlene_bond ; set knows_darlene_sister ; set krista_truth ; stab 40 ; set shayla_out ; quest sq_shayla done")
	# FINALE via dialogue.
	game.dialog.auto_advance = true
	_ok("finale gate ready", DialogueManager.check("flag.rootkit_planted") and GameState.quest_state("mq_steel") == "done")
	game.minigames.auto_result = 1
	game.dialog.auto_advance = true
	print("DBG before finale: joined=%s rootkit=%s steel=%s da=%d ecorp=%s auto=%d" % [str(GameState.has_flag("joined_fsociety")), str(GameState.has_flag("rootkit_planted")), GameState.quest_state("mq_steel"), GameState.quest_stage("mq_darkarmy"), str(GameState.has_flag("ecorp_door_tyrell")), game.minigames.auto_result])
	await game.dialog.run("finale_check", null)
	print("DBG after finale: five_nine=%s mq_finale=%d ending_flags=%s" % [str(GameState.has_flag("five_nine_done")), GameState.quest_stage("mq_finale"), str(GameState.has_item("deus_invite"))])
	_ok("five_nine done", GameState.has_flag("five_nine_done"))
	_ok("has deus invite", GameState.has_item("deus_invite"))
	# Enter Salina with the invite.
	await _visit_door("d_deus", "salina_hotel")
	await _run("quest mq_finale 40")
	# Run the deus table -> ending. test_picker returns 0 (first option each time).
	game.test_picker = func(chs: Array) -> int:
		# pick the overlap option if present, else first.
		for i in chs.size():
			if str((chs[i] as Dictionary)["text"]).to_lower().contains("together"):
				return i
		return 0
	await game.dialog.run("deus_group", null)
	await _until(func() -> bool: return GameState.ending != "", 300)
	_ok("reached an ending", GameState.ending != "")
	log.append("ENDING = " + GameState.ending)
	# Report.
	for l in log:
		print(l)
	print("PLAYTHROUGH DONE fails=%d ending=%s" % [fails, GameState.ending])
	get_tree().quit()


func _run(fx: String) -> void:
	await DialogueManager.run_effects(DialogueManager.parse_effects(fx, "test"))
	await get_tree().process_frame


func _enter(link: String) -> void:
	await game._take_exit(link)
	await _settle()


func _visit_door(door_id: String, expect_cell: String) -> void:
	var doors := WorldLayout.all_doors()
	if not doors.has(door_id):
		_ok("door exists " + door_id, false)
		return
	var d: Dictionary = doors[door_id]
	var to := str(d["interior"])
	await game.enter_cell(to, InteriorBuilder.exit_spawn(game.interior_def(to), 0)["pos"], 0.0, false)
	await _settle()
	_ok("entered " + expect_cell, GameState.cell == expect_cell)
	# And leave back to world so the next door works from outside.
	if to == expect_cell:
		await game.enter_cell("world", WorldLayout.door_exit(door_id)["pos"], 0.0, false, true)
		await _settle()


func _settle() -> void:
	await get_tree().process_frame
	await get_tree().physics_frame
	await _until(func() -> bool: return not game.busy_transition, 400)


func _until(cond: Callable, limit: int) -> void:
	var t := 0
	while not cond.call() and t < limit:
		await get_tree().process_frame
		t += 1


func _ok(name: String, cond: bool) -> void:
	log.append(("PASS " if cond else "FAIL ") + name)
	if not cond:
		fails += 1
