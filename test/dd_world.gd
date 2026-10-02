extends Node
## Deep test for the open-world systems: generated doors/interiors, the loot
## index, ATMs, pickpocketing, jobs, encounters, unique weapon placement.
var game
var problems: Array = []
var notes: Array = []

func _e(c: bool, n: String) -> void:
	if not c:
		problems.append(n)

func _ready() -> void:
	var scene: PackedScene = load("res://game/Game.tscn")
	game = scene.instantiate(); game.test_mode = true; game.test_picker = func(chs): return 0
	add_child(game)
	await _until(func(): return game.player != null and not game.busy_transition and GameState.cell == "krista_office" and not game.dialog.is_open() and GameState.quests.has("mq_hello"), 6000)
	print("BOOTED t=", Time.get_ticks_msec())
	game.minigames.auto_result = 1
	game.dialog.auto_advance = true
	GameState.new_game(); GameState.set_tags(["hacking", "sneak", "lockpick"])
	notes.append("gen_doors=%d lootables=%d" % [game.gen_doors.size(), game.loot_index.count])
	_e(game.gen_doors.size() > 1500, "expected >1500 generated doors, got %d" % game.gen_doors.size())
	_e(game.loot_index.count > 3000, "expected >3000 index entries")

	print("PHASE . t=", Time.get_ticks_msec())
	# ---- 1. Static validation of EVERY generated interior.
	var kinds := {}
	var furn_ok := ["bed", "bed_double", "mattress", "sofa", "armchair", "coffee_table", "table", "chair", "stool", "desk", "desk_pc", "office_desk", "monitor_wall", "tv", "bookshelf", "shelf", "shelf_industrial", "kitchen", "fridge", "fridge_glass", "counter", "register", "coffee_machine", "cafe_table", "bar_counter", "bar_shelf", "pool_table", "jukebox", "booth", "arcade_cab", "pinball", "server_rack", "filing_cabinet", "locker_row", "whiteboard", "water_cooler", "vending", "reception", "logo_wall", "plant", "lamp", "rug", "window", "poster", "radiator", "boxes", "crate", "trash_pile", "toilet", "sink", "wardrobe", "dresser", "gun_rack", "display_case", "safe", "clothes_rack", "mannequin", "duffel", "lantern", "screen_fold"]
	for gid in game.gen_doors.keys():
		var gd: Dictionary = game.gen_doors[gid]
		var k := str(gd["kind"])
		kinds[k] = int(kinds.get(k, 0)) + 1
		var d: Dictionary = game.interior_def("bld:" + str(gid))
		if d.is_empty():
			problems.append("empty def " + str(gid)); continue
		var rects: Array = []
		for r in d["rooms"]:
			var rr: Array = (r as Dictionary)["r"]
			rects.append(Rect2(float(rr[0]), float(rr[1]), float(rr[2]) - float(rr[0]), float(rr[3]) - float(rr[1])))
		var inside := func(x: float, z: float) -> bool:
			for rc in rects:
				if (rc as Rect2).grow(0.05).has_point(Vector2(x, z)):
					return true
			return false
		for f in d["furn"]:
			if not (str((f as Array)[0]) in furn_ok):
				problems.append("unknown furniture %s in %s" % [str(f[0]), k])
			if not inside.call(float(f[1]), float(f[2])):
				problems.append("furniture %s outside rooms in %s (%s)" % [str(f[0]), k, gid])
		for c in d["containers"]:
			var cd: Dictionary = c
			if cd.has("loot") and not NPCData.LOOT.has(str(cd["loot"])):
				problems.append("missing loot table %s (%s)" % [str(cd["loot"]), k])
			var pa: Array = cd["pos"]
			if not inside.call(float(pa[0]), float(pa[1])):
				problems.append("container outside rooms in %s" % k)
		for n in d.get("npcs", []):
			var nd: Dictionary = n
			if not NPCData.TEMPLATES.has(str(nd["t"])):
				problems.append("missing template %s" % str(nd["t"]))
			var np: Array = nd["pos"]
			if not inside.call(float(np[0]), float(np[1])):
				problems.append("npc outside rooms in %s" % k)
			if str(nd.get("when", "")) != "":
				DialogueManager.parse_cond(str(nd["when"]), "test")
		for s in d.get("spots", []):
			var sd: Dictionary = s
			if str(sd["kind"]) == "shop" and not NPCData.SHOPS.has(str(sd["shop"])):
				problems.append("missing shop " + str(sd["shop"]))
		var ex: Array = d["exits"]
		_e(ex.size() == 1 and str(ex[0]["to"]) == "world:" + str(gid), "bad exit in " + str(gid))
		var sp: Dictionary = InteriorBuilder.exit_spawn(d, 0)
		_e(inside.call((sp["pos"] as Vector3).x, (sp["pos"] as Vector3).z), "spawn outside rooms " + str(gid))
	notes.append("kinds: " + str(kinds))
	if DialogueManager.parse_errors.size() > 0:
		problems.append("parse errors: " + str(DialogueManager.parse_errors.slice(0, 3)))

	print("PHASE . t=", Time.get_ticks_msec())
	# ---- 2. Enter a sample of each kind, check occupants, walk back out.
	var sample := {}
	for gid in game.gen_doors.keys():
		var k2 := str(game.gen_doors[gid]["kind"])
		if not sample.has(k2):
			sample[k2] = []
		if (sample[k2] as Array).size() < 2:
			(sample[k2] as Array).append(str(gid))
	for k3 in sample.keys():
		for gid in sample[k3]:
			for hr in [13, 2]:
				GameState.game_minutes = GameState.day() * 1440.0 + float(hr) * 60.0 + 1440.0
				var d2: Dictionary = game.interior_def("bld:" + gid)
				var sp2: Dictionary = InteriorBuilder.exit_spawn(d2, 0)
				await game.enter_cell("bld:" + gid, sp2["pos"], float(sp2["yaw"]), false)
				await _settle(); await _frames(4)
				game.npcs.refresh(true); await _frames(3)
				_e(GameState.cell == "bld:" + gid, "failed to enter " + gid + " " + k3)
				var here := 0
				for n in get_tree().get_nodes_in_group("npc"):
					if (n as NPC).cell == GameState.cell:
						here += 1
				# Player must not spawn inside furniture: step forward a bit.
				var p0: Vector3 = game.player.global_position
				_e(p0.y > -0.5 and p0.y < 1.0, "player fell/launched in " + k3)
				await game._take_exit("world:" + gid)
				await _settle()
				var dw: Dictionary = game.door_world_any(gid)
				_e(GameState.cell == "world" and game.player.global_position.distance_to(dw["pos"]) < 4.0, "exit didn't land at door " + gid)
				notes.append("%s %s @%d:00 npcs=%d" % [k3, gid, hr, here])

	print("PHASE . t=", Time.get_ticks_msec())
	# ---- 3. Loot index: rays pick props, containers roll & restock.
	await game.enter_cell("world", Vector3(-466, 0, 318), 0, false, true); await _settle()
	var picked := 0
	var tested := 0
	var by_kind := {}
	for e in game.loot_index.by_id.values():
		var ed: Dictionary = e
		var k4 := str(ed["kind"])
		if int(by_kind.get(k4, 0)) >= 6:
			continue
		by_kind[k4] = int(by_kind.get(k4, 0)) + 1
		var c: Vector3 = ed["p"]
		var he: Vector3 = ed["he"]
		var from := c + Vector3(0, 1.62 - c.y, 0) + Vector3(0, 0, he.z + 1.2)
		if k4 == "gdoor":
			from = c + Vector3(0, 0.4, 0) + ((game.gen_doors[ed["id"]] as Dictionary)["out"] as Vector3) * 1.5
		var dir := (c - from).normalized()
		var v = game.loot_pick(from, dir, 3.0)
		tested += 1
		if v != null and v.ident == str(ed["id"]):
			picked += 1
			if v.kind == "container" and not v.is_locked():
				game.open_container(v.ident, v.title, v.data)
				await _frames(2)
				if game.loot_ui.is_open():
					game.loot_ui.close_modal()
				await _frames(1)
				_e(GameState.containers.has(v.ident), "container state missing " + k4)
		else:
			notes.append("pick miss %s (%s)" % [k4, str(ed["id"])])
	notes.append("loot picks %d/%d  kinds=%s" % [picked, tested, str(by_kind.keys())])
	_e(picked >= tested - 4, "too many loot pick misses: %d/%d" % [picked, tested])
	# Restock: empty a dumpster, jump days.
	for e in game.loot_index.by_id.values():
		if str(e["kind"]) == "dumpster":
			var v2 = game._virtual_for(e)
			GameState.containers[v2.ident] = {"items": {}, "cash": 0, "day": GameState.day()}
			_e(v2.interact_info()["name"].ends_with("(empty)"), "empty dumpster not shown empty")
			GameState.game_minutes += 1440.0 * 4
			_e(not v2.interact_info()["name"].ends_with("(empty)"), "dumpster didn't restock")
			break

	print("PHASE . t=", Time.get_ticks_msec())
	# ---- 4. ATM.
	for e in game.loot_index.by_id.values():
		if str(e["kind"]) == "atm":
			var v3 = game._virtual_for(e)
			var before := GameState.cash
			GameState.give("credit_card", 2, true)
			game.test_picker = func(chs): return 1 if chs.size() > 2 else 0
			await game._use_atm(v3)
			await _frames(3)
			_e(GameState.cash > before, "ATM hack paid nothing (cash %d -> %d)" % [before, GameState.cash])
			notes.append("atm: $%d -> $%d" % [before, GameState.cash])
			game.test_picker = func(chs): return 0
			var c2 := GameState.count("credit_card")
			await game._use_atm(v3)
			await _frames(3)
			_e(GameState.count("credit_card") < c2, "card cash-out didn't take a card")
			break

	print("PHASE . t=", Time.get_ticks_msec())
	# ---- 5. Pickpocket a generic civilian.
	var civ := NPC.new(); civ.setup("pp_test", NPCData.TEMPLATES["patron"].duplicate(true).merged({"generic": true}), game.player.global_position + Vector3(0, 0, -1.2), 0, "world", game)
	game.npcs.add_child(civ); civ.global_position = game.player.global_position + Vector3(0, 0, -1.2)
	await _frames(3)
	GameState.raise_skill("sneak", 80)
	var c0 := GameState.cash
	game._pickpocket(civ, civ.global_position, civ.display_name)
	_e(civ.picked, "pickpocket didn't mark target")
	notes.append("pickpocket cash %d -> %d" % [c0, GameState.cash])

	print("PHASE . t=", Time.get_ticks_msec())
	# ---- 6. Jobs: take every board job and complete it.
	var done0 := int(GameState.jobs_state.get("done", 0))
	var cash0 := GameState.cash
	for round_i in 3:
		GameState.game_minutes += 1440.0
		for j in game.jobs.board().duplicate():
			if game.jobs.active().size() >= Jobs.MAX_ACTIVE:
				break
			game.jobs.accept(str(j["id"]))
		for j in game.jobs.active().duplicate():
			await _complete_job(j)
	var done1 := int(GameState.jobs_state.get("done", 0))
	notes.append("jobs completed %d, cash %d -> %d, still active %d" % [done1 - done0, cash0, GameState.cash, game.jobs.active().size()])
	_e(done1 - done0 >= 5, "jobs: only %d completed" % (done1 - done0))

	print("PHASE . t=", Time.get_ticks_msec())
	# ---- 7. Encounters.
	GameState.stability = 80; GameState.hp = GameState.max_hp()
	await game.enter_cell("world", Vector3(-466, 0, 318), 0, false, true); await _settle()
	for i in 6:
		game.encounters._spawn_random()
	game.npcs.refresh(true); await _frames(4)
	var enc := 0
	for n in get_tree().get_nodes_in_group("npc"):
		if str((n as NPC).id).begins_with("enc:"):
			enc += 1
	notes.append("encounters active=%d npcs=%d" % [game.encounters.active.size(), enc])
	_e(game.encounters.active.size() > 0, "no encounters spawned")

	print("PHASE . t=", Time.get_ticks_msec())
	# ---- 8. Unique weapons: reachable, not buried in geometry.
	var space: PhysicsDirectSpaceState3D = game.get_world_3d().direct_space_state
	for pk in WorldObjects.PICKUPS:
		var pa2: Array = pk["pos"]
		var at := Vector3(float(pa2[0]), 0.0, float(pa2[2]))
		var q := PhysicsRayQueryParameters3D.create(at + Vector3(0, 12, 0), at + Vector3(0, -1, 0), Phys.WORLD)
		var hit := space.intersect_ray(q)
		var top := float((hit.get("position", Vector3.ZERO) as Vector3).y) if not hit.is_empty() else -99.0
		if top > 0.6:
			problems.append("pickup %s buried under geometry (top %.1f)" % [str(pk["id"]), top])
		if not WorldLayout.in_bounds(at.x, at.z) and WorldLayout.district_at(at.x, at.z) != "coney":
			notes.append("pickup %s outside grid (%s)" % [str(pk["id"]), str(at)])

	print("PHASE . t=", Time.get_ticks_msec())
	# ---- 9. Save / load inside a generated building.
	var g1: String = sample["apartment"][0]
	var d3: Dictionary = game.interior_def("bld:" + g1)
	await game.enter_cell("bld:" + g1, InteriorBuilder.exit_spawn(d3, 0)["pos"], 0, false); await _settle()
	game.sync_state_for_save()
	SaveManager.save("slot4", "gen")
	var sd2 = SaveManager._read("slot4")
	GameState.from_dict(sd2["state"])
	_e(GameState.cell == "bld:" + g1, "save/load lost generated cell")
	_e(GameState.jobs_state.has("board"), "jobs state not saved")

	print("WORLD DONE problems=%d" % problems.size())
	for n in notes: print("NOTE ", n)
	for p in problems: print("PROBLEM ", p)
	get_tree().quit()


func _complete_job(j: Dictionary) -> void:
	var gid := str(j["door"])
	match str(j["kind"]):
		"delivery":
			var d: Dictionary = game.interior_def("bld:" + gid)
			await game.enter_cell("bld:" + gid, InteriorBuilder.exit_spawn(d, 0)["pos"], 0, false); await _settle()
			await game._take_exit("world:" + gid); await _settle()
		"bounty":
			var gd: Dictionary = game.gen_doors[gid]
			await game.enter_cell("world", gd["pos"] + (gd["out"] as Vector3) * 6.0, 0, false, true); await _settle()
			game.npcs.refresh(true); await _frames(3)
			for n in get_tree().get_nodes_in_group("npc"):
				var o := n as NPC
				if o.id.begins_with("job:" + str(j["id"])) and not o.dead:
					o.die(game.player)
			await _frames(3)
		"heist", "repo":
			var d2: Dictionary = game.interior_def("bld:" + gid)
			await game.enter_cell("bld:" + gid, InteriorBuilder.exit_spawn(d2, 0)["pos"], 0, false); await _settle()
			var cid := "jobc:" + str(j["id"])
			var found := false
			for c in d2["containers"]:
				if str(c["id"]) == cid:
					found = true
			_e(found, "job container not planted for " + str(j["kind"]))
			var data := {}
			for c in d2["containers"]:
				if str(c["id"]) == cid:
					data = c
			if not GameState.containers.has(cid):
				GameState.containers[cid] = game._roll_container(data)
			var items: Dictionary = GameState.containers[cid]["items"]
			for k in items.keys():
				GameState.give(str(k), int(items[k]), true)
			items.clear()
			await game._take_exit("world:" + gid); await _settle()
		"hit":
			var d3: Dictionary = game.interior_def("bld:" + gid)
			await game.enter_cell("bld:" + gid, InteriorBuilder.exit_spawn(d3, 0)["pos"], 0, false); await _settle()
			game.npcs.refresh(true); await _frames(3)
			for n in get_tree().get_nodes_in_group("npc"):
				var o2 := n as NPC
				if o2.cell == "bld:" + gid and not o2.dead and o2.is_hostile_to_player():
					o2.die(game.player)
			await _frames(70)
			await game._take_exit("world:" + gid); await _settle()


func _until(c, l): var t = 0; while not c.call() and t < l: await get_tree().process_frame; t += 1
func _settle(): await get_tree().physics_frame; await _until(func(): return not game.busy_transition, 300)
func _frames(n): for i in n: await get_tree().process_frame
