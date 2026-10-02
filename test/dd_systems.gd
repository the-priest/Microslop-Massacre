extends Node
var game
var problems: Array = []
var rng := RandomNumberGenerator.new()
func _e(c,n): if not c: problems.append(n)
func _ready() -> void:
	rng.seed=3
	var scene: PackedScene = load("res://game/Game.tscn")
	game = scene.instantiate(); game.test_mode=true; game.test_picker=func(chs): return 0
	add_child(game)
	await _until(func(): return game.player!=null and not game.busy_transition and GameState.cell=="krista_office" and not game.dialog.is_open() and GameState.quests.has("mq_hello"), 6000)

	# death
	await game.enter_cell("world", Vector3(-466,0,318),0,false,true); await _settle()
	GameState.hp=5.0; game.player.take_damage(999, game.player.global_position)
	await _frames(70); _e(game.death_ui.is_open(), "death UI at 0hp")
	if game.death_ui.is_open(): game.death_ui.close_modal()
	game._dead = false  # production recovers by reloading the scene; the harness reuses it
	_e(game.ui_depth == 0, "ui_depth balanced after death+close")

	# exploit melee
	GameState.new_game(); GameState.set_tags(["guns","melee","sneak"])
	await game.enter_cell("world", Vector3(-466,0,318),0,false,true); await _settle()
	GameState.equip("fists")
	var m=NPC.new(); m.setup("dm",NPCData.TEMPLATES["thug"],game.player.global_position+Vector3(0,0,-3),0,"world",game); game.npcs.add_child(m); m.global_position=game.player.global_position+Vector3(0,0,-3)
	GameState.hostile["dm"]=true
	await _frames(20); game.player.look_toward(m.chest_pos()); GameState.focus=GameState.max_focus()
	game.exploit_ui.try_open(); await _frames(8)
	_e(game.exploit_ui.is_open(), "exploit opens for melee")
	if game.exploit_ui.is_open():
		game.exploit_ui._enqueue(); await _frames(2); game.exploit_ui._execute()
		await _until(func(): return not game.exploit_ui.executing, 300)
	_e(is_equal_approx(Engine.time_scale,1.0), "timescale restored (melee exploit)")

	# companions
	GameState.new_game()
	await game.enter_cell("world", Vector3(-466,0,318),0,false,true); await _settle()
	await DialogueManager.run_effects(DialogueManager.parse_effects("recruit darlene_n","t"))
	_e(GameState.companions.has("darlene_n"), "recruit companion")
	await game.enter_cell("bodega", InteriorBuilder.exit_spawn(game.interior_def("bodega"),0)["pos"],0,false); await _settle()
	await _frames(8)
	var comp=game.npcs.get_npc("darlene_n"); _e(comp!=null and comp.cell=="bodega", "companion follows to interior")
	await DialogueManager.run_effects(DialogueManager.parse_effects("dismiss darlene_n","t"))
	_e(not GameState.companions.has("darlene_n"), "dismiss companion")

	# wanted + slow update
	await game.enter_cell("world", Vector3(-466,0,318),0,false,true); await _settle()
	GameState.set_wanted(120); game._slow_update(); await _frames(30)
	_e(GameState.wanted_until>GameState.game_minutes, "wanted persists")
	var cops=0
	for n in get_tree().get_nodes_in_group("npc"):
		if (n as NPC).faction=="nypd" and not (n as NPC).dead: cops+=1
	_e(cops>0, "cops spawn when wanted")

	# blackout
	GameState.discover("d_apt","apt")
	await game.blackout(""); await _settle()
	_e(not game.busy_transition, "blackout completes")
	_e(GameState.get_flag("blackouts",0)>=1 or GameState.stability>=25, "blackout applied effects")

	# minigames real (build + abort)
	for mg in ["lockpick","exploit","recon","bruteforce","signal","cascade","invaders","loghunt"]:
		var s=load(game.minigames.SCRIPTS[mg]).new()
		if mg=="lockpick": s.set("dc",30)
		s.theme=UI.theme(); add_child(s); await _frames(6)
		_e(is_instance_valid(s), "minigame builds: "+mg)
		if s.has_signal("finished"): s.emit_signal("finished", false)
		await _frames(2); if is_instance_valid(s): s.queue_free()

	# save/load in interior
	await game.enter_cell("elliot_apt", InteriorBuilder.exit_spawn(game.interior_def("elliot_apt"),0)["pos"],0,false); await _settle()
	SaveManager.save("slot3","int"); var d=SaveManager._read("slot3"); GameState.from_dict(d["state"])
	_e(GameState.cell=="elliot_apt", "save/load keeps interior cell")

	# inventory edges
	GameState.new_game(); GameState.give("pistol_9mm"); GameState.equip("pistol_9mm"); GameState.take("pistol_9mm",1)
	_e(str(GameState.equipped["weapon"])=="fists", "drop equipped weapon -> fists")
	GameState.give("leather_jacket"); GameState.equip("leather_jacket")
	_e(str(GameState.equipped["body"])=="leather_jacket", "equip body apparel")
	GameState.take("leather_jacket",1)
	_e(str(GameState.equipped["body"])=="", "removing worn apparel unequips")

	print("SYSTEMS DONE problems=%d" % problems.size())
	for p in problems: print("PROBLEM ", p)
	get_tree().quit()
func _until(c,l): var t=0; while not c.call() and t<l: await get_tree().process_frame; t+=1
func _settle(): await get_tree().physics_frame; await _until(func(): return not game.busy_transition, 300)
func _frames(n): for i in n: await get_tree().process_frame
