extends Control
## Invader — a tiny arcade shooter. A/D or arrows to move, SPACE to shoot.
## 12 kills wins the prize. The swarm reaches your line, you lose.
## signal finished(success).

signal finished(success: bool)

const AREA_W := 620.0
const AREA_H := 400.0
const COLS := 6
const ROWS := 3
const KILLS_TO_WIN := 12

var _area: Control
var _ship: ColorRect
var _score_label: Label
var _status: Label
var _invaders: Array = [] # {node, alive}
var _bullets: Array = [] # {node, vel}
var _dir: float = 1.0
var _speed: float = 42.0
var _cool: float = 0.0
var _kills: int = 0
var _done: bool = false
var _started: bool = false


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
	vb.add_theme_constant_override("separation", 8)
	center.add_child(vb)
	var head := Label.new()
	head.text = "▓ INVADER — 12 kills takes the prize"
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 22)
	head.add_theme_color_override("font_color", Color(0.3, 1, 0.5))
	head.add_theme_font_override("font", _mono())
	vb.add_child(head)
	_score_label = Label.new()
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.add_theme_font_size_override("font_size", 16)
	_score_label.add_theme_color_override("font_color", Color(0.8, 1, 0.85))
	_score_label.add_theme_font_override("font", _mono())
	vb.add_child(_score_label)
	_area = Control.new()
	_area.custom_minimum_size = Vector2(AREA_W, AREA_H)
	_area.clip_contents = true
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.01, 0.03, 0.02)
	bg.border_color = Color(0, 1, 0.45, 0.8)
	bg.set_border_width_all(2)
	_area.add_theme_stylebox_override("panel", bg)
	vb.add_child(_area)
	_ship = ColorRect.new()
	_ship.color = Color(0.3, 1, 0.5)
	_ship.position = Vector2(AREA_W / 2.0 - 23, AREA_H - 30)
	_ship.size = Vector2(46, 14)
	_area.add_child(_ship)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 12)
	vb.add_child(hb)
	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 14)
	_status.add_theme_color_override("font_color", Color(0.6, 0.85, 0.65))
	_status.add_theme_font_override("font", _mono())
	_status.text = "A/D move • SPACE shoot"
	hb.add_child(_status)
	var start := Button.new()
	start.text = "INSERT COIN"
	_style_btn(start, Color(0.3, 1, 0.5))
	start.pressed.connect(_on_start)
	hb.add_child(start)
	var abort := Button.new()
	abort.text = "WALK AWAY"
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
	_refresh_score()


func _style_btn(b: Button, accent: Color) -> void:
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_font_override("font", _mono())
	b.add_theme_color_override("font_color", Color(0.75, 1, 0.8))
	b.add_theme_color_override("font_hover_color", Color(0, 0, 0))
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.02, 0.07, 0.04)
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


func _refresh_score() -> void:
	_score_label.text = "KILLS %d / %d" % [_kills, KILLS_TO_WIN]


func _on_start() -> void:
	if _started or _done:
		return
	_started = true
	_status.text = "A/D move • SPACE shoot"
	for r in ROWS:
		for c in COLS:
			var inv := ColorRect.new()
			inv.color = Color(1, 0.35 - float(r) * 0.06, 0.4)
			inv.position = Vector2(60 + float(c) * 82, 30 + float(r) * 44)
			inv.size = Vector2(36, 22)
			_area.add_child(inv)
			_invaders.append({"node": inv, "alive": true})


func _process(delta: float) -> void:
	if _done or not _started:
		return
	# Ship.
	var mx := Input.get_axis("ui_left", "ui_right")
	if mx == 0.0:
		mx = float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	_ship.position.x = clampf(_ship.position.x + mx * 380.0 * delta, 0, AREA_W - _ship.size.x)
	# Fire.
	_cool = maxf(0.0, _cool - delta)
	if Input.is_action_pressed("ui_accept") and _cool <= 0.0:
		_cool = 0.35
		var b := ColorRect.new()
		b.color = Color(0.5, 1, 0.6)
		b.position = _ship.position + Vector2(_ship.size.x / 2.0 - 2, -12)
		b.size = Vector2(4, 12)
		_area.add_child(b)
		_bullets.append({"node": b})
		AudioManager.play_key()
	# Bullets.
	for bi in range(_bullets.size() - 1, -1, -1):
		var bd: Dictionary = _bullets[bi]
		var bn: ColorRect = bd["node"]
		bn.position.y -= 520.0 * delta
		if bn.position.y < -16:
			bn.queue_free()
			_bullets.remove_at(bi)
			continue
		var br := Rect2(bn.position, bn.size)
		var hit := false
		for inv in _invaders:
			if not inv["alive"]:
				continue
			var inode: ColorRect = inv["node"]
			if br.intersects(Rect2(inode.position, inode.size)):
				hit = true
				inv["alive"] = false
				inode.visible = false
				_kills += 1
				_speed *= 1.04
				_refresh_score()
				break
		if hit:
			bn.queue_free()
			_bullets.remove_at(bi)
	if _kills >= KILLS_TO_WIN:
		_status.text = "NEW HIGH SCORE."
		_finish(true)
		return
	# Swarm.
	var drop := false
	for inv in _invaders:
		if not inv["alive"]:
			continue
		var inode2: ColorRect = inv["node"]
		inode2.position.x += _dir * _speed * delta
		if inode2.position.x < 8 or inode2.position.x > AREA_W - 44:
			drop = true
		if inode2.position.y + 22 >= _ship.position.y:
			_status.text = "THE SWARM GOT YOU."
			_finish(false)
			return
	if drop:
		_dir = -_dir
		for inv in _invaders:
			if inv["alive"]:
				(inv["node"] as ColorRect).position.y += 22


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
