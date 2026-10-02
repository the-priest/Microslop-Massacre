class_name RobotPopup
extends CanvasLayer
## The game's Vault Boy moment. When Elliot levels up, Mr. Robot slides in
## on a green CRT card (rendered live with the game's own character model),
## raises a fist, and tells him about it. The same card announces completed
## quests and new objectives, so it's always clear when something is done
## and what comes next. Popups queue; nothing here pauses the game.

var game: Node
var _queue: Array = []
var _busy: bool = false
var _card: Panel
var _portrait_box: SubViewportContainer
var _vp: SubViewport
var _model: MeshInstance3D
var _title: Label
var _sub: Label
var _line: Label
var _hint: Label
var _t: float = 0.0
var _raise_t: float = -1.0

const W := 560.0
const H := 196.0

const LEVEL_LINES := [
	"Level %d. Look at you, kid. Harder to kill every day. I like that.",
	"Another notch. Don't get sentimental about it. Get dangerous.",
	"Level %d. Every system has an admin. Today a little more of it is you.",
	"You're leveling up. They're not. That's the whole war, right there.",
	"Level %d. See? The world rewards you the second you stop asking it for permission.",
	"Stronger, faster, meaner. E Corp just moved you to a different spreadsheet, kid.",
	"Level %d. Your father would've been proud. Or scared. He had the same look for both.",
]


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_card.visible = false


func _build() -> void:
	_card = Panel.new()
	_card.size = Vector2(W, H)
	_card.position = Vector2(-W - 40.0, 170.0)
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.01, 0.05, 0.025, 0.93)
	sb.border_color = UI.GREEN
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.shadow_color = Color(0.1, 1.0, 0.4, 0.25)
	sb.shadow_size = 10
	_card.add_theme_stylebox_override("panel", sb)
	add_child(_card)
	# Portrait: Mr. Robot, live, in a little world of his own.
	_portrait_box = SubViewportContainer.new()
	_portrait_box.position = Vector2(10, 10)
	_portrait_box.size = Vector2(176, H - 20)
	_portrait_box.stretch = true
	_portrait_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(_portrait_box)
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.transparent_bg = true
	_vp.size = Vector2i(176, int(H - 20))
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_portrait_box.add_child(_vp)
	var root := Node3D.new()
	_vp.add_child(root)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.45, 2.5)
	cam.fov = 42.0
	root.add_child(cam)
	cam.look_at(Vector3(0, 1.38, 0), Vector3.UP)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 30, 0)
	sun.light_color = Color(0.75, 1.0, 0.8)
	sun.light_energy = 3.0
	root.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-10, -140, 0)
	fill.light_color = Color(0.3, 0.9, 0.5)
	fill.light_energy = 0.9
	root.add_child(fill)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.35, 0.55, 0.4)
	e.ambient_light_energy = 1.7
	env.environment = e
	root.add_child(env)
	_model = MeshInstance3D.new()
	_model.mesh = PersonMesh.mesh(PersonMesh.preset("mr_robot"))
	_model.material_override = Mats.npc
	root.add_child(_model)
	# Green scanlines over the portrait.
	var scan := ColorRect.new()
	scan.position = _portrait_box.position
	scan.size = _portrait_box.size
	scan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/crt.gdshader") as Shader
	scan.material = mat
	_card.add_child(scan)
	var frame := Panel.new()
	frame.position = _portrait_box.position
	frame.size = _portrait_box.size
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fs := StyleBoxFlat.new()
	fs.bg_color = Color(0, 0, 0, 0)
	fs.border_color = UI.GREEN_DIM
	fs.set_border_width_all(1)
	frame.add_theme_stylebox_override("panel", fs)
	_card.add_child(frame)
	# Text.
	var tx := 200.0
	_sub = UI.label("", 13, UI.GREEN_DIM)
	_sub.position = Vector2(tx, 14)
	_sub.size = Vector2(W - tx - 14, 18)
	_card.add_child(_sub)
	_title = UI.label("", 30, UI.AMBER)
	_title.position = Vector2(tx, 32)
	_title.size = Vector2(W - tx - 14, 40)
	_title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_title.add_theme_constant_override("outline_size", 4)
	_card.add_child(_title)
	_line = UI.label("", 16, UI.WHITE)
	_line.position = Vector2(tx, 78)
	_line.size = Vector2(W - tx - 16, 84)
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card.add_child(_line)
	_hint = UI.label("", 13, UI.GREEN)
	_hint.position = Vector2(tx, H - 28)
	_hint.size = Vector2(W - tx - 14, 18)
	_card.add_child(_hint)


# ------------------------------------------------------------------ public
func level_up(level: int) -> void:
	_queue.append({"kind": "level", "level": level})
	_pump()


func quest_done(title: String, xp: int) -> void:
	_queue.append({"kind": "quest", "title": title, "xp": xp})
	_pump()


func objective(title: String, text: String) -> void:
	# A newer objective for the same quest replaces one still waiting.
	for q in _queue:
		if str((q as Dictionary).get("kind", "")) == "objective" and str(q["title"]) == title:
			q["text"] = text
			return
	_queue.append({"kind": "objective", "title": title, "text": text})
	_pump()


func is_showing() -> bool:
	return _busy


# ------------------------------------------------------------------ playback
func _pump() -> void:
	if _busy or _queue.is_empty() or not is_inside_tree():
		return
	_busy = true
	var item: Dictionary = _queue.pop_front()
	await _show(item)
	_busy = false
	_pump()


func _show(item: Dictionary) -> void:
	var kind := str(item["kind"])
	var dur := 5.5
	var robot := true
	match kind:
		"level":
			var lv := int(item["level"])
			_sub.text = "MR. ROBOT  //  FSOCIETY00.DAT"
			_title.text = "LEVEL %d" % lv
			_title.add_theme_color_override("font_color", UI.AMBER)
			_line.text = "\"%s\"" % _level_line(lv)
			if GameState.pending_levels > 0:
				_hint.text = "Spend your skill points  —  [%s]" % Pad.glyph("TAB")
			elif GameState.perk_points > 0:
				_hint.text = "A perk is waiting  —  [%s]" % Pad.glyph("TAB")
			else:
				_hint.text = ""
			AudioManager.play_levelup()
			dur = 6.5
		"quest":
			_sub.text = "QUEST COMPLETE"
			_title.text = str(item["title"]).to_upper()
			_title.add_theme_color_override("font_color", UI.GREEN)
			_line.text = "\"%s\"" % _quest_line()
			_hint.text = "+%d XP" % int(item["xp"]) if int(item["xp"]) > 0 else ""
			AudioManager.play_success()
			dur = 5.0
		"objective":
			robot = false
			_sub.text = "NEW OBJECTIVE  //  " + str(item["title"]).to_upper()
			_title.text = ""
			_line.text = str(item["text"])
			_hint.text = "Follow the marker on your compass"
			AudioManager.play_quest()
			dur = 5.0
	_portrait_box.visible = robot
	for c in _card.get_children():
		if c is ColorRect or (c is Panel and c != _card):
			(c as Control).visible = robot
	var tx := 200.0 if robot else 18.0
	for l in [_sub, _title, _line, _hint]:
		(l as Label).position.x = tx
		(l as Label).size.x = W - tx - 16
	_line.position.y = 78.0 if robot else 40.0
	_line.size.y = 84.0 if robot else 110.0
	_card.size.y = H if robot else 150.0
	_hint.position.y = _card.size.y - 28.0
	if game != null and game.hud != null and game.hud.hidden_all:
		# Don't talk over a conversation or a cutscene: wait for it.
		var w := 0.0
		while game.hud.hidden_all and w < 120.0:
			if not is_inside_tree():
				return
			await get_tree().process_frame
			w += get_process_delta_time()
	if not _queue.is_empty() and kind == "objective":
		dur = 3.4 # more is coming: keep it moving
	_card.visible = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if robot else SubViewport.UPDATE_DISABLED
	_t = 0.0
	_raise_t = 0.55 if kind == "level" else (0.8 if kind == "quest" else -1.0)
	_model.rotation.y = PI - 1.1
	_line.visible_ratio = 0.0
	var tw := create_tween()
	tw.tween_property(_card, "position:x", 24.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_line, "visible_ratio", 1.0, 1.4)
	if not is_inside_tree():
		return
	await get_tree().create_timer(dur, true, false, true).timeout
	var tw2 := create_tween()
	tw2.tween_property(_card, "position:x", -W - 40.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw2.finished
	_card.visible = false
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED


func _process(delta: float) -> void:
	if not _card.visible or not _portrait_box.visible:
		return
	_t += delta
	# Turn to face you, then the fist goes up; he talks while the line types out.
	# (People face -Z; the portrait camera sits at +Z, so "facing you" is PI.)
	_model.rotation.y = lerp_angle(_model.rotation.y, PI + 0.25 * sin(_t * 0.7), minf(1.0, delta * 5.0))
	var raise := 0.0
	if _raise_t >= 0.0 and _t > _raise_t:
		raise = clampf((_t - _raise_t) / 0.35, 0.0, 1.0)
		if _t > _raise_t + 2.6:
			raise = clampf(1.0 - (_t - _raise_t - 2.6) / 0.5, 0.0, 1.0)
	_model.set_instance_shader_parameter("raise", raise)
	_model.set_instance_shader_parameter("talk", 1.0 if _line.visible_ratio < 1.0 else 0.0)
	_model.position.y = sin(_t * 2.0) * 0.01


func _level_line(lv: int) -> String:
	var GS := GameState
	if lv == 5:
		return "Level five. Now you're somebody worth watching. Don't let them watch back."
	if lv == 10:
		return "Double digits, kid. The Dark Army just opened a file on you. Frame it."
	if lv == 20:
		return "Level twenty. Whiterose keeps a clock for people like you now. Tick tock."
	if int(GS.stats.get("innocents", 0)) >= 6:
		return "Level %d. You're getting good at the wrong things, kid. ...Or the right ones. I stopped being sure." % lv
	if GS.stability < 30:
		return "Level %d. Don't look at me like that. You did this. I just watched." % lv
	if GS.has_flag("kingpin"):
		return "Level %d. Nine corners and a crown. Just don't forget who taught you to take things." % lv
	var line: String = LEVEL_LINES[randi() % LEVEL_LINES.size()]
	return line % lv if line.contains("%d") else line


func _quest_line() -> String:
	var lines := [
		"One down. The city's still standing. For now.",
		"Done. Don't celebrate. Celebrating is how they find you.",
		"That's how it's done, kid. Quiet. Clean. Next.",
		"Good. Now don't think about it too hard. Thinking is how the doubt gets in.",
		"Another loose end, tied. Or cut. Depends how you did it.",
	]
	return lines[randi() % lines.size()]
