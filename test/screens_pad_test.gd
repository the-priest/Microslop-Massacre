extends Node
## The rest of the pop-ups, pad only: loot, barter, wait, subway map, death
## screen, ending slides.

var game
var fails := 0


func _ready() -> void:
	Pad.fake = true
	var scene: PackedScene = load("res://game/Game.tscn")
	game = scene.instantiate()
	game.test_mode = true
	game.test_picker = func(c): return 0
	add_child(game)
	await _until(func() -> bool: return game.player != null and not game.busy_transition and GameState.cell == "krista_office" and not game.dialog.is_open() and GameState.quests.has("mq_hello"), 6000)
	await _frames(10)
	# Loot: A takes one, X takes all, B closes.
	var data := {"items": {"soda": 2, "bandages": 1, "cigarettes": 1}, "cash": 0}
	var s0: int = GameState.count("soda") + GameState.count("bandages") + GameState.count("cigarettes")
	(func() -> void: await game.loot_ui.open_container("Test Box", data, false)).call()
	await _frames(15)
	_ok("loot open with focus", game.loot_ui.is_open() and _focus_in(game.loot_ui))
	print("    loot focus: ", get_viewport().gui_get_focus_owner(), " pad=", Pad.using_pad, " ctx=", Pad.context(), " scr=", Pad._screen(), " depth=", game.ui_depth)
	await _press(JOY_BUTTON_A)
	print("    after A focus: ", get_viewport().gui_get_focus_owner(), " items=", data["items"])
	await _frames(5)
	var s1: int = GameState.count("soda") + GameState.count("bandages") + GameState.count("cigarettes")
	_ok("A takes an item (%d -> %d)" % [s0, s1], s1 > s0)
	await _press(JOY_BUTTON_X)
	await _frames(5)
	_ok("X takes all / closes", (data["items"] as Dictionary).is_empty() or not game.loot_ui.is_open())
	if game.loot_ui.is_open():
		await _press(JOY_BUTTON_B)
	_ok("loot closed, nothing stuck", not game.loot_ui.is_open() and game.ui_depth == 0)
	# Barter: A buys, B closes.
	GameState.cash = 5000
	var c0: int = GameState.cash
	(func() -> void: await game.barter_ui.open("pawn", "Pawn Shop", "test_pawn")).call()
	await _frames(15)
	_ok("barter open with focus", game.barter_ui.is_open() and _focus_in(game.barter_ui))
	await _press(JOY_BUTTON_A)
	await _frames(5)
	_ok("A buys something ($%d -> $%d)" % [c0, GameState.cash], GameState.cash < c0)
	await _press(JOY_BUTTON_B)
	await _frames(5)
	_ok("B leaves the shop", not game.barter_ui.is_open() and game.ui_depth == 0)
	# Wait: stick right adds hours, A waits, screen closes.
	var t0: float = GameState.game_minutes
	(func() -> void: await game.wait_ui.open()).call()
	await _frames(15)
	_ok("wait open with focus", game.wait_ui.is_open() and _focus_in(game.wait_ui))
	await _press(JOY_BUTTON_A)
	for i in 300:
		if not game.wait_ui.is_open():
			break
		await _frames(2)
	_ok("A waits (%.0f min passed)" % (GameState.game_minutes - t0), GameState.game_minutes > t0 and not game.wait_ui.is_open())
	await _frames(10)
	# Subway map (in a station).
	game.current_subway = "sub_les"
	await game.enter_cell("subway:sub_les", Vector3(6, 0, 3), 0.0, false)
	await _frames(15)
	(func() -> void: await game.travel_ui.open_subway()).call()
	await _frames(15)
	_ok("subway map open with focus", game.travel_ui.is_open() and _focus_in(game.travel_ui))
	await _press(JOY_BUTTON_DPAD_DOWN)
	await _press(JOY_BUTTON_B)
	await _frames(5)
	_ok("B closes the subway map", not game.travel_ui.is_open() and game.ui_depth == 0)
	# Death: the screen takes the pad.
	GameState.hp = 0.0
	GameState.emit_signal("died")
	await _until(func() -> bool: return game.death_ui.is_open(), 600)
	await _frames(15)
	_ok("death screen has pad focus (%s)" % str(get_viewport().gui_get_focus_owner().get("text") if get_viewport().gui_get_focus_owner() != null else "none"), game.death_ui.is_open() and _focus_in(game.death_ui))
	print("SCREENS PAD TEST DONE fails=%d" % fails)
	get_tree().quit()


func _focus_in(n: Node) -> bool:
	var fo: Control = get_viewport().gui_get_focus_owner()
	return fo != null and n.is_ancestor_of(fo) and fo.is_visible_in_tree()


func _press(b: int) -> void:
	var e := InputEventJoypadButton.new()
	e.device = 0
	e.button_index = b
	e.pressed = true
	Input.parse_input_event(e)
	await _frames(3)
	var r := InputEventJoypadButton.new()
	r.device = 0
	r.button_index = b
	r.pressed = false
	Input.parse_input_event(r)
	await _frames(4)


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
