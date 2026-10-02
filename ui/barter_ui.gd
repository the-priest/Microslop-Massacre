class_name BarterUI
extends Modal
## Buy and sell. Prices scale with BARTER; shops have limited cash and restock.

var _title: Label
var _left: VBoxContainer
var _right: VBoxContainer
var _info: Label
var _shop_id: String = ""
var _stock_key: String = ""
var _stock: Dictionary = {}


func _build() -> void:
	var p := panel(1060, 620)
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
	lcol.add_child(UI.label("FOR SALE  (click: buy)", 14, UI.GREEN_DIM))
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
	rcol.add_child(UI.label("YOURS  (click: sell)", 14, UI.GREEN_DIM))
	var rs := ScrollContainer.new()
	rs.follow_focus = true
	rs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rcol.add_child(rs)
	_right = VBoxContainer.new()
	_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rs.add_child(_right)
	_info = UI.label("", 15, UI.GREEN_DIM)
	vb.add_child(_info)


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if (event as InputEventKey).physical_keycode in [KEY_ESCAPE, KEY_TAB, KEY_E]:
		close_modal()
	get_viewport().set_input_as_handled()


func buy_price(id: String) -> int:
	var v := float(DB.item(id).get("value", 1))
	var b := float(GameState.skill("barter"))
	var mult := 1.6 - b * 0.006
	var sd: Dictionary = NPCData.SHOPS.get(_shop_id, {})
	mult *= float(sd.get("markup", 1.0))
	if GameState.faction_hostile(str(sd.get("faction", "__none"))):
		mult *= 1.3
	return maxi(1, int(ceil(v * mult)))


func sell_price(id: String) -> int:
	var v := float(DB.item(id).get("value", 0))
	var b := float(GameState.skill("barter"))
	var mult := 0.35 + b * 0.004
	if GameState.has_perk("deep_pockets"):
		mult *= 1.15
	return maxi(0, int(floor(v * mult)))


## stock_key: separate inventory for one store instance that shares a shop
## definition (generated stores). Defaults to the shop id.
func open(shop_id: String, title: String, stock_key: String = "") -> void:
	if not NPCData.SHOPS.has(shop_id):
		push_warning("unknown shop " + shop_id)
		return
	_shop_id = shop_id
	_stock_key = stock_key if stock_key != "" else shop_id
	_restock_if_needed()
	_stock = GameState.shop_stock[_stock_key]
	_title.text = "BARTER — %s" % title
	open_modal()
	_refresh()
	await closed


func _restock_if_needed() -> void:
	var sd: Dictionary = NPCData.SHOPS[_shop_id]
	var cur: Dictionary = GameState.shop_stock.get(_stock_key, {})
	var every := int(sd.get("restock", 3))
	if cur.is_empty() or GameState.day() - int(cur.get("day", -99)) >= every:
		var items := {}
		for k in (sd.get("stock", {}) as Dictionary).keys():
			var v: Variant = sd["stock"][k]
			var n := int(v) if not (v is Array) else randi_range(int(v[0]), int(v[1]))
			if n > 0:
				items[str(k)] = n
		GameState.shop_stock[_stock_key] = {"items": items, "cash": int(sd.get("cash", 300)), "day": GameState.day()}


func _refresh() -> void:
	clear(_left)
	clear(_right)
	var items: Dictionary = _stock["items"]
	var keys := items.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return DB.item_name(a) < DB.item_name(b))
	for id in keys:
		var iid := str(id)
		var n := int(items[id])
		if n <= 0:
			continue
		var price := buy_price(iid)
		var b := UI.button("%-26s x%-3d $%d" % [DB.item_name(iid), n, price], 16)
		if price > GameState.cash:
			b.add_theme_color_override("font_color", UI.GREEN_DIM)
		b.pressed.connect(func() -> void: _buy(iid))
		b.mouse_entered.connect(func() -> void: _info.text = _summary() + "\n" + str(DB.item(iid).get("desc", "")))
		b.focus_entered.connect(func() -> void: _info.text = _summary() + "\n" + str(DB.item(iid).get("desc", "")))
		_left.add_child(b)
	var mine := GameState.inventory.keys()
	mine.sort_custom(func(a: String, b: String) -> bool: return DB.item_name(a) < DB.item_name(b))
	for id in mine:
		var iid2 := str(id)
		var d := DB.item(iid2)
		if bool(d.get("quest", false)) or str(d.get("type", "")) in ["note", "key"]:
			continue
		var price2 := sell_price(iid2)
		if price2 <= 0:
			continue
		var n2 := GameState.count(iid2)
		var eq := GameState.is_equipped(iid2)
		var b2 := UI.button("%s%-24s x%-3d $%d" % ["■" if eq else " ", DB.item_name(iid2), n2, price2], 16)
		if price2 > int(_stock["cash"]):
			b2.add_theme_color_override("font_color", UI.GREEN_DIM)
		b2.pressed.connect(func() -> void: _sell(iid2))
		b2.mouse_entered.connect(func() -> void: _info.text = _summary() + "\n" + str(DB.item(iid2).get("desc", "")))
		b2.focus_entered.connect(func() -> void: _info.text = _summary() + "\n" + str(DB.item(iid2).get("desc", "")))
		_right.add_child(b2)
	_info.text = _summary()


func _summary() -> String:
	return "Your cash: $%d      Their cash: $%d      BARTER %d      %s" % [GameState.cash, int(_stock["cash"]), GameState.skill("barter"), "[A] trade one    [B] done" if Pad.using_pad else "[SHIFT+click] x10    [ESC] done"]


func _buy(id: String) -> void:
	var items: Dictionary = _stock["items"]
	var times := 10 if Input.is_key_pressed(KEY_SHIFT) else 1
	for i in times:
		var price := buy_price(id)
		if int(items.get(id, 0)) <= 0 or GameState.cash < price:
			if i == 0:
				AudioManager.play_fail()
			break
		GameState.add_cash(-price, true)
		_stock["cash"] = int(_stock["cash"]) + price
		items[id] = int(items[id]) - 1
		if int(items[id]) <= 0:
			items.erase(id)
		GameState.give(id, 1, true)
		AudioManager.play_coin()
	_refresh()


func _sell(id: String) -> void:
	var items: Dictionary = _stock["items"]
	var times := 10 if Input.is_key_pressed(KEY_SHIFT) else 1
	for i in times:
		var price := sell_price(id)
		if GameState.count(id) <= 0 or int(_stock["cash"]) < price:
			if i == 0:
				AudioManager.play_fail()
			break
		GameState.take(id, 1, true)
		GameState.add_cash(price, true)
		_stock["cash"] = int(_stock["cash"]) - price
		items[id] = int(items.get(id, 0)) + 1
		AudioManager.play_coin()
	_refresh()
