extends Node
## Static content validator: every dialogue jump, effect, quest, marker,
## interior, door, shop, convo, item and NPC reference must resolve.

var errors: Array = []
var warns: Array = []


func _ready() -> void:
	DialogueManager.load_all()
	DB.load_all()
	_check_dialogue_parse()
	_check_targets()
	_check_effects_and_conditions()
	_check_quests()
	_check_interiors()
	_check_npcs()
	_check_world()
	_check_markers()
	_check_story()
	_check_furniture()
	print("=== VALIDATE ===")
	for w in warns:
		print("WARN: ", w)
	for e in errors:
		print("ERR:  ", e)
	print("VALIDATE DONE errors=%d warns=%d" % [errors.size(), warns.size()])
	get_tree().quit()


func _err(m: String) -> void:
	errors.append(m)


func _warn(m: String) -> void:
	warns.append(m)


func _check_dialogue_parse() -> void:
	for e in DialogueManager.parse_errors:
		_err("dlg parse: " + str(e))


func _all_item_ids() -> Dictionary:
	var d := {}
	for k in DB.ITEMS.keys():
		d[str(k)] = true
	for k in DB.NOTES.keys():
		d[str(k)] = true
	return d


func _check_targets() -> void:
	for cid in DialogueManager.convos.keys():
		var c: Dictionary = DialogueManager.convos[cid]
		for nid in (c["nodes"] as Dictionary).keys():
			var node: Dictionary = c["nodes"][nid]
			for st in node["stmts"]:
				var s: Dictionary = st
				if str(s["k"]) in ["if", "goto"]:
					_check_target(str(cid), str(s["to"]))
			for ch in node["choices"]:
				var cc: Dictionary = ch
				_check_target(str(cid), str(cc["to"]))
				if str(cc["fail"]) != "":
					_check_target(str(cid), str(cc["fail"]))


func _check_target(cid: String, tgt: String) -> void:
	if tgt == "" or tgt == "END":
		return
	var c: Dictionary = DialogueManager.convos[cid]
	if (c["nodes"] as Dictionary).has(tgt):
		return
	var dot := tgt.find(".")
	if dot > 0:
		var oc := tgt.substr(0, dot)
		var on := tgt.substr(dot + 1)
		if DialogueManager.convos.has(oc) and (DialogueManager.convos[oc]["nodes"] as Dictionary).has(on):
			return
	if DialogueManager.convos.has(tgt):
		return
	_err("bad jump target '%s' in convo %s" % [tgt, cid])


func _check_effects_and_conditions() -> void:
	var items := _all_item_ids()
	for cid in DialogueManager.convos.keys():
		var c: Dictionary = DialogueManager.convos[cid]
		for nid in (c["nodes"] as Dictionary).keys():
			var node: Dictionary = c["nodes"][nid]
			for st in node["stmts"]:
				var s: Dictionary = st
				if str(s["k"]) == "do":
					_check_fx(s["fx"], "%s.%s" % [cid, nid], items)
			for ch in node["choices"]:
				_check_fx((ch as Dictionary)["fx"], "%s.%s choice" % [cid, nid], items)


func _check_fx(fx: Array, where: String, items: Dictionary) -> void:
	for e in fx:
		var cmd := str(e["cmd"])
		var args: Array = e["args"]
		var a0 := str(args[0]) if args.size() > 0 else ""
		match cmd:
			"give", "take", "note":
				if a0 != "" and not items.has(a0):
					_err("%s: unknown item '%s' in %s" % [cmd, a0, where])
			"quest":
				if not DB.QUESTS.has(a0):
					_err("quest effect: unknown quest '%s' in %s" % [a0, where])
			"minigame":
				if not ["lockpick", "exploit", "recon", "bruteforce", "signal", "cascade", "invaders", "loghunt"].has(a0):
					_err("minigame: unknown '%s' in %s" % [a0, where])
			"fame", "infamy":
				if not DB.FACTIONS.has(a0):
					_warn("%s: unknown faction '%s' in %s" % [cmd, a0, where])
			"trust":
				if not ["darlene", "angela", "robot", "krista", "shayla", "leon", "tyrell", "trenton", "gideon", "whiterose", "dipierro", "walt", "bev", "hale", "brandt", "ruthie", "silas", "marcus", "lena", "alvarez", "dana", "marta", "edie", "priya", "hector", "ines", "gus", "graham", "anita"].has(a0):
					_warn("trust: unknown '%s' in %s" % [a0, where])
			"race":
				if not Races.RACES.has(a0):
					_err("race: unknown street race '%s' in %s" % [a0, where])
			"airrace":
				if not AirRaces.RACES.has(a0):
					_err("airrace: unknown air race '%s' in %s" % [a0, where])
			"ending":
				if not EndingData.NAMES.has(a0):
					_err("ending: unknown '%s' in %s" % [a0, where])
			"equip":
				if a0 != "" and not items.has(a0):
					_err("equip: unknown item '%s' in %s" % [a0, where])


func _check_quests() -> void:
	for qid in DB.QUESTS.keys():
		var q: Dictionary = DB.QUESTS[qid]
		if (q["stages"] as Dictionary).is_empty():
			_err("quest %s has no stages" % qid)
		# Every quest should be startable from some effect.
		var started := false
		for cid in DialogueManager.convos.keys():
			if _convo_starts_quest(str(cid), str(qid)):
				started = true
				break
		for t in WorldObjects.TRIGGERS:
			if str(t.get("fx", "")).contains("quest " + str(qid) + " "):
				started = true
		if not started and _data_fx_mentions("quest " + str(qid) + " "):
			started = true
		if str(qid) != "mq_hello" and not started:
			_warn("quest %s is never started by any dialogue/trigger" % qid)


## Any interior/world spot, entry or action effect containing `needle`.
func _data_fx_mentions(needle: String) -> bool:
	var spots: Array = WorldObjects.SPOTS.duplicate()
	for iid in InteriorData.INTERIORS.keys():
		spots.append_array((InteriorData.INTERIORS[iid] as Dictionary).get("spots", []))
	for sp in spots:
		var sd: Dictionary = sp
		var all: Array = [sd]
		all.append_array(sd.get("entries", []))
		all.append_array(sd.get("actions", []))
		for e in all:
			for k in ["fx", "fx_hack"]:
				if (str((e as Dictionary).get(k, "")) + " ").contains(needle):
					return true
	return false


func _convo_starts_quest(cid: String, qid: String) -> bool:
	var c: Dictionary = DialogueManager.convos[cid]
	for nid in (c["nodes"] as Dictionary).keys():
		var node: Dictionary = c["nodes"][nid]
		for st in node["stmts"]:
			if str((st as Dictionary)["k"]) == "do":
				for e in (st as Dictionary)["fx"]:
					if str((e as Dictionary)["cmd"]) == "quest" and str(((e as Dictionary)["args"] as Array)[0] if ((e as Dictionary)["args"] as Array).size() > 0 else "") == qid:
						return true
		for ch in node["choices"]:
			for e in (ch as Dictionary)["fx"]:
				if str((e as Dictionary)["cmd"]) == "quest" and ((e as Dictionary)["args"] as Array).size() > 0 and str(((e as Dictionary)["args"] as Array)[0]) == qid:
					return true
	return false


func _check_interiors() -> void:
	for id in InteriorData.INTERIORS.keys():
		var d: Dictionary = InteriorData.INTERIORS[id]
		for e in d.get("exits", []):
			var to := str((e as Dictionary).get("to", ""))
			_check_link(to, "interior %s exit" % id)
		for f in d.get("furn", []):
			pass
		# Spots referencing convos/shops.
		for s in d.get("spots", []):
			var sd: Dictionary = s
			if str(sd.get("kind", "")) == "convo" and sd.has("convo"):
				if not DialogueManager.has_convo(str(sd["convo"])):
					_err("interior %s spot %s: missing convo %s" % [id, sd.get("id", "?"), sd["convo"]])
			if str(sd.get("kind", "")) == "shop" and not NPCData.SHOPS.has(str(sd.get("shop", ""))):
				_err("interior %s: unknown shop %s" % [id, sd.get("shop", "")])


func _check_link(to: String, where: String) -> void:
	if to.begins_with("world:"):
		var door := to.substr(6)
		if door != "subway" and not _any_door(door):
			_err("%s: unknown world door '%s'" % [where, door])
	elif to.begins_with("interior:"):
		var parts := to.split(":")
		if not InteriorData.INTERIORS.has(str(parts[1])) and str(parts[1]) != "subway":
			_err("%s: unknown interior '%s'" % [where, parts[1]])


## A door on any map: NYC's (loaded by default) or another region's.
func _any_door(door: String) -> bool:
	if WorldLayout.all_doors().has(door):
		return true
	for reg in RegionContent.DOORS.keys():
		if (RegionContent.DOORS[reg] as Dictionary).has(door):
			return true
	return false


func _check_npcs() -> void:
	for id in NPCData.NPCS.keys():
		var d: Dictionary = NPCData.NPCS[id]
		if d.has("convo") and not DialogueManager.has_convo(str(d["convo"])):
			_err("npc %s: missing convo %s" % [id, d["convo"]])
		for s in d.get("spawns", []):
			var cell := str((s as Dictionary).get("cell", "world"))
			if cell != "world" and not InteriorData.INTERIORS.has(cell) and not cell.begins_with("subway"):
				_err("npc %s: spawn in unknown cell %s" % [id, cell])
	# Doors point to real interiors.
	for did in WorldLayout.DOORS.keys():
		var inter := str(WorldLayout.DOORS[did]["interior"])
		if not inter.begins_with("subway") and not InteriorData.INTERIORS.has(inter):
			_err("door %s: interior '%s' not defined" % [did, inter])


func _check_world() -> void:
	var items := _all_item_ids()
	for pk in WorldObjects.PICKUPS:
		var it := str((pk as Dictionary).get("item", ""))
		if it != "cash" and not items.has(it):
			_err("pickup %s: unknown item %s" % [(pk as Dictionary).get("id", "?"), it])
	for sp in WorldObjects.SPOTS:
		var sd: Dictionary = sp
		if str(sd.get("kind", "")) == "convo" and not DialogueManager.has_convo(str(sd.get("convo", ""))):
			_err("world spot %s: missing convo %s" % [sd.get("id", "?"), sd.get("convo", "")])
	for t in WorldObjects.TRIGGERS:
		var td: Dictionary = t
		if td.has("convo") and not DialogueManager.has_convo(str(td["convo"])):
			_err("trigger %s: missing convo %s" % [td.get("id", "?"), td["convo"]])


func _check_markers() -> void:
	# Quest markers should resolve to a door, poi, npc, cell or pos.
	for qid in DB.QUESTS.keys():
		var q: Dictionary = DB.QUESTS[qid]
		for stage in (q["stages"] as Dictionary).keys():
			for o in (q["stages"] as Dictionary)[stage]:
				var m := str((o as Dictionary).get("marker", ""))
				if m == "":
					continue
				if not _marker_ok(m):
					_warn("quest %s stage %s: unresolved marker '%s'" % [qid, stage, m])


func _marker_ok(m: String) -> bool:
	if m == "ring":
		return true # the next ring of Gus's flight course (Game.RINGS)
	if m.begins_with("npc:"):
		return NPCData.NPCS.has(m.substr(4))
	if m.begins_with("cell:"):
		return true
	if m.begins_with("pos:"):
		return true
	if m.begins_with("region:"):
		return m.substr(7) == "nyc" or Regions.DEFS.has(m.substr(7))
	if m.begins_with("gate:"):
		var g := m.substr(5)
		for reg in Regions.GATES.keys():
			if (Regions.GATES[reg] as Dictionary).has(g):
				return true
		return false
	if _any_door(m):
		return true
	for reg2 in RegionContent.POIS.keys():
		if (RegionContent.POIS[reg2] as Dictionary).has(m):
			return true
	if WorldLayout.POIS.has(m):
		return true
	if InteriorData.INTERIORS.has(m):
		return true
	return false


# ------------------------------------------------------------- deep story checks
const BARE_ATOMS := ["true", "false", "won", "night", "day", "rain", "mask", "companion", "cash", "level", "stab", "hp", "hour", "daynum", "chance", "kills", "innocents"]
var _stage_sets: Dictionary = {} # qid -> {stage:int or "done": true}


func _cells() -> Dictionary:
	var out := {"world": true, "subway": true, "*": true, "bld": true}
	for k in InteriorData.INTERIORS.keys():
		out[k] = true
	return out


func _atom_ok(a: Dictionary, where: String) -> void:
	var key := str(a["key"])
	if key in BARE_ATOMS:
		return
	if key.contains(":"):
		_err("%s: malformed condition atom '%s'" % [where, key])
		return
	var dot := key.find(".")
	if dot < 0:
		return # bare flag
	var ns := key.substr(0, dot)
	var rest := key.substr(dot + 1)
	match ns:
		"q":
			var qid := rest.split(".")[0]
			if not DB.QUESTS.has(qid):
				_err("%s: condition on unknown quest '%s'" % [where, qid])
			if rest.contains("."):
				var sub := rest.split(".")[1]
				if not sub in ["done", "active", "failed", "started"]:
					_err("%s: bad quest state '%s'" % [where, sub])
		"item", "equipped":
			if not _all_item_ids().has(rest):
				_err("%s: condition on unknown item '%s'" % [where, rest])
		"skill":
			if not DB.SKILL_NAMES.has(rest):
				_err("%s: unknown skill '%s'" % [where, rest])
		"fame", "infamy", "hostile":
			if not DB.FACTIONS.has(rest):
				_warn("%s: unknown faction '%s'" % [where, rest])
		"in":
			if not _cells().has(rest):
				_err("%s: in.<cell> unknown cell '%s'" % [where, rest])
		"dead":
			if not NPCData.NPCS.has(rest):
				_warn("%s: dead.<npc> unknown npc '%s'" % [where, rest])
		"at":
			if not (rest == "nyc" or Regions.DEFS.has(rest)):
				_err("%s: at.<map> unknown map '%s'" % [where, rest])
		"trust", "perk", "trait", "companion", "seen", "disguise", "flag", "driving":
			pass
		_:
			_err("%s: unknown condition namespace '%s' in '%s'" % [where, ns, key])


func _cond_ok(c: Variant, where: String) -> void:
	if c == null:
		return
	for ands in c:
		for atom in ands:
			_atom_ok(atom, where)


func _cond_str(s: String, where: String) -> void:
	if s == "":
		return
	_cond_ok(DialogueManager.parse_cond(s, where), where)


func _fx_str(s: String, where: String) -> void:
	if s == "":
		return
	var fx := DialogueManager.parse_effects(s, where)
	_check_fx(fx, where, _all_item_ids())
	_note_stages(fx)


func _note_stages(fx: Array) -> void:
	for e in fx:
		if str(e["cmd"]) != "quest":
			continue
		var args: Array = e["args"]
		if args.size() < 2:
			continue
		var qid := str(args[0])
		if not _stage_sets.has(qid):
			_stage_sets[qid] = {}
		var a1 := str(args[1])
		_stage_sets[qid][int(a1) if a1.is_valid_int() else a1] = true


func _check_story() -> void:
	var n0 := DialogueManager.parse_errors.size()
	# Dialogue conditions + stage setters.
	for cid in DialogueManager.convos.keys():
		var c: Dictionary = DialogueManager.convos[cid]
		for nid in (c["nodes"] as Dictionary).keys():
			var node: Dictionary = c["nodes"][nid]
			var w := "%s.%s" % [cid, nid]
			for st in node["stmts"]:
				var sd: Dictionary = st
				if str(sd["k"]) == "if":
					_cond_ok(sd["cond"], w)
				elif str(sd["k"]) == "do":
					_note_stages(sd["fx"])
			for ch in node["choices"]:
				_cond_ok((ch as Dictionary)["cond"], w + " choice")
				_note_stages((ch as Dictionary)["fx"])
	# Data-side conditions and effects.
	for t in WorldObjects.TRIGGERS:
		var td: Dictionary = t
		var w2 := "trigger " + str(td.get("id", "?"))
		_cond_str(str(td.get("when", "")), w2)
		_fx_str(str(td.get("fx", "")), w2)
		if not _cells().has(str(td.get("cell", "world"))):
			_err("%s: unknown cell %s" % [w2, td.get("cell")])
	for id in NPCData.NPCS.keys():
		var d: Dictionary = NPCData.NPCS[id]
		for sp in d.get("spawns", []):
			_cond_str(str((sp as Dictionary).get("when", "")), "npc %s spawn" % id)
		_fx_str(str(d.get("on_death", "")), "npc %s on_death" % id)
	for gid in NPCData.GROUPS.keys():
		_cond_str(str(NPCData.GROUPS[gid].get("when", "")), "group " + str(gid))
	for iid in InteriorData.INTERIORS.keys():
		var idef: Dictionary = InteriorData.INTERIORS[iid]
		_cond_str(str(idef.get("allowed_when", "")), "interior %s allowed_when" % iid)
		for cn in idef.get("containers", []):
			var cd: Dictionary = cn
			var wc := "interior %s container %s" % [iid, cd.get("id", "?")]
			_cond_str(str(cd.get("when", "")), wc)
			_cond_str(str(cd.get("owner_ok", "")), wc)
			_fx_str(str(cd.get("fx_open", "")), wc)
		for sp2 in idef.get("spots", []):
			var sd2: Dictionary = sp2
			var ws := "interior %s spot %s" % [iid, sd2.get("id", "?")]
			_cond_str(str(sd2.get("when", "")), ws)
			_fx_str(str(sd2.get("fx", "")), ws)
			_fx_str(str(sd2.get("fx_hack", "")), ws)
			for e in sd2.get("entries", []):
				_cond_str(str((e as Dictionary).get("when", "")), ws + " entry")
				_fx_str(str((e as Dictionary).get("fx", "")), ws + " entry")
			for a in sd2.get("actions", []):
				_cond_str(str((a as Dictionary).get("when", "")), ws + " action")
				_fx_str(str((a as Dictionary).get("fx", "")), ws + " action")
	for hi in RadioData.HEADLINES.size():
		var hd: Dictionary = RadioData.HEADLINES[hi]
		_cond_str(str(hd.get("when", "")), "radio headline %d" % hi)
		if hd.has("region") and not (str(hd["region"]) == "nyc" or Regions.DEFS.has(str(hd["region"]))):
			_err("radio headline %d: unknown region %s" % [hi, str(hd["region"])])
	for sp3 in WorldObjects.SPOTS:
		var sd3: Dictionary = sp3
		_cond_str(str(sd3.get("when", "")), "world spot " + str(sd3.get("id", "?")))
		_fx_str(str(sd3.get("fx", "")), "world spot " + str(sd3.get("id", "?")))
		_fx_str(str(sd3.get("fx_hack", "")), "world spot " + str(sd3.get("id", "?")))
		for e3 in sd3.get("entries", []):
			_cond_str(str((e3 as Dictionary).get("when", "")), "world spot %s entry" % sd3.get("id", "?"))
			_fx_str(str((e3 as Dictionary).get("fx", "")), "world spot %s entry" % sd3.get("id", "?"))
		for a3 in sd3.get("actions", []):
			_cond_str(str((a3 as Dictionary).get("when", "")), "world spot %s action" % sd3.get("id", "?"))
			_fx_str(str((a3 as Dictionary).get("fx", "")), "world spot %s action" % sd3.get("id", "?"))
	for i in range(n0, DialogueManager.parse_errors.size()):
		_err("effect parse: " + str(DialogueManager.parse_errors[i]))
	# Every objective stage must be set by something, and every quest must finish.
	for qid in DB.QUESTS.keys():
		var q: Dictionary = DB.QUESTS[qid]
		var sets: Dictionary = _stage_sets.get(qid, {})
		var done_stage := -1
		for stage in (q["stages"] as Dictionary).keys():
			var objs: Array = (q["stages"] as Dictionary)[stage]
			if objs.size() == 1 and str((objs[0] as Dictionary)["text"]) == "done":
				done_stage = int(stage)
				continue
			if int(stage) == 10 and str(qid) == "mq_hello":
				continue # set in code at New Game
			if int(stage) == 20 and str(qid) == "mq_pr2":
				continue # set in code when you climb into the night freight truck
			if not sets.has(int(stage)):
				_err("quest %s stage %s is never set by any effect" % [qid, stage])
		if not sets.has("done") and not sets.has(done_stage):
			_err("quest %s can never be completed" % qid)
	# Markers resolve to something the game can place.
	for qid2 in DB.QUESTS.keys():
		var q2: Dictionary = DB.QUESTS[qid2]
		for stage2 in (q2["stages"] as Dictionary).keys():
			for o in (q2["stages"] as Dictionary)[stage2]:
				var m := str((o as Dictionary).get("marker", ""))
				if m.begins_with("cell:"):
					var cell := m.split(":")[1]
					if not _cells().has(cell):
						_err("quest %s stage %s: marker cell '%s' unknown" % [qid2, stage2, cell])
				elif m.begins_with("npc:"):
					var nd: Dictionary = NPCData.NPCS.get(m.substr(4), {})
					if (nd.get("spawns", []) as Array).is_empty():
						_err("quest %s stage %s: marker npc '%s' never spawns" % [qid2, stage2, m.substr(4)])


## Every furniture type used anywhere must exist in Furniture.build, or it
## silently renders nothing (this happened: mailbox, stairs_up, ac_unit).
func _check_furniture() -> void:
	var src := FileAccess.get_file_as_string("res://game/furniture.gd")
	var known := {}
	var re := RegEx.new()
	re.compile("\\n\\t\\t((?:\"[a-z_0-9]+\"(?:, )?)+):")
	for m in re.search_all(src):
		for part in m.get_string(1).split(","):
			known[part.strip_edges().trim_prefix("\"").trim_suffix("\"")] = true
	if known.size() < 40:
		_err("furniture check: parsed only %d types" % known.size())
		return
	for iid in InteriorData.INTERIORS.keys():
		for f in (InteriorData.INTERIORS[iid] as Dictionary).get("furn", []):
			var t := str((f as Array)[0])
			if not known.has(t):
				_err("interior %s: unknown furniture '%s'" % [iid, t])
	var psrc := FileAccess.get_file_as_string("res://game/proc_interior.gd")
	var re2 := RegEx.new()
	re2.compile("f\\(\"([a-z_0-9]+)\"")
	for m2 in re2.search_all(psrc):
		if not known.has(m2.get_string(1)):
			_err("proc_interior: unknown furniture '%s'" % m2.get_string(1))
