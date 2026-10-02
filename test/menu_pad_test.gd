extends Node
## The title screen with nothing but a (simulated) gamepad.

var fails := 0


func _ready() -> void:
	Pad.fake = true
	var menu: Control = load("res://ui/MainMenu.tscn").instantiate()
	add_child(menu)
	await _frames(30)
	var fo: Control = get_viewport().gui_get_focus_owner()
	_ok("title screen has focus (%s)" % (fo.get("text") if fo != null else "none"), fo != null)
	# Walk down to SETTINGS. CONTINUE / LOAD may be disabled without saves.
	var guard := 0
	while guard < 10:
		guard += 1
		fo = get_viewport().gui_get_focus_owner()
		if fo != null and str(fo.get("text")) == "> SETTINGS":
			break
		await _press(JOY_BUTTON_DPAD_DOWN)
	_ok("D-pad reaches SETTINGS", fo != null and str(fo.get("text")) == "> SETTINGS")
	await _press(JOY_BUTTON_A)
	await _frames(5)
	_ok("A opens settings", menu._page == "settings")
	# Every kind of settings control works from the pad.
	var cb: CheckBox = null
	var ob: OptionButton = null
	var stack: Array = [menu]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is CheckBox and cb == null:
			cb = n
		if n is OptionButton and ob == null:
			ob = n
		stack.append_array(n.get_children())
	_ok("settings has a checkbox and a dropdown", cb != null and ob != null)
	if cb != null:
		var was := cb.button_pressed
		var seq: Array = []
		for i in 40:
			var f0: Control = get_viewport().gui_get_focus_owner()
			seq.append(str(f0.get_class()) + ":" + str(f0.get("text")) if f0 != null else "null")
			if f0 == cb:
				break
			await _press(JOY_BUTTON_DPAD_DOWN)
		print("    focus walk: ", seq)
		await _press(JOY_BUTTON_A)
		_ok("A flips a checkbox", cb.button_pressed != was)
		await _press(JOY_BUTTON_A)
		_ok("A flips it back", cb.button_pressed == was)
	if ob != null:
		var sel := ob.selected
		for i in 60:
			if get_viewport().gui_get_focus_owner() == ob:
				break
			await _press(JOY_BUTTON_DPAD_UP)
		await _press(JOY_BUTTON_A)
		await _frames(3)
		_ok("A flips a dropdown to the next option (%d -> %d)" % [sel, ob.selected], ob.selected != sel and not ob.get_popup().visible)
		await _press(JOY_BUTTON_DPAD_LEFT)
		await _frames(3)
		_ok("D-pad left flips it back", ob.selected == sel)
		ob.selected = sel
		ob.item_selected.emit(sel)
	await _press(JOY_BUTTON_B)
	await _frames(5)
	_ok("B goes back", menu._page == "main")
	await _frames(5)
	fo = get_viewport().gui_get_focus_owner()
	_ok("focus restored on the title page", fo != null and menu.is_ancestor_of(fo))
	# Controls page scrolls with the stick.
	while guard < 30:
		guard += 1
		fo = get_viewport().gui_get_focus_owner()
		if fo != null and str(fo.get("text")) == "> CONTROLS":
			break
		await _press(JOY_BUTTON_DPAD_DOWN)
	await _press(JOY_BUTTON_A)
	await _frames(5)
	_ok("A opens controls", menu._page == "help")
	await _press(JOY_BUTTON_DPAD_DOWN)
	await _press(JOY_BUTTON_DPAD_DOWN)
	await _frames(3)
	_ok("stick scrolls the controls page", menu._help != null and menu._help.get_v_scroll_bar().value > 0.0)
	await _press(JOY_BUTTON_B)
	_ok("B leaves controls", menu._page == "main")
	print("MENU PAD TEST DONE fails=%d" % fails)
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
