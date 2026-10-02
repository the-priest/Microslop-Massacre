extends Control
## BruteForce — hangman vs a weak password. Guess letters (click or type),
## 6 misses burns it. Word list is in-fiction (pets, teams, defaults).
## signal finished(success).

signal finished(success: bool)

var target_word: String = "ronccino"
var hint_text: String = "his favorite word. it's on the menu."

var _word: String = ""
var _shown: Array = []
var _missed: Array = []
var _grid: GridContainer
var _word_label: Label
var _miss_label: Label
var _status: Label
var _done: bool = false
var _started: bool = false
const MAX_MISS := 6


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	_word = target_word.to_lower()
	for i in _word.length():
		_shown.append("_")
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
	head.text = "▓ BRUTE FORCE — weak humans, weaker passwords"
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 20)
	head.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))
	head.add_theme_font_override("font", _mono())
	vb.add_child(head)
	_word_label = Label.new()
	_word_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_word_label.add_theme_font_size_override("font_size", 44)
	_word_label.add_theme_color_override("font_color", Color(0.4, 1, 0.55))
	_word_label.add_theme_font_override("font", _mono())
	vb.add_child(_word_label)
	_miss_label = Label.new()
	_miss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_miss_label.add_theme_font_size_override("font_size", 15)
	_miss_label.add_theme_color_override("font_color", Color(1, 0.5, 0.4))
	_miss_label.add_theme_font_override("font", _mono())
	vb.add_child(_miss_label)
	_grid = GridContainer.new()
	_grid.columns = 9
	_grid.add_theme_constant_override("h_separation", 5)
	_grid.add_theme_constant_override("v_separation", 5)
	_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(_grid)
	for code in range(26):
		var ch := String.chr(97 + code)
		var b := Button.new()
		b.text = ch.to_upper()
		b.custom_minimum_size = Vector2(44, 44)
		b.add_theme_font_size_override("font_size", 17)
		b.add_theme_font_override("font", _mono())
		_style_key(b)
		b.pressed.connect(func() -> void: _guess(ch, b))
		_grid.add_child(b)
	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 14)
	_status.add_theme_color_override("font_color", Color(0.7, 0.85, 0.7))
	_status.add_theme_font_override("font", _mono())
	_status.text = "hint: %s" % hint_text
	vb.add_child(_status)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(hb)
	var abort := Button.new()
	abort.text = "ABORT"
	abort.add_theme_font_size_override("font_size", 15)
	abort.add_theme_font_override("font", _mono())
	_style_btn(abort)
	abort.focus_mode = Control.FOCUS_NONE # ESC / B walks away; A never quits by accident
	abort.pressed.connect(func() -> void: _finish(false))
	hb.add_child(abort)
	var crt := ColorRect.new()
	crt.set_anchors_preset(Control.PRESET_FULL_RECT)
	crt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/crt.gdshader") as Shader
	crt.material = m
	add_child(crt)
	_refresh()


func _style_key(b: Button) -> void:
	b.add_theme_color_override("font_color", Color(0.8, 1, 0.82))
	b.add_theme_color_override("font_hover_color", Color(0, 0, 0))
	b.add_theme_color_override("font_disabled_color", Color(0.3, 0.35, 0.3))
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.05, 0.06, 0.03)
	n.border_color = Color(0.9, 0.65, 0.2, 0.8)
	n.set_border_width_all(1)
	b.add_theme_stylebox_override("normal", n)
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = Color(0.9, 0.65, 0.2)
	b.add_theme_stylebox_override("hover", h)
	var d := n.duplicate() as StyleBoxFlat
	d.bg_color = Color(0.02, 0.02, 0.02)
	b.add_theme_stylebox_override("disabled", d)


func _style_btn(b: Button) -> void:
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_font_override("font", _mono())
	b.add_theme_color_override("font_color", Color(0.75, 1, 0.8))
	b.add_theme_color_override("font_hover_color", Color(0, 0, 0))
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.02, 0.07, 0.04)
	n.border_color = Color(0, 1, 0.45, 0.8)
	n.set_border_width_all(1)
	n.content_margin_left = 12
	n.content_margin_right = 12
	n.content_margin_top = 6
	n.content_margin_bottom = 6
	b.add_theme_stylebox_override("normal", n)
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = Color(0, 0.9, 0.4)
	b.add_theme_stylebox_override("hover", h)


func _refresh() -> void:
	_word_label.text = " ".join(_shown)
	_miss_label.text = "misses: %s (%d/%d)" % [", ".join(_missed), _missed.size(), MAX_MISS]


func _guess(ch: String, b: Button) -> void:
	if _done:
		return
	_started = true
	b.disabled = true
	if ch in _word:
		AudioManager.play_key()
		for i in _word.length():
			if _word.substr(i, 1) == ch:
				_shown[i] = ch
		_refresh()
		if not "_" in _shown:
			_status.text = "CRACKED: %s. humans." % _word
			_finish(true)
	else:
		AudioManager.play_fail()
		_missed.append(ch.to_upper())
		_refresh()
		if _missed.size() >= MAX_MISS:
			_status.text = "LOCKED OUT. it was '%s'." % _word
			_finish(false)


func _unhandled_key_input(event: InputEvent) -> void:
	if _done:
		return
	if event.has_meta("pad"):
		return # pad buttons arrive as keys (X = R...); they pick letters through focus instead
	if event is InputEventKey and event.pressed and not event.echo:
		var k := (event as InputEventKey).keycode
		if k >= KEY_A and k <= KEY_Z:
			var ch := String.chr(96 + int(k - KEY_A) + 1).to_lower()
			for btn in _grid.get_children():
				var bb := btn as Button
				if bb != null and not bb.disabled and bb.text.to_lower() == ch:
					_guess(ch, bb)
					get_viewport().set_input_as_handled()
					return


func _finish(success: bool) -> void:
	if _done:
		return
	_done = true
	if success:
		AudioManager.play_success()
		GameState.add_xp(20)
	else:
		AudioManager.play_fail()
	await get_tree().create_timer(0.9, true).timeout
	if not is_instance_valid(self): return
	emit_signal("finished", success)
