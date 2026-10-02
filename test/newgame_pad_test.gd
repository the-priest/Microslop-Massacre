extends Node
## The real start of the game, pad only: title screen -> NEW GAME -> skip the
## intro -> Krista's session -> intake form -> playing. Also CONTINUE.

var fails := 0


func _ready() -> void:
	Pad.fake = true
	# Survive the scene changes: live under the root, not as the current scene.
	_go.call_deferred()


func _go() -> void:
	var tree := get_tree()
	var root := tree.root
	get_parent().remove_child(self)
	root.add_child(self)
	tree.current_scene = null
	tree.change_scene_to_file("res://ui/MainMenu.tscn")
	await _frames(40)
	_ok("title screen up", _menu() != null)
	# Walk to NEW GAME and press A.
	if not await _focus_text("> NEW GAME"):
		_ok("reached NEW GAME", false)
		_done()
		return
	await _press(JOY_BUTTON_A)
	await _until(func() -> bool: return _game() != null, 600)
	_ok("A on NEW GAME starts the game", _game() != null)
	var g = _game()
	if g == null:
		_done()
		return
	# The intro: START skips it.
	await _until(func() -> bool: return g.get("cinematic") == true or g.dialog != null and g.dialog.is_open(), 6000)
	if g.cinematic:
		await _frames(30)
		await _press(JOY_BUTTON_START)
	await _until(func() -> bool: return g.dialog != null and g.dialog.is_open(), 6000)
	_ok("intro skipped, Krista's session started", g.dialog.is_open() and GameState.cell == "krista_office")
	# Talk through the session with A until the intake form opens.
	for i in 200:
		if g.intake_ui.is_open():
			break
		await _press(JOY_BUTTON_A)
		await _frames(6)
	_ok("intake form open", g.intake_ui.is_open())
	await _frames(10)
	var fo: Control = get_viewport().gui_get_focus_owner()
	_ok("intake has pad focus (%s)" % (fo.get("text") if fo != null else "none"), fo != null and g.intake_ui.is_ancestor_of(fo))
	await _press(JOY_BUTTON_A) # untag the first skill
	await _frames(4)
	_ok("A toggles a skill tag (%d tagged)" % g.intake_ui._tags.size(), g.intake_ui._tags.size() == 2)
	await _press(JOY_BUTTON_A) # and tag it back
	await _frames(4)
	_ok("A tags it again", g.intake_ui._tags.size() == 3)
	for i in 30:
		fo = get_viewport().gui_get_focus_owner()
		if fo == g.intake_ui._confirm:
			break
		await _press(JOY_BUTTON_DPAD_DOWN)
	_ok("D-pad reaches SIGN THE FORM", get_viewport().gui_get_focus_owner() == g.intake_ui._confirm)
	await _press(JOY_BUTTON_A)
	await _frames(10)
	_ok("A signs the form", not g.intake_ui.is_open())
	for i in 200:
		if not g.dialog.is_open() and GameState.quest_stage("mq_hello") >= 10:
			break
		await _press(JOY_BUTTON_A)
		await _frames(6)
	_ok("playing: Hello, Friend started", GameState.quest_stage("mq_hello") >= 10 and not g.ui_open())
	# Save, quit to the title with the pad, and CONTINUE.
	g.sync_state_for_save()
	SaveManager.save("slot1", "test")
	await _press(JOY_BUTTON_START)
	_ok("START pauses", g.pause_menu.is_open())
	if not await _focus_text("Quit to Main Menu"):
		_ok("reached Quit to Main Menu", false)
	await _press(JOY_BUTTON_A)
	await _until(func() -> bool: return _menu() != null and _game() == null, 600)
	await _frames(30)
	_ok("back on the title screen", _menu() != null)
	if await _focus_text("> CONTINUE"):
		await _press(JOY_BUTTON_A)
		await _until(func() -> bool: return _game() != null and not _game().busy_transition and _game().player != null, 6000)
		await _frames(30)
		_ok("A on CONTINUE loads the game", _game() != null and GameState.quest_stage("mq_hello") >= 10)
	else:
		_ok("reached CONTINUE", false)
	_done()


func _menu() -> Node:
	var cs := get_tree().current_scene
	return cs if cs != null and cs.get_script() != null and str(cs.get_script().resource_path).ends_with("main_menu.gd") else null


func _game() -> Node:
	var cs := get_tree().current_scene
	return cs if cs != null and cs.get_script() != null and str(cs.get_script().resource_path).ends_with("game.gd") else null


## D-pad down until the focused button reads `t` (wraps around once).
func _focus_text(t: String) -> bool:
	for i in 24:
		var fo: Control = get_viewport().gui_get_focus_owner()
		if fo != null and str(fo.get("text")) == t:
			return true
		await _press(JOY_BUTTON_DPAD_DOWN)
	return false


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


func _done() -> void:
	print("NEWGAME PAD TEST DONE fails=%d" % fails)
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
