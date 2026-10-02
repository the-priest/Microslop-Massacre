class_name Phone
extends Modal
## Elliot's phone, running a custom OS: the Pip-Boy of this game.
## STATS (status, skills, perks, reputation, general) · ITEMS (weapons,
## apparel, aid, misc, notes) · DATA (map, quests, radio).

const TABS := {
	"stats": ["status", "skills", "perks", "rep", "general"],
	"items": ["weapons", "apparel", "aid", "misc", "notes"],
	"data": ["map", "quests", "jobs", "radio"],
}
const SUB_NAMES := {"status": "STATUS", "skills": "SKILLS", "perks": "PERKS", "rep": "REPUTATION", "general": "GENERAL",
	"weapons": "WEAPONS", "apparel": "APPAREL", "aid": "AID", "misc": "MISC", "notes": "NOTES",
	"map": "MAP", "quests": "QUESTS", "jobs": "JOBS", "radio": "RADIO"}

var tab: String = "stats"
var sub: String = "status"
var _header: Label
var _tabs_row: HBoxContainer
var _sub_row: HBoxContainer
var _list: VBoxContainer
var _list_scroll: ScrollContainer
var _detail: RichTextLabel
var _actions: HBoxContainer
var _footer: Label
var _body: HBoxContainer
var _map_view: Control
var _map_tex: TextureRect
var _map_overlay: Control
var _selected: Variant = null
var _hover_item: String = ""
var _map_hover: String = ""
var _left: VBoxContainer


func _build() -> void:
	var p := panel(1160, 660)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	p.add_child(vb)
	_header = UI.label("", 16, UI.GREEN_DIM)
	vb.add_child(_header)
	_tabs_row = HBoxContainer.new()
	_tabs_row.add_theme_constant_override("separation", 24)
	vb.add_child(_tabs_row)
	_sub_row = HBoxContainer.new()
	_sub_row.add_theme_constant_override("separation", 14)
	vb.add_child(_sub_row)
	var line := ColorRect.new()
	line.color = UI.GREEN_DIM
	line.custom_minimum_size = Vector2(0, 1)
	vb.add_child(line)
	_body = HBoxContainer.new()
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 16)
	vb.add_child(_body)
	_left = VBoxContainer.new()
	_left.custom_minimum_size = Vector2(420, 0)
	_body.add_child(_left)
	_list_scroll = ScrollContainer.new()
	_list_scroll.follow_focus = true
	_list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_left.add_child(_list_scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_scroll.add_child(_list)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_child(right)
	_detail = UI.rich(17)
	_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail.scroll_active = true
	right.add_child(_detail)
	_actions = HBoxContainer.new()
	_actions.add_theme_constant_override("separation", 12)
	right.add_child(_actions)
	# Map view (replaces body content on the map tab).
	_map_view = Control.new()
	_map_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map_view.visible = false
	vb.add_child(_map_view)
	_map_tex = TextureRect.new()
	_map_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_map_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_map_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map_view.add_child(_map_tex)
	_map_overlay = Control.new()
	_map_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_map_overlay.draw.connect(_draw_map)
	_map_overlay.gui_input.connect(_map_input)
	_map_view.add_child(_map_overlay)
	_footer = UI.label("[Q/E] tabs   [A/D] sections   [TAB/ESC] close   [1-8] hotkey weapon/aid", 13, UI.GREEN_DIM)
	vb.add_child(_footer)


func open(which: String = "stats") -> void:
	if TABS.has(which):
		tab = which
		sub = TABS[which][0]
	elif which in ["map", "quests", "jobs", "radio"]:
		tab = "data"
		sub = which
	elif which in ["weapons", "apparel", "aid", "misc", "notes"]:
		tab = "items"
		sub = which
	open_modal()
	AudioManager.play_blip()
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k := (event as InputEventKey).physical_keycode
	match k:
		KEY_TAB, KEY_ESCAPE, KEY_J, KEY_I, KEY_M:
			close_modal()
		KEY_Q:
			_cycle_tab(-1)
		KEY_E:
			_cycle_tab(1)
		KEY_A:
			_cycle_sub(-1)
		KEY_D:
			_cycle_sub(1)
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8:
			if _hover_item != "":
				var t := str(DB.item(_hover_item).get("type", ""))
				if t == "weapon" or t == "aid":
					var idx := int(k - KEY_1)
					for i in GameState.hotkeys.size():
						if str(GameState.hotkeys[i]) == _hover_item:
							GameState.hotkeys[i] = ""
					GameState.hotkeys[idx] = _hover_item
					game.hud.notify("%s -> hotkey %d" % [DB.item_name(_hover_item), idx + 1], "")
					_refresh()
	get_viewport().set_input_as_handled()


func _cycle_tab(d: int) -> void:
	var keys := TABS.keys()
	var i := keys.find(tab)
	tab = str(keys[(i + d + keys.size()) % keys.size()])
	sub = str(TABS[tab][0])
	AudioManager.play_key()
	_refresh()


func _cycle_sub(d: int) -> void:
	var subs: Array = TABS[tab]
	var i := subs.find(sub)
	sub = str(subs[(i + d + subs.size()) % subs.size()])
	AudioManager.play_key()
	_refresh()


func _refresh() -> void:
	if Pad.using_pad:
		_footer.text = "[LB/RB] tabs   [LT/RT] sections   [A] select   [B] close   map: stick picks a place, A travels"
	else:
		_footer.text = "[Q/E] tabs   [A/D] sections   [TAB/ESC] close   [1-8] hotkey weapon/aid   map: arrows + ENTER"
	_header.text = "fsociety OS 5.9  ·  ELLIOT ALDERSON  ·  LVL %d  ·  $%d  ·  %s %s  ·  HP %d/%d" % [GameState.level, GameState.cash, GameState.clock_text(), GameState.date_text(), int(GameState.hp), int(GameState.max_hp())]
	clear(_tabs_row)
	for t in TABS.keys():
		var b := UI.button(str(t).to_upper(), 22)
		if t == tab:
			b.add_theme_color_override("font_color", UI.WHITE)
			b.text = "[ %s ]" % str(t).to_upper()
		var tt := str(t)
		b.pressed.connect(func() -> void:
			tab = tt
			sub = str(TABS[tt][0])
			_refresh())
		_tabs_row.add_child(b)
	clear(_sub_row)
	for s in TABS[tab]:
		var b2 := UI.button(SUB_NAMES[s], 16)
		if s == sub:
			b2.add_theme_color_override("font_color", UI.WHITE)
			b2.text = "▸ " + SUB_NAMES[s]
		var ss := str(s)
		b2.pressed.connect(func() -> void:
			sub = ss
			_refresh())
		_sub_row.add_child(b2)
	clear(_list)
	clear(_actions)
	_detail.text = ""
	_hover_item = ""
	var is_map := sub == "map"
	_body.visible = not is_map
	_map_view.visible = is_map
	match sub:
		"status": _status()
		"skills": _skills()
		"perks": _perks()
		"rep": _rep()
		"general": _general()
		"weapons", "apparel", "aid", "misc", "notes": _items(sub)
		"map": _map()
		"quests": _quests()
		"jobs": _jobs()
		"radio": _radio()


func _row(text: String, on_click: Callable, on_hover: Callable = Callable(), col: Color = UI.GREEN) -> Button:
	var b := UI.button(text, 17)
	b.add_theme_color_override("font_color", col)
	b.custom_minimum_size = Vector2(400, 28)
	b.pressed.connect(on_click)
	if on_hover.is_valid():
		b.mouse_entered.connect(on_hover)
		b.focus_entered.connect(on_hover)
	_list.add_child(b)
	return b


func _bar(v: float, mx: float, n: int = 20) -> String:
	var f := int(round(clampf(v / maxf(mx, 0.01), 0.0, 1.0) * float(n)))
	return "█".repeat(f) + "░".repeat(n - f)


# -------------------------------------------------------------------- stats
func _status() -> void:
	var need := DB.xp_for_level(GameState.level + 1)
	var prev := DB.xp_for_level(GameState.level)
	var t := "[b]ELLIOT ALDERSON[/b]   Level %d\n" % GameState.level
	t += "XP   %s  %d / %d\n\n" % [_bar(float(GameState.xp - prev), float(need - prev)), GameState.xp, need]
	t += "HP         %s  %d/%d\n" % [_bar(GameState.hp, GameState.max_hp()), int(GameState.hp), int(GameState.max_hp())]
	t += "FOCUS      %s  %d/%d\n" % [_bar(GameState.focus, GameState.max_focus()), int(GameState.focus), int(GameState.max_focus())]
	t += "STABILITY  %s  %d/100\n" % [_bar(float(GameState.stability), 100.0), GameState.stability]
	t += "DT %d    CASH $%d\n\n" % [int(GameState.damage_threshold()), GameState.cash]
	var eq := GameState.equipped
	t += "[color=#6fbf8f]EQUIPPED[/color]\n  Weapon: %s\n  Body: %s\n  Head: %s\n\n" % [DB.item_name(str(eq["weapon"])), DB.item_name(str(eq["body"])) if str(eq["body"]) != "" else "—", DB.item_name(str(eq["head"])) if str(eq["head"]) != "" else "—"]
	if not GameState.traits.is_empty():
		t += "[color=#6fbf8f]TRAITS[/color]\n"
		for tr in GameState.traits:
			t += "  %s\n" % str(DB.trait_def(str(tr)).get("name", tr))
		t += "\n"
	t += "[color=#6fbf8f]PEOPLE[/color]\n"
	for who in ["darlene", "angela", "robot", "krista", "shayla", "tyrell", "leon"]:
		if GameState.get_trust(who) != 0 or GameState.flags.has("met_" + who):
			t += "  %-10s %s\n" % [who.capitalize() if who != "robot" else "Mr. Robot", _trust_word(GameState.get_trust(who))]
	if not GameState.buffs.is_empty():
		t += "\n[color=#6fbf8f]EFFECTS[/color]\n"
		for b in GameState.buffs:
			t += "  %s (%d min)\n" % [DB.item_name(str(b["id"])), int(float(b["until"]) - GameState.game_minutes)]
	_detail.text = t
	if GameState.pending_levels > 0:
		_row("▶ LEVEL UP (%d pending)" % GameState.pending_levels, func() -> void:
			close_modal()
			game.levelup_ui.open(), Callable(), UI.AMBER)
	_row("Wait / Sleep  [T]", func() -> void:
		close_modal()
		if not game._in_combat():
			game.wait_ui.open())


func _trust_word(v: int) -> String:
	if v >= 7: return "family"
	if v >= 4: return "trusts you"
	if v >= 1: return "warming up"
	if v == 0: return "neutral"
	if v >= -3: return "wary"
	if v >= -6: return "angry"
	return "done with you"


func _skills() -> void:
	for s in DB.SKILLS:
		var ss := str(s)
		var v := GameState.skill(ss)
		var base := int(GameState.base_skills.get(ss, 15))
		var tag := " ★" if GameState.tags.has(ss) else ""
		_row("%-10s %3d%s" % [DB.SKILL_NAMES[ss], v, tag], func() -> void: pass, func() -> void:
			_detail.text = "[b]%s[/b]  %d  (base %d)\n\n%s" % [DB.SKILL_NAMES[ss], v, base, DB.SKILL_DESC[ss]])
	_detail.text = "Skills go from 0 to 100. Tagged skills (★) started higher.\nDialogue checks compare your skill against a fixed number: if you meet it, you pass. Always."


func _perks() -> void:
	if GameState.perks.is_empty():
		_detail.text = "No perks yet. You get one every even level."
	for id in GameState.perks.keys():
		var p := DB.perk(str(id))
		var nm := str(p.get("name", id))
		var r := GameState.perk_rank(str(id))
		var desc := str(p.get("desc", ""))
		_row(nm + (" (%d)" % r if int(p.get("ranks", 1)) > 1 else ""), func() -> void: pass, func() -> void:
			_detail.text = "[b]%s[/b]\n\n%s" % [nm, desc])
	if GameState.perk_points > 0:
		_row("▶ Unspent perk points: %d" % GameState.perk_points, func() -> void:
			close_modal()
			game.levelup_ui.open_perk_only(), Callable(), UI.AMBER)


func _rep() -> void:
	for f in DB.FACTIONS.keys():
		var fs := str(f)
		var d: Dictionary = DB.FACTIONS[fs]
		var fa := int(GameState.fame.get(fs, 0))
		var inf := int(GameState.infamy.get(fs, 0))
		if fa == 0 and inf == 0 and not GameState.flags.has("met_faction_" + fs) and fs != "locals":
			continue
		var title := GameState.rep_title(fs)
		var host := GameState.faction_hostile(fs)
		_row("%-18s %s" % [str(d["name"]), title], func() -> void: pass, func() -> void:
			_detail.text = "[b]%s[/b] — %s%s\n\nFame     %s %d\nInfamy   %s %d\n\n%s" % [str(d["name"]), title, "  [color=#ff5555](HOSTILE)[/color]" if host else "", _bar(float(fa), 60.0, 16), fa, _bar(float(inf), 60.0, 16), inf, str(d["desc"])], UI.RED if host else UI.GREEN)
	_detail.text = "How the city's powers see you. Fame and infamy are tracked separately: you can be a folk hero and a public enemy at once."


func _general() -> void:
	var st := GameState.stats
	var t := "[b]GENERAL[/b]\n\n"
	t += "Days survived: %d\nPlaytime: %d min\n" % [GameState.day() + 1, int(GameState.playtime / 60.0)]
	t += "Quests completed: %d\nPeople killed: %d\nTerminals hacked: %d\nLocks picked: %d\nSkill checks passed: %d\nLocations discovered: %d\nBlackouts: %d\n\n" % [int(st.get("quests", 0)), int(st.get("kills", 0)), int(st.get("hacks", 0)), int(st.get("locks", 0)), int(st.get("checks", 0)), GameState.discovered.size(), int(GameState.get_flag("blackouts", 0))]
	t += "[color=#6fbf8f]ACHIEVEMENTS[/color]  %d/%d\n" % [GameState.achievements.size(), GameState.ACHIEVEMENTS.size()]
	for a in GameState.ACHIEVEMENTS.keys():
		var ad: Array = GameState.ACHIEVEMENTS[a]
		if GameState.achievements.has(a):
			t += "  ✔ %s — %s\n" % [ad[0], ad[1]]
		else:
			t += "  · ???\n"
	_detail.text = t


# -------------------------------------------------------------------- items
func _items(cat: String) -> void:
	var type_map := {"weapons": ["weapon", "ammo"], "apparel": ["apparel"], "aid": ["aid"], "misc": ["misc", "key"], "notes": ["note"]}
	var types: Array = type_map[cat]
	var ids: Array = []
	for id in GameState.inventory.keys():
		var t := str(DB.item(str(id)).get("type", ""))
		if types.has(t):
			ids.append(str(id))
	if cat == "weapons":
		ids.push_front("fists")
	ids.sort_custom(func(a: String, b: String) -> bool:
		var ta := str(DB.item(a).get("type", ""))
		var tb := str(DB.item(b).get("type", ""))
		if ta != tb:
			return ta > tb
		return DB.item_name(a) < DB.item_name(b))
	if ids.is_empty():
		_detail.text = "Nothing here."
	for id in ids:
		var iid := str(id)
		var d := DB.item(iid)
		var n := GameState.count(iid)
		var eq := GameState.is_equipped(iid) or (iid == "fists" and str(GameState.equipped["weapon"]) == "fists")
		var hk := GameState.hotkeys.find(iid)
		var label := "%s %s%s%s" % ["■" if eq else " ", DB.item_name(iid), (" (%d)" % n) if n > 1 else "", ("  [%d]" % (hk + 1)) if hk >= 0 else ""]
		_row(label, func() -> void: _select_item(iid), func() -> void:
			_hover_item = iid
			_show_item(iid), UI.WHITE if eq else UI.GREEN)
	if _selected is String and GameState.count(str(_selected)) > 0:
		_show_item(str(_selected))


func _show_item(iid: String) -> void:
	var d := DB.item(iid)
	var t := "[b]%s[/b]\n" % DB.item_name(iid)
	var typ := str(d.get("type", ""))
	match typ:
		"weapon":
			var dmg := float(d.get("dmg", 0)) * float(d.get("pellets", 1))
			t += "DMG %d   RATE %.1f/s   %s\n" % [int(dmg), float(d.get("rate", 1)), ("MAG %d  AMMO %s" % [int(d.get("mag", 0)), DB.item_name(str(d.get("ammo", "")))]) if d.has("mag") else "MELEE"]
			t += "Skill: %s   EXPLOIT cost: %d FOCUS\n" % [DB.SKILL_NAMES[str(d.get("skill", "guns"))], int(d.get("ap", 20))]
			if bool(d.get("silent", false)):
				t += "Silenced.\n"
			if float(d.get("stun", 0)) > 0.0:
				t += "Non-lethal stun.\n"
		"apparel":
			t += "DT %d   Slot: %s\n" % [int(d.get("dt", 0)), str(d.get("slot", "body")).to_upper()]
			var bonus: Dictionary = d.get("bonus", {})
			for s in bonus.keys():
				t += "%s %+d\n" % [DB.SKILL_NAMES.get(s, s), int(bonus[s])]
			if d.has("disguise"):
				t += "Disguise: %s\n" % str(DB.FACTIONS.get(str(d["disguise"]), {}).get("name", d["disguise"]))
		"note":
			t += "\n" + str(d.get("text", ""))
			_detail.text = t
			return
	t += "Value: $%d\n\n%s" % [int(d.get("value", 0)), str(d.get("desc", ""))]
	_detail.text = t


func _select_item(iid: String) -> void:
	_selected = iid
	_show_item(iid)
	clear(_actions)
	var d := DB.item(iid)
	var typ := str(d.get("type", ""))
	match typ:
		"weapon", "apparel":
			var b := UI.button("[ UNEQUIP ]" if GameState.is_equipped(iid) and typ == "apparel" else "[ EQUIP ]", 17)
			b.pressed.connect(func() -> void:
				GameState.equip(iid)
				AudioManager.play_select()
				_refresh())
			_actions.add_child(b)
		"aid":
			var b2 := UI.button("[ USE ]", 17)
			b2.pressed.connect(func() -> void:
				if GameState.use_aid(iid):
					AudioManager.play_heal()
				_refresh())
			_actions.add_child(b2)
	if typ != "note" and typ != "key" and not bool(d.get("quest", false)) and iid != "fists":
		var b3 := UI.button("[ DROP ]", 17)
		b3.pressed.connect(func() -> void:
			GameState.take(iid, 1)
			_refresh())
		_actions.add_child(b3)


# --------------------------------------------------------------------- data
func _quests() -> void:
	# Group by quest line: the line you're following first, then main lines,
	# then side lines; inside a line, the current mission, then what's done.
	var lines: Dictionary = {} # line -> {active: [], done: []}
	for qid in GameState.quests.keys():
		var ln := DB.quest_line(str(qid))
		if not lines.has(ln):
			lines[ln] = {"active": [], "done": []}
		if str(GameState.quests[qid]["state"]) == "active":
			(lines[ln]["active"] as Array).append(str(qid))
		else:
			(lines[ln]["done"] as Array).append(str(qid))
	if lines.is_empty():
		_detail.text = "No quests. Go outside. Talk to people. It's awful, but it works."
		return
	var tl := DB.quest_line(GameState.tracked_quest) if GameState.tracked_quest != "" else ""
	var order: Array = lines.keys()
	order.sort_custom(func(a: String, b: String) -> bool:
		var ka := _line_rank(a, tl, lines)
		var kb := _line_rank(b, tl, lines)
		return ka < kb if ka != kb else DB.line_title(a) < DB.line_title(b))
	for ln in order:
		var L: Dictionary = lines[ln]
		var act: Array = L["active"]
		var dn: Array = L["done"]
		var total := int((DB.LINES.get(ln, {}).get("quests", []) as Array).size())
		var main := false
		for q in act + dn:
			if str(DB.QUESTS.get(q, {}).get("kind", "")) == "main":
				main = true
		var head := "%s%s" % [DB.line_title(ln).to_upper(), ("   %d/%d" % [dn.size(), total]) if total > 1 else ""]
		var first := str(act[0]) if not act.is_empty() else str(dn[dn.size() - 1])
		_row(("■ " if main else "□ ") + head, func() -> void: _show_quest(first), func() -> void: _show_quest(first), UI.GREEN if not act.is_empty() else UI.GREEN_DIM)
		for qid in act:
			var q: Dictionary = DB.QUESTS.get(qid, {})
			var tracked: bool = GameState.tracked_quest == qid
			var qq := str(qid)
			_row("   %s %s" % ["▸" if tracked else "·", str(q.get("title", qid))], func() -> void:
				GameState.tracked_quest = qq
				AudioManager.play_select()
				_refresh()
				_show_quest(qq), func() -> void: _show_quest(qq), UI.WHITE if tracked else UI.GREEN)
		for qid in dn:
			var q2: Dictionary = DB.QUESTS.get(qid, {})
			var st := str(GameState.quests[qid]["state"])
			var qq2 := str(qid)
			_row("     ✔ %s%s" % [str(q2.get("title", qid)), "" if st == "done" else "  [FAILED]"], func() -> void: _show_quest(qq2), func() -> void: _show_quest(qq2), UI.GREEN_DIM)
	if GameState.tracked_quest != "":
		_show_quest(GameState.tracked_quest)


func _line_rank(ln: String, tracked_line: String, lines: Dictionary) -> int:
	if ln == tracked_line:
		return 0
	var act: Array = lines[ln]["active"]
	if act.is_empty():
		return 9
	for q in act:
		if str(DB.QUESTS.get(q, {}).get("kind", "")) == "main":
			return 1
	return 2


func _show_quest(qid: String) -> void:
	var q: Dictionary = DB.QUESTS.get(qid, {})
	var st: Dictionary = GameState.quests.get(qid, {})
	var lp := DB.line_pos(qid)
	var lhead := ""
	if int(lp[1]) > 1:
		lhead = "[color=#7a9]%s  ·  mission %d of %d[/color]\n" % [DB.line_title(DB.quest_line(qid)).to_upper(), int(lp[0]), int(lp[1])]
	var t := "%s[b]%s[/b]\n[color=#7a9]%s[/color]\n\n" % [lhead, str(q.get("title", qid)), str(q.get("desc", ""))]
	if str(st.get("state", "")) == "active":
		t += "[color=#ffbf4d]CURRENT[/color]\n"
		for o in DB.quest_objectives(qid, int(st.get("stage", 0))):
			t += "  ▸ %s\n" % str(o["text"])
	t += "\n[color=#7a9]LOG[/color]\n"
	var lg: Array = st.get("log", [])
	for s in lg:
		if int(s) == int(st.get("stage", 0)) and str(st.get("state", "")) == "active":
			continue
		for o in DB.quest_objectives(qid, int(s)):
			if str(o["text"]) != "" and str(o["text"]) != "done":
				t += "  ✔ [color=#6a8]%s[/color]\n" % str(o["text"])
	if str(st.get("state", "")) == "active":
		t += "\n[i]Click to track this quest.[/i]"
	_detail.text = t


func _jobs() -> void:
	var J: Jobs = game.jobs
	var act: Array = J.active()
	_list.add_child(UI.label("ACTIVE  (%d/%d)" % [act.size(), Jobs.MAX_ACTIVE], 14, UI.AMBER))
	if act.is_empty():
		_list.add_child(UI.label("  nothing on your plate", 14, UI.GREEN_DIM))
	for j in act:
		var jd: Dictionary = j
		_row("▸ %s  $%d" % [str(jd["title"]), int(jd["pay"])], func() -> void: _show_job(jd, true), func() -> void: _show_job(jd, true), UI.WHITE)
	_list.add_child(UI.label("", 8))
	_list.add_child(UI.label("THE BOARD  (new jobs every day)", 14, UI.AMBER))
	var b: Array = J.board()
	if b.is_empty():
		_list.add_child(UI.label("  board's empty. check back tomorrow.", 14, UI.GREEN_DIM))
	for j in b:
		var jd2: Dictionary = j
		_row("  %s  $%d" % [str(jd2["title"]), int(jd2["pay"])], func() -> void: _show_job(jd2, false), func() -> void: _show_job(jd2, false))
	if _detail.text == "":
		_detail.text = "[b]JOBS[/b]\n\nThe darknet board. People with problems, people with money, people with both. Take a contract, get it done, get paid. Active jobs show on your compass as blue diamonds.\n\nJobs completed: %d" % int(GameState.jobs_state.get("done", 0))


func _show_job(jd: Dictionary, is_active: bool) -> void:
	clear(_actions)
	var t := "[b]%s[/b]\n[color=#7a9]from: %s[/color]\n\n%s\n\n[color=#ffbf4d]PAYS $%d  ·  %d XP[/color]" % [str(jd["title"]), str(jd["client"]), str(jd["desc"]), int(jd["pay"]), int(jd["xp"])]
	var gd: Dictionary = game.gen_doors.get(str(jd["door"]), {})
	if not gd.is_empty():
		var dp: Vector3 = gd["pos"]
		var here: Vector3 = game.player.global_position if GameState.cell == "world" else dp
		t += "\n\n[color=#7a9]%s  ·  %dm away[/color]" % [str(gd["addr"]), int(dp.distance_to(here))]
	_detail.text = t
	var jid := str(jd["id"])
	if is_active:
		var b := UI.button("[ DROP JOB ]", 16)
		b.pressed.connect(func() -> void:
			game.jobs.abandon(jid)
			_refresh())
		_actions.add_child(b)
	else:
		var b2 := UI.button("[ TAKE JOB ]", 16)
		b2.pressed.connect(func() -> void:
			if game.jobs.accept(jid):
				_refresh())
		_actions.add_child(b2)


func _radio() -> void:
	_detail.text = "[b]RADIO[/b]\n\nThe city still broadcasts. Pick a frequency.\n\nNow playing: %s" % (str(AudioManager.STATIONS.get(AudioManager.radio_station, {}).get("name", "—")) if AudioManager.radio_on() else "OFF")
	for s in AudioManager.STATIONS.keys():
		var ss := str(s)
		if ss == "pirate" and not GameState.has_flag("pirate_radio"):
			continue
		var d: Dictionary = AudioManager.STATIONS[ss]
		var on := AudioManager.radio_station == ss and AudioManager.radio_on()
		_row(("■ " if on else "  ") + str(d["name"]), func() -> void:
			if on:
				AudioManager.radio_stop()
			else:
				AudioManager.radio_play(ss)
			_refresh(), func() -> void:
			_detail.text = "[b]%s[/b]\n\n%s" % [str(d["name"]), str(d["desc"])], UI.WHITE if on else UI.GREEN)
	_row("  OFF", func() -> void:
		AudioManager.radio_stop()
		_refresh())


# ---------------------------------------------------------------------- map
func _map() -> void:
	if _map_tex.texture == null and game.map_image != null:
		_map_tex.texture = MapRender.texture(game.map_image)
	_map_overlay.queue_redraw()


func _map_rect() -> Rect2:
	var s := _map_overlay.size
	var side := minf(s.x, s.y)
	return Rect2((s.x - side) * 0.5, (s.y - side) * 0.5, side, side)


func _w2m(x: float, z: float) -> Vector2:
	var r := _map_rect()
	var p := MapRender.to_px(x, z) / float(MapRender.SIZE)
	return r.position + p * r.size.x


func _map_locations() -> Array:
	var out: Array = []
	for pid in WorldLayout.POIS.keys():
		if GameState.discovered.has(pid):
			var pa: Array = WorldLayout.POIS[pid]["pos"]
			out.append({"id": pid, "name": WorldLayout.POIS[pid]["name"], "pos": Vector2(float(pa[0]), float(pa[1])), "kind": "poi"})
	for did in WorldLayout.DOORS.keys():
		if GameState.discovered.has(did):
			var dw := WorldLayout.door_world(str(did))
			var dp: Vector3 = dw["pos"]
			out.append({"id": did, "name": WorldLayout.DOORS[did]["name"], "pos": Vector2(dp.x, dp.z), "kind": "door"})
	for sid in WorldLayout.SUBWAYS.keys():
		if GameState.discovered.has(sid):
			var sp := WorldLayout.subway_world(str(sid))
			out.append({"id": sid, "name": WorldLayout.SUBWAYS[sid]["name"], "pos": Vector2(sp.x, sp.z), "kind": "subway"})
	return out


func _draw_map() -> void:
	if not _map_view.visible:
		return
	var font := UI.mono()
	var r := _map_rect()
	_map_overlay.draw_rect(r, UI.GREEN_DIM, false, 1.0)
	# District labels.
	for dname in [["WASHINGTON HEIGHTS", -450, -700], ["INDUSTRIAL NORTH", 450, -760], ["MIDTOWN", -150, -380], ["DOCKS", -760, -150], ["CENTRAL PARK", -65, 80], ["HELL'S KITCHEN", -520, 100], ["UPPER EAST", 450, 100], ["LOWER EAST SIDE", -480, 440], ["CIVIC", 60, 460], ["CHINATOWN", 480, 460], ["CONEY ISLAND", 0, 650], ["INWOOD", -640, -1000], ["FORT TRYON", -700, -1330], ["HARLEM", 180, -1000], ["THE BRONX", 60, -1420], ["HUNTS POINT", 1180, -1250], ["ASTORIA", 1180, -480], ["LONG ISLAND CITY", 1140, 220]]:
		var pp := _w2m(float(dname[1]), float(dname[2]))
		_map_overlay.draw_string(font, pp - Vector2(60, 0), str(dname[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.4, 0.8, 0.5, 0.55))
	for loc in _map_locations():
		var p: Vector2 = _w2m((loc["pos"] as Vector2).x, (loc["pos"] as Vector2).y)
		var c := UI.GREEN
		match str(loc["kind"]):
			"subway":
				c = Color(0.3, 0.9, 1.0)
				_map_overlay.draw_circle(p, 4.0, c)
			"door":
				_map_overlay.draw_rect(Rect2(p - Vector2(3, 3), Vector2(6, 6)), c)
			_:
				_map_overlay.draw_rect(Rect2(p - Vector2(4, 4), Vector2(8, 8)), c, false, 1.5)
		if str(loc["id"]) == _map_hover:
			_map_overlay.draw_string(font, p + Vector2(8, -6), str(loc["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UI.WHITE)
			_map_overlay.draw_string(font, p + Vector2(8, 10), ("A: fast travel" if Pad.using_pad else "click / ENTER: fast travel"), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UI.GREEN_DIM)
	# Quest marker.
	var tq := GameState.tracked_quest
	if tq != "" and GameState.quest_state(tq) == "active":
		for o in DB.quest_objectives(tq, GameState.quest_stage(tq)):
			var m := str((o as Dictionary).get("marker", ""))
			if m == "":
				continue
			var wp: Variant = game.marker_pos(m)
			if wp == null:
				continue
			var gp := wp as Vector3
			if GameState.cell != "world" and gp.x > 5000.0:
				continue
			var mp := _w2m(gp.x, gp.z)
			_map_overlay.draw_colored_polygon(PackedVector2Array([mp + Vector2(-7, -14), mp + Vector2(7, -14), mp]), UI.AMBER)
	# Job targets.
	for jp in game.jobs.marker_positions():
		var jm := _w2m((jp as Vector3).x, (jp as Vector3).z)
		_map_overlay.draw_colored_polygon(PackedVector2Array([jm + Vector2(0, -7), jm + Vector2(6, 0), jm + Vector2(0, 7), jm + Vector2(-6, 0)]), Color(0.4, 0.85, 1.0))
	# Player.
	if GameState.cell == "world":
		var pl: Player = game.player
		var pp2 := _w2m(pl.global_position.x, pl.global_position.z)
		var fwd := Vector2(-sin(pl.yaw), -cos(pl.yaw))
		var side := Vector2(-fwd.y, fwd.x)
		_map_overlay.draw_colored_polygon(PackedVector2Array([pp2 + fwd * 10.0, pp2 - fwd * 6.0 + side * 6.0, pp2 - fwd * 6.0 - side * 6.0]), UI.WHITE)
	else:
		_map_overlay.draw_string(font, r.position + Vector2(10, 20), "(indoors: %s)" % str(game.interior_def(GameState.cell).get("name", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UI.WHITE)
	_map_overlay.draw_string(font, r.position + Vector2(10, r.size.y - 10), "Fast travel to places you've been. Time passes.", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UI.GREEN_DIM)


## Keyboard / pad on the map: arrows (stick, D-pad) hop between known places,
## ENTER (A) fast-travels there.
func _input(event: InputEvent) -> void:
	if not _is_open or not _map_view.visible or not (event is InputEventKey) or not event.pressed:
		return
	var k := (event as InputEventKey).keycode
	var dirs := {KEY_UP: Vector2(0, -1), KEY_DOWN: Vector2(0, 1), KEY_LEFT: Vector2(-1, 0), KEY_RIGHT: Vector2(1, 0)}
	if dirs.has(k):
		_map_step(dirs[k])
		get_viewport().set_input_as_handled()
	elif (k == KEY_ENTER or k == KEY_KP_ENTER) and not event.echo and _map_hover != "":
		get_viewport().set_input_as_handled()
		var dest := _map_hover
		close_modal()
		game.travel_ui.fast_travel(dest)


func _map_step(dir: Vector2) -> void:
	var locs := _map_locations()
	if locs.is_empty():
		return
	var from := Vector2.ZERO
	var have := false
	for loc in locs:
		if str(loc["id"]) == _map_hover:
			from = _w2m((loc["pos"] as Vector2).x, (loc["pos"] as Vector2).y)
			have = true
	if not have:
		# Start from wherever you are.
		var pp: Vector3 = game.player.global_position
		if GameState.cell != "world":
			var dw: Dictionary = game.door_world_any(game._door_for_interior(GameState.cell))
			pp = dw.get("pos", Vector3.ZERO)
		from = _w2m(pp.x, pp.z)
	var best := ""
	var bs := INF
	for loc in locs:
		var p := _w2m((loc["pos"] as Vector2).x, (loc["pos"] as Vector2).y)
		var v := p - from
		var l := v.length()
		if l < 2.0 and have:
			continue
		if have and v.normalized().dot(dir) < 0.5:
			continue
		var score := l * (1.0 if not have else (2.0 - v.normalized().dot(dir)))
		if score < bs:
			bs = score
			best = str(loc["id"])
	if best != "":
		_map_hover = best
		AudioManager.play_key()
		_map_overlay.queue_redraw()


func _map_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mp := (event as InputEventMouseMotion).position
		var best := ""
		var bd := 12.0
		for loc in _map_locations():
			var p := _w2m((loc["pos"] as Vector2).x, (loc["pos"] as Vector2).y)
			var d := p.distance_to(mp)
			if d < bd:
				bd = d
				best = str(loc["id"])
		if best != _map_hover:
			_map_hover = best
			_map_overlay.queue_redraw()
	elif event is InputEventMouseButton and event.pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		if _map_hover != "":
			var dest := _map_hover
			close_modal()
			game.travel_ui.fast_travel(dest)
