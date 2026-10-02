extends Node
## Companions: recruit through real dialogue, follow, ride along in a car,
## skill bonus, heart-to-heart unlocks + perk, a reaction, leaving, dismissing.

var game
var fails := 0
var prefs: Array = []


func _ready() -> void:
	var scene: PackedScene = load("res://game/Game.tscn")
	game = scene.instantiate()
	game.test_mode = true
	game.test_picker = _pick
	add_child(game)
	await _until(func() -> bool: return game.player != null and not game.busy_transition and GameState.cell == "krista_office" and not game.dialog.is_open() and GameState.quests.has("mq_hello"), 6000)
	game.dialog.auto_advance = true
	GameState.hp = 5000.0
	# Leon lives on Coney Island.
	GameState.flags["met_leon"] = true
	await game.enter_cell("world", Vector3(-6, 0.2, 650), 0.0, false, true)
	await _frames(30)
	game.npcs.refresh(true)
	await _frames(5)
	var leon = game.npcs.get_npc("leon")
	_ok("Leon is on Coney", leon != null)
	if leon == null:
		_done()
		return
	var hack0: int = GameState.skill("guns")
	prefs = ["Come with me, Leon"]
	game.interact(leon)
	await _until(func() -> bool: return not game.dialog.is_open(), 1200)
	await _frames(5)
	_ok("Leon joined", GameState.companions.has("leon"))
	_ok("companion bonus (+%d GUNS)" % (GameState.skill("guns") - hack0), GameState.skill("guns") == hack0 + 10)
	# Following.
	game.player.global_position = Vector3(-6, 0.2, 620)
	for i in 480:
		await get_tree().physics_frame
	_ok("Leon follows (%.1f m)" % leon.global_position.distance_to(game.player.global_position), leon.global_position.distance_to(game.player.global_position) < 8.0)
	# Ride along.
	var v := Vehicle.new().setup("sedan", 1, Vector3(-6, 0.1, 612), 0.0, game)
	v.locked = false
	game.vehicles_root.add_child(v)
	await _frames(3)
	game.enter_vehicle(v)
	for i in 30:
		await get_tree().physics_frame
	_ok("Leon rides along (hidden, no collision)", not leon.visible and leon.collision_layer == 0)
	v.speed = 0.0
	game.exit_vehicle(true)
	for i in 30:
		await get_tree().physics_frame
	_ok("Leon gets out with you", leon.visible and leon.collision_layer == Phys.NPC)
	# Heart-to-hearts unlock with time together.
	GameState.flags["aff_leon"] = 1000
	prefs = ["What's your deal with TV", "Let's go"]
	game.interact(leon)
	await _until(func() -> bool: return not game.dialog.is_open(), 1200)
	_ok("first talk done", GameState.flags.has("ltalk1"))
	GameState.flags["aff_leon"] = 2000
	prefs = ["Who do you really work for", "Thanks for telling me", "Let's go"]
	game.interact(leon)
	await _until(func() -> bool: return not game.dialog.is_open(), 1200)
	prefs = ["If they told you to kill me", "Let's go"]
	game.interact(leon)
	await _until(func() -> bool: return not game.dialog.is_open(), 1200)
	_ok("all three talks done + perk", GameState.flags.has("ltalk3") and GameState.flags.has("cperk_leon"))
	# A reaction.
	GameState.flags["ecorp_jet_gone"] = true
	game._companion_tick()
	_ok("reaction fired once", GameState.flags.has("react_leon_ecorp_jet_gone"))
	# Dismiss: walks home and stops being a companion.
	prefs = ["Go back to Coney"]
	game.interact(leon)
	await _until(func() -> bool: return not game.dialog.is_open(), 1200)
	await _frames(5)
	_ok("dismissed", not GameState.companions.has("leon") and leon.aggro != "companion")
	_ok("perk stays after dismissal", GameState.skill("guns") == hack0 + 5)
	# Leaving on a bad choice: Trenton won't stay for murder.
	GameState.companions.append("trenton_n")
	GameState.stats["innocents"] = 3
	game._companion_tick()
	_ok("Trenton walks out", not GameState.companions.has("trenton_n") and GameState.flags.has("left_trenton_n"))
	_done()


func _pick(chs: Array) -> int:
	for p in prefs:
		for i in chs.size():
			if str((chs[i] as Dictionary)["text"]).to_lower().contains(str(p).to_lower()):
				return i
	return chs.size() - 1


func _done() -> void:
	print("COMPANION TEST DONE fails=%d" % fails)
	get_tree().quit()


func _ok(what: String, cond: bool) -> void:
	print(("  ok   " if cond else "  FAIL ") + what)
	if not cond:
		fails += 1


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _until(c: Callable, limit: int) -> void:
	var t := 0
	while not c.call() and t < limit:
		await get_tree().process_frame
		t += 1
