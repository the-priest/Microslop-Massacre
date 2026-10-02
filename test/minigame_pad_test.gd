extends Node
## Every minigame, pad only: something to press, A does something, B gets out.

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
	for mg in ["lockpick", "exploit", "recon", "bruteforce", "signal", "cascade", "invaders", "loghunt"]:
		var res := [null]
		var runner := func() -> void: res[0] = await game.minigames.run(mg, {"dc": 20, "arg": "ron"})
		runner.call()
		await _frames(30)
		_ok("%s running" % mg, game.minigames.is_running())
		var fo: Control = get_viewport().gui_get_focus_owner()
		var focus_ok: bool = mg in ["lockpick", "signal"] or (fo != null and game.minigames.is_ancestor_of(fo))
		_ok("%s: pad focus inside the minigame (%s)" % [mg, fo.get("text") if fo != null else "none"], focus_ok)
		await _press(JOY_BUTTON_DPAD_DOWN)
		await _press(JOY_BUTTON_A)
		await _frames(10)
		_ok("%s: A didn't kill it" % mg, game.minigames.is_running() or res[0] != null)
		if game.minigames.is_running():
			await _press(JOY_BUTTON_B)
			for i in 120:
				if not game.minigames.is_running():
					break
				await _frames(2)
		_ok("%s: B walks away (result %s)" % [mg, str(res[0])], not game.minigames.is_running())
		_ok("%s: pause stack balanced (depth %d)" % [mg, game.ui_depth], game.ui_depth == 0)
		await _frames(10)
	print("MINIGAME PAD TEST DONE fails=%d" % fails)
	get_tree().quit()


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
