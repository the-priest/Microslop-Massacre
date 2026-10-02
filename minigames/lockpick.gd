extends Control
## Lockpick — hold to lift the pin, release inside the green zone.
## 4 pins, 3 strikes. No guns needed. signal finished(success).

signal finished(success: bool)

const PINS := 4
const MAX_STRIKES := 3
const LIFT_TIME := 1.15

var _tracks: Array[Control] = []
var _fills: Array[ColorRect] = []
var _zones: Array[ColorRect] = []
var _status: Label
var _round_label: Label
var _pin: int = 0
var _val: float = 0.0
var _holding: bool = false
var _was_down: bool = false
var _strikes: int = 0
var _zone_lo: float = 0.4
var _zone_hi: float = 0.58
var _done: bool = false
## Lock difficulty (LOCKPICK skill needed). Set before adding to the tree.
var dc: int = 25


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	_build()
	_new_zone()


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
	head.text = "▓ LOCKPICK — hold, release in the green"
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 20)
	head.add_theme_color_override("font_color", Color(0.9, 0.75, 0.4))
	head.add_theme_font_override("font", _mono())
	vb.add_child(head)
	_round_label = Label.new()
	_round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_round_label.add_theme_font_size_override("font_size", 16)
	_round_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6))
	_round_label.add_theme_font_override("font", _mono())
	vb.add_child(_round_label)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 14)
	vb.add_child(hb)
	for i in PINS:
		var track := ColorRect.new()
		track.custom_minimum_size = Vector2(54, 300)
		track.color = Color(0.05, 0.045, 0.03)
		hb.add_child(track)
		_tracks.append(track)
		var zone := ColorRect.new()
		zone.color = Color(0.15, 0.7, 0.3, 0.9)
		zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		track.add_child(zone)
		_zones.append(zone)
		var fill := ColorRect.new()
		fill.color = Color(0.9, 0.7, 0.3)
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fill.position = Vector2(0, 300)
		fill.size = Vector2(54, 0)
		track.add_child(fill)
		_fills.append(fill)
	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 14)
	_status.add_theme_color_override("font_color", Color(0.75, 0.7, 0.6))
	_status.add_theme_font_override("font", _mono())
	_status.text = "HOLD space/click to lift — release in the green."
	vb.add_child(_status)
	var hb2 := HBoxContainer.new()
	hb2.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(hb2)
	var abort := Button.new()
	abort.text = "WALK AWAY"
	abort.add_theme_font_size_override("font_size", 15)
	abort.add_theme_font_override("font", _mono())
	abort.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65))
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.07, 0.06, 0.03)
	n.border_color = Color(0.9, 0.65, 0.2, 0.8)
	n.set_border_width_all(1)
	n.content_margin_left = 12
	n.content_margin_right = 12
	n.content_margin_top = 6
	n.content_margin_bottom = 6
	abort.add_theme_stylebox_override("normal", n)
	abort.focus_mode = Control.FOCUS_NONE # ESC / B walks away; A never quits by accident
	abort.pressed.connect(func() -> void: _finish(false))
	hb2.add_child(abort)
	var crt := ColorRect.new()
	crt.set_anchors_preset(Control.PRESET_FULL_RECT)
	crt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/crt.gdshader") as Shader
	crt.material = m
	add_child(crt)
	_refresh()


func _refresh() -> void:
	_round_label.text = "PIN %d / %d   strikes %d / %d" % [mini(_pin + 1, PINS), PINS, _strikes, MAX_STRIKES]


func _new_zone() -> void:
	if _pin < 0 or _pin >= PINS or _pin >= _zones.size():
		return
	var margin := float(GameState.skill("lockpick") - dc)
	var w := clampf(0.13 + margin * 0.003 - float(_pin) * 0.015, 0.07, 0.3)
	if GameState.has_perk("lock_whisperer"):
		w *= 1.25
	_zone_lo = 0.25 + randf() * (0.75 - w - 0.25)
	_zone_hi = _zone_lo + w
	var z := _zones[_pin]
	z.position = Vector2(0, 300.0 * (1.0 - _zone_hi))
	z.size = Vector2(54, 300.0 * (_zone_hi - _zone_lo))
	_refresh()


func _process(delta: float) -> void:
	if _done:
		return
	var down := Input.is_action_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if down and not _was_down:
		_holding = true
		_val = 0.0
		AudioManager.play_key()
	_was_down = down
	if _holding:
		if down:
			_val += delta / LIFT_TIME
			if _val >= 1.2:
				_strike("overshot it.")
		else:
			_holding = false
			if _val >= _zone_lo and _val <= _zone_hi:
				AudioManager.play_success()
				_pin += 1
				_val = 0.0
				if _pin >= PINS:
					_status.text = "CLICK. open."
					_finish(true)
					return
				_new_zone()
			else:
				_strike("wrong height.")
	var f: Control = _fills[_pin] if _pin < PINS else null
	if f != null:
		var h := clampf(_val, 0.0, 1.0) * 300.0
		f.position.y = 300.0 - h
		f.size.y = h


func _strike(why: String) -> void:
	_holding = false
	_val = 0.0
	_strikes += 1
	AudioManager.play_fail()
	# A bad lift can snap a bobby pin.
	if not (GameState.has_perk("lock_whisperer") and randf() < 0.5) and randf() < 0.6:
		GameState.take("bobby_pin", 1, true)
		why += " A bobby pin snapped (%d left)." % GameState.count("bobby_pin")
		AudioManager.sfx("lockbreak")
	if _strikes >= MAX_STRIKES or GameState.count("bobby_pin") <= 0:
		_status.text = "Pick snapped. %s" % why
		_finish(false)
	else:
		_status.text = "%s (%d/%d)" % [why.capitalize(), _strikes, MAX_STRIKES]
		_refresh()


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
