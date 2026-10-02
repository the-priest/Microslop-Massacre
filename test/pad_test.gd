extends Node
## Plays with a (simulated) gamepad only: walk, look, open the phone and switch
## tabs, talk and pick a dialogue choice, use a terminal, steal and drive a car.

var game
var fails := 0


func _ready() -> void:
	Pad.fake = true
	var scene: PackedScene = load("res://game/Game.tscn")
	game = scene.instantiate()
	game.test_mode = true
	game.test_picker = Callable()
	add_child(game)
	await _until(func() -> bool: return game.player != null and not game.busy_transition and GameState.cell == "krista_office" and not game.dialog.is_open() and GameState.quests.has("mq_hello"), 6000)
	game.dialog.auto_advance = false
	await _frames(10)
	# --- walk and look -------------------------------------------------
	await game.enter_cell("world", Vector3(-466, 0.2, 318), PI * 0.5, false, true)
	await _frames(20)
	var p0: Vector3 = game.player.global_position
	_axis(JOY_AXIS_LEFT_Y, -1.0)
	await _secs(0.8)
	_axis(JOY_AXIS_LEFT_Y, 0.0)
	_ok("left stick walks (%.1f m)" % game.player.global_position.distance_to(p0), game.player.global_position.distance_to(p0) > 1.0)
	_ok("pad detected", Pad.using_pad)
	var y0: float = game.player.yaw
	_axis(JOY_AXIS_RIGHT_X, 1.0)
	await _secs(0.4)
	_axis(JOY_AXIS_RIGHT_X, 0.0)
	_ok("right stick looks (%.2f rad)" % absf(game.player.yaw - y0), absf(game.player.yaw - y0) > 0.2)
	# --- phone -----------------------------------------------------------
	await _press(JOY_BUTTON_B)
	_ok("B opens the phone", game.phone.is_open())
	await _press(JOY_BUTTON_RIGHT_SHOULDER)
	await _press(JOY_BUTTON_B)
	_ok("B closes the phone", not game.phone.is_open())
	# --- phone sections (triggers) and map ---------------------------------
	await _press(JOY_BUTTON_B)
	var sub0: String = game.phone.sub
	_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _frames(4)
	_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	await _frames(4)
	_ok("RT flips phone sections (%s -> %s)" % [sub0, game.phone.sub], game.phone.sub != sub0)
	await _press(JOY_BUTTON_B)
	for d in ["d_apt", "d_allsafe", "d_ron"]:
		GameState.discovered[d] = true
	await _press(JOY_BUTTON_BACK)
	_ok("BACK opens the map", game.phone.is_open() and game.phone.sub == "map")
	await _press(JOY_BUTTON_DPAD_RIGHT)
	await _frames(3)
	_ok("D-pad picks a place on the map (%s)" % game.phone._map_hover, game.phone._map_hover != "")
	await _press(JOY_BUTTON_B)
	_ok("B closes the map", not game.phone.is_open())
	# --- pause menu ---------------------------------------------------------
	await _press(JOY_BUTTON_START)
	_ok("START pauses", game.pause_menu.is_open())
	await _frames(20)
	var fo: Control = game.get_viewport().gui_get_focus_owner()
	_ok("pause menu has focus (%s)" % (fo.get("text") if fo != null else "none"), fo != null and game.pause_menu.is_ancestor_of(fo))
	for i in 3:
		await _press(JOY_BUTTON_DPAD_DOWN)
	fo = game.get_viewport().gui_get_focus_owner()
	_ok("D-pad walks the pause menu (%s)" % (fo.get("text") if fo != null else "none"), fo != null and str(fo.get("text")) == "Settings")
	await _press(JOY_BUTTON_A)
	await _frames(5)
	_ok("A opens Settings", game.pause_menu._page == "settings")
	await _press(JOY_BUTTON_B)
	_ok("B backs out of Settings", game.pause_menu._page == "main" and game.pause_menu.is_open())
	await _press(JOY_BUTTON_B)
	_ok("B resumes", not game.pause_menu.is_open())
	# --- minigame: B walks away, A can't hit ABORT ------------------------------
	var res := [null]
	var runner := func() -> void: res[0] = await game.minigames.run("lockpick", {"dc": 20})
	runner.call()
	await _frames(20)
	_ok("lockpick running", game.minigames.is_running())
	await _press(JOY_BUTTON_A)
	await _frames(10)
	_ok("A doesn't abort the minigame", game.minigames.is_running())
	await _press(JOY_BUTTON_B)
	await _secs(1.3)
	_ok("B walks away from the minigame", not game.minigames.is_running() and res[0] == false)
	# --- level up: spend points with the pad -----------------------------------
	GameState.pending_levels = 1
	var lv_runner := func() -> void: await game.levelup_ui.open()
	lv_runner.call()
	await _frames(20)
	_ok("level-up open", game.levelup_ui.is_open())
	var pts0: int = game.levelup_ui._points
	fo = game.get_viewport().gui_get_focus_owner()
	print("    level-up focus before A: ", fo, " ", fo.get("text") if fo != null else "", " ctx=", Pad.context(), " scr=", Pad._screen())
	await _press(JOY_BUTTON_A) # focus starts on a button; A presses it
	await _frames(5)
	fo = game.get_viewport().gui_get_focus_owner()
	_ok("level-up keeps focus after a rebuild", fo != null and game.levelup_ui.is_ancestor_of(fo))
	_ok("A spends or refunds a point (%d -> %d)" % [pts0, game.levelup_ui._points], game.levelup_ui._points != pts0 or str(fo.get("text")).strip_edges() == "-")
	await _press(JOY_BUTTON_B)
	_ok("B closes level-up", not game.levelup_ui.is_open())
	GameState.pending_levels = 0
	# --- talk: walk up to Krista's office and use A ------------------------
	await game.enter_cell("krista_office", Vector3(4.0, 0, 4.5), PI, false)
	await _frames(20)
	var k = game.npcs.get_npc("krista")
	_ok("krista present", k != null)
	if k != null:
		game.player.look_toward(k.global_position + Vector3(0, 1.5, 0))
		game.player.global_position = k.global_position + (game.player.global_position - k.global_position).normalized() * 1.4
		await _frames(10)
		game.player.look_toward(k.global_position + Vector3(0, 1.5, 0))
		await _frames(5)
		_ok("krista targeted", game.player.interact_target == k)
		await _press(JOY_BUTTON_A)
		await _frames(10)
		_ok("A starts the conversation", game.dialog.is_open())
		for i in 12:
			if game.dialog._waiting_choice:
				break
			await _press(JOY_BUTTON_A)
			await _frames(4)
		_ok("reached a choice", game.dialog._waiting_choice)
		var sel0: int = game.dialog._sel
		await _press(JOY_BUTTON_DPAD_DOWN)
		_ok("D-pad moves the selection", game.dialog._sel != sel0)
		await _press(JOY_BUTTON_A)
		for i in 20:
			if not game.dialog.is_open():
				break
			await _press(JOY_BUTTON_A)
			await _frames(4)
		_ok("conversation finished with A", not game.dialog.is_open())
	# --- terminal ----------------------------------------------------------
	await game.enter_cell("elliot_apt", Vector3(3.5, 0, 2.5), 0.0, false)
	await _frames(20)
	var pc: Interactable = null
	for n in game.get_tree().get_nodes_in_group("interactable"):
		if n is Interactable and (n as Interactable).ident == "apt_pc":
			pc = n
	if pc == null:
		var stack: Array = [game]
		while not stack.is_empty():
			var nd: Node = stack.pop_back()
			if nd is Interactable and (nd as Interactable).ident == "apt_pc" and (nd as Node3D).is_visible_in_tree():
				pc = nd
			for c in nd.get_children():
				stack.append(c)
	_ok("pc present", pc != null)
	if pc != null:
		game.interact(pc)
		await _frames(10)
		_ok("terminal open", game.terminal_ui.is_open())
		await _press(JOY_BUTTON_DPAD_DOWN)
		await _press(JOY_BUTTON_A)
		await _frames(5)
		_ok("A opens the highlighted entry", game.terminal_ui._mode == "entry")
		await _press(JOY_BUTTON_B)
		await _press(JOY_BUTTON_B)
		await _frames(5)
		_ok("B backs out and closes", not game.terminal_ui.is_open())
	# --- steal and drive ------------------------------------------------------
	await game.enter_cell("world", Vector3(-466, 0.2, 318), 0.0, false, true)
	await _frames(20)
	for i in 12:
		game._update_parked()
	if game.parked_cars.is_empty():
		_ok("parked car to steal", false)
	else:
		var car: Vehicle = game.parked_cars[0]
		car.locked = false
		car.global_position = Vector3(WorldLayout.ax(2) + 2.2, 0.3, 250.0)
		car.rotation.y = 0.0
		await _frames(5)
		game.player.global_position = car.global_position + Vector3(2.4, 0, 0)
		await _frames(3)
		game.player.look_toward(car.global_position + Vector3(0, 0.9, 0))
		await _frames(5)
		_ok("car targeted", game.player.interact_target == car)
		await _press(JOY_BUTTON_A)
		await _frames(5)
		_ok("A gets in", game.player.driving == car)
		_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
		await _secs(1.5)
		_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
		_ok("RT is the gas (%.1f m/s)" % car.speed, car.speed > 4.0)
		_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)
		await _secs(1.5)
		_axis(JOY_AXIS_TRIGGER_LEFT, 0.0)
		_ok("LT brakes (%.1f m/s)" % car.speed, car.speed < 4.0)
		car.speed = 0.0
		await _press(JOY_BUTTON_A)
		await _frames(5)
		_ok("A gets out", game.player.driving == null)
	print("PAD TEST DONE fails=%d" % fails)
	get_tree().quit()


func _axis(axis: int, v: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.device = 0
	e.axis = axis
	e.axis_value = v
	Input.parse_input_event(e)


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


func _secs(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _until(c: Callable, limit: int) -> void:
	var t := 0
	while not c.call() and t < limit:
		await get_tree().process_frame
		t += 1
