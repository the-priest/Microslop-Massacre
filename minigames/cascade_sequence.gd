extends Control
## CascadeSequence — the takedown skill test. Watch the grid flash a sequence,
## then repeat it. 4 rounds, growing length, limited total mistakes.
## Original minigame. signal finished(success).

signal finished(success: bool)

const GRID := 3
const ROUNDS := 4

var _buttons: Array[Button] = []
var _status: Label
var _round_label: Label
var _start_btn: Button
var _seq: Array[int] = []
var _input_pos: int = 0
var _round: int = 0
var _fails: int = 0
var _fail_limit: int = 3
var _accepting: bool = false
var _done: bool = false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	_rng.randomize()
	if GameState.has_flag("owns_schematics") or GameState.has_perk("cascade_tuned"):
		_fail_limit = 4
	_build()


func _mono() -> Font:
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray(["DejaVu Sans Mono", "monospace"])
	return sf


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.88)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	center.add_child(vb)

	var head := Label.new()
	head.text = "▓ CASCADE — hold the grid down"
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 22)
	head.add_theme_color_override("font_color", Color(1, 0.35, 0.4))
	head.add_theme_font_override("font", _mono())
	vb.add_child(head)

	_round_label = Label.new()
	_round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_round_label.add_theme_font_size_override("font_size", 16)
	_round_label.add_theme_color_override("font_color", Color(1, 0.8, 0.75))
	_round_label.add_theme_font_override("font", _mono())
	vb.add_child(_round_label)

	var grid := GridContainer.new()
	grid.name = "Grid"
	grid.columns = GRID
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(grid)

	for i in GRID * GRID:
		var b := Button.new()
		b.custom_minimum_size = Vector2(96, 96)
		b.add_theme_font_size_override("font_size", 20)
		b.add_theme_font_override("font", _mono())
		var idx := i
		b.pressed.connect(func() -> void: _on_cell(idx))
		_set_cell_idle(b)
		grid.add_child(b)
		_buttons.append(b)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 15)
	_status.add_theme_color_override("font_color", Color(0.9, 0.75, 0.7))
	_status.add_theme_font_override("font", _mono())
	_status.text = "press START — watch, then repeat."
	vb.add_child(_status)

	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 12)
	vb.add_child(hb)
	_start_btn = Button.new()
	_start_btn.text = "START CASCADE"
	_style_btn(_start_btn, Color(1, 0.35, 0.4))
	_start_btn.pressed.connect(_on_start)
	hb.add_child(_start_btn)
	var abort := Button.new()
	abort.text = "ABORT"
	_style_btn(abort, Color(0.6, 0.6, 0.65))
	abort.focus_mode = Control.FOCUS_NONE # ESC / B walks away; A never quits by accident
	abort.pressed.connect(func() -> void: _finish(false))
	hb.add_child(abort)

	var crt := ColorRect.new()
	crt.set_anchors_preset(Control.PRESET_FULL_RECT)
	crt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/crt.gdshader") as Shader
	crt.material = mat
	add_child(crt)
	_refresh_round()


func _style_btn(b: Button, accent: Color) -> void:
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_font_override("font", _mono())
	b.add_theme_color_override("font_color", Color(1, 0.85, 0.8))
	b.add_theme_color_override("font_hover_color", Color(0, 0, 0))
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.08, 0.02, 0.03)
	n.border_color = accent
	n.set_border_width_all(1)
	n.content_margin_left = 14
	n.content_margin_right = 14
	n.content_margin_top = 8
	n.content_margin_bottom = 8
	b.add_theme_stylebox_override("normal", n)
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = accent
	b.add_theme_stylebox_override("hover", h)


func _set_cell_idle(b: Button) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.04, 0.05)
	sb.border_color = Color(0.7, 0.25, 0.3)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_color_override("font_color", Color(0.7, 0.3, 0.32))
	b.text = "·"


func _flash_cell(i: int) -> void:
	var b := _buttons[i]
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 0.3, 0.35)
	sb.border_color = Color(1, 0.9, 0.85)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	b.add_theme_stylebox_override("normal", sb)
	b.text = "▓"
	AudioManager.play_key()
	await get_tree().create_timer(0.5, true).timeout
	if not is_instance_valid(self): return
	if is_instance_valid(b) and not _done:
		_set_cell_idle(b)


func _on_start() -> void:
	if _done or _accepting:
		return
	_start_btn.disabled = true
	_round = 0
	_fails = 0
	_play_round()


func _seq_len() -> int:
	return 3 + _round


func _play_round() -> void:
	_refresh_round()
	_seq.clear()
	for i in _seq_len():
		_seq.append(_rng.randi_range(0, GRID * GRID - 1))
	_input_pos = 0
	_accepting = false
	_status.text = "WATCH..."
	await get_tree().create_timer(0.8, true).timeout
	if not is_instance_valid(self): return
	if _done:
		return
	for i in _seq:
		if _done:
			return
		await _flash_cell(i)
		if not is_instance_valid(self): return
		await get_tree().create_timer(0.18, true).timeout
		if not is_instance_valid(self): return
	_input_pos = 0
	_accepting = true
	_status.text = "REPEAT IT — %d / %d" % [_input_pos, _seq.size()]


func _on_cell(i: int) -> void:
	if _done or not _accepting:
		return
	if _input_pos < 0 or _input_pos >= _seq.size():
		return
	if i < 0 or i >= _buttons.size():
		return
	AudioManager.play_key()
	if i == _seq[_input_pos]:
		_input_pos += 1
		var b := _buttons[i]
		b.text = "×"
		if _input_pos >= _seq.size():
			_accepting = false
			_round += 1
			AudioManager.play_success()
			if _round >= ROUNDS:
				_status.text = "CASCADE COMPLETE — grid is down."
				GameState.set_flag("cascade_done", true)
				_finish(true)
			else:
				_status.text = "round held. next wave..."
				await get_tree().create_timer(1.0, true).timeout
				if not is_instance_valid(self): return
				if not _done:
					_play_round()
		else:
			_status.text = "REPEAT IT — %d / %d" % [_input_pos, _seq.size()]
	else:
		_fails += 1
		AudioManager.play_fail()
		SceneRouter.glitch_pulse(0.6, 0.4)
		if _fails >= _fail_limit:
			_status.text = "GRID FOUGHT BACK — cascade lost."
			_finish(false)
		else:
			_status.text = "WRONG NODE (%d/%d) — watch again..." % [_fails, _fail_limit]
			_accepting = false
			await get_tree().create_timer(1.0, true).timeout
			if not is_instance_valid(self): return
			if not _done:
				_replay_round()


func _replay_round() -> void:
	_input_pos = 0
	_status.text = "WATCH..."
	await get_tree().create_timer(0.8, true).timeout
	if not is_instance_valid(self): return
	if _done:
		return
	for i in _seq:
		if _done:
			return
		await _flash_cell(i)
		if not is_instance_valid(self): return
		await get_tree().create_timer(0.18, true).timeout
		if not is_instance_valid(self): return
	_input_pos = 0
	_accepting = true
	_status.text = "REPEAT IT — %d / %d" % [_input_pos, _seq.size()]
	_refresh_round()


func _refresh_round() -> void:
	_round_label.text = "ROUND %d / %d   fails %d / %d" % [mini(_round + 1, ROUNDS), ROUNDS, _fails, _fail_limit]


func _finish(success: bool) -> void:
	if _done:
		return
	_done = true
	_accepting = false
	if success:
		AudioManager.play_success()
		GameState.add_xp(20)
	else:
		AudioManager.play_fail()
	await get_tree().create_timer(0.9, true).timeout
	if not is_instance_valid(self): return
	emit_signal("finished", success)
