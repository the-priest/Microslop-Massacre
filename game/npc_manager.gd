class_name NPCManager
extends Node3D
## Decides which named NPCs and enemy groups exist in the current cell, based
## on their spawn conditions. Companions travel with the player.

var game: Node = null
var live: Dictionary = {} # id -> NPC
var _refresh_t: float = 0.0
var _conds: Dictionary = {} # cond text -> parsed


func _cond(text: String) -> bool:
	if text == "":
		return true
	if not _conds.has(text):
		_conds[text] = DialogueManager.parse_cond(text, "npc spawn")
	return DialogueManager.eval_cond(_conds[text])


func _process(delta: float) -> void:
	_refresh_t -= delta
	if _refresh_t <= 0.0 and game != null and not game.busy_transition:
		_refresh_t = 3.0
		refresh(false)


## Where should NPC `id` be right now? Returns {cell, pos, yaw} or {}.
func placement(id: String, d: Dictionary) -> Dictionary:
	for s in d.get("spawns", []):
		var sd: Dictionary = s
		if str(sd.get("cell", "world")) == "world" and str(sd.get("region", "nyc")) != WorldLayout.region:
			continue
		if _cond(str(sd.get("when", ""))):
			var p: Array = sd.get("pos", [0, 0])
			return {"cell": str(sd.get("cell", "world")), "pos": Vector3(float(p[0]), float(sd.get("y", 0.0)), float(p[1])), "yaw": deg_to_rad(float(sd.get("yaw", 0.0))), "wander": float(sd.get("wander", d.get("wander", 0.0)))}
	return {}


func refresh(force: bool) -> void:
	if game == null:
		return
	var cell: String = GameState.cell
	var player: Node3D = game.player
	var want: Dictionary = {}
	# Named NPCs.
	for id in NPCData.NPCS.keys():
		var d: Dictionary = NPCData.NPCS[id]
		if GameState.companions.has(id):
			if not GameState.is_dead(id):
				want[id] = {"def": d, "cell": cell, "pos": player.global_position + player.global_transform.basis.x * 1.5 + player.global_transform.basis.z * 1.5, "yaw": 0.0, "companion": true}
			continue
		if GameState.is_dead(id):
			continue
		var pl := placement(id, d)
		if pl.is_empty():
			continue
		# "subway" means any station platform (they share one layout).
		var pc := str(pl["cell"])
		if pc != cell and not (pc == "subway" and cell.begins_with("subway:")):
			continue
		want[id] = {"def": d, "cell": cell, "pos": game.cell_to_global(cell, pl["pos"]), "yaw": float(pl["yaw"]), "wander": float(pl["wander"])}
	# Groups (enemies, guards, crews).
	for gid in NPCData.GROUPS.keys():
		var g: Dictionary = NPCData.GROUPS[gid]
		if str(g.get("cell", "world")) != cell or not _cond(str(g.get("when", ""))):
			continue
		if cell == "world" and str(g.get("region", "nyc")) != WorldLayout.region:
			continue
		var tmpl: Dictionary = NPCData.TEMPLATES.get(str(g.get("template", "thug")), {}).duplicate(true)
		for k in (g.get("override", {}) as Dictionary).keys():
			tmpl[k] = g["override"][k]
		var i := 0
		for p in g.get("positions", []):
			var pa: Array = p
			var mid := "%s#%d" % [gid, i]
			i += 1
			if GameState.is_dead(mid):
				continue
			var d2 := tmpl.duplicate(true)
			if pa.size() > 3 and pa[3] is String:
				var t2: Dictionary = NPCData.TEMPLATES.get(str(pa[3]), {})
				for k in t2.keys():
					d2[k] = t2[k]
			if g.has("name"):
				d2["name"] = g["name"]
			d2["group"] = gid
			want[mid] = {"def": d2, "cell": cell, "pos": game.cell_to_global(cell, Vector3(float(pa[0]), 0.0, float(pa[1]))), "yaw": deg_to_rad(float(pa[2]) if pa.size() > 2 else 0.0), "wander": float(g.get("wander", 0.0))}
	# Dynamic occupants: generated interiors, street encounters, job targets.
	if game.has_method("dynamic_spawns"):
		for sp in game.dynamic_spawns(cell):
			var sd: Dictionary = sp
			var did := str(sd["id"])
			if GameState.is_dead(did) or not _cond(str(sd.get("when", ""))):
				continue
			var t0: Dictionary = NPCData.TEMPLATES.get(str(sd.get("template", "civilian")), {})
			if t0.is_empty():
				continue
			var d4 := t0.duplicate(true)
			d4["generic"] = true
			if str(sd.get("name", "")) != "":
				d4["name"] = sd["name"]
			if sd.has("override"):
				for k in (sd["override"] as Dictionary).keys():
					d4[k] = sd["override"][k]
			var pa4: Variant = sd["pos"]
			var gp := Vector3.ZERO
			if pa4 is Vector3:
				gp = pa4
			else:
				gp = Vector3(float(pa4[0]), 0.0, float(pa4[1]))
			if bool(sd.get("local", false)):
				gp = game.cell_to_global(cell, gp)
			want[did] = {"def": d4, "cell": cell, "pos": gp, "yaw": deg_to_rad(float(sd.get("yaw", 0.0))), "wander": float(sd.get("wander", 0.0))}
	# Despawn what shouldn't be here (not while fighting nearby).
	for id in live.keys():
		var nv: Variant = live[id]
		if not is_instance_valid(nv):
			live.erase(id)
			continue
		var n: NPC = nv
		if n.dead:
			# Named corpses are re-created from saved state; generated
			# interiors share one slot, so their corpses must go when you leave.
			if n.cell != cell and (not n.generic or n.cell.begins_with("bld:")):
				n.queue_free()
				live.erase(id)
			continue
		if not want.has(id) or n.cell != cell:
			var far := n.global_position.distance_to(player.global_position) > 35.0
			if force or far or n.cell != cell:
				if n.mode != "combat" or force or n.cell != cell:
					n.queue_free()
					live.erase(id)
	# Spawn missing.
	for id in want.keys():
		if live.has(id) and is_instance_valid(live[id]):
			var existing: NPC = live[id]
			if bool(want[id].get("companion", false)) and existing.cell != cell:
				existing.cell = cell
				existing.global_position = want[id]["pos"]
			continue
		var w: Dictionary = want[id]
		# Don't pop named characters into view right under the camera in the world.
		var n := NPC.new()
		var d: Dictionary = w["def"]
		if not d.has("wander") and float(w.get("wander", 0.0)) > 0.0:
			d = d.duplicate()
			d["wander"] = w["wander"]
		n.setup(str(id), d, w["pos"], float(w["yaw"]), cell, game)
		n.restricted = game.cell_restricted(cell, str(d.get("faction", "")))
		if bool(w.get("companion", false)):
			n.aggro = "companion"
		n.died.connect(game.on_npc_died_signal)
		add_child(n)
		n.global_position = w["pos"]
		live[id] = n
	# Corpses of named NPCs that died here.
	for id in GameState.dead_npc_pos.keys():
		if live.has(id):
			continue
		var d3: Dictionary = NPCData.NPCS.get(str(id), {})
		if d3.is_empty():
			continue
		var pp: Array = GameState.dead_npc_pos[id]
		var pl2 := str(pp[3]) if pp.size() > 3 else _last_cell_of(str(id), d3)
		if pl2 != cell:
			continue
		var c := NPC.new()
		c.setup(str(id), d3, Vector3(float(pp[0]), float(pp[1]), float(pp[2])), 0.0, cell, game)
		add_child(c)
		c.global_position = Vector3(float(pp[0]), float(pp[1]), float(pp[2]))
		c.call_deferred("die", null, true)
		live[id] = c


func _last_cell_of(id: String, d: Dictionary) -> String:
	# Corpses stay in whatever cell they were first placed in.
	for s in d.get("spawns", []):
		return str((s as Dictionary).get("cell", "world"))
	return "world"


func get_npc(id: String) -> NPC:
	var n: Variant = live.get(id)
	if n != null and is_instance_valid(n):
		return n
	return null


func clear_all() -> void:
	for id in live.keys():
		if is_instance_valid(live[id]):
			(live[id] as Node).queue_free()
	live.clear()
