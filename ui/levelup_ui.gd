class_name LevelUpUI
extends Modal
## Spend skill points, then pick a perk on even levels.

var _title: Label
var _rows: VBoxContainer
var _perk_list: VBoxContainer
var _info: RichTextLabel
var _confirm: Button
var _spent: Dictionary = {}
var _points: int = 0
var _perk: String = ""
var _perk_only: bool = false
var _perk_scroll: ScrollContainer


func _build() -> void:
	var p := panel(1060, 640)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	p.add_child(vb)
	_title = UI.label("", 24, UI.AMBER)
	vb.add_child(_title)
	var hb := HBoxContainer.new()
	hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hb.add_theme_constant_override("separation", 20)
	vb.add_child(hb)
	_rows = VBoxContainer.new()
	_rows.custom_minimum_size = Vector2(430, 0)
	hb.add_child(_rows)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(right)
	right.add_child(UI.label("PERK", 16, UI.GREEN_DIM))
	_perk_scroll = ScrollContainer.new()
	_perk_scroll.follow_focus = true
	_perk_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_perk_scroll)
	_perk_list = VBoxContainer.new()
	_perk_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_perk_scroll.add_child(_perk_list)
	_info = UI.rich(15)
	_info.custom_minimum_size = Vector2(0, 90)
	right.add_child(_info)
	_confirm = UI.button("[ CONFIRM ]", 20)
	_confirm.pressed.connect(_on_confirm)
	vb.add_child(_confirm)


func open() -> void:
	if GameState.pending_levels <= 0:
		return
	_perk_only = false
	_spent = {}
	_points = GameState.skill_points_per_level()
	_perk = ""
	_title.text = "LEVEL %d  —  distribute %d skill points" % [GameState.level + 1, _points]
	open_modal()
	AudioManager.play_levelup()
	_refresh()
	await closed


func open_perk_only() -> void:
	if GameState.perk_points <= 0:
		return
	_perk_only = true
	_spent = {}
	_points = 0
	_perk = ""
	_title.text = "CHOOSE A PERK"
	open_modal()
	_refresh()
	await closed


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if (event as InputEventKey).physical_keycode == KEY_ESCAPE:
		close_modal()
	get_viewport().set_input_as_handled()


func _will_get_perk() -> bool:
	if _perk_only:
		return GameState.perk_points > 0
	return (GameState.level + 1) % 2 == 0 or GameState.perk_points > 0


func _refresh() -> void:
	# Rebuilding frees the focused button: remember which one it was (pad / keys).
	var fo := get_viewport().gui_get_focus_owner()
	var fkey := str(fo.get_meta("fk", "")) if fo != null and is_ancestor_of(fo) else ""
	if _perk != "" and not _perk_ok(_perk):
		_perk = "" # un-spending a point can make the chosen perk unreachable
	clear(_rows)
	if not _perk_only:
		_rows.add_child(UI.label("Points left: %d" % _points, 18, UI.WHITE))
		for s in DB.SKILLS:
			var ss := str(s)
			var base := int(GameState.base_skills.get(ss, 15))
			var add := int(_spent.get(ss, 0))
			var hb := HBoxContainer.new()
			var minus := UI.button(" - ", 18)
			minus.pressed.connect(func() -> void:
				if int(_spent.get(ss, 0)) > 0:
					_spent[ss] = int(_spent[ss]) - 1
					_points += 1
					_refresh())
			minus.set_meta("fk", "m_" + ss)
			minus.focus_entered.connect(func() -> void: _info.text = DB.SKILL_DESC[ss])
			hb.add_child(minus)
			var lbl := UI.label("%-10s %3d%s" % [DB.SKILL_NAMES[ss], base + add, (" (+%d)" % add) if add > 0 else ""], 18, UI.WHITE if add > 0 else UI.GREEN)
			lbl.custom_minimum_size = Vector2(260, 0)
			hb.add_child(lbl)
			var plus := UI.button(" + ", 18)
			plus.pressed.connect(func() -> void:
				if _points > 0 and base + int(_spent.get(ss, 0)) < 100:
					_spent[ss] = int(_spent.get(ss, 0)) + 1
					_points -= 1
					_refresh())
			plus.set_meta("fk", "p_" + ss)
			plus.focus_entered.connect(func() -> void: _info.text = DB.SKILL_DESC[ss])
			hb.add_child(plus)
			hb.mouse_entered.connect(func() -> void: _info.text = DB.SKILL_DESC[ss])
			_rows.add_child(hb)
	clear(_perk_list)
	if _will_get_perk():
		for p in DB.PERKS:
			var pd: Dictionary = p
			var id := str(pd["id"])
			var ok := _perk_ok(id)
			if GameState.perk_rank(id) >= int(pd["ranks"]):
				continue
			var req := ""
			for s in (pd["req"] as Dictionary).keys():
				req += " %s %d" % [DB.SKILL_NAMES[s], int(pd["req"][s])]
			var b := UI.button("%s%s  (L%d%s)" % ["▶ " if _perk == id else "", str(pd["name"]), int(pd["level"]), req], 15)
			b.add_theme_color_override("font_color", UI.WHITE if _perk == id else (UI.GREEN if ok else UI.GREEN_DIM))
			b.disabled = not ok
			b.set_meta("fk", "k_" + id)
			b.pressed.connect(func() -> void:
				_perk = id
				_refresh())
			b.mouse_entered.connect(func() -> void: _info.text = "[b]%s[/b]\n%s" % [str(pd["name"]), str(pd["desc"])])
			b.focus_entered.connect(func() -> void: _info.text = "[b]%s[/b]\n%s" % [str(pd["name"]), str(pd["desc"])])
			_perk_list.add_child(b)
	else:
		_perk_list.add_child(UI.label("Perks come every even level.", 15, UI.GREEN_DIM))
	var ready := (_points == 0 or _perk_only) and (not _will_get_perk() or _perk != "" or not _any_perk_available())
	_confirm.disabled = not ready
	_confirm.text = "[ CONFIRM ]" if ready else ("[ spend all points ]" if _points > 0 else "[ pick a perk ]")
	if fkey != "":
		_refocus.call_deferred(fkey)


func _refocus(fkey: String) -> void:
	for root in [_rows, _perk_list]:
		var stack: Array = [root]
		while not stack.is_empty():
			var n: Node = stack.pop_back()
			if n is BaseButton and str(n.get_meta("fk", "")) == fkey and not (n as BaseButton).disabled:
				(n as Control).grab_focus()
				return
			stack.append_array(n.get_children())
	# A perk button that just went disabled: fall back to CONFIRM.
	if not _confirm.disabled:
		_confirm.grab_focus()


func _perk_ok(id: String) -> bool:
	var p := DB.perk(id)
	var lvl := GameState.level + (0 if _perk_only else 1)
	if lvl < int(p["level"]) or GameState.perk_rank(id) >= int(p["ranks"]):
		return false
	for s in (p["req"] as Dictionary).keys():
		if int(GameState.base_skills.get(s, 0)) + int(_spent.get(s, 0)) < int(p["req"][s]):
			return false
	return true


func _any_perk_available() -> bool:
	for p in DB.PERKS:
		if _perk_ok(str((p as Dictionary)["id"])):
			return true
	return false


func _on_confirm() -> void:
	if _perk_only:
		if _perk != "":
			GameState.take_perk(_perk)
		close_modal()
		return
	var perk_after := _perk
	var gets_perk := (GameState.level + 1) % 2 == 0
	GameState.apply_level_up(_spent, "")
	if perk_after != "" and (gets_perk or GameState.perk_points > 0):
		GameState.take_perk(perk_after)
	close_modal()
	if GameState.pending_levels > 0:
		open.call_deferred()
