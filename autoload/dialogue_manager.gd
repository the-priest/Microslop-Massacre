extends Node
## DialogueManager — parses the .dlg dialogue language and evaluates its
## conditions and effects. The DialogueUI walks conversations; world-facing
## effects (hostile, barter, minigame, travel...) are delegated to `game`.
##
## ---------------------------------------------------------------- .dlg format
##   # comment
##   === convo_id                 start a conversation (ids are global)
##   -- node_id                   start a node (first node = entry)
##   SPEAKER: text                a spoken line (waits for the player)
##   > text                       narration line
##   ? condition -> target        jump now if the condition holds
##   ! effect ; effect            run effects
##   -> target                    continue to target when the node is done
##   * [if cond] [once] [SPEECH 40] Choice text -> pass | fail ! effect ; effect
## Targets: node id, END, other_convo (its entry), other_convo.node
## Conditions: atoms joined with & (and) and | (or); ! negates an atom.
##   flag, flag>=2, q.id>=20, q.id.done, item.id>=2, skill.speech>=40, cash>=50,
##   fame.f>=10, infamy.f, hostile.f, trust.who>=3, perk.id, trait.id,
##   companion.id, party>=2 (companions with you), dead.npc, seen.loc, equipped.item, disguise.f, mask, won,
##   night, day, rain, level>=5, stab<30, hp<50, hour>=20, daynum>=2, chance<30,
##   driving.truck / driving.plane / driving.any (what you're at the wheel of),
##   at.<map> (which map you're on: nyc, highway, chicago, township, port, gary)

signal convo_finished(convo_id: String)

const CHECK_SKILLS := {
	"HACKING": "hacking", "SPEECH": "speech", "SNEAK": "sneak", "LOCKPICK": "lockpick",
	"GUNS": "guns", "MELEE": "melee", "BARTER": "barter", "MEDICINE": "medicine",
}
const WORLD_EFFECTS := ["hostile", "barter", "minigame", "recruit", "dismiss", "travel", "ending",
	"glitch", "sfx", "kill", "move", "sleep", "save", "blackout", "calm", "spawn", "fade", "levelup", "race", "airrace"]
const STATE_EFFECTS := ["set", "unset", "add", "quest", "track", "give", "take", "cash", "xp", "fame",
	"infamy", "trust", "stab", "hp", "heal", "skill", "time", "check", "achieve", "discover",
	"wanted", "hostile_faction", "note", "equip", "weather"]

var convos: Dictionary = {}
var parse_errors: Array = []
var game: Node = null # set by Game while a world is running
var current_npc: String = ""
var _loaded: bool = false


func _ready() -> void:
	load_all()


func load_all() -> void:
	if _loaded:
		return
	_loaded = true
	var dir := DirAccess.open("res://data/dialogue")
	if dir == null:
		push_error("no dialogue dir")
		return
	var files: Array = []
	dir.list_dir_begin()
	var fn := dir.get_next()
	while fn != "":
		# Exported builds may list "name.dlg.remap" — never, since .dlg is raw text,
		# but be tolerant.
		var clean := fn.trim_suffix(".remap")
		if clean.ends_with(".dlg"):
			files.append(clean)
		fn = dir.get_next()
	dir.list_dir_end()
	files.sort()
	for f in files:
		parse_file("res://data/dialogue/" + str(f))


func parse_file(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		parse_errors.append("cannot open " + path)
		return
	parse_text(f.get_as_text(), path.get_file())


func parse_text(text: String, fname: String) -> void:
	var cid := ""
	var nid := ""
	var lineno := 0
	for raw in text.split("\n"):
		lineno += 1
		var line := raw.strip_edges()
		if line == "" or line.begins_with("#"):
			continue
		var where := "%s:%d" % [fname, lineno]
		if line.begins_with("=== "):
			cid = line.substr(4).strip_edges()
			nid = ""
			if convos.has(cid):
				parse_errors.append("%s duplicate convo %s" % [where, cid])
			convos[cid] = {"file": fname, "entry": "", "nodes": {}, "order": []}
			continue
		if cid == "":
			parse_errors.append("%s text outside convo" % where)
			continue
		var c: Dictionary = convos[cid]
		if line.begins_with("-- "):
			nid = line.substr(3).strip_edges()
			if (c["nodes"] as Dictionary).has(nid):
				parse_errors.append("%s duplicate node %s.%s" % [where, cid, nid])
			c["nodes"][nid] = {"stmts": [], "choices": [], "where": where}
			(c["order"] as Array).append(nid)
			if str(c["entry"]) == "":
				c["entry"] = nid
			continue
		if nid == "":
			# Implicit entry node for tiny convos.
			nid = "start"
			c["nodes"][nid] = {"stmts": [], "choices": [], "where": where}
			(c["order"] as Array).append(nid)
			c["entry"] = nid
		var node: Dictionary = c["nodes"][nid]
		if line.begins_with("* "):
			var ch := _parse_choice(line.substr(2).strip_edges(), where)
			if not ch.is_empty():
				ch["key"] = "%s.%s.%d" % [cid, nid, (node["choices"] as Array).size()]
				(node["choices"] as Array).append(ch)
		elif line.begins_with("? "):
			var body := line.substr(2)
			var arrow := body.rfind("->")
			if arrow < 0:
				parse_errors.append("%s '?' without ->" % where)
				continue
			(node["stmts"] as Array).append({"k": "if", "cond": parse_cond(body.substr(0, arrow).strip_edges(), where), "to": body.substr(arrow + 2).strip_edges()})
		elif line.begins_with("! "):
			(node["stmts"] as Array).append({"k": "do", "fx": parse_effects(line.substr(2), where)})
		elif line.begins_with("->"):
			(node["stmts"] as Array).append({"k": "goto", "to": line.substr(2).strip_edges()})
		elif line.begins_with("> "):
			(node["stmts"] as Array).append({"k": "narr", "text": line.substr(2).strip_edges()})
		else:
			var colon := line.find(": ")
			if colon <= 0:
				parse_errors.append("%s unrecognized line: %s" % [where, line])
				continue
			(node["stmts"] as Array).append({"k": "line", "speaker": line.substr(0, colon).strip_edges(), "text": line.substr(colon + 2).strip_edges()})


func _parse_choice(s: String, where: String) -> Dictionary:
	var ch := {"text": "", "cond": null, "once": false, "check": null, "to": "END", "fail": "", "fx": [], "tag": ""}
	# Leading bracket groups.
	while s.begins_with("["):
		var close := s.find("]")
		if close < 0:
			break
		var inner := s.substr(1, close - 1).strip_edges()
		var consumed := true
		if inner.begins_with("if ") or inner.begins_with("require "):
			# [if cond] and [require cond] both gate the choice (hidden when unmet).
			if ch["cond"] != null:
				parse_errors.append("%s choice has two conditions" % where)
			ch["cond"] = parse_cond(inner.substr(inner.find(" ") + 1).strip_edges(), where)
		elif inner == "once":
			ch["once"] = true
		else:
			var parts := inner.split(" ", false)
			if parts.size() == 2 and CHECK_SKILLS.has(parts[0].to_upper()) and parts[1].is_valid_int():
				ch["check"] = {"skill": CHECK_SKILLS[parts[0].to_upper()], "dc": int(parts[1])}
			else:
				consumed = false
		if not consumed:
			parse_errors.append("%s unrecognized choice tag [%s]" % [where, inner])
			break
		s = s.substr(close + 1).strip_edges()
	# Effects after '!'.
	var bang := s.find(" ! ")
	if bang >= 0:
		ch["fx"] = parse_effects(s.substr(bang + 3), where)
		s = s.substr(0, bang).strip_edges()
	var arrow := s.rfind("->")
	if arrow >= 0:
		var tgt := s.substr(arrow + 2).strip_edges()
		s = s.substr(0, arrow).strip_edges()
		var bar := tgt.find("|")
		if bar >= 0:
			ch["to"] = tgt.substr(0, bar).strip_edges()
			ch["fail"] = tgt.substr(bar + 1).strip_edges()
		else:
			ch["to"] = tgt
	ch["text"] = s
	if ch["check"] != null and str(ch["fail"]) == "":
		parse_errors.append("%s skill check without fail target" % where)
	return ch


func parse_effects(s: String, where: String) -> Array:
	var out: Array = []
	for part in s.split(";"):
		var p := part.strip_edges()
		if p == "":
			continue
		var toks := p.split(" ", false)
		var cmd := str(toks[0])
		var args: Array = []
		for i in range(1, toks.size()):
			args.append(str(toks[i]))
		if not (cmd in WORLD_EFFECTS or cmd in STATE_EFFECTS):
			parse_errors.append("%s unknown effect '%s'" % [where, cmd])
		out.append({"cmd": cmd, "args": args})
	return out


# ------------------------------------------------------------- conditions
func parse_cond(s: String, where: String = "") -> Array:
	# Returns [[atom, atom], [atom]] = OR of ANDs.
	var ors: Array = []
	for grp in s.split("|"):
		var ands: Array = []
		for a in grp.split("&"):
			var t := a.strip_edges()
			if t == "":
				continue
			ands.append(_parse_atom(t, where))
		if not ands.is_empty():
			ors.append(ands)
	return ors


func _parse_atom(t: String, where: String) -> Dictionary:
	var neg := false
	if t.begins_with("!"):
		neg = true
		t = t.substr(1).strip_edges()
	for op in [">=", "<=", "==", "!=", ">", "<", "="]:
		var i := t.find(op)
		if i > 0:
			var left := t.substr(0, i).strip_edges()
			var right := t.substr(i + op.length()).strip_edges()
			return {"neg": neg, "key": left, "op": "==" if op == "=" else op, "val": right, "where": where}
	return {"neg": neg, "key": t, "op": "", "val": "", "where": where}


func eval_cond(cond: Variant) -> bool:
	if cond == null:
		return true
	var ors: Array = cond
	if ors.is_empty():
		return true
	for ands in ors:
		var ok := true
		for atom in ands:
			if not _eval_atom(atom):
				ok = false
				break
		if ok:
			return true
	return false


func check(cond_text: String) -> bool:
	return eval_cond(parse_cond(cond_text))


func _eval_atom(a: Dictionary) -> bool:
	var r := _atom_value(a)
	return (not r) if bool(a["neg"]) else r


func _cmp(lhs: Variant, op: String, rhs: String) -> bool:
	if op == "":
		if lhs is bool:
			return lhs
		if lhs is int or lhs is float:
			return float(lhs) != 0.0
		if lhs is String:
			return lhs != "" and lhs != "false" and lhs != "0"
		return lhs != null
	var lnum := lhs is int or lhs is float or lhs is bool
	if rhs.is_valid_float() and lnum:
		var l := float(lhs)
		var r := float(rhs)
		match op:
			">=": return l >= r
			"<=": return l <= r
			"==": return is_equal_approx(l, r)
			"!=": return not is_equal_approx(l, r)
			">": return l > r
			"<": return l < r
	var ls := str(lhs)
	if rhs == "true" or rhs == "false":
		var lb := _cmp(lhs, "", "")
		return (lb == (rhs == "true")) if op == "==" else (lb != (rhs == "true"))
	match op:
		"==": return ls == rhs
		"!=": return ls != rhs
	return false


func _atom_value(a: Dictionary) -> bool:
	var key: String = a["key"]
	var op: String = a["op"]
	var val: String = a["val"]
	var GS := GameState
	match key:
		"true": return true
		"false": return false
		"won": return GS.last_won
		"night": return GS.is_night()
		"day": return not GS.is_night()
		"rain": return GS.weather == "rain"
		"mask": return GS.wearing_mask()
		"companion": return GS.companions.size() > 0
		"party": return _cmp(GS.companions.size(), op, val)
		"cash": return _cmp(GS.cash, op, val)
		"level": return _cmp(GS.level, op, val)
		"stab": return _cmp(GS.stability, op, val)
		"hp": return _cmp(GS.hp, op, val)
		"hour": return _cmp(GS.hour(), op, val)
		"daynum": return _cmp(GS.day(), op, val)
		"chance": return _cmp(randi() % 100, op, val)
		"kills": return _cmp(int(GS.stats.get("kills", 0)), op, val)
		"innocents": return _cmp(int(GS.stats.get("innocents", 0)), op, val)
	var dot := key.find(".")
	if dot < 0:
		return _cmp(GS.flags.get(key, false), op, val)
	var ns := key.substr(0, dot)
	var rest := key.substr(dot + 1)
	match ns:
		"q":
			var sub := ""
			var d2 := rest.find(".")
			if d2 >= 0:
				sub = rest.substr(d2 + 1)
				rest = rest.substr(0, d2)
			var state := GS.quest_state(rest)
			match sub:
				"done": return state == "done"
				"active": return state == "active"
				"failed": return state == "failed"
				"started": return state != ""
			if op == "":
				return state != ""
			if state == "done" and (op == ">=" or op == ">"):
				return true
			return _cmp(GS.quest_stage(rest), op, val)
		"item": return _cmp(GS.count(rest), op if op != "" else ">=", val if op != "" else "1")
		"skill": return _cmp(GS.skill(rest), op, val)
		"fame": return _cmp(int(GS.fame.get(rest, 0)), op, val)
		"infamy": return _cmp(int(GS.infamy.get(rest, 0)), op, val)
		"hostile": return GS.faction_hostile(rest)
		"trust": return _cmp(GS.get_trust(rest), op, val)
		"perk": return GS.has_perk(rest)
		"trait": return GS.has_trait(rest)
		"companion": return GS.companions.has(rest)
		"dead": return GS.is_dead(rest)
		"seen": return GS.discovered.has(rest)
		"equipped": return GS.is_equipped(rest)
		"disguise": return GS.disguise() == rest
		"in": return GS.cell == rest or (rest == "subway" and GS.cell.begins_with("subway")) or (rest == "bld" and GS.cell.begins_with("bld:"))
		"driving": return _driving(rest)
		"at": return WorldLayout.region == rest
		"flag": return _cmp(GS.flags.get(rest, false), op, val)
	push_warning("unknown condition atom: " + key)
	return false


## driving.truck, driving.plane, driving.boat, driving.any: what you're at the wheel of.
func _driving(what: String) -> bool:
	if game == null:
		return false
	var pl: Variant = game.get("player")
	if pl == null:
		return false
	var dv: Variant = (pl as Node).get("driving")
	if dv == null or not is_instance_valid(dv):
		return false
	if what == "any":
		return true
	if dv is Aircraft:
		return what == "plane" or (dv as Aircraft).model == what
	if dv is Boat:
		return what == "boat" or (dv as Boat).model == what
	return (dv as Vehicle).kind == what


# ---------------------------------------------------------------- effects
## Runs effects in order; awaits world effects (minigames etc.).
func run_effects(fx: Array) -> void:
	for e in fx:
		await apply_effect(str(e["cmd"]), e["args"])


func apply_effect(cmd: String, args: Array) -> void:
	var GS := GameState
	var a0: String = str(args[0]) if args.size() > 0 else ""
	var a1: String = str(args[1]) if args.size() > 1 else ""
	match cmd:
		"set":
			var eq := a0.find("=")
			if eq > 0:
				var v := a0.substr(eq + 1)
				GS.set_flag(a0.substr(0, eq), int(v) if v.is_valid_int() else v)
			else:
				GS.set_flag(a0, true)
		"unset":
			GS.flags.erase(a0)
			GS.emit_signal("changed")
		"add":
			GS.add_flag(a0, int(a1) if a1 != "" else 1)
		"quest":
			if a1 == "done":
				GS.complete_quest(a0)
			elif a1 == "fail":
				GS.fail_quest(a0)
			else:
				GS.set_quest_stage(a0, int(a1))
		"track":
			GS.tracked_quest = a0
			GS.emit_signal("changed")
		"give", "note":
			GS.give(a0, int(a1) if a1 != "" else 1)
		"take":
			GS.take(a0, int(a1) if a1 != "" else 1)
		"cash":
			GS.add_cash(int(a0))
		"xp":
			GS.add_xp(int(a0))
		"fame":
			GS.add_fame(a0, int(a1))
		"infamy":
			GS.add_infamy(a0, int(a1))
		"trust":
			GS.add_trust(a0, int(a1))
		"stab":
			GS.adjust_stability(int(a0))
		"hp":
			if int(a0) >= 0:
				GS.heal(float(a0))
			else:
				GS.damage(-float(a0))
		"heal":
			GS.heal(GS.max_hp())
		"skill":
			GS.raise_skill(a0, int(a1))
			GS.emit_signal("notify", "%s +%s" % [DB.SKILL_NAMES.get(a0, a0), a1], "skill")
		"time":
			GS.advance_time(float(a0))
		"check":
			GS.last_won = GS.skill(a0) >= int(a1)
		"achieve":
			GS.unlock(a0)
		"discover":
			if game != null and game.has_method("discover_location"):
				game.discover_location(a0)
			else:
				GS.discover(a0)
		"wanted":
			GS.set_wanted(float(a0))
		"hostile_faction":
			GS.set_flag("hostile_" + a0, true)
		"equip":
			GS.equip(a0)
		"weather":
			GS.weather = a0
			GS.weather_until = GS.game_minutes + (float(a1) if a1 != "" else 180.0)
		_:
			if cmd in WORLD_EFFECTS:
				if game != null and game.has_method("dlg_world_effect"):
					await game.dlg_world_effect(cmd, args)
				else:
					GS.log_msg("world effect skipped (no game): " + cmd)
			else:
				push_error("unknown effect " + cmd)


# ---------------------------------------------------------------- helpers
func has_convo(cid: String) -> bool:
	return convos.has(cid)


func resolve_target(cid: String, target: String) -> Array:
	# Returns [convo_id, node_id] or ["", ""] for END.
	if target == "" or target == "END":
		return ["", ""]
	if (convos.get(cid, {}).get("nodes", {}) as Dictionary).has(target):
		return [cid, target]
	var dot := target.find(".")
	if dot > 0:
		var oc := target.substr(0, dot)
		var on := target.substr(dot + 1)
		if convos.has(oc) and (convos[oc]["nodes"] as Dictionary).has(on):
			return [oc, on]
	if convos.has(target):
		return [target, str(convos[target]["entry"])]
	push_error("bad dialogue target %s in %s" % [target, cid])
	return ["", ""]


func node(cid: String, nid: String) -> Dictionary:
	if not convos.has(cid):
		return {}
	return (convos[cid]["nodes"] as Dictionary).get(nid, {})


func entry(cid: String) -> String:
	return str(convos.get(cid, {}).get("entry", ""))


## Visible choices for a node, with display info.
func visible_choices(n: Dictionary) -> Array:
	var out: Array = []
	var idx := 0
	for ch in n.get("choices", []):
		var c: Dictionary = ch
		idx += 1
		if c["once"] and GameState.flags.has("seen:" + str(c["key"])):
			continue
		if not eval_cond(c["cond"]):
			continue
		out.append(c)
	return out


func choice_label(c: Dictionary) -> Dictionary:
	# Returns {text, color_kind: normal|pass|fail|seen}
	var t: String = c["text"]
	var kind := "normal"
	if c["check"] != null:
		var ck: Dictionary = c["check"]
		var sk := str(ck["skill"])
		var have := GameState.skill(sk)
		var dc := int(ck["dc"])
		t = "[%s %d] %s" % [DB.SKILL_NAMES[sk], dc, t]
		if have >= dc:
			kind = "pass"
		else:
			kind = "fail"
			t += "  (%d/%d)" % [have, dc]
	elif GameState.flags.has("seen:" + str(c["key"])):
		kind = "seen"
	return {"text": t, "kind": kind}


func mark_seen(c: Dictionary) -> void:
	GameState.flags["seen:" + str(c["key"])] = true
