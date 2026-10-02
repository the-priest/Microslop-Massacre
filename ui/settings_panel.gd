class_name SettingsPanel
extends ScrollContainer
## Settings controls; changes apply immediately. Picking a graphics preset
## updates the individual graphics controls; touching one of those switches
## the preset to Custom.

const GFX := ["render_scale", "view_distance", "crowd_density", "traffic_density", "shadow_q", "aa", "glow", "grade", "detail", "reflections"]

var _box: VBoxContainer
## key -> control, so a preset can refresh the rows without rebuilding them
## (keeps gamepad focus where it is).
var _ctl := {}


func _ready() -> void:
	custom_minimum_size = Vector2(700, 430)
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	follow_focus = true
	_box = VBoxContainer.new()
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_box)
	_toggle("Fullscreen", "fullscreen")
	_toggle("V-Sync", "vsync")
	_choice("Graphics preset", "gfx_preset", ["Low", "Medium", "High", "Ultra", "Custom"])
	_slider("3D resolution scale", "render_scale", 0.5, 1.0, 0.05)
	_choice("View distance", "view_distance", ["Near (fastest)", "Normal", "Far"])
	_choice("Crowd density", "crowd_density", ["Low", "Normal", "High"])
	_choice("Traffic density", "traffic_density", ["Low", "Normal", "High"])
	_choice("Sun shadows", "shadow_q", ["Off", "Low", "High (soft)"])
	_choice("Anti-aliasing", "aa", ["Off", "FXAA", "MSAA 2x", "MSAA 4x"])
	_choice("Surface detail (textures)", "detail", ["Off (flat)", "Low", "High", "Ultra (relief, puddles)"])
	_toggle("Reflections (wet streets, glass, paint)", "reflections")
	_toggle("Glow / bloom", "glow")
	_toggle("Colour grading", "grade")
	_toggle("CRT scanlines", "crt")
	_toggle("Skip New Game intro", "skip_intro")
	_choice("Frame cap", "max_fps", ["Unlimited", "30", "60", "120"], [0, 30, 60, 120])
	_slider("Field of view", "fov", 60.0, 100.0, 1.0)
	_slider("Mouse sensitivity", "mouse_sens", 0.2, 3.0, 0.05)
	_slider("Gamepad look sensitivity", "pad_sens", 0.3, 2.5, 0.05)
	_toggle("Gamepad vibration", "pad_rumble")
	_toggle("Invert mouse Y", "invert_y")
	_slider("Master volume", "master_volume", 0.0, 1.0, 0.05)
	_slider("Music / radio volume", "music_volume", 0.0, 1.0, 0.05)
	_slider("Effects volume", "sfx_volume", 0.0, 1.0, 0.05)
	_slider("Narrator volume", "voice_volume", 0.0, 1.0, 0.05)
	_toggle("Quest markers on compass", "show_markers")
	_slider("Dialogue text speed", "subtitles_speed", 0.5, 3.0, 0.1)
	var note := UI.label("Everything is on by default (Ultra). If a Ryzen iGPU drops below 60 fps, pick High, or Medium for the most headroom. View distance and crowd/traffic density apply fully after a reload.", 13, UI.GREEN_DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_box.add_child(note)


func _row(label: String) -> HBoxContainer:
	var hb := HBoxContainer.new()
	var l := UI.label(label, 16, UI.GREEN)
	l.custom_minimum_size = Vector2(300, 0)
	hb.add_child(l)
	_box.add_child(hb)
	return hb


## Called after any control writes its value.
func _changed(key: String) -> void:
	if key == "gfx_preset":
		var p := int(Settings.get_v("gfx_preset"))
		if p < Settings.PRESETS.size():
			Settings.set_preset(p)
			_refresh()
	elif key in GFX:
		Settings.mark_custom()
		_refresh_one("gfx_preset")
	Settings.apply()


func _refresh() -> void:
	for k in _ctl:
		_refresh_one(k)


func _refresh_one(k: String) -> void:
	var c: Control = _ctl.get(k)
	if c == null:
		return
	var v: Variant = Settings.get_v(k)
	if c is CheckBox:
		(c as CheckBox).set_pressed_no_signal(bool(v))
	elif c is HSlider:
		(c as HSlider).set_value_no_signal(float(v))
		var lbl: Label = c.get_meta("lbl")
		lbl.text = "%.2f" % float(v)
	elif c is OptionButton:
		var ob := c as OptionButton
		var vals: Array = ob.get_meta("vals", [])
		ob.selected = clampi(int(v), 0, ob.item_count - 1) if vals.is_empty() else maxi(0, vals.find(int(v)))


func _toggle(label: String, key: String) -> void:
	var hb := _row(label)
	var cb := CheckBox.new()
	cb.button_pressed = bool(Settings.get_v(key))
	cb.toggled.connect(func(on: bool) -> void:
		Settings.set_v(key, on)
		_changed(key))
	hb.add_child(cb)
	_ctl[key] = cb


func _slider(label: String, key: String, mn: float, mx: float, st: float) -> void:
	var hb := _row(label)
	var s := HSlider.new()
	s.min_value = mn
	s.max_value = mx
	s.step = st
	s.value = float(Settings.get_v(key))
	s.custom_minimum_size = Vector2(260, 20)
	var v := UI.label("%.2f" % s.value, 14, UI.WHITE)
	s.set_meta("lbl", v)
	s.value_changed.connect(func(x: float) -> void:
		Settings.set_v(key, x)
		v.text = "%.2f" % x
		_changed(key))
	hb.add_child(s)
	hb.add_child(v)
	_ctl[key] = s


func _choice(label: String, key: String, opts: Array, values: Array = []) -> void:
	var hb := _row(label)
	var ob := OptionButton.new()
	for o in opts:
		ob.add_item(str(o))
	ob.set_meta("vals", values)
	var cur: int = int(Settings.get_v(key))
	if values.is_empty():
		ob.selected = clampi(cur, 0, opts.size() - 1)
	else:
		ob.selected = maxi(0, values.find(cur))
	ob.item_selected.connect(func(i: int) -> void:
		Settings.set_v(key, i if values.is_empty() else int(values[i]))
		_changed(key))
	hb.add_child(ob)
	_ctl[key] = ob
