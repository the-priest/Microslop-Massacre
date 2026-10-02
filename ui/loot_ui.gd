class_name LootUI
extends Modal
## Container transfer screen: take / take all / store. Stealing shows in red.

var _title: Label
var _left: VBoxContainer
var _right: VBoxContainer
var _info: Label
var _data: Dictionary = {}
var _stealing: bool = false
var took_anything: bool = false


func _build() -> void:
	var p := panel(1000, 600)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	p.add_child(vb)
	_title = UI.label("", 22, UI.GREEN)
	vb.add_child(_title)
	var hb := HBoxContainer.new()
	hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hb.add_theme_constant_override("separation", 20)
	vb.add_child(hb)
	var lcol := VBoxContainer.new()
	lcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(lcol)
	lcol.add_child(UI.label("CONTAINER  (click: take)", 14, UI.GREEN_DIM))
	var ls := ScrollContainer.new()
	ls.follow_focus = true
	ls.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lcol.add_child(ls)
	_left = VBoxContainer.new()
	_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ls.add_child(_left)
	var rcol := VBoxContainer.new()
	rcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(rcol)
	rcol.add_child(UI.label("YOU  (click: store)", 14, UI.GREEN_DIM))
	var rs := ScrollContainer.new()
	rs.follow_focus = true
	rs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rcol.add_child(rs)
	_right = VBoxContainer.new()
	_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rs.add_child(_right)
	_info = UI.label("[R] take all    [E/ESC/TAB] close", 14, UI.GREEN_DIM)
	vb.add_child(_info)


func open_container(title: String, data: Dictionary, stealing: bool) -> void:
	_data = data
	if not _data.has("items"):
		_data["items"] = {}
	if not _data.has("cash"):
		_data["cash"] = 0
	_stealing = stealing
	took_anything = false
	_info.text = "[A] take    [X] take all    [B] close" if Pad.using_pad else "[R] take all    [E/ESC/TAB] close"
	_title.text = ("STEAL: " if stealing else "") + title
	_title.add_theme_color_override("font_color", UI.RED if stealing else UI.GREEN)
	open_modal()
	AudioManager.play_blip()
	_refresh()
	await closed


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k := (event as InputEventKey).physical_keycode
	if k in [KEY_ESCAPE, KEY_TAB, KEY_E]:
		close_modal()
	elif k == KEY_R:
		_take_all()
	get_viewport().set_input_as_handled()


func _take_all() -> void:
	var items: Dictionary = _data["items"]
	for id in items.keys():
		var n := int(items[id])
		if n > 0:
			GameState.give(str(id), n, true)
			took_anything = true
	items.clear()
	if int(_data["cash"]) > 0:
		GameState.add_cash(int(_data["cash"]), true)
		GameState.stat_add("caps_found", int(_data["cash"]))
		took_anything = true
		_data["cash"] = 0
		AudioManager.play_coin()
	AudioManager.play_pickup()
	close_modal()


func _refresh() -> void:
	clear(_left)
	clear(_right)
	var items: Dictionary = _data["items"]
	if int(_data["cash"]) > 0:
		var cb := UI.button("$%d cash" % int(_data["cash"]), 17)
		cb.add_theme_color_override("font_color", UI.AMBER)
		cb.pressed.connect(func() -> void:
			GameState.add_cash(int(_data["cash"]), true)
			GameState.stat_add("caps_found", int(_data["cash"]))
			_data["cash"] = 0
			took_anything = true
			AudioManager.play_coin()
			_refresh())
		_left.add_child(cb)
	var keys := items.keys()
	keys.sort()
	for id in keys:
		var n := int(items[id])
		if n <= 0:
			items.erase(id)
			continue
		var iid := str(id)
		var b := UI.button("%s%s" % [DB.item_name(iid), (" (%d)" % n) if n > 1 else ""], 17)
		if _stealing:
			b.add_theme_color_override("font_color", UI.RED)
		b.pressed.connect(func() -> void:
			var cnt := int(items.get(iid, 0))
			var take_n := cnt if (Input.is_key_pressed(KEY_SHIFT) or str(DB.item(iid).get("type", "")) == "ammo") else 1
			GameState.give(iid, take_n, true)
			items[iid] = cnt - take_n
			if int(items[iid]) <= 0:
				items.erase(iid)
			took_anything = true
			AudioManager.play_pickup()
			_refresh())
		_left.add_child(b)
	if _left.get_child_count() == 0:
		_left.add_child(UI.label("(empty)", 16, UI.GREEN_DIM))
	var mine := GameState.inventory.keys()
	mine.sort()
	for id in mine:
		var iid2 := str(id)
		var d := DB.item(iid2)
		if bool(d.get("quest", false)) or str(d.get("type", "")) == "note":
			continue
		var n2 := GameState.count(iid2)
		var eq := GameState.is_equipped(iid2)
		var b2 := UI.button("%s%s%s" % ["■ " if eq else "", DB.item_name(iid2), (" (%d)" % n2) if n2 > 1 else ""], 16)
		b2.pressed.connect(func() -> void:
			var give_n := n2 if (Input.is_key_pressed(KEY_SHIFT) or str(DB.item(iid2).get("type", "")) == "ammo") else 1
			var removed := GameState.take(iid2, give_n, true)
			items[iid2] = int(items.get(iid2, 0)) + removed
			AudioManager.play_key()
			_refresh())
		_right.add_child(b2)
