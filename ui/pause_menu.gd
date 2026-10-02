class_name PauseMenu
extends Modal
## ESC menu: resume, save, load, settings, controls, quit.

var _box: VBoxContainer
var _page: String = "main"
var _help: RichTextLabel = null


func _build() -> void:
	var p := panel(760, 600)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 8)
	p.add_child(_box)


func open() -> void:
	_page = "main"
	open_modal()
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if (event as InputEventKey).physical_keycode == KEY_ESCAPE:
		if _page == "main":
			close_modal()
		else:
			if _page == "settings":
				Settings.save_settings()
			_page = "main"
			_refresh()
	get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	# The controls page scrolls with the stick / arrows (its only button is Back).
	if not _is_open or _help == null or not (event is InputEventKey) or not event.pressed:
		return
	var k := (event as InputEventKey).keycode
	if k == KEY_UP or k == KEY_DOWN:
		_help.get_v_scroll_bar().value += 60.0 * (1.0 if k == KEY_DOWN else -1.0)
		get_viewport().set_input_as_handled()


func _b(text: String, f: Callable) -> Button:
	var b := UI.button(text, 20)
	b.clip_text = true
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	b.pressed.connect(f)
	_box.add_child(b)
	return b


func _refresh() -> void:
	clear(_box)
	_help = null
	match _page:
		"main":
			_box.add_child(UI.label("PAUSED  ·  %s  ·  %s" % [GameState.clock_text(), game._location_name()], 22, UI.WHITE))
			_b("Resume", close_modal)
			_b("Save Game", func() -> void:
				_page = "save"
				_refresh())
			_b("Load Game", func() -> void:
				_page = "load"
				_refresh())
			_b("Settings", func() -> void:
				_page = "settings"
				_refresh())
			_b("Controls", func() -> void:
				_page = "help"
				_refresh())
			_b("Quit to Main Menu", func() -> void:
				close_modal()
				SceneRouter.goto_menu())
			_b("Quit Game", func() -> void: get_tree().quit())
		"save":
			_box.add_child(UI.label("SAVE GAME", 22, UI.WHITE))
			if game.save_blocked() != "":
				_box.add_child(UI.label(game.save_blocked(), 16, UI.RED))
			else:
				for s in SaveManager.SLOTS:
					var ss := str(s)
					var m := SaveManager.read_meta(ss)
					var lbl := "%s  —  %s" % [ss.to_upper(), _meta_text(m) if not m.is_empty() else "(empty)"]
					_b(lbl, func() -> void:
						game.sync_state_for_save()
						if SaveManager.save(ss, game._location_name()):
							game.hud.notify("Saved to %s." % ss, "")
						_refresh())
			_b("< Back", func() -> void:
				_page = "main"
				_refresh())
		"load":
			_box.add_child(UI.label("LOAD GAME", 22, UI.WHITE))
			for s in ["quick", "auto", "auto2"] + SaveManager.SLOTS:
				var ss2 := str(s)
				var m2 := SaveManager.read_meta(ss2)
				if m2.is_empty():
					continue
				_b("%s  —  %s" % [ss2.to_upper(), _meta_text(m2)], func() -> void:
					if SaveManager.load_slot(ss2):
						close_modal()
						SceneRouter.goto_game())
			_b("< Back", func() -> void:
				_page = "main"
				_refresh())
		"settings":
			_box.add_child(UI.label("SETTINGS", 22, UI.WHITE))
			var sui := SettingsPanel.new()
			_box.add_child(sui)
			_b("< Back", func() -> void:
				Settings.save_settings()
				_page = "main"
				_refresh())
		"help":
			_box.add_child(UI.label("CONTROLS", 22, UI.WHITE))
			var r := UI.rich(16)
			r.custom_minimum_size = Vector2(700, 440)
			r.text = Help.CONTROLS
			_box.add_child(r)
			_help = r
			_b("< Back", func() -> void:
				_page = "main"
				_refresh())


	_focus_first.call_deferred()


func _focus_first() -> void:
	var b := Modal._first_button(_box)
	if b != null:
		b.grab_focus()


func _meta_text(m: Dictionary) -> String:
	var t := float(m.get("time", 0))
	var dt := Time.get_datetime_dict_from_unix_time(int(t))
	return "LVL %d · %s · %s · %s  (%04d-%02d-%02d %02d:%02d)" % [int(m.get("level", 1)), str(m.get("location", "")), str(m.get("date", "")), str(m.get("clock", "")), int(dt["year"]), int(dt["month"]), int(dt["day"]), int(dt["hour"]), int(dt["minute"])]
