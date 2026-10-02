extends Node
var game
var problems: Array = []
var rng := RandomNumberGenerator.new()
func _ready() -> void:
	rng.seed = 999
	var scene: PackedScene = load("res://game/Game.tscn")
	game = scene.instantiate(); game.test_mode = true
	game.test_picker = func(chs): return rng.randi() % maxi(1, chs.size())
	add_child(game)
	await _until(func(): return game.player != null and not game.busy_transition and not game.dialog.is_open() and GameState.quests.has("mq_hello"), 5000)
	game.minigames.auto_result = 1
	game.dialog.auto_advance = true
	# This harness only exercises the dialogue UI; hide the 3D world so software-GL
	# rendering isn't the bottleneck, and reveal text instantly.
	Settings.set_v("subtitles_speed", 40.0)
	game.city_root.visible = false; game.city_extras.visible = false; game.world_inter.visible = false
	game.crowd.set_active(false); game.traffic.set_active(false)
	for k in game.built_interiors.keys(): (game.built_interiors[k] as Node3D).visible = false
	var convos := DialogueManager.convos.keys(); convos.sort()
	var P := int(OS.get_environment("P")) if OS.get_environment("P")!="" else 0
	_state(P)
	var start := int(OS.get_environment("START")) if OS.get_environment("START")!="" else 0
	var count := int(OS.get_environment("COUNT")) if OS.get_environment("COUNT")!="" else convos.size()
	var idx := 0
	for cid in convos:
		idx += 1
		if idx <= start or idx > start + count:
			continue
		print("FUZZ walk %d/%d: %s" % [idx, convos.size(), str(cid)])
		var done := [false]
		var r = func(): await game.dialog.run(str(cid), null); done[0]=true
		r.call()
		var t := 0
		while not done[0] and t < 500: await get_tree().process_frame; t+=1
		if not done[0]:
			problems.append("HUNG: "+str(cid)); if game.dialog.is_open(): game.dialog.abort(); await _frames(3)
		# Reset transient world state so effects don't accumulate across convos
		# (spawned combat NPCs, wanted cops, cinematic) and drag every later walk.
		game.cinematic = false
		GameState.set_wanted(0)
		game.npcs.clear_all()
		_state(P)
	print("FUZZ pass %d done, %d convos, problems=%d" % [P, convos.size(), problems.size()])
	for p in problems: print("PROBLEM ", p)
	get_tree().quit()
func _state(p):
	GameState.new_game(); GameState.set_tags(["hacking","sneak","speech"])
	if p==1:
		for f in ["knows_ron_secret","found_ron_code","joined_fsociety","rootkit_planted","met_tyrell_invite","ecorp_door_tyrell","fbi_contact","knows_darlene_sister","darlene_bond","krista_truth","shayla_out","has_lenny_phone","five_nine_done","lenny_gone","township_resolved","vera_deal"]:
			GameState.set_flag(f)
		for it in ["stalker_db","colby_archive","raspberry_pi","deus_invite","lenny_phone","cd_mixtape","rose_package","flipper_leash"]: GameState.give(it)
		for q in ["mq_rootkit","mq_fsociety","mq_steel","mq_darkarmy","mq_ecorp","mq_fbi","mq_finale","sq_ron","sq_shayla","sq_krista","sq_colby","sq_cat","sq_courier","sq_busker","sq_super"]: GameState.set_quest_stage(q, 20)
		GameState.raise_skill("speech",70); GameState.raise_skill("hacking",70); GameState.raise_skill("barter",70)
		GameState.add_fame("darkarmy",30); GameState.add_fame("fbi",30); GameState.add_cash(500)
		GameState.trust["darlene"]=8; GameState.trust["robot"]=-5
	elif p==2:
		GameState.stability=8
		for s in DB.SKILLS: GameState.base_skills[s]=3
func _until(c,l): var t=0; while not c.call() and t<l: await get_tree().process_frame; t+=1
func _frames(n): for i in n: await get_tree().process_frame
