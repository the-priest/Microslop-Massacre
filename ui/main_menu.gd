extends Control
## Title screen.

var _box: VBoxContainer
var _page: String = "main"
var _bg_text: RichTextLabel
var _t: float = 0.0
var _lines: Array = []
var _into: Container = null # where _b() puts buttons (a scroll list on the load page)
var _help: RichTextLabel = null

const BG_LINES := [
	"hello, friend.", "are you a one or a zero?", "control is an illusion.",
	"the world is a dangerous place.", "we are fsociety.", "5/9",
	"who is mr. robot?", "is any of it real?", "the city never sleeps. neither do you.",
	"debt is a leash.", "every window is a ledger.", "remember what you said.",
]


func _ready() -> void:
	theme = UI.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
	Engine.time_scale = 1.0
	var bg := ColorRect.new()
	bg.color = Color(0, 0.01, 0.005)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_bg_text = UI.rich(14)
	_bg_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_text.add_theme_color_override("default_color", Color(0.1, 0.35, 0.18))
	_bg_text.scroll_active = false
	_bg_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg_text)
	var title := UI.label("MICROSLOP MASSACRE", 64, UI.GREEN)
	title.position = Vector2(80, 70)
	add_child(title)
	var sub := UI.label("hello, friend.  ·  fsociety vs. E Corp and every corporation it owns", 18, UI.GREEN_DIM)
	sub.position = Vector2(86, 160)
	add_child(sub)
	_box = VBoxContainer.new()
	_box.position = Vector2(86, 230)
	_box.custom_minimum_size = Vector2(760, 0)
	_box.add_theme_constant_override("separation", 6)
	add_child(_box)
	var ver := UI.label("v3.0 · fan project and parody · original script · all art and audio procedural · no microtransactions, ever", 12, UI.GREEN_DIM)
	ver.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	ver.position = Vector2(86, -40)
	add_child(ver)
	var crt := ColorRect.new()
	crt.set_anchors_preset(Control.PRESET_FULL_RECT)
	crt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cm := ShaderMaterial.new()
	cm.shader = load("res://shaders/crt.gdshader")
	crt.material = cm
	add_child(crt)
	AudioManager.set_ambient("jazz")
	AudioManager.radio_stop()
	_refresh()


func _process(delta: float) -> void:
	_t += delta
	if _t > 0.15:
		_t = 0.0
		var s := ""
		if randf() < 0.25:
			s = str(BG_LINES[randi() % BG_LINES.size()])
		else:
			for i in randi_range(20, 60):
				s += "%02x " % (randi() % 256)
		_lines.append(" ".repeat(randi() % 70) + s)
		while _lines.size() > 48:
			_lines.pop_front()
		_bg_text.text = "\n".join(_lines)


func _b(text: String, f: Callable, enabled: bool = true) -> Button:
	var b := UI.button(text, 24)
	b.disabled = not enabled
	b.pressed.connect(func() -> void:
		AudioManager.play_select()
		f.call())
	(_into if _into != null else _box).add_child(b)
	return b


func _clear() -> void:
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()


func _refresh() -> void:
	_clear()
	_into = null
	_help = null
	match _page:
		"main":
			var latest := SaveManager.latest_slot()
			_b("> CONTINUE", func() -> void:
				if SaveManager.load_slot(latest):
					SceneRouter.goto_game(), latest != "")
			_b("> NEW GAME", func() -> void:
				SaveManager.pending_load = {}
				GameState.new_game()
				SceneRouter.goto_game())
			_b("> LOAD", func() -> void:
				_page = "load"
				_refresh(), latest != "")
			_b("> SETTINGS", func() -> void:
				_page = "settings"
				_refresh())
			_b("> CONTROLS", func() -> void:
				_page = "help"
				_refresh())
			_b("> ENDINGS SEEN", func() -> void:
				_page = "endings"
				_refresh())
			_b("> QUIT", func() -> void: get_tree().quit())
		"load":
			var sc := ScrollContainer.new()
			sc.custom_minimum_size = Vector2(760, 400)
			sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			sc.follow_focus = true
			_box.add_child(sc)
			var list := VBoxContainer.new()
			list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			list.add_theme_constant_override("separation", 6)
			sc.add_child(list)
			_into = list
			for s in ["quick", "auto", "auto2"] + SaveManager.SLOTS:
				var ss := str(s)
				var m := SaveManager.read_meta(ss)
				if m.is_empty():
					continue
				_b("%s — LVL %d · %s · %s %s" % [ss.to_upper(), int(m.get("level", 1)), str(m.get("location", "")), str(m.get("date", "")), str(m.get("clock", ""))], func() -> void:
					if SaveManager.load_slot(ss):
						SceneRouter.goto_game())
			_into = null
			_b("< BACK", func() -> void:
				_page = "main"
				_refresh())
		"settings":
			_box.add_child(SettingsPanel.new())
			_b("< BACK", func() -> void:
				Settings.save_settings()
				_page = "main"
				_refresh())
		"help":
			var r := UI.rich(15)
			r.custom_minimum_size = Vector2(760, 420)
			r.text = Help.CONTROLS
			_box.add_child(r)
			_help = r
			_b("< BACK", func() -> void:
				_page = "main"
				_refresh())
		"endings":
			var cfg := ConfigFile.new()
			cfg.load("user://endings.cfg")
			for id in EndingData.NAMES.keys():
				var seen: bool = cfg.get_value("endings", str(id), false)
				_box.add_child(UI.label(("✔ " + str(EndingData.NAMES[id])) if seen else "· ???", 20, UI.GREEN if seen else UI.GREEN_DIM))
			_b("< BACK", func() -> void:
				_page = "main"
				_refresh())
	# Something must hold focus or a pad / arrow keys can't drive the menu.
	_focus_first.call_deferred()


func _focus_first() -> void:
	# Depth-first, in screen order: the first setting, not the Back button.
	var b := Modal._first_button(_box)
	if b != null:
		b.grab_focus()


func _back() -> void:
	if _page == "settings":
		Settings.save_settings()
	_page = "main"
	_refresh()


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed:
		return
	var k := (event as InputEventKey).keycode
	if k == KEY_ESCAPE and _page != "main" and not event.echo:
		AudioManager.play_select()
		_back()
		get_viewport().set_input_as_handled()
	elif _help != null and (k == KEY_UP or k == KEY_DOWN):
		var bar := _help.get_v_scroll_bar()
		bar.value += 60.0 * (1.0 if k == KEY_DOWN else -1.0)
		get_viewport().set_input_as_handled()
