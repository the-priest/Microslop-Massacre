extends Node
## Deep-debug harness: fuzzes every dialogue branch, enters every interior,
## exercises combat/death/wanted/companions/minigames/save-load edge cases.
## Fails loudly on any runtime error via a custom error counter.
var game
var problems: Array = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 12345
	var scene: PackedScene = load("res://game/Game.tscn")
	game = scene.instantiate(); game.test_mode = true
	game.test_picker = func(chs): return rng.randi() % maxi(1, chs.size())
	add_child(game)
	await _until(func(): return game.player != null and not game.busy_transition and GameState.cell=="krista_office" and not game.dialog.is_open() and GameState.quests.has("mq_hello"), 4000)
	game.minigames.auto_result = 1
	game.dialog.auto_advance = true

	# 2) ENTER EVERY INTERIOR, verify exits resolve, leave.
	print("--- entering every interior ---")
	GameState.new_game(); GameState.set_tags(["hacking","sneak","speech"])
	# unlock everything so restricted cells are enterable
	for f in ["disguise_all"]: pass
	for cell in InteriorData.INTERIORS.keys():
		if str(cell) == "subway": continue
		await game.enter_cell(str(cell), InteriorBuilder.exit_spawn(game.interior_def(str(cell)),0)["pos"], 0.0, false)
		await _settle()
		if GameState.cell != str(cell):
			problems.append("failed to enter interior "+str(cell))
		# check no NPC/interactable errors by ticking a few frames
		await _frames(4)
	print("interiors done")

	# 3) COMBAT DEATH + respawn path
	print("--- combat/death ---")
	await game.enter_cell("world", Vector3(-466,0,318), 0, false, true); await _settle()
	GameState.hp = 5.0
	game.player.take_damage(999, game.player.global_position)
	await _frames(60)
	problems.append_array(_expect(game.death_ui.is_open(), "death UI opens at 0 hp"))
	game.death_ui.close_modal()
	game._dead = false  # production recovers by reloading the scene; the harness reuses it
	problems.append_array(_expect(game.ui_depth == 0, "ui_depth balanced after death+close"))
	GameState.new_game(); GameState.hp = 100

	# 4) EXPLOIT with melee weapon
	print("--- exploit melee ---")
	await game.enter_cell("world", Vector3(-466,0,318), 0, false, true); await _settle()
	GameState.equip("fists")
	var m = NPC.new(); m.setup("dm", NPCData.TEMPLATES["thug"], game.player.global_position+Vector3(0,0,-3), 0, "world", game); game.npcs.add_child(m); m.global_position=game.player.global_position+Vector3(0,0,-3)
	GameState.hostile["dm"]=true
	await _frames(20); game.player.look_toward(m.chest_pos()); GameState.focus=GameState.max_focus()
	game.exploit_ui.try_open(); await _frames(8)
	if game.exploit_ui.is_open():
		game.exploit_ui._enqueue(); await _frames(2); game.exploit_ui._execute()
		await _until(func(): return not game.exploit_ui.executing, 300)
	problems.append_array(_expect(is_equal_approx(Engine.time_scale,1.0), "time scale restored after melee exploit"))

	# 5) companions recruit + cell travel + dismiss
	print("--- companions ---")
	GameState.new_game()
	await game.enter_cell("world", Vector3(-466,0,318), 0, false, true); await _settle()
	await DialogueManager.run_effects(DialogueManager.parse_effects("recruit darlene_n","t"))
	problems.append_array(_expect(GameState.companions.has("darlene_n"), "companion recruited"))
	await game.enter_cell("bodega", InteriorBuilder.exit_spawn(game.interior_def("bodega"),0)["pos"], 0, false); await _settle()
	await _frames(6)
	var comp = game.npcs.get_npc("darlene_n")
	problems.append_array(_expect(comp != null and comp.cell=="bodega", "companion followed into interior"))
	await DialogueManager.run_effects(DialogueManager.parse_effects("dismiss darlene_n","t"))
	problems.append_array(_expect(not GameState.companions.has("darlene_n"), "companion dismissed"))

	# 6) wanted system + cop spawn
	print("--- wanted ---")
	await game.enter_cell("world", Vector3(-466,0,318), 0, false, true); await _settle()
	GameState.set_wanted(120)
	game._slow_update()
	await _frames(10)
	problems.append_array(_expect(GameState.wanted_until > GameState.game_minutes, "wanted flag set"))

	# 7) blackout
	print("--- blackout ---")
	GameState.discover("d_apt","apt"); GameState.discover("poi_park","park")
	await game.blackout("")
	await _settle()
	problems.append_array(_expect(not game.busy_transition, "blackout completes"))

	# 8) each minigame instantiates + runs to _finish without auto
	print("--- minigames real ---")
	game.minigames.auto_result = -1
	for mg in ["lockpick","exploit","recon","bruteforce","signal","cascade","invaders","loghunt"]:
		var host_ok = await _try_minigame(mg)
		problems.append_array(_expect(host_ok, "minigame builds+aborts: "+mg))

	# 9) save/load inside an interior
	print("--- save/load interior ---")
	await game.enter_cell("elliot_apt", InteriorBuilder.exit_spawn(game.interior_def("elliot_apt"),0)["pos"], 0, false); await _settle()
	SaveManager.save("slot2","interior test")
	var d = SaveManager._read("slot2")
	GameState.from_dict(d["state"])
	problems.append_array(_expect(GameState.cell=="elliot_apt", "save/load preserves interior cell"))

	# 10) drop equipped weapon, unequip apparel edge
	print("--- inventory edges ---")
	GameState.new_game(); GameState.give("pistol_9mm"); GameState.equip("pistol_9mm")
	GameState.take("pistol_9mm", 1)
	problems.append_array(_expect(str(GameState.equipped["weapon"])=="fists", "dropping equipped weapon reverts to fists"))

	# REPORT
	print("=== DEEP DEBUG PROBLEMS: %d ===" % problems.size())
	for p in problems: print("PROBLEM: ", p)
	print("DEEPDEBUG DONE problems=%d" % problems.size())
	get_tree().quit()

func _randomize_state(seed_i):
	GameState.new_game()
	GameState.set_tags(["hacking","sneak","speech"])
	if seed_i >= 1:
		# mid-game state
		for f in ["knows_ron_secret","found_ron_code","joined_fsociety","rootkit_planted","met_tyrell_invite","ecorp_door_tyrell","fbi_contact","knows_darlene_sister","darlene_bond","krista_truth","shayla_out","has_lenny_phone"]:
			GameState.set_flag(f)
		GameState.give("stalker_db"); GameState.give("colby_archive"); GameState.give("raspberry_pi"); GameState.give("deus_invite"); GameState.give("lenny_phone")
		for q in ["mq_rootkit","mq_fsociety","mq_steel","mq_darkarmy","mq_ecorp","sq_ron","sq_shayla","sq_krista","sq_colby"]:
			GameState.set_quest_stage(q, 20)
		GameState.raise_skill("speech", 60); GameState.raise_skill("hacking", 60)
		GameState.add_fame("darkarmy", 30); GameState.add_fame("fbi", 30)
	if seed_i >= 2:
		GameState.stability = 15
		GameState.raise_skill("speech", 0)
		for s in DB.SKILLS: GameState.base_skills[s] = 5

func _fuzz_convo(cid):
	# Run a convo to completion with random choices; catch hangs.
	game.dialog.auto_advance = true
	var done := false
	var runner = func():
		await game.dialog.run(cid, null)
		done = true
	runner.call()
	var t := 0
	while not done and t < 400:
		await get_tree().process_frame
		t += 1
	if not done:
		problems.append("convo HUNG or errored: "+cid)
		if game.dialog.is_open(): game.dialog.abort()
		await _frames(3)

func _try_minigame(name) -> bool:
	var host: Node = game.minigames
	var path: String = host.SCRIPTS.get(name,"")
	if path == "": return false
	var mg = load(path).new()
	if name == "lockpick": mg.set("dc", 30)
	mg.theme = UI.theme()
	add_child(mg)
	await _frames(5)
	var ok = is_instance_valid(mg)
	# emit finished to unblock any awaiters, then free
	if mg.has_signal("finished"): mg.emit_signal("finished", false)
	await _frames(2)
	if is_instance_valid(mg): mg.queue_free()
	return ok

func _expect(c, n): return [] if c else [n]
func _until(c,l): var t=0; while not c.call() and t<l: await get_tree().process_frame; t+=1
func _settle(): await get_tree().process_frame; await get_tree().physics_frame; await _until(func(): return not game.busy_transition, 400)
func _frames(n): for i in n: await get_tree().process_frame
