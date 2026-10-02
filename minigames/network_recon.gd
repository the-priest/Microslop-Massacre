extends Control
## NetworkRecon — trace a route from ENTRY to TARGET avoiding IDS nodes.
## Deterministic puzzle. Click orthogonal neighbours to extend; click back to undo.

signal finished(success: bool)

const W := 5
const H := 5
const START := Vector2i(0, 0)
const TARGET := Vector2i(4, 4)
const IDS := [Vector2i(1, 2), Vector2i(3, 1), Vector2i(2, 3), Vector2i(3, 3)]
const MAX_STEPS := 14

var _path: Array[Vector2i] = [START]
var _buttons: Dictionary = {} # Vector2i -> Button
var _status: Label
var _steps: Label
var _fails: int = 0
var _done: bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	_build()
	_refresh()


func _mono() -> Font:
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray(["DejaVu Sans Mono", "monospace"])
	return sf


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.85)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	center.add_child(vb)

	var head := Label.new()
	head.text = "▓ NETWORK RECON — trace ENTRY → TARGET, avoid IDS"
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 20)
	head.add_theme_color_override("font_color", Color(0.2, 1, 0.5))
	head.add_theme_font_override("font", _mono())
	vb.add_child(head)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 15)
	_status.add_theme_color_override("font_color", Color(0.7, 0.9, 0.75))
	_status.add_theme_font_override("font", _mono())
	_status.text = "click neighbours of the green head. red = IDS."
	vb.add_child(_status)

	var grid := GridContainer.new()
	grid.columns = W
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(grid)

	for y in H:
		for x in W:
			var p := Vector2i(x, y)
			var b := Button.new()
			b.custom_minimum_size = Vector2(64, 64)
			b.add_theme_font_size_override("font_size", 13)
			b.add_theme_font_override("font", _mono())
			b.pressed.connect(_on_cell.bind(p))
			grid.add_child(b)
			_buttons[p] = b

	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 12)
	vb.add_child(hb)
	_steps = Label.new()
	_steps.add_theme_font_size_override("font_size", 15)
	_steps.add_theme_color_override("font_color", Color(0.7, 0.9, 0.75))
	_steps.add_theme_font_override("font", _mono())
	hb.add_child(_steps)
	var reset := Button.new()
	reset.text = "RESET"
	_style_btn(reset, Color(0.3, 0.9, 1.0))
	reset.pressed.connect(_reset_path)
	hb.add_child(reset)
	var abort := Button.new()
	abort.text = "ABORT"
	_style_btn(abort, Color(1, 0.35, 0.35))
	abort.focus_mode = Control.FOCUS_NONE # ESC / B walks away; A never quits by accident
	abort.pressed.connect(func() -> void: _finish(false))
	hb.add_child(abort)
	# CRT scanlines over the whole minigame.
	var crt := ColorRect.new()
	crt.set_anchors_preset(Control.PRESET_FULL_RECT)
	crt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/crt.gdshader") as Shader
	crt.material = mat
	add_child(crt)


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


func _key(p: Vector2i) -> bool:
	return _buttons.has(p)


func _on_cell(p: Vector2i) -> void:
	if _done:
		return
	AudioManager.play_key()
	var head: Vector2i = _path[_path.size() - 1]
	if p == head:
		return
	# Backtrack?
	if _path.size() >= 2 and p == _path[_path.size() - 2]:
		_path.pop_back()
		_refresh()
		return
	# Extend only orthogonal neighbour, not visited. Distant clicks
	# (incl. far IDS) are ignored, not trips.
	if _path.has(p):
		return
	var d := Vector2i(absi(p.x - head.x), absi(p.y - head.y))
	if d != Vector2i(1, 0) and d != Vector2i(0, 1):
		_status.text = "only orthogonal neighbours of the head."
		return
	if p in IDS:
		_fails += 1
		_status.text = "IDS TRIP! (%d) trace burned — resetting." % _fails
		AudioManager.play_fail()
		SceneRouter.glitch_pulse(0.7, 0.4)
		_reset_path()
		return
	if _path.size() > MAX_STEPS:
		_status.text = "trace too long (max %d). reset." % MAX_STEPS
		AudioManager.play_fail()
		return
	_path.append(p)
	_refresh()
	if p == TARGET:
		var steps := _path.size() - 1
		var rating := "LOUD"
		if steps <= 9:
			rating = "GHOST"
		elif steps <= 12:
			rating = "CLEAN"
		_status.text = "TARGET REACHED — %d steps. rating: %s." % [steps, rating]
		_finish(true)


func _reset_path() -> void:
	if _done:
		return
	_path = [START]
	_refresh()


func _refresh() -> void:
	_steps.text = "steps %d/%d   fails %d" % [_path.size() - 1, MAX_STEPS, _fails]
	var head: Vector2i = _path[_path.size() - 1]
	for p in _buttons.keys():
		var b: Button = _buttons[p]
		var label := "%d,%d" % [p.x, p.y]
		var bg := Color(0.04, 0.08, 0.06)
		var fg := Color(0.6, 0.85, 0.68)
		if p == START:
			label = "ENTRY"
			bg = Color(0.05, 0.35, 0.15)
			fg = Color(0.5, 1, 0.6)
		elif p == TARGET:
			label = "TARGET"
			bg = Color(0.35, 0.08, 0.08)
			fg = Color(1, 0.6, 0.55)
		elif p in IDS:
			label = "IDS"
			bg = Color(0.22, 0.05, 0.05)
			fg = Color(1, 0.35, 0.3)
		if p in _path:
			var idx := _path.find(p)
			if p == head and p != TARGET:
				label = "◎"
			elif p != START and p != TARGET:
				label = str(idx)
			bg = Color(0.0, 0.55, 0.25)
			fg = Color(0, 0, 0)
		b.text = label
		var sb := StyleBoxFlat.new()
		sb.bg_color = bg
		sb.border_color = fg
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(4)
		b.add_theme_stylebox_override("normal", sb)
		var hov := sb.duplicate() as StyleBoxFlat
		hov.bg_color = bg.lightened(0.25)
		b.add_theme_stylebox_override("hover", hov)
		var pr := sb.duplicate() as StyleBoxFlat
		pr.bg_color = bg.lightened(0.45)
		b.add_theme_stylebox_override("pressed", pr)
		b.add_theme_color_override("font_color", fg)


func _finish(success: bool) -> void:
	if _done:
		return
	_done = true
	if success:
		AudioManager.play_success()
		GameState.add_xp(20)
		GameState.set_flag("recon_act2_done", true)
	else:
		AudioManager.play_fail()
	await get_tree().create_timer(0.8, true).timeout
	if not is_instance_valid(self): return
	emit_signal("finished", success)
