class_name TravelUI
extends Modal
## Subway rides between discovered stations, and map fast travel.

var _box: VBoxContainer
var _title: Label
var _mode: String = ""
var _dest: String = ""


func _build() -> void:
	var p := panel(700, 520)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	p.add_child(vb)
	_title = UI.label("", 22, UI.WHITE)
	vb.add_child(_title)
	var sc := ScrollContainer.new()
	sc.follow_focus = true
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(sc)
	_box = VBoxContainer.new()
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_box)


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if (event as InputEventKey).physical_keycode in [KEY_ESCAPE, KEY_TAB]:
		close_modal()
	get_viewport().set_input_as_handled()


func open_subway() -> void:
	_mode = "subway"
	_title.text = "MTA  ·  %s" % str(WorldLayout.SUBWAYS.get(game.current_subway, {}).get("name", "Subway"))
	clear(_box)
	var here := WorldLayout.subway_world(game.current_subway)
	var any := false
	for sid in WorldLayout.SUBWAYS.keys():
		var s := str(sid)
		if s == game.current_subway:
			continue
		var known := GameState.discovered.has(s)
		var mins := int(here.distance_to(WorldLayout.subway_world(s)) / 8.0 / 60.0) + 8
		var b := UI.button(("%-30s ~%d min" % [str(WorldLayout.SUBWAYS[s]["name"]), mins]) if known else "??? (find this station on foot first)", 18)
		b.disabled = not known
		b.pressed.connect(func() -> void: _ride(s, mins))
		_box.add_child(b)
		any = any or known
	if not any:
		_box.add_child(UI.label("You haven't found any other stations yet.\nEvery district has one. Look for the green globes.", 16, UI.GREEN_DIM))
	var c := UI.button("[ LEAVE ]", 18)
	c.pressed.connect(close_modal)
	_box.add_child(c)
	open_modal()
	await closed


func _ride(sid: String, mins: int) -> void:
	close_modal()
	game.push_ui()
	AudioManager.sfx("train")
	await SceneRouter.fade(true, 0.5)
	GameState.advance_time(float(mins))
	game.current_subway = sid
	GameState.cell = "subway:" + sid
	var d: Dictionary = game.interior_def("subway:" + sid)
	var sp := InteriorBuilder.exit_spawn(d, 0)
	game.player.teleport(game.cell_to_global("subway:" + sid, sp["pos"]))
	game.player.set_look(float(sp["yaw"]))
	for cid in GameState.companions:
		var n: NPC = game.npcs.get_npc(str(cid))
		if n != null:
			n.cell = "subway:" + sid
			n.global_position = game.player.global_position + Vector3(1.0, 0.1, 1.0)
	await get_tree().create_timer(0.6).timeout
	await SceneRouter.fade(false, 0.5)
	game.pop_ui()
	game.hud.location(str(WorldLayout.SUBWAYS[sid]["name"]).to_upper())


## Map fast travel to a discovered location id.
func fast_travel(dest: String) -> void:
	if game._in_combat():
		game.hud.notify("You can't fast travel with enemies nearby.", "warn")
		return
	var t: Dictionary = game.resolve_location(dest)
	if t.is_empty():
		return
	var from: Vector3 = game.player.global_position
	if GameState.cell != "world":
		var door: String = game._door_for_interior(GameState.cell)
		if door != "":
			var dw: Dictionary = game.door_world_any(door)
			if dw.has("pos"):
				from = dw["pos"]
	var mins := int(from.distance_to(t["pos"] as Vector3) / 1.5 / 60.0) + 2
	_mode = "confirm"
	_dest = dest
	_title.text = "FAST TRAVEL"
	clear(_box)
	var nm := dest
	if WorldLayout.POIS.has(dest):
		nm = str(WorldLayout.POIS[dest]["name"])
	elif WorldLayout.all_doors().has(dest):
		nm = str(WorldLayout.all_doors()[dest]["name"])
	_box.add_child(UI.label("Walk to %s?\nAbout %d minutes pass." % [nm, mins], 18, UI.WHITE))
	var yes := UI.button("[ GO ]", 20)
	yes.pressed.connect(func() -> void:
		close_modal()
		GameState.advance_time(float(mins))
		game.travel_to(dest))
	_box.add_child(yes)
	var no := UI.button("[ CANCEL ]", 20)
	no.pressed.connect(close_modal)
	_box.add_child(no)
	open_modal()
