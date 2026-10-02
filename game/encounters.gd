class_name Encounters
extends Node
## Random street events that find you while you walk the city. Nothing here
## is scripted to a place: every few minutes outdoors the city throws
## something at you somewhere down the block.
##
##   mugging    someone's being robbed ahead; stop it and they'll pay you back
##   ambush     a crew followed you (nights, or when you've got a reputation)
##   dealer     someone selling out of an alley at night (a fence; barter)
##   shakedown  a gang leaning on a shopkeeper; intervene or walk on
##   wallet     a dropped wallet on the sidewalk

var game: Node = null
var active: Array = [] # {id, kind, pos, until, npcs:[ids], resolved}
var _t: float = 90.0
var _n: int = 0


func _process(delta: float) -> void:
	if game == null or game.player == null or game.busy_transition or game.ui_open():
		return
	if GameState.cell != "world":
		return
	_t -= delta
	# Expire far-away or old encounters.
	var pp: Vector3 = game.player.global_position
	for e in active.duplicate():
		var ed: Dictionary = e
		if GameState.game_minutes > float(ed["until"]) or (ed["pos"] as Vector3).distance_to(pp) > 260.0:
			active.erase(ed)
	if _t > 0.0:
		return
	_t = randf_range(110.0, 200.0) if not GameState.is_night() else randf_range(70.0, 140.0)
	if active.size() >= 2 or game._in_combat():
		return
	_spawn_random()


func _spawn_random() -> void:
	var p := _spot_ahead()
	if p == Vector3.INF:
		return
	var night := GameState.is_night()
	var roll := randf()
	var kind := "mugging"
	if night:
		kind = ["mugging", "ambush", "dealer", "shakedown", "wallet", "mugging", "dealer"][randi() % 7]
	else:
		kind = ["mugging", "wallet", "shakedown", "wallet", "mugging"][randi() % 5]
	if kind == "ambush" and GameState.level < 3:
		kind = "mugging"
	# Ids persist across saves so a dead mugger from last night stays dead and
	# a new encounter never reuses a dead one's id.
	_n = maxi(_n, int(GameState.flags.get("enc_n", 0))) + 1
	GameState.flags["enc_n"] = _n
	var id := "enc:%d" % _n
	var e := {"id": id, "kind": kind, "pos": p, "until": GameState.game_minutes + 240.0, "resolved": false, "npcs": []}
	match kind:
		"mugging":
			e["npcs"] = [["mugger_knife", p + Vector3(0.9, 0, 0.3), "Mugger"], ["victim", p, "Frightened Local"]]
		"ambush":
			# Behind you, closing in.
			var back: Vector3 = game.player.global_position + game.player.global_transform.basis.z * 26.0
			var b2 := _snap_walkable(back)
			if b2 == Vector3.INF:
				return
			e["pos"] = b2
			var crew := ["thug_gun", "gang_smg", "thug", "mugger_knife"]
			var list: Array = []
			for k in randi_range(2, 3 + mini(2, GameState.level / 6)):
				list.append([crew[k % crew.size()], b2 + Vector3(float(k) * 1.4 - 1.5, 0, float(k % 2) * 1.2), "Ambusher"])
			e["npcs"] = list
			game.hud.subtitle("ELLIOT (V.O.)", "Footsteps behind me. Matching mine. Speeding up when I do.", 3.5)
		"dealer":
			e["npcs"] = [["dealer", p, "Dealer"]]
		"shakedown":
			e["npcs"] = [["thug", p + Vector3(1.2, 0, 0), "Shakedown Crew"], ["thug_gun", p + Vector3(-1.2, 0, 0.6), "Shakedown Crew"], ["victim", p + Vector3(0, 0, 1.0), "Shop Owner"]]
		"wallet":
			var cash := randi_range(15, 90)
			game.spawn_dynamic_pickup(id, "cash" if randf() < 0.6 else "credit_card", cash if randf() < 0.6 else 1, p + Vector3(0, 0.12, 0))
			e["resolved"] = true
	active.append(e)
	GameState.log_msg("encounter %s at %s" % [kind, str(p)])


## A sidewalk point 35-60 m ahead of the player, on the nearest avenue or street.
func _spot_ahead() -> Vector3:
	var pl: Node3D = game.player
	var fwd := -pl.global_transform.basis.z
	fwd.y = 0.0
	if fwd.length() < 0.1:
		fwd = Vector3(0, 0, -1)
	fwd = fwd.normalized()
	for tries in 6:
		var dist := randf_range(35.0, 60.0)
		var ang := randf_range(-0.5, 0.5)
		var cand: Vector3 = pl.global_position + fwd.rotated(Vector3.UP, ang) * dist
		var s := _snap_walkable(cand)
		if s != Vector3.INF:
			return s
	return Vector3.INF


## Snap a point onto the nearest sidewalk strip.
func _snap_walkable(p: Vector3) -> Vector3:
	if WorldLayout.district_at(p.x, p.z) in ["park", "steel", "coney"]:
		return Vector3.INF
	var i := int(round((p.x - WorldLayout.AX0) / WorldLayout.AXS))
	var j := int(round((p.z - WorldLayout.SZ0) / WorldLayout.SZS))
	var ax := WorldLayout.ax(i)
	var sz := WorldLayout.sz(j)
	var out := p
	if absf(p.x - ax) < absf(p.z - sz):
		out.x = ax + (8.4 if p.x > ax else -8.4)
	else:
		out.z = sz + (6.6 if p.z > sz else -6.6)
	out.y = 0.0
	if not WorldLayout.in_bounds(out.x, out.z):
		return Vector3.INF
	return out


func spawns() -> Array:
	var out: Array = []
	for e in active:
		var ed: Dictionary = e
		var k := 0
		for spec in ed["npcs"]:
			var sa: Array = spec
			out.append({"id": "%s#%d" % [str(ed["id"]), k], "template": str(sa[0]), "pos": sa[1], "yaw": 0.0, "name": str(sa[2]), "wander": 1.5 if str(sa[0]) != "victim" else 0.0})
			k += 1
	return out


func on_npc_died(n: NPC, by_player: bool) -> void:
	if not n.id.begins_with("enc:"):
		return
	var eid := n.id.split("#")[0]
	for e in active:
		var ed: Dictionary = e
		if str(ed["id"]) != eid or bool(ed["resolved"]):
			continue
		# All aggressors down, victim alive: they thank you.
		var k := 0
		var hostile_left := 0
		var victim_id := ""
		for spec in ed["npcs"]:
			var t := str((spec as Array)[0])
			var sid := "%s#%d" % [eid, k]
			if t == "victim":
				victim_id = sid
			elif t != "dealer" and not GameState.is_dead(sid):
				hostile_left += 1
			k += 1
		if hostile_left > 0:
			return
		ed["resolved"] = true
		if victim_id != "" and not GameState.is_dead(victim_id):
			var reward := randi_range(25, 70) + GameState.level * 4
			GameState.add_cash(reward)
			GameState.add_fame("locals", 2)
			GameState.add_xp(20)
			GameState.adjust_stability(3)
			GameState.stat_add("rescues")
			var v: NPC = game.npcs.get_npc(victim_id)
			if v != null:
				game.bark(v, "Thank you — thank you. Here, it's all I've got on me.")
		elif str(ed["kind"]) == "ambush":
			GameState.add_xp(25)
		return
