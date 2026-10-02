class_name DialogueUI
extends CanvasLayer
## Walks a conversation from DialogueManager: typewriter lines, FNV-style
## numbered choices with skill checks, effects (including async ones like
## minigames and barter) mid-conversation.

signal _advance
signal _picked(idx: int)

var game: Node = null
var _open: bool = false
var _panel: PanelContainer
var _name: Label
var _text: RichTextLabel
var _choices: VBoxContainer
var _hint: Label
var _dim: ColorRect
var _typing: bool = false
var _type_t: float = 0.0
var _full_len: int = 0
var _waiting_line: bool = false
var _waiting_choice: bool = false
var _choice_buttons: Array = []
var _sel: int = 0
var _abort: bool = false
var _history: RichTextLabel
var auto_advance: bool = false # used by automated tests


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.35)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.visible = false
	add_child(_dim)
	_panel = PanelContainer.new()
	_panel.theme = UI.theme()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 90
	_panel.offset_right = -90
	_panel.offset_top = -400
	_panel.offset_bottom = -24
	_panel.add_theme_stylebox_override("panel", UI.box(Color(0.0, 0.03, 0.015, 0.95), UI.GREEN_DIM, 2, 18))
	_panel.visible = false
	add_child(_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	_panel.add_child(vb)
	_name = UI.label("", 20, UI.GREEN)
	vb.add_child(_name)
	_text = UI.rich(21)
	_text.custom_minimum_size = Vector2(0, 104)
	_text.fit_content = false
	_text.scroll_active = false
	vb.add_child(_text)
	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", UI.box(UI.GREEN_DIM * Color(1, 1, 1, 0.5), UI.GREEN_DIM, 0, 0))
	vb.add_child(sep)
	var sc := ScrollContainer.new()
	sc.follow_focus = true
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(sc)
	_choices = VBoxContainer.new()
	_choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_choices.add_theme_constant_override("separation", 2)
	sc.add_child(_choices)
	_hint = UI.label("[SPACE / CLICK] continue    [1-9] or [W/S + ENTER] choose", 13, UI.GREEN_DIM)
	vb.add_child(_hint)


func is_open() -> bool:
	return _open


func _process(delta: float) -> void:
	if _typing:
		_type_t += delta * 55.0 * float(Settings.get_v("subtitles_speed"))
		var shown := int(_type_t)
		if shown >= _full_len:
			_typing = false
			_text.visible_characters = -1
		else:
			_text.visible_characters = shown
	if auto_advance:
		if _waiting_line and not _typing:
			_waiting_line = false
			emit_signal("_advance")


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event is InputEventMouseButton and event.pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		if _waiting_line:
			_continue()
			get_viewport().set_input_as_handled()
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k := (event as InputEventKey).physical_keycode
	if _waiting_line:
		if k in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_E]:
			_continue()
			get_viewport().set_input_as_handled()
		return
	if _waiting_choice:
		if k >= KEY_1 and k <= KEY_9:
			var i := int(k - KEY_1)
			if i < _choice_buttons.size():
				_pick(i)
			get_viewport().set_input_as_handled()
		elif k == KEY_W or k == KEY_UP:
			_select(_sel - 1)
			get_viewport().set_input_as_handled()
		elif k == KEY_S or k == KEY_DOWN:
			_select(_sel + 1)
			get_viewport().set_input_as_handled()
		elif k in [KEY_ENTER, KEY_KP_ENTER, KEY_E, KEY_SPACE]:
			_pick(_sel)
			get_viewport().set_input_as_handled()


func _continue() -> void:
	if _typing:
		_typing = false
		_text.visible_characters = -1
		return
	_waiting_line = false
	AudioManager.play_key()
	emit_signal("_advance")


func _select(i: int) -> void:
	if _choice_buttons.is_empty():
		return
	_sel = clampi(i, 0, _choice_buttons.size() - 1)
	(_choice_buttons[_sel] as Button).grab_focus()


func _pick(i: int) -> void:
	if not _waiting_choice or i < 0 or i >= _choice_buttons.size():
		return
	_waiting_choice = false
	AudioManager.play_select()
	emit_signal("_picked", i)


func _show_line(speaker: String, text: String) -> void:
	_clear_choices()
	var spk := speaker
	var vo := speaker.ends_with("(V.O.)")
	if speaker == "":
		_name.text = ""
		_text.text = "[i][color=#9fb9a8]%s[/color][/i]" % text
	else:
		_name.text = spk
		_name.add_theme_color_override("font_color", UI.speaker_color(spk))
		if vo:
			_text.text = "[i][color=#%s]%s[/color][/i]" % [UI.speaker_color(spk).to_html(false), text]
		else:
			_text.text = text
	_full_len = _text.get_total_character_count()
	_text.visible_characters = 0
	_type_t = 0.0
	_typing = true
	_hint.text = "[A] continue" if Pad.using_pad else "[SPACE / CLICK] continue"
	_waiting_line = true
	await _advance


func _clear_choices() -> void:
	for c in _choices.get_children():
		c.queue_free()
	_choice_buttons.clear()


func _choose(chs: Array) -> int:
	_clear_choices()
	var i := 0
	for c in chs:
		var lab := DialogueManager.choice_label(c)
		var b := UI.button("%d. %s" % [i + 1, str(lab["text"])], 19)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(0, 32)
		match str(lab["kind"]):
			"fail":
				b.add_theme_color_override("font_color", UI.RED)
			"pass":
				b.add_theme_color_override("font_color", UI.WHITE)
			"seen":
				b.add_theme_color_override("font_color", UI.GREEN_DIM)
		var idx := i
		b.pressed.connect(func() -> void: _pick(idx))
		b.mouse_entered.connect(func() -> void: _select(idx))
		b.focus_entered.connect(func() -> void: _sel = idx)
		_choices.add_child(b)
		_choice_buttons.append(b)
		i += 1
	if Pad.using_pad:
		_hint.text = "[D-PAD / STICK] move    [A] select"
	else:
		_hint.text = "[1-%d] choose    [W/S] move    [ENTER] select" % chs.size()
	_waiting_choice = true
	_select(0)
	if auto_advance:
		# Tests pick via game.test_choice_picker if set.
		var pick := 0
		if game != null and game.has_method("test_pick_choice"):
			pick = int(game.test_pick_choice(chs))
		call_deferred("_pick", pick)
	var r: int = await _picked
	_clear_choices()
	return r


## Run a conversation to the end. npc may be null (scripted spots).
func run(cid: String, npc: Node = null) -> void:
	if _open:
		return
	if not DialogueManager.has_convo(cid):
		push_error("missing convo " + cid)
		return
	_open = true
	_abort = false
	_panel.visible = true
	_dim.visible = true
	if game != null:
		game.push_ui()
		game.hud.set_visible_all(false)
	if npc != null and npc.has_method("set_talking"):
		npc.call("set_talking", true)
	DialogueManager.current_npc = str(npc.get("id")) if npc != null and npc.get("id") != null else ""
	var cur_c := cid
	var cur_n := DialogueManager.entry(cid)
	var guard := 0
	while cur_c != "" and guard < 400 and not _abort:
		guard += 1
		var node := DialogueManager.node(cur_c, cur_n)
		if node.is_empty():
			push_error("missing node %s.%s" % [cur_c, cur_n])
			break
		var nxt: Array = []
		for st in node["stmts"]:
			var s: Dictionary = st
			match str(s["k"]):
				"line":
					await _show_line(str(s["speaker"]), str(s["text"]))
				"narr":
					await _show_line("", str(s["text"]))
				"if":
					if DialogueManager.eval_cond(s["cond"]):
						nxt = DialogueManager.resolve_target(cur_c, str(s["to"]))
				"do":
					_panel.visible = false
					await DialogueManager.run_effects(s["fx"])
					_panel.visible = _open
				"goto":
					nxt = DialogueManager.resolve_target(cur_c, str(s["to"]))
			if not nxt.is_empty() or _abort:
				break
		if _abort:
			break
		if nxt.is_empty():
			var chs := DialogueManager.visible_choices(node)
			if chs.is_empty():
				nxt = ["", ""]
			else:
				var pick := await _choose(chs)
				var ch: Dictionary = chs[pick]
				DialogueManager.mark_seen(ch)
				var ok := true
				if ch["check"] != null:
					var ck: Dictionary = ch["check"]
					ok = GameState.skill(str(ck["skill"])) >= int(ck["dc"])
					GameState.last_won = ok
					if ok:
						GameState.stat_add("checks")
						GameState.add_xp(15)
						AudioManager.play_success()
					else:
						AudioManager.play_fail()
					await _show_line("", "[%s %d] %s" % [DB.SKILL_NAMES[str(ck["skill"])], int(ck["dc"]), "SUCCEEDED" if ok else "FAILED"])
				_panel.visible = false
				await DialogueManager.run_effects(ch["fx"])
				_panel.visible = _open
				var tgt := str(ch["to"]) if ok else str(ch["fail"])
				nxt = DialogueManager.resolve_target(cur_c, tgt)
		cur_c = str(nxt[0])
		cur_n = str(nxt[1])
	_close(npc)
	DialogueManager.emit_signal("convo_finished", cid)


func abort() -> void:
	_abort = true
	if _waiting_line:
		_waiting_line = false
		emit_signal("_advance")
	if _waiting_choice:
		_waiting_choice = false
		emit_signal("_picked", 0)


func _close(npc) -> void:  # untyped: npc may have been freed mid-conversation
	_open = false
	_panel.visible = false
	_dim.visible = false
	_clear_choices()
	if npc != null and is_instance_valid(npc) and npc.has_method("set_talking"):
		npc.call("set_talking", false)
	DialogueManager.current_npc = ""
	if game != null:
		game.hud.set_visible_all(true)
		game.pop_ui()
		game.after_dialogue()
