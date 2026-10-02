class_name WaitUI
extends Modal
## Wait or sleep. Sleeping heals, steadies you, and saves.

var _title: Label
var _hours: HSlider
var _lbl: Label
var _sleep: bool = false


func _build() -> void:
	var p := panel(560, 260)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	p.add_child(vb)
	_title = UI.label("", 22, UI.GREEN)
	vb.add_child(_title)
	_hours = HSlider.new()
	_hours.min_value = 1
	_hours.max_value = 24
	_hours.step = 1
	_hours.value = 8
	_hours.value_changed.connect(func(_v: float) -> void: _update())
	vb.add_child(_hours)
	_lbl = UI.label("", 18, UI.WHITE)
	vb.add_child(_lbl)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 20)
	vb.add_child(hb)
	var ok := UI.button("[ OK ]", 20)
	ok.pressed.connect(_do)
	hb.add_child(ok)
	var morning := UI.button("[ UNTIL MORNING ]", 20)
	morning.pressed.connect(func() -> void:
		var h := GameState.hour()
		var need := fposmod(7.0 - h, 24.0)
		_hours.value = clampf(roundf(need), 1.0, 24.0)
		_do())
	hb.add_child(morning)
	var cancel := UI.button("[ CANCEL ]", 20)
	cancel.pressed.connect(close_modal)
	hb.add_child(cancel)


func open(sleep: bool = false) -> void:
	_sleep = sleep
	_title.text = "SLEEP" if sleep else "WAIT"
	open_modal()
	_update()
	await closed


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k := (event as InputEventKey).physical_keycode
	if k == KEY_ESCAPE or k == KEY_T:
		close_modal()
	elif k in [KEY_ENTER, KEY_KP_ENTER, KEY_E]:
		_do()
	elif k in [KEY_A, KEY_LEFT]:
		_hours.value -= 1
	elif k in [KEY_D, KEY_RIGHT]:
		_hours.value += 1
	get_viewport().set_input_as_handled()


func _update() -> void:
	var h := int(_hours.value)
	var end := GameState.game_minutes + float(h) * 60.0
	var m := int(fmod(end, 1440.0))
	var hh := m / 60
	_lbl.text = "%d hour%s  →  %d:%02d %s" % [h, "" if h == 1 else "s", (hh % 12) if hh % 12 != 0 else 12, m % 60, "AM" if hh < 12 else "PM"]


func _do() -> void:
	var h := float(_hours.value)
	close_modal()
	game.push_ui()
	await SceneRouter.fade(true, 0.4)
	GameState.advance_time(h * 60.0)
	if _sleep:
		GameState.heal(GameState.max_hp() * minf(1.0, h / 7.0))
		GameState.adjust_stability(int(h * 2.0))
		GameState.set_flag("slept_day", GameState.day())
	else:
		GameState.heal(h * 2.0)
	game.npcs.refresh(true)
	await get_tree().create_timer(0.3).timeout
	await SceneRouter.fade(false, 0.5)
	game.pop_ui()
	game.hud.notify(("Slept %d hours." if _sleep else "Waited %d hours.") % int(h), "")
	if _sleep:
		game.sync_state_for_save()
		SaveManager.autosave(game._location_name(), true)
