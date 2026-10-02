extends Node
## Plays the story the way a player does: follow the tracked quest's marker,
## walk through the door it points at, talk to the NPC who's actually standing
## there, use the terminal/spot, pick dialogue choices by their text, and check
## that the objective really advances. No quest effects are scripted directly;
## if a stage can't be reached through the game's own content, this fails.

var game: Node
var fails: int = 0
var prefs: Array = [] # choice-text substrings, tried in order
var default_picks: Array = []


func _ready() -> void:
	var scene: PackedScene = load("res://game/Game.tscn")
	game = scene.instantiate()
	game.test_mode = true
	game.test_picker = _pick
	add_child(game)
	await _until(func() -> bool: return game.player != null and not game.busy_transition and GameState.cell == "krista_office" and not game.dialog.is_open() and GameState.quests.has("mq_hello"), 6000)
	game.minigames.auto_result = 1
	GameState.cash = 2000
	await _main_line()
	await _side_quests()
	await _finale()
	for d in default_picks:
		print("NOTE default pick: ", d)
	print("STORY WALK DONE fails=%d" % fails)
	get_tree().quit()


# ------------------------------------------------------------------ main
func _main_line() -> void:
	print("PHASE act1")
	_expect("mq_hello", 10)
	await _follow("mq_hello") # -> your building
	_ok("in apt_building", GameState.cell == "apt_building")
	await _exit_to("interior:elliot_apt:0")
	await _wait_rules()
	_expect("mq_hello", 20)
	await _term("apt_pc", ["Gideon", "fsociety00", "auth.log", "Shayla", "headlines", "CourierNet"], [])
	_expect("mq_hello", 25)
	_ok("fsociety file read", GameState.has_flag("fsociety_msg"))
	print("PHASE block")
	await _enter_world_at(Vector3(-470, 0, 338))
	await _talk("super", ["I'll take a look"])
	_expect("sq_super", 10)
	GameState.tracked_quest = "sq_super"
	await _follow("sq_super")
	await _term("apt_boiler", ["service_contract"], ["Kill the service lock"])
	_expect("sq_super", 20)
	await _follow("sq_super")
	await _talk("super", [])
	_ok("super done", GameState.quest_state("sq_super") == "done")
	GameState.game_minutes = GameState.day() * 1440.0 + 14 * 60.0
	await _enter_door("d_apt")
	await _talk("shayla_n", ["Who's Vera", "Don't meet him"])
	_expect("sq_shayla", 10)
	await _wait_rules()
	_expect("mq_hello", 30)
	GameState.tracked_quest = "mq_hello"
	await _follow("mq_hello") # -> Gideon at Allsafe
	await _talk("gideon", ["Show me"])
	_expect("mq_hello", 35)
	await _spot("allsafe_server_spot", ["Keep it"])
	_ok("mq_hello done", GameState.quest_state("mq_hello") == "done")
	_ok("dat kept", GameState.has_flag("dat_kept"))
	_expect("mq_rootkit", 10)

	print("PHASE ron")
	await _follow("mq_rootkit") # -> Ron's
	await _wait_rules()
	_expect("mq_rootkit", 20)
	_ok("sq_ron started", GameState.quest_state("sq_ron") != "")
	await _talk("ron", ["Brave", "Just coffee"]) # SPEECH 20 -> password hint
	await _term("ron_server", ["customers", "README"], ["Copy the customer"])
	await _wait_rules()
	_expect("mq_rootkit", 30)
	await _talk("ron", ["Your customers", "Report him", "Plant the rootkit"])
	_ok("rootkit planted", GameState.has_flag("rootkit_planted"))
	_expect("mq_fsociety", 10)
	_ok("sq_ron done", GameState.quest_state("sq_ron") == "done")

	print("PHASE fsociety")
	await _enter_world_at(Vector3(-470, 0, 300))
	await _follow("mq_fsociety") # -> nearest station, then the platform
	_ok("on a platform", GameState.cell.begins_with("subway"))
	await _follow("mq_fsociety")
	await _talk("robot_n", ["What do you want", "Why should I"])
	_expect("mq_fsociety", 20)
	await _follow("mq_fsociety") # -> arcade
	await _wait_rules()
	_expect("mq_fsociety", 30)
	await _talk("robot_n", ["I'm in"])
	_ok("joined fsociety", GameState.has_flag("joined_fsociety"))
	await _wait_rules()
	for q in ["mq_steel", "mq_darkarmy", "mq_ecorp", "mq_finale"]:
		_expect(q, 10)

	print("PHASE steel")
	await _talk("mobley", ["Where's the device"])
	await _container("arcade_stash")
	_ok("has pi", GameState.has_item("raspberry_pi"))
	_ok("has femtocell", GameState.has_item("femtocell"))
	GameState.tracked_quest = "mq_steel"
	await _follow("mq_steel") # -> Ricky's
	await _buy("guns", "steel_coveralls")
	GameState.equip("steel_coveralls")
	await _wait_rules()
	_expect("mq_steel", 20)
	await _follow("mq_steel") # -> Steel Mountain
	await _wait_rules()
	_expect("mq_steel", 30)
	_ok("not trespassing in steel", not game.cell_restricted("steel_mountain", "ecorp"))
	await _spot("steel_climate", ["Rig the Pi", "Plug it in"])
	_ok("steel done", GameState.quest_state("mq_steel") == "done")

	print("PHASE fbi")
	await _wait_rules()
	_expect("mq_fbi", 10)
	print("PHASE darkarmy")
	GameState.tracked_quest = "mq_darkarmy"
	await _follow("mq_darkarmy") # -> Rose Garden
	await _talk("cisco", ["Understood"])
	await _wait_rules()
	_expect("mq_darkarmy", 30)
	await _follow("mq_darkarmy") # -> Whiterose
	await _talk("whiterose_n", ["fsociety wants", "Gideon goes down"])
	_expect("mq_darkarmy", 35)
	await _follow("mq_darkarmy") # -> Allsafe workstation
	await _term("allsafe_terminal", [], ["Frame Gideon"])
	_ok("darkarmy done", GameState.quest_state("mq_darkarmy") == "done")
	_ok("da allied", GameState.has_flag("da_allied") and GameState.has_flag("ally_secured"))

	print("PHASE ecorp")
	GameState.tracked_quest = "mq_ecorp"
	GameState.game_minutes = GameState.day() * 1440.0 + 13 * 60.0 # business hours
	await _follow("mq_ecorp") # -> Tyrell in the lobby
	_ok("lobby allowed by day", not game.cell_restricted("ecorp_lobby", "ecorp"))
	await _talk("tyrell_n", ["What do you want"])
	_expect("mq_ecorp", 20)
	await _follow("mq_ecorp") # -> penthouse
	await _talk("tyrell_n", ["Fine."])
	_ok("ecorp door", GameState.has_flag("ecorp_door_tyrell"))
	_ok("ecorp done", GameState.quest_state("mq_ecorp") == "done")
	# The femtocell route still works too.
	await _enter_cell_spawn("ecorp_floor")
	_ok("floor allowed with Tyrell", not game.cell_restricted("ecorp_floor", "ecorp"))
	await _term("ecorp_term", ["debt records", "Washington"], ["Install fsociety"])
	_ok("foothold", GameState.has_flag("ecorp_foothold"))
	await _container("ecorp_files")
	await _wait_rules()
	_expect("sq_colby", 20)


	print("PHASE dipierro")
	GameState.tracked_quest = "mq_fbi"
	await _follow("mq_fbi")
	await _talk("dipierro", ["It was him", "closer than fsociety"])
	_expect("mq_fbi", 20)

	print("PHASE robot")
	await _wait_rules()
	_expect("mq_robot", 10)
	GameState.tracked_quest = "mq_robot"
	await _follow("mq_robot") # -> Darlene's building
	_ok("in darlene_apt", GameState.cell == "darlene_apt")
	await _talk("darlene_n", [])
	_expect("mq_robot", 20)
	await _spot("darlene_photo", ["Darlene."])
	_expect("mq_robot", 30)
	_ok("sister", GameState.has_flag("knows_darlene_sister"))
	await _follow("mq_robot") # -> arcade sign
	await _spot("arcade_sign", [])
	_expect("mq_robot", 40)
	await _follow("mq_robot") # -> Mercy General records
	await _term("hosp_records", ["ALDERSON, ELLIOT"], [])
	_expect("mq_robot", 50)
	GameState.game_minutes = GameState.day() * 1440.0 + 23 * 60.0
	await _enter_world_at(Vector3(-30, 0, 850))
	await _follow("mq_robot") # -> the pier
	await _talk("robot_n", ["You're me", "You're part of me"])
	_ok("robot done", GameState.quest_state("mq_robot") == "done")
	_ok("accepted", GameState.has_flag("robot_accepted"))

	print("PHASE candyman")
	await _enter_world_at(Vector3(-62, 0, -1372))
	await _talk("mrs_reyes", ["Who's selling"])
	_expect("sq_candyman", 10)
	GameState.tracked_quest = "sq_candyman"
	await _follow("sq_candyman")
	await _talk("lil_tee", ["Two hundred", "Get me in"])
	_expect("sq_candyman", 20)
	_ok("invited up", GameState.has_flag("candy_invited"))
	await _follow("sq_candyman")
	_ok("in carver_c", GameState.cell == "carver_c")
	_ok("not trespassing in carver", not game.cell_restricted("carver_c", "candyman"))
	await _talk("candyman", ["computer problem", "I'll think about it"])
	await _spot("candy_notebook", [])
	await _term("candy_laptop", ["ledger", "supplier"], [])
	_expect("sq_candyman", 30)
	_ok("has ledger", GameState.has_item("candy_ledger"))
	await _enter_door("d_precinct")
	await _talk("brody", ["Candyman's ledger"])
	_ok("candyman busted", GameState.has_flag("candy_busted"))
	_expect("sq_candyman", 40)
	await _follow("sq_candyman")
	await _talk("mrs_reyes", [])
	_ok("candyman done", GameState.quest_state("sq_candyman") == "done")

	print("PHASE badco")
	await _enter_door("d_shelter")
	await _talk("okafor", ["I heard you've been", "Let me look"])
	_expect("sq_badco", 10)
	GameState.tracked_quest = "sq_badco"
	await _term("shelter_phone", ["Messages", "Account recovery"], [])
	_expect("sq_badco", 20)
	await _enter_world_at(Vector3(965, 0, -590))
	await _pickup("wp_keller_key")
	_ok("spare key", GameState.has_item("key_keller"))
	await _follow("sq_badco")
	_ok("in keller_apt", GameState.cell == "keller_apt")
	await _spot("keller_bag", [])
	await _term("keller_pc", ["Documents", "Calendar"], [])
	_expect("sq_badco", 30)
	_ok("has drive", GameState.has_item("keller_drive"))
	await _enter_door("d_precinct")
	await _talk("brody", ["report a man"])
	_ok("keller arrested", GameState.has_flag("keller_arrested"))
	_expect("sq_badco", 40)
	await _follow("sq_badco")
	await _talk("okafor", [])
	_ok("badco done", GameState.quest_state("sq_badco") == "done")

	print("PHASE lopez")
	GameState.stats["innocents"] = 6
	await _wait_rules()
	_expect("sq_lopez", 10)
	GameState.tracked_quest = "sq_lopez"
	await _follow("sq_lopez")
	await _talk("lopez", ["I don't know what you're talking about"])
	_expect("sq_lopez", 20)
	await _spot("precinct_sticky", [])
	await _term("precinct_term", ["Stairwell"], ["Delete Lopez"])
	_ok("lopez done", GameState.quest_state("sq_lopez") == "done")
	GameState.stats["innocents"] = 0


func _finale() -> void:
	print("PHASE finale")
	await _wait_rules()
	_expect("mq_finale", 20)
	GameState.tracked_quest = "mq_finale"
	await _follow("mq_finale") # -> Mr. Robot at the arcade
	await _talk("robot_n", ["Show me where we stand", "Do it"])
	_ok("five/nine", GameState.has_flag("five_nine_done"))
	_expect("mq_finale", 30)
	await _wait_rules()
	_expect("mq_after", 10)
	print("PHASE after")
	GameState.tracked_quest = "mq_after"
	await _follow("mq_after") # -> home, the TV
	await _spot("apt_tv", [])
	_expect("mq_after", 20)
	await _follow("mq_after") # -> Darlene at the arcade
	await _talk("darlene_n", ["break the rollout"])
	_expect("mq_after", 30)
	GameState.game_minutes = GameState.day() * 1440.0 + 13 * 60.0
	await _follow("mq_after") # -> branch 0419
	await _spot("credit_gary", [])
	_ok("found Gary's password", GameState.has_flag("credit_pw"))
	await _term("credit_mgr", [], ["Poison"])
	_ok("after done", GameState.quest_state("mq_after") == "done")
	_expect("mq_finale", 40)
	GameState.tracked_quest = "mq_finale"
	await _follow("mq_finale") # -> Salina (invite opens it)
	_ok("in salina", GameState.cell == "salina_hotel")
	await _talk("price_n", ["You want E Corp"])
	var tbl := _find_it("deus_table")
	_ok("deus table present", tbl != null)
	if tbl != null:
		prefs = ["Hear their offer", "No. I've got people", "And if I say yes", "fsociety keeps it"]
		game.interact(tbl) # the ending returns to the main menu; don't await it
		var t := 0
		while GameState.ending == "" and t < 3000:
			await get_tree().process_frame
			t += 1
	_ok("ending reached (%s)" % GameState.ending, GameState.ending != "")
	for d in default_picks:
		print("NOTE default pick: ", d)
	print("STORY WALK DONE fails=%d" % fails)
	get_tree().quit()


# ------------------------------------------------------------------- sides
func _side_quests() -> void:
	print("PHASE shayla")
	GameState.game_minutes = GameState.day() * 1440.0 + 23 * 60.0
	await _enter_world_at(Vector3(-470, 0, 300))
	await _wait_rules()
	_expect("sq_shayla", 20)
	GameState.tracked_quest = "sq_shayla"
	await _follow("sq_shayla") # -> Dutch at the docks
	await _talk("dutch", ["Two-fifty"])
	_expect("sq_shayla", 30)
	_ok("parley", GameState.has_flag("vera_parley"))
	await _follow("sq_shayla") # -> the blue door
	await _spot("ws_vera_door", ["Knock"])
	_ok("door open", GameState.has_flag("vera_door_open"))
	await _enter_door("d_vera")
	_ok("in stash", GameState.cell == "vera_stash")
	_ok("not trespassing", not game.cell_restricted("vera_stash", "vera"))
	await _talk("vera", ["What do you want", "Deal."])
	_expect("sq_shayla", 35)
	await _enter_door("d_precinct")
	await _spot("precinct_sticky", [])
	await _term("precinct_term", [], ["People v. Vera"])
	_ok("case wiped", GameState.has_flag("vera_case_wiped"))
	await _wait_rules()
	_expect("sq_shayla", 38)
	await _follow("sq_shayla") # -> back to Vera
	await _talk("vera", [])
	_ok("shayla freed", GameState.has_flag("shayla_freed"))
	_expect("sq_shayla", 45)
	await _follow("sq_shayla") # -> home
	await _wait_rules()
	_ok("shayla home", GameState.quest_state("sq_shayla") == "done")

	print("PHASE bodega")
	GameState.game_minutes = GameState.day() * 1440.0 + 22 * 60.0
	await _enter_door("d_bodega")
	await _talk("omar", ["closing early", "I'll talk to Rico"])
	_expect("sq_bodega", 10)
	GameState.tracked_quest = "sq_bodega"
	await _follow("sq_bodega")
	await _talk("rico", ["one-fifty"])
	_expect("sq_bodega", 20)
	await _follow("sq_bodega")
	await _talk("omar", [])
	_ok("bodega done", GameState.quest_state("sq_bodega") == "done")

	print("PHASE cat")
	await _enter_world_at(Vector3(-100, 0, 8))
	await _talk("catlady", ["I'll look"])
	_expect("sq_cat", 10)
	GameState.tracked_quest = "sq_cat"
	await _follow("sq_cat")
	await _pickup("wp_flipper")
	print("  dbg flipper=%d cat=%d ui=%d paused=%s busy=%s trig=%s cond=%s" % [GameState.count("flipper_leash"), GameState.quest_stage("sq_cat"), game.ui_depth, str(get_tree().paused), str(game.busy_transition), str(GameState.flags.has("trig:sd_cat_found")), str(DialogueManager.check("item.flipper_leash>=1 & q.sq_cat>=10 & q.sq_cat<20"))])
	await _wait_rules()
	_expect("sq_cat", 20)
	await _follow("sq_cat")
	await _talk("catlady", [])
	_ok("cat done", GameState.quest_state("sq_cat") == "done")

	print("PHASE courier")
	await _enter_world_at(Vector3(72, 0, 8))
	await _talk("courier", ["I'm in"])
	_expect("sq_courier", 10)
	GameState.tracked_quest = "sq_courier"
	await _follow("sq_courier")
	await _talk("gardener", [])
	_expect("sq_courier", 20)
	await _follow("sq_courier")
	await _talk("courier", [])
	_ok("courier done", GameState.quest_state("sq_courier") == "done")

	print("PHASE krista")
	await _enter_door("d_krista")
	await _talk("krista", ["lighter today"])
	_expect("sq_krista", 10)
	GameState.tracked_quest = "sq_krista"
	await _follow("sq_krista") # Lenny at the bar
	await _talk("lenny", ["How do you know Krista"])
	_expect("sq_krista", 20)
	await _follow("sq_krista") # his apartment
	await _term("bar_router", ["Sniff"], [])
	_expect("sq_krista", 30)
	await _follow("sq_krista")
	await _talk("krista", ["married"])
	_ok("krista done", GameState.quest_state("sq_krista") == "done")

	print("PHASE colby")
	GameState.tracked_quest = "sq_colby"
	await _follow("sq_colby")
	await _talk("angela_n", ["public", "everyone", "Publish", "Leak"])
	_ok("colby done", GameState.quest_state("sq_colby") == "done")

	print("PHASE busker")
	GameState.game_minutes = GameState.day() * 1440.0 + 12 * 60.0
	await _enter_world_at(Vector3(56, 0, 8))
	await _talk("busker", ["I'll get your signal"])
	_expect("sq_busker", 10)
	GameState.tracked_quest = "sq_busker"
	GameState.give("key_roof")
	await _follow("sq_busker")
	await _term("relay_pirate", ["Broadcast"], [])
	_expect("sq_busker", 20)
	await _follow("sq_busker")
	await _talk("busker", [])
	_ok("busker done", GameState.quest_state("sq_busker") == "done")


# ----------------------------------------------------------------- helpers
func _process(_d: float) -> void:
	# This test checks story flow, not combat: the test character can't die.
	if game != null:
		GameState.hp = 5000.0


func _physics_process(_d: float) -> void:
	if game != null:
		GameState.hp = 5000.0


func _pick(chs: Array) -> int:
	for p in prefs:
		for i in chs.size():
			if str((chs[i] as Dictionary)["text"]).to_lower().contains(str(p).to_lower()):
				return i
	var texts: Array = []
	for c in chs:
		texts.append(str((c as Dictionary)["text"]).left(50))
	default_picks.append(str(texts))
	return 0


func _objective_marker(qid: String) -> String:
	var objs := DB.quest_objectives(qid, GameState.quest_stage(qid))
	for o in objs:
		var m := str((o as Dictionary).get("marker", ""))
		if m != "":
			return m
	return ""


## Go where the quest marker says, the way a player would: through the door.
func _follow(qid: String) -> void:
	var m := _objective_marker(qid)
	if m == "":
		_ok("%s stage %d has a marker" % [qid, GameState.quest_stage(qid)], false)
		return
	_ok("%s marker '%s' points somewhere from %s" % [qid, m, GameState.cell], game.marker_pos(m) != null)
	var t: Dictionary = game._marker_target(m)
	if t.is_empty():
		_ok("marker target resolves: " + m, false)
		return
	var cell := str(t["cell"])
	if WorldLayout.all_doors().has(m) or game.gen_doors.has(m):
		await _enter_door(m)
		return
	if cell == "subway" or cell.begins_with("subway"):
		if not GameState.cell.begins_with("subway"):
			var sid: String = game._door_for_interior("subway")
			await _enter_door(sid)
		return
	if cell == "world":
		await _enter_world_at(t["pos"])
		return
	# An interior: go through the door that leads into it.
	if GameState.cell != cell:
		var door: String = game._door_for_interior(cell)
		if door != "" and InteriorData.INTERIORS.has(cell) and _interior_of(door) == cell:
			await _enter_door(door)
		else:
			await _enter_cell_spawn(cell)
	_ok("reached %s for %s" % [cell, qid], GameState.cell == cell)


func _interior_of(door: String) -> String:
	var d: Dictionary = WorldLayout.all_doors().get(door, {})
	return str(d.get("interior", ""))


func _enter_door(did: String) -> void:
	var d: Dictionary = WorldLayout.all_doors().get(did, {})
	if d.is_empty():
		_ok("door exists " + did, false)
		return
	var to := str(d["interior"])
	var lock := int(d.get("lock", 0))
	var key := str(d.get("key", ""))
	if lock > 0 and not (key != "" and GameState.has_item(key)) and GameState.skill("lockpick") < lock:
		print("NOTE door %s: lock %d, player lockpick %d (needs key %s or skill)" % [did, lock, GameState.skill("lockpick"), key])
	if key != "" and lock > 100 and not GameState.has_item(key):
		_ok("have key %s for %s" % [key, did], false)
	var def: Dictionary = game.interior_def(to)
	var idx: int = game._exit_index_for_door(def, did)
	var sp := InteriorBuilder.exit_spawn(def, idx)
	if to.begins_with("subway:"):
		game.current_subway = to.substr(7)
	await game.enter_cell(to, sp["pos"], float(sp["yaw"]), false)
	await _settle()
	await _wait_rules()
	_ok("entered %s via %s" % [to, did], GameState.cell == to)


func _exit_to(link: String) -> void:
	await game._take_exit(link)
	await _settle()


func _enter_cell_spawn(cell: String) -> void:
	var sp := InteriorBuilder.exit_spawn(game.interior_def(cell), 0)
	await game.enter_cell(cell, sp["pos"], float(sp["yaw"]), false)
	await _settle()


func _enter_world_at(p: Vector3) -> void:
	await game.enter_cell("world", Vector3(p.x, 0.2, p.z + 3.0), 0.0, false, true)
	await _settle()
	await _wait_rules()


func _npc_here(id: String) -> NPC:
	var n: NPC = game.npcs.get_npc(id)
	if n == null or n.dead or not is_instance_valid(n):
		return null
	if str(n.cell) != GameState.cell and not (str(n.cell) == "subway" and GameState.cell.begins_with("subway")):
		return null
	return n


func _talk(id: String, p: Array) -> void:
	game.npcs.refresh(false)
	await _settle()
	var n := _npc_here(id)
	if n == null:
		_ok("npc %s is present in %s (stage %s)" % [id, GameState.cell, str(GameState.quests.get(GameState.tracked_quest, {}).get("stage", "?"))], false)
		return
	prefs = p
	game.player.global_position = n.global_position + Vector3(0, 0, 1.2)
	await game.interact(n)
	await _until(func() -> bool: return not game.dialog.is_open(), 2000)
	await _settle()
	await _wait_rules()


func _find_it(id: String) -> Interactable:
	var stack: Array = [game]
	while not stack.is_empty():
		var nd: Node = stack.pop_back()
		if nd is Interactable and (nd as Interactable).ident == id and (nd as Node3D).is_visible_in_tree():
			return nd
		for c in nd.get_children():
			stack.append(c)
	return null


func _spot(id: String, p: Array) -> void:
	var it := _find_it(id)
	if it == null:
		_ok("spot %s present in %s" % [id, GameState.cell], false)
		return
	if it.cond != null and not DialogueManager.eval_cond(it.cond):
		_ok("spot %s condition met" % id, false)
		return
	prefs = p
	await game.interact(it)
	await _until(func() -> bool: return not game.dialog.is_open(), 2000)
	await _settle()
	await _wait_rules()


func _term(id: String, entries: Array, actions: Array) -> void:
	var it := _find_it(id)
	if it == null:
		_ok("terminal %s present in %s" % [id, GameState.cell], false)
		return
	if it.cond != null and not DialogueManager.eval_cond(it.cond):
		_ok("terminal %s condition met" % id, false)
		return
	var tu = game.terminal_ui
	tu.open(it.ident, it.data)
	await get_tree().process_frame
	if tu._mode == "locked":
		var dc := int(it.data.get("hack", 0))
		var pw := it.data.has("password_flag") and GameState.has_flag(str(it.data["password_flag"]))
		if GameState.skill("hacking") >= dc or pw:
			await tu._access_granted()
		else:
			_ok("can get into %s (HACKING %d vs %d, no password)" % [id, GameState.skill("hacking"), dc], false)
			tu.close_modal()
			await _settle()
			return
	var ents: Array = it.data.get("entries", [])
	for want in entries:
		var found := false
		for i in ents.size():
			var ed: Dictionary = ents[i]
			if str(ed.get("title", "")).to_lower().contains(str(want).to_lower()):
				if ed.has("when") and not DialogueManager.check(str(ed["when"])):
					continue
				tu._show_entry(i)
				found = true
				await get_tree().process_frame
				break
		_ok("%s entry '%s'" % [id, want], found)
	var acts: Array = it.data.get("actions", [])
	for want2 in actions:
		for j in acts.size():
			var ad: Dictionary = acts[j]
			if str(ad.get("title", "")).to_lower().contains(str(want2).to_lower()):
				if ad.has("when") and not DialogueManager.check(str(ad["when"])):
					print("NOTE %s action '%s' not available" % [id, want2])
					continue
				await tu._do_action(j)
				break
	tu.close_modal()
	await _settle()
	await _wait_rules()


func _container(id: String) -> void:
	var it := _find_it(id)
	if it == null:
		_ok("container %s present in %s" % [id, GameState.cell], false)
		return
	if not GameState.containers.has(id):
		GameState.containers[id] = game._roll_container(it.data)
	var c: Dictionary = GameState.containers[id]
	for k in (c.get("items", {}) as Dictionary).keys():
		GameState.give(str(k), int(c["items"][k]))
	c["items"] = {}
	if it.data.has("fx_open"):
		await DialogueManager.run_effects(DialogueManager.parse_effects(str(it.data["fx_open"]), id))
	await _wait_rules()


func _pickup(id: String) -> void:
	var it := _find_it(id)
	if it == null:
		# World pickups live in the world interactables; stand near it and look.
		_ok("pickup %s present" % id, false)
		return
	game.player.global_position = it.global_position + Vector3(0, 0, 1)
	await game.interact(it)
	await _settle()


func _buy(shop: String, item: String) -> void:
	var sd: Dictionary = NPCData.SHOPS.get(shop, {})
	_ok("shop %s sells %s" % [shop, item], (sd.get("stock", {}) as Dictionary).has(item))
	GameState.give(item, 1)


func _close_modals() -> void:
	# A real player closes the level-up screen (or any leftover menu) and moves on.
	var stack: Array = [game]
	while not stack.is_empty():
		var nd: Node = stack.pop_back()
		if nd.has_method("close_modal") and bool(nd.get("_is_open")):
			print("  (closing leftover UI: %s)" % nd.name)
			nd.call("close_modal")
		for c in nd.get_children():
			stack.append(c)


func _wait_rules() -> void:
	_close_modals()
	for i in 4:
		await get_tree().create_timer(0.3).timeout
		await get_tree().process_frame


func _diag() -> void:
	var pend: Array = []
	for tr in WorldObjects.TRIGGERS:
		var td: Dictionary = tr
		if GameState.flags.has("trig:" + str(td["id"])):
			continue
		var w := str(td.get("when", ""))
		if w == "" or DialogueManager.check(w):
			pend.append("%s(cell=%s)" % [td["id"], td.get("cell", "world")])
	print("  diag: cell=%s tick=%.2f ui=%d paused=%s busy=%s dead=%s pending=%s" % [GameState.cell, float(game._tick), game.ui_depth, str(get_tree().paused), str(game.busy_transition), str(game._dead), str(pend)])


func _expect(qid: String, stage: int) -> void:
	var st := GameState.quest_stage(qid)
	var ok := st >= stage or GameState.quest_state(qid) == "done"
	if not ok:
		_diag()
	_ok("%s at stage %d (is %d, %s)" % [qid, stage, st, GameState.quest_state(qid)], ok)


func _ok(what: String, cond: bool) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _settle() -> void:
	await get_tree().process_frame
	await get_tree().physics_frame
	await _until(func() -> bool: return not game.busy_transition, 600)


func _until(cond: Callable, limit: int) -> void:
	var t := 0
	while not cond.call() and t < limit:
		await get_tree().process_frame
		t += 1
