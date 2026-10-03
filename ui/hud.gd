class_name HUD
extends CanvasLayer
## In-game heads-up display.

var game: Node = null
var compass: Compass
var _root: Control
var _hp_bar: ProgressBar
var _hp_lbl: Label
var _focus_bar: ProgressBar
var _ammo_lbl: Label
var _weapon_lbl: Label
var _cross: Control
var _prompt: Label
var _prompt_name: Label
var _notes: VBoxContainer
var _sub: RichTextLabel
var _sub_t: float = 0.0
var _stealth: Label
var _clock: Label
var _loc: Label
var _loc_t: float = 0.0
var _stab: Label
var _wanted: Label
var _target_box: VBoxContainer
var _target_name: Label
var _target_bar: ProgressBar
var _xp_lbl: Label
var _xp_t: float = 0.0
var _xp_acc: int = 0
var _lvl_hint: Label
var _hit_t: float = 0.0
var _hit_crit: bool = false
var _dmg_rect: ColorRect
var _dmg_mat: ShaderMaterial
var _glitch_rect: ColorRect
var _glitch_mat: ShaderMaterial
var _glitch_t: float = 0.0
var _crt: ColorRect
var _hurt: float = 0.0
var _center_msg: Label
var _center_t: float = 0.0
var _quest_lbl: Label
var _car_lbl: Label
var hidden_all: bool = false


func _ready() -> void:
	layer = 10
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UI.theme()
	add_child(_root)
	# Overlays (bottom of stack).
	_dmg_rect = ColorRect.new()
	_dmg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dmg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dmg_mat = ShaderMaterial.new()
	_dmg_mat.shader = load("res://shaders/damage.gdshader")
	_dmg_rect.material = _dmg_mat
	_root.add_child(_dmg_rect)
	_glitch_rect = ColorRect.new()
	_glitch_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_glitch_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glitch_mat = ShaderMaterial.new()
	_glitch_mat.shader = load("res://shaders/glitch.gdshader")
	_glitch_rect.material = _glitch_mat
	_glitch_rect.visible = false
	_root.add_child(_glitch_rect)
	_crt = ColorRect.new()
	_crt.set_anchors_preset(Control.PRESET_FULL_RECT)
	_crt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cm := ShaderMaterial.new()
	cm.shader = load("res://shaders/crt.gdshader")
	cm.set_shader_parameter("scan_strength", 0.06)
	cm.set_shader_parameter("vignette_strength", 0.28)
	_crt.material = cm
	_crt.visible = bool(Settings.get_v("crt"))
	_root.add_child(_crt)
	# Crosshair.
	_cross = Control.new()
	_cross.set_anchors_preset(Control.PRESET_CENTER)
	_cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cross.draw.connect(_draw_cross)
	_root.add_child(_cross)
	# Prompt.
	_prompt = UI.label("", 20, UI.GREEN)
	_prompt.set_anchors_preset(Control.PRESET_CENTER)
	_prompt.position = Vector2(-200, 26)
	_prompt.size = Vector2(400, 26)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_prompt.add_theme_constant_override("outline_size", 6)
	_root.add_child(_prompt)
	_prompt_name = UI.label("", 17, UI.WHITE)
	_prompt_name.set_anchors_preset(Control.PRESET_CENTER)
	_prompt_name.position = Vector2(-200, 50)
	_prompt_name.size = Vector2(400, 24)
	_prompt_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_name.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_prompt_name.add_theme_constant_override("outline_size", 6)
	_root.add_child(_prompt_name)
	# Bottom-left: HP + compass.
	var bl := VBoxContainer.new()
	# Pinned to the bottom-left corner and growing upward, so a long objective
	# pushes the block up instead of running off the bottom of the screen.
	bl.anchor_left = 0.0
	bl.anchor_right = 0.0
	bl.anchor_top = 1.0
	bl.anchor_bottom = 1.0
	bl.offset_left = 24
	bl.offset_right = 24 + 400
	bl.offset_top = -98
	bl.offset_bottom = -12
	bl.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bl.alignment = BoxContainer.ALIGNMENT_END
	bl.add_theme_constant_override("separation", 4)
	_root.add_child(bl)
	var hp_row := HBoxContainer.new()
	bl.add_child(hp_row)
	var hp_t := UI.label("HP", 15, UI.GREEN)
	hp_row.add_child(hp_t)
	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size = Vector2(230, 12)
	_hp_bar.show_percentage = false
	_hp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hp_row.add_child(_hp_bar)
	_hp_lbl = UI.label("", 13, UI.GREEN_DIM)
	hp_row.add_child(_hp_lbl)
	compass = Compass.new()
	compass.custom_minimum_size = Vector2(380, 26)
	bl.add_child(compass)
	_car_lbl = UI.label("", 16, UI.GREEN)
	bl.add_child(_car_lbl)
	_quest_lbl = UI.label("", 13, UI.AMBER)
	_quest_lbl.custom_minimum_size = Vector2(380, 0)
	_quest_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bl.add_child(_quest_lbl)
	# Bottom-right: focus + weapon + ammo.
	var br := VBoxContainer.new()
	br.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	br.position = Vector2(-300, -92)
	br.custom_minimum_size = Vector2(276, 0)
	br.alignment = BoxContainer.ALIGNMENT_END
	_root.add_child(br)
	_weapon_lbl = UI.label("", 15, UI.GREEN_DIM)
	_weapon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	br.add_child(_weapon_lbl)
	_ammo_lbl = UI.label("", 26, UI.GREEN)
	_ammo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	br.add_child(_ammo_lbl)
	var fr := HBoxContainer.new()
	fr.alignment = BoxContainer.ALIGNMENT_END
	br.add_child(fr)
	fr.add_child(UI.label("FOCUS", 13, UI.GREEN))
	_focus_bar = ProgressBar.new()
	_focus_bar.custom_minimum_size = Vector2(200, 10)
	_focus_bar.show_percentage = false
	_focus_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fr.add_child(_focus_bar)
	# Top-left: notifications.
	_notes = VBoxContainer.new()
	_notes.position = Vector2(24, 20)
	_notes.custom_minimum_size = Vector2(520, 0)
	_notes.add_theme_constant_override("separation", 2)
	_root.add_child(_notes)
	# Top-right: clock, location, stability, wanted.
	var tr := VBoxContainer.new()
	tr.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	tr.position = Vector2(-330, 16)
	tr.custom_minimum_size = Vector2(310, 0)
	_root.add_child(tr)
	_clock = UI.label("", 16, UI.GREEN)
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tr.add_child(_clock)
	_stab = UI.label("", 14, UI.GREEN_DIM)
	_stab.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tr.add_child(_stab)
	_wanted = UI.label("", 15, UI.RED)
	_wanted.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tr.add_child(_wanted)
	_lvl_hint = UI.label("LEVEL UP  —  [TAB]", 16, UI.AMBER)
	_lvl_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_lvl_hint.visible = false
	tr.add_child(_lvl_hint)
	# Top-center: stealth + target.
	_stealth = UI.label("", 18, UI.GREEN)
	_stealth.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_stealth.position = Vector2(-150, 20)
	_stealth.size = Vector2(300, 24)
	_stealth.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_stealth)
	_target_box = VBoxContainer.new()
	_target_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_target_box.position = Vector2(-150, 50)
	_target_box.custom_minimum_size = Vector2(300, 0)
	_root.add_child(_target_box)
	_target_name = UI.label("", 15, UI.WHITE)
	_target_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_target_box.add_child(_target_name)
	_target_bar = ProgressBar.new()
	_target_bar.custom_minimum_size = Vector2(300, 8)
	_target_bar.show_percentage = false
	var fill := UI.box(UI.RED, UI.RED, 0, 0)
	_target_bar.add_theme_stylebox_override("fill", fill)
	_target_box.add_child(_target_bar)
	_target_box.visible = false
	# Location popup (center-top-ish).
	_loc = UI.label("", 30, UI.GREEN)
	_loc.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_loc.position = Vector2(-400, 110)
	_loc.size = Vector2(800, 40)
	_loc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loc.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_loc.add_theme_constant_override("outline_size", 8)
	_loc.modulate.a = 0.0
	_root.add_child(_loc)
	_center_msg = UI.label("", 20, UI.WHITE)
	_center_msg.set_anchors_preset(Control.PRESET_CENTER)
	_center_msg.position = Vector2(-400, -120)
	_center_msg.size = Vector2(800, 30)
	_center_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center_msg.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_center_msg.add_theme_constant_override("outline_size", 6)
	_root.add_child(_center_msg)
	# XP popup.
	_xp_lbl = UI.label("", 16, UI.GREEN)
	_xp_lbl.set_anchors_preset(Control.PRESET_CENTER)
	_xp_lbl.position = Vector2(40, -60)
	_xp_lbl.size = Vector2(200, 24)
	_root.add_child(_xp_lbl)
	# Subtitles.
	_sub = UI.rich(20)
	_sub.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_sub.position = Vector2(-460, -170)
	_sub.size = Vector2(920, 60)
	_sub.fit_content = true
	_sub.scroll_active = false
	_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sub.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_sub.add_theme_constant_override("outline_size", 6)
	_root.add_child(_sub)
	GameState.notify.connect(notify)
	GameState.xp_gained.connect(_on_xp)
	GameState.quest_updated.connect(_on_quest)
	GameState.achievement_unlocked.connect(func(t: String, d: String) -> void:
		notify("ACHIEVEMENT: %s — %s" % [t, d], "achieve"))
	Settings.applied.connect(func() -> void: _crt.visible = bool(Settings.get_v("crt")))


func set_visible_all(v: bool) -> void:
	hidden_all = not v
	_root.visible = v


func _process(delta: float) -> void:
	if game == null or game.player == null:
		return
	var p: Player = game.player
	var mh := GameState.max_hp()
	_hp_bar.max_value = mh
	_hp_bar.value = GameState.hp
	_hp_lbl.text = "%d/%d" % [int(GameState.hp), int(mh)]
	_focus_bar.max_value = GameState.max_focus()
	_focus_bar.value = GameState.focus
	var wid := str(GameState.equipped["weapon"])
	var w := DB.item(wid)
	_weapon_lbl.text = str(w.get("name", ""))
	if w.has("mag"):
		_ammo_lbl.text = "%d / %d" % [int(GameState.mags.get(wid, 0)), GameState.count(str(w.get("ammo", "")))]
	else:
		_ammo_lbl.text = "—"
	compass.heading = p.yaw
	compass.markers = game.compass_markers()
	compass.queue_redraw()
	if p.driving != null and is_instance_valid(p.driving):
		var car: Vehicle = p.driving
		if car is Aircraft:
			var ac := car as Aircraft
			var hdg := int(fposmod(-rad_to_deg(ac.heading), 360.0))
			var line1 := "%s   %d%%%s" % [ac.display_name().to_upper(), int(ac.hp / float(ac.spec["hp"]) * 100.0), "   ▲ STOLEN" if ac.stolen else ""]
			var line2 := "%d KT    ALT %d FT    THR %d%%    HDG %03d" % [int(ac.speed * 1.944), int(maxf(0.0, ac.altitude if ac.airborne else 0.0) * 3.281), int(ac.throttle * 100.0), hdg]
			_car_lbl.text = line1 + "\n" + line2 + ("\n▲ %s ▲" % ac.warn if ac.warn != "" else "")
			var ars: String = game.air_races.status() if game.get("air_races") != null else ""
			if ars != "":
				_car_lbl.text += "\n" + ars
			_car_lbl.add_theme_color_override("font_color", UI.RED if ac.warn != "" or ac.hp < 40.0 else UI.GREEN)
		else:
			_car_lbl.text = "%d km/h    %s %d%%%s" % [int(absf(car.speed) * 3.6), car.display_name().to_upper(), int(car.hp), "   ▲ STOLEN" if car.stolen else ""]
			var ts: String = game.taxi.status() if game.get("taxi") != null else ""
			if ts == "" and game.get("emergency") != null:
				ts = game.emergency.status()
			if ts != "":
				_car_lbl.text += "\n" + ts
			_car_lbl.add_theme_color_override("font_color", UI.RED if car.hp < 30.0 else (UI.AMBER if car.hp < 60.0 else UI.GREEN))
	else:
		_car_lbl.text = ""
	var tq := GameState.tracked_quest
	if tq != "" and GameState.quest_state(tq) == "active":
		var objs := DB.quest_objectives(tq, GameState.quest_stage(tq))
		var lp := DB.line_pos(tq)
		var lt := DB.line_title(DB.quest_line(tq)).to_upper()
		var head := "◆ " + str(DB.QUESTS.get(tq, {}).get("title", tq)).to_upper()
		if int(lp[1]) > 1:
			head = "◆ %s  ·  %d/%d  ·  %s" % [lt, int(lp[0]), int(lp[1]), str(DB.QUESTS.get(tq, {}).get("title", tq)).to_upper()]
		var t := head + "\n"
		for o in objs:
			t += "▸ " + str(o["text"]) + "\n"
		_quest_lbl.text = t.strip_edges()
	else:
		_quest_lbl.text = ""
	_clock.text = "%s  ·  %s" % [GameState.clock_text(), GameState.date_text()]
	var st := GameState.stability
	var bars := int(round(float(st) / 10.0))
	_stab.text = "STABILITY " + "▮".repeat(bars) + "▯".repeat(10 - bars)
	_stab.add_theme_color_override("font_color", UI.RED if st < 30 else (UI.AMBER if st < 55 else UI.GREEN_DIM))
	if GameState.is_wanted():
		var h := GameState.heat
		var stars := "★".repeat(h) + "☆".repeat(5 - h)
		var who := "FBI + POLICE" if h >= 5 else "POLICE"
		var lost: float = game.unseen_t if game != null and game.get("unseen_t") != null else 0.0
		if lost > 0.0:
			# Out of sight: the stars flash while they search.
			var on := int(Time.get_ticks_msec() / 400) % 2 == 0
			_wanted.text = "%s  %s\nSEARCHING  —  stay out of sight" % [who, stars if on else "     "]
			_wanted.add_theme_color_override("font_color", UI.AMBER)
		else:
			_wanted.text = "%s  %s" % [who, stars]
			_wanted.add_theme_color_override("font_color", UI.RED)
	else:
		_wanted.text = ""
	_lvl_hint.visible = GameState.pending_levels > 0
	if _lvl_hint.visible:
		_lvl_hint.text = "LEVEL UP  —  [%s]" % Pad.glyph("TAB")
	# Stealth.
	if p.crouching:
		var s: String = ["[ HIDDEN ]", "[ CAUTION ]", "[ DANGER ]"][clampi(p.detection, 0, 2)]
		_stealth.text = s
		_stealth.add_theme_color_override("font_color", [UI.GREEN, UI.AMBER, UI.RED][clampi(p.detection, 0, 2)])
	else:
		_stealth.text = ""
	# Prompt.
	var it: Object = p.interact_target
	if it != null and is_instance_valid(it) and not p.frozen:
		var info: Dictionary = it.call("interact_info")
		if info.is_empty():
			_prompt.text = ""
			_prompt_name.text = ""
		else:
			_prompt.text = "%s) %s" % [Pad.glyph("E"), str(info.get("verb", "Use"))]
			_prompt_name.text = str(info.get("name", ""))
			_prompt.add_theme_color_override("font_color", UI.RED if bool(info.get("locked", false)) else UI.GREEN)
	else:
		_prompt.text = ""
		_prompt_name.text = ""
	# Target health.
	var tgt: Variant = game.aim_target()
	if tgt != null and is_instance_valid(tgt) and not p.frozen:
		var n := tgt as NPC
		_target_box.visible = true
		_target_name.text = n.display_name
		_target_bar.max_value = n.max_hp
		_target_bar.value = maxf(0.0, n.hp)
	else:
		_target_box.visible = false
	# Timers.
	_sub_t -= delta
	if _sub_t <= 0.0:
		_sub.text = ""
	_loc_t -= delta
	_loc.modulate.a = clampf(_loc_t, 0.0, 1.0)
	_center_t -= delta
	_center_msg.modulate.a = clampf(_center_t, 0.0, 1.0)
	_xp_t -= delta
	if _xp_t <= 0.0:
		_xp_lbl.text = ""
		_xp_acc = 0
	_hit_t = maxf(0.0, _hit_t - delta)
	_cross.visible = not p.frozen and not hidden_all
	_cross.queue_redraw()
	for c in _notes.get_children():
		var lbl := c as Label
		var t2 := float(lbl.get_meta("t", 0.0)) - delta
		lbl.set_meta("t", t2)
		lbl.modulate.a = clampf(t2, 0.0, 1.0)
		if t2 <= 0.0:
			lbl.queue_free()
	# Overlays.
	_hurt = maxf(0.0, _hurt - delta * 1.5)
	_dmg_mat.set_shader_parameter("hurt", _hurt)
	_dmg_mat.set_shader_parameter("low", clampf(1.0 - GameState.hp / (mh * 0.35), 0.0, 1.0))
	var gi := 0.0
	if st < 30:
		gi = (1.0 - float(st) / 30.0) * 0.25 * (0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.003))
	_glitch_t = maxf(0.0, _glitch_t - delta)
	gi = maxf(gi, _glitch_t)
	_glitch_rect.visible = gi > 0.02
	_glitch_mat.set_shader_parameter("intensity", gi)


func _draw_cross() -> void:
	if game == null or game.player == null:
		return
	var p: Player = game.player
	var w := p.weapon()
	var c := Color(1, 1, 1, 0.8)
	if p.interact_target != null:
		c = UI.GREEN
	if w.has("mag"):
		var sp := p.spread_deg(w)
		var px := tan(deg_to_rad(sp)) / tan(deg_to_rad(p.cam.fov * 0.5)) * float(get_viewport().get_visible_rect().size.y) * 0.5
		px = clampf(px, 4.0, 80.0)
		for dvec in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
			_cross.draw_line(dvec * px, dvec * (px + 7.0), c, 2.0)
	else:
		_cross.draw_circle(Vector2.ZERO, 2.5, c)
	if _hit_t > 0.0:
		var hc := UI.RED if _hit_crit else Color(1, 1, 1)
		for dvec in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			_cross.draw_line(dvec * 6.0, dvec * 13.0, hc, 2.0)


func notify(text: String, kind: String = "") -> void:
	var col := UI.GREEN
	match kind:
		"quest": col = UI.AMBER
		"warn": col = UI.RED
		"rep": col = UI.BLUE
		"level", "achieve": col = UI.AMBER
		"discover": col = UI.WHITE
	var l := UI.label(text, 16, col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 5)
	l.set_meta("t", 5.0)
	_notes.add_child(l)
	while _notes.get_child_count() > 7:
		_notes.get_child(0).queue_free()
		_notes.remove_child(_notes.get_child(0))
	if kind == "discover":
		AudioManager.play_discover()
	elif kind == "level":
		AudioManager.play_levelup()


func _on_xp(amount: int) -> void:
	_xp_acc += amount
	_xp_lbl.text = "+%d XP" % _xp_acc
	_xp_t = 2.0


func _on_quest(qid: String, stage: int, kind: String) -> void:
	var q: Dictionary = DB.QUESTS.get(qid, {})
	var title := str(q.get("title", qid))
	match kind:
		"started":
			var lp := DB.line_pos(qid)
			if int(lp[1]) > 1 and int(lp[0]) > 1:
				notify("NEXT IN %s (%d/%d): %s" % [DB.line_title(DB.quest_line(qid)).to_upper(), int(lp[0]), int(lp[1]), title], "quest")
			else:
				notify("QUEST STARTED: %s" % title, "quest")
			AudioManager.play_quest()
		"stage":
			var objs := DB.quest_objectives(qid, stage)
			for o in objs:
				if str(o["text"]) != "" and str(o["text"]) != "done" and game != null and game.robot_popup != null:
					game.robot_popup.objective(title, str(o["text"]))
		"done":
			notify("QUEST COMPLETED: %s" % title, "quest")
			if game != null and game.robot_popup != null:
				game.robot_popup.quest_done(title, int(q.get("xp", 0)))
			else:
				AudioManager.play_success()
		"failed":
			notify("QUEST FAILED: %s" % title, "warn")
			AudioManager.play_fail()


func subtitle(speaker: String, text: String, dur: float = 3.5) -> void:
	var c := UI.speaker_color(speaker)
	_sub.text = "[center][color=#%s]%s:[/color] %s[/center]" % [c.to_html(false), speaker.to_upper(), text]
	_sub_t = dur


func location(text: String) -> void:
	_loc.text = text
	_loc_t = 3.5


func center(text: String, dur: float = 2.5) -> void:
	_center_msg.text = text
	_center_t = dur


func hit_marker(crit: bool) -> void:
	_hit_t = 0.15
	_hit_crit = crit


func hurt(amount: float) -> void:
	_hurt = clampf(_hurt + amount / 40.0, 0.0, 1.0)


func glitch(strength: float = 0.6, dur: float = 0.5) -> void:
	_glitch_t = maxf(_glitch_t, strength)
	var tw := create_tween()
	tw.tween_property(self, "_glitch_t", 0.0, dur)
