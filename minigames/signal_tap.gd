extends Control
## SignalTap — timing minigame. Needle sweeps the band; hit SPACE inside the
## green window. 5 taps wins, 3 misses loses. Speed ramps each hit.
## signal finished(success).

signal finished(success: bool)

const HITS_TO_WIN := 5

var _track: ColorRect
var _window_rect: ColorRect
var _needle: ColorRect
var _status: Label
var _score: Label
var _pos: float = 0.0
var _dir: float = 1.0
var _speed: float = 0.9
var _win_lo: float = 0.4
var _win_hi: float = 0.6
var _hits: int = 0
var _misses: int = 0
var _done: bool = false
var _live: bool = false
var _cool: float = 0.0
const TRACK_W := 560.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
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
	vb.add_theme_constant_override("separation", 12)
	center.add_child(vb)
	var head := Label.new()
	head.text = "▓ SIGNAL TAP — catch it in the green"
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 22)
	head.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	head.add_theme_font_override("font", _mono())
	vb.add_child(head)
	_score = Label.new()
	_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score.add_theme_font_size_override("font_size", 16)
	_score.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
	_score.add_theme_font_override("font", _mono())
	vb.add_child(_score)
	_track = ColorRect.new()
	_track.custom_minimum_size = Vector2(TRACK_W, 46)
	_track.color = Color(0.03, 0.06, 0.08)
	_track.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(_track)
	_window_rect = ColorRect.new()
	_window_rect.color = Color(0.1, 0.8, 0.35, 0.85)
	_window_rect.position = Vector2(TRACK_W * _win_lo, 0)
	_window_rect.size = Vector2(TRACK_W * (_win_hi - _win_lo), 46)
	_window_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_track.add_child(_window_rect)
	_needle = ColorRect.new()
	_needle.color = Color(0.95, 0.95, 1.0)
	_needle.position = Vector2(0, -6)
	_needle.size = Vector2(4, 58)
	_needle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_track.add_child(_needle)
	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 15)
	_status.add_theme_color_override("font_color", Color(0.65, 0.8, 0.9))
	_status.add_theme_font_override("font", _mono())
	_status.text = "SPACE when the needle is green. 5 taps."
	vb.add_child(_status)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 12)
	vb.add_child(hb)
	var start := Button.new()
	start.text = "START TAP"
	_style_btn(start, Color(0.4, 0.9, 1.0))
	start.pressed.connect(_on_start)
	hb.add_child(start)
	var abort := Button.new()
	abort.text = "ABORT"
	_style_btn(abort, Color(0.6, 0.6, 0.65))
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


func _style_btn(b: Button, accent: Color) -> void:
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_font_override("font", _mono())
	b.add_theme_color_override("font_color", Color(0.8, 0.95, 1.0))
	b.add_theme_color_override("font_hover_color", Color(0, 0, 0))
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.02, 0.05, 0.08)
	n.border_color = accent
	n.set_border_width_all(1)
	n.content_margin_left = 12
	n.content_margin_right = 12
	n.content_margin_top = 6
	n.content_margin_bottom = 6
	b.add_theme_stylebox_override("normal", n)
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = accent
	b.add_theme_stylebox_override("hover", h)


func _refresh() -> void:
	_score.text = "TAPS %d / %d   misses %d / 3" % [_hits, HITS_TO_WIN, _misses]


func _on_start() -> void:
	if _done or _live:
		return
	_live = true
	_cool = 0.3 # the press that started the tap must not count as a tap
	_status.text = "listening..."


func _new_window() -> void:
	var w := maxf(0.10, 0.20 - float(_hits) * 0.02)
	if GameState.has_perk("signal_hound"):
		w = minf(0.30, w + 0.05)
	_win_lo = randf() * (1.0 - w)
	_win_hi = _win_lo + w
	_window_rect.position.x = TRACK_W * _win_lo
	_window_rect.size.x = TRACK_W * (_win_hi - _win_lo)


func _process(delta: float) -> void:
	if _done or not _live:
		return
	_pos += _dir * _speed * delta
	if _pos > 1.0:
		_pos = 1.0
		_dir = -1.0
	elif _pos < 0.0:
		_pos = 0.0
		_dir = 1.0
	_needle.position.x = _pos * TRACK_W
	_cool = maxf(0.0, _cool - delta)
	if Input.is_action_just_pressed("ui_accept") and _cool <= 0.0:
		_cool = 0.25
		if _pos >= _win_lo and _pos <= _win_hi:
			_hits += 1
			_speed += 0.22
			AudioManager.play_key()
			_new_window()
			_refresh()
			if _hits >= HITS_TO_WIN:
				_status.text = "SIGNAL HELD."
				_finish(true)
		else:
			_misses += 1
			AudioManager.play_fail()
			if _misses >= 3:
				_status.text = "THEY HEARD YOU LISTENING."
				_finish(false)
			else:
				_status.text = "missed. (%d/3)" % _misses
				_refresh()


func _finish(success: bool) -> void:
	if _done:
		return
	_done = true
	_live = false
	if success:
		AudioManager.play_success()
		GameState.add_xp(20)
	else:
		AudioManager.play_fail()
	await get_tree().create_timer(0.9, true).timeout
	if not is_instance_valid(self): return
	emit_signal("finished", success)
