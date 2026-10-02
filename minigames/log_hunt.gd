extends Control
## LogHunt — deduction minigame. Read the access log, click the entries that
## don't belong. 2 rounds, 3 strikes. Datasets picked by `case_id`.
## signal finished(success).

signal finished(success: bool)

var case_id: String = "rons"

var _list: VBoxContainer
var _status: Label
var _round_label: Label
var _round: int = 0
var _total_rounds: int = 2
var _strikes: int = 0
var _found: int = 0
var _need: int = 0
var _done: bool = false
var _locked: bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	_build()
	_play_round()


func _mono() -> Font:
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray(["DejaVu Sans Mono", "monospace"])
	return sf


func _cases() -> Dictionary:
	return {
		"rons": {
			"title": "RON'S SERVER — access log",
			"rounds": [
				[{"t": "21:02", "s": "orders.php", "m": "200 GET /menu (214)", "bad": false},
				{"t": "21:14", "s": "orders.php", "m": "200 GET /photos/cat.jpg (88)", "bad": false},
				{"t": "21:31", "s": "mirror.php", "m": "200 GET /mirror/index (1) — 4.1GB", "bad": true},
				{"t": "21:33", "s": "orders.php", "m": "200 GET /menu (301)", "bad": false},
				{"t": "21:40", "s": "cron", "m": "backup rotated, 0 errors", "bad": false}],
				[{"t": "22:05", "s": "orders.php", "m": "200 GET /menu (122)", "bad": false},
				{"t": "22:11", "s": "mirror.php", "m": "200 GET /mirror/index (1) — 4.1GB", "bad": true},
				{"t": "22:12", "s": "mirror.php", "m": "200 GET /mirror/index (1) — 4.1GB", "bad": true},
				{"t": "22:19", "s": "orders.php", "m": "404 /favicon.ico", "bad": false},
				{"t": "22:26", "s": "orders.php", "m": "200 GET /photos/latte.jpg (41)", "bad": false},
				{"t": "22:31", "s": "cron", "m": "backup rotated, 0 errors", "bad": false}],
			],
		},
		"honey": {
			"title": "HONEYPOT — intrusion log",
			"rounds": [
				[{"t": "03:12", "s": "port 22", "m": "fail root x40 — script kiddie", "bad": false},
				{"t": "03:29", "s": "port 80", "m": "GET / — nikto scan, loud", "bad": false},
				{"t": "03:44", "s": "port 443", "m": "valid session cookie, no login. patient.", "bad": true},
				{"t": "03:51", "s": "port 22", "m": "fail admin x12 — dictionary", "bad": false},
				{"t": "04:02", "s": "cron", "m": "honeypot rotated", "bad": false}],
				[{"t": "04:20", "s": "port 443", "m": "session resumes. reads /docs, never /login", "bad": true},
				{"t": "04:31", "s": "port 22", "m": "fail root x90 — botnet", "bad": false},
				{"t": "04:33", "s": "dns", "m": "lookup darkarmy.onion — deliberate breadcrumb?", "bad": true},
				{"t": "04:40", "s": "port 80", "m": "GET /robots.txt — researcher", "bad": false},
				{"t": "04:55", "s": "port 22", "m": "fail ubnt x30 — mirai", "bad": false},
				{"t": "05:00", "s": "cron", "m": "honeypot rotated", "bad": false}],
			],
		},
		"lenny": {
			"title": "LENNY'S PHONE — message export",
			"rounds": [
				[{"t": "FRI", "s": "lenny", "m": "working late again, don't wait up x", "bad": false},
				{"t": "FRI", "s": "unknown-646", "m": "same motel? bring the red folder", "bad": true},
				{"t": "SAT", "s": "krista", "m": "missed call (2)", "bad": false},
				{"t": "SAT", "s": "lenny", "m": "dentist. boring. love you", "bad": false},
				{"t": "SAT", "s": "carrier", "m": "voicemail 0:42 — breathing, hangup", "bad": false}],
				[{"t": "SUN", "s": "unknown-646", "m": "he suspects nothing. men never do", "bad": true},
				{"t": "SUN", "s": "lenny", "m": "working late. big merger stuff", "bad": false},
				{"t": "SUN", "s": "bank", "m": "motel charge $89 — receipt kept?!", "bad": false},
				{"t": "MON", "s": "unknown-646", "m": "delete these. ALL of these.", "bad": true},
				{"t": "MON", "s": "krista", "m": "called mom. she asked about him.", "bad": false},
				{"t": "MON", "s": "lenny", "m": "home by 8. promise", "bad": false}],
			],
		},
		"steel": {
			"title": "STEEL MTN — guard roster log",
			"rounds": [
				[{"t": "18:00", "s": "shift A", "m": "2 guards, north + south doors", "bad": false},
				{"t": "19:30", "s": "shift A", "m": "south guard +45min smoke break, door unwatched", "bad": true},
				{"t": "20:00", "s": "shift B", "m": "1 guard, both doors (rounds)", "bad": false},
				{"t": "21:00", "s": "shift B", "m": "camera 3 looped for cleaning", "bad": false},
				{"t": "22:00", "s": "shift C", "m": "1 guard, desk, half asleep", "bad": false}],
				[{"t": "22:30", "s": "shift C", "m": "guard microwaves fish. whole building knows.", "bad": false},
				{"t": "23:00", "s": "shift C", "m": "corridor walk skipped — 'quiet night'", "bad": true},
				{"t": "23:30", "s": "shift C", "m": "thermostat override, server room (logged)", "bad": false},
				{"t": "00:00", "s": "shift A", "m": "2 guards, north + south doors", "bad": false},
				{"t": "00:30", "s": "shift A", "m": "south guard early break again — pattern", "bad": true},
				{"t": "01:00", "s": "shift A", "m": "rounds logged, all quiet", "bad": false}],
			],
		},
	}


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.86)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	vb.custom_minimum_size = Vector2(760, 0)
	center.add_child(vb)
	var data: Dictionary = _cases().get(case_id, _cases()["rons"])
	var head := Label.new()
	head.text = "▓ LOG HUNT — %s" % str(data["title"])
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 20)
	head.add_theme_color_override("font_color", Color(0.3, 1, 0.55))
	head.add_theme_font_override("font", _mono())
	vb.add_child(head)
	_round_label = Label.new()
	_round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_round_label.add_theme_font_size_override("font_size", 15)
	_round_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.75))
	_round_label.add_theme_font_override("font", _mono())
	vb.add_child(_round_label)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 5)
	vb.add_child(_list)
	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 14)
	_status.add_theme_color_override("font_color", Color(0.6, 0.85, 0.65))
	_status.add_theme_font_override("font", _mono())
	_status.text = "click the entries that don't belong."
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


func _style_btn(b: Button) -> void:
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


func _play_round() -> void:
	if _done:
		return
	_locked = false
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	var data: Dictionary = _cases().get(case_id, _cases()["rons"])
	var rounds: Array = data["rounds"]
	_total_rounds = rounds.size()
	if _round >= rounds.size():
		_finish(true)
		return
	_round_label.text = "ROUND %d / %d   strikes %d / 3" % [_round + 1, _total_rounds, _strikes]
	_found = 0
	_need = 0
	for e in rounds[_round]:
		if bool(e["bad"]):
			_need += 1
		var b := Button.new()
		b.text = "%s  %-10s  %s" % [str(e["t"]), str(e["s"]), str(e["m"])]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 15)
		b.add_theme_font_override("font", _mono())
		b.add_theme_color_override("font_color", Color(0.7, 0.95, 0.78))
		b.add_theme_color_override("font_hover_color", Color(0, 0, 0))
		var n := StyleBoxFlat.new()
		n.bg_color = Color(0.02, 0.06, 0.035)
		n.border_color = Color(0, 0.7, 0.35, 0.5)
		n.set_border_width_all(1)
		n.content_margin_left = 10
		n.content_margin_top = 6
		n.content_margin_bottom = 6
		b.add_theme_stylebox_override("normal", n)
		var h := n.duplicate() as StyleBoxFlat
		h.bg_color = Color(0, 0.85, 0.4)
		b.add_theme_stylebox_override("hover", h)
		var entry: Dictionary = e
		b.pressed.connect(func() -> void: _on_pick(b, entry))
		_list.add_child(b)


func _on_pick(b: Button, e: Dictionary) -> void:
	if _done or _locked:
		return
	if bool(e["bad"]):
		AudioManager.play_success()
		_found += 1
		b.disabled = true
		b.text = "✔ " + b.text
		if _found >= _need:
			_status.text = "clean. next page..."
			_locked = true
			# Round increments after the beat so _round always matches
			# the visible buttons (driver + round label stay in sync).
			await get_tree().create_timer(0.9, true).timeout
			if not is_instance_valid(self): return
			if not _done:
				_round += 1
				_play_round()
	else:
		AudioManager.play_fail()
		_strikes += 1
		# Wrong entries stay open but can't be farmed for strikes.
		b.disabled = true
		if _strikes >= 3:
			_status.text = "too much noise — they noticed the reader."
			_finish(false)
		else:
			_status.text = "wrong. that's just a %s. (%d/3)" % [str(e["s"]), _strikes]
			_round_label.text = "ROUND %d / %d   strikes %d / 3" % [_round + 1, _total_rounds, _strikes]


func _finish(success: bool) -> void:
	if _done:
		return
	_done = true
	if success:
		AudioManager.play_success()
		GameState.add_xp(20)
	else:
		AudioManager.play_fail()
	await get_tree().create_timer(0.8, true).timeout
	if not is_instance_valid(self): return
	emit_signal("finished", success)
