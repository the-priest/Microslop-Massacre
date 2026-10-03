class_name Jobs
extends Node
## The job board: repeatable, generated contracts that pay cash. Offers
## refresh every in-game day; take up to three at once from the phone's JOBS
## tab. Every job targets a real door somewhere in the city, far enough away
## that you'll have to cross a few districts to get paid.
##
##   delivery   carry a sealed package to an address
##   bounty     a crew is loitering on a corner; clear them out
##   heist      lift an encrypted drive from an office server room
##   repo       recover a marked item from an apartment
##   hit        clear out a gang hideout
##   air        fly a crate to another town's airfield and land there
##   haul       drive a crate to a diner or a bar in another town
##
## State lives in GameState.jobs_state so it saves with the game.

const MAX_ACTIVE := 3
const CLIENTS := ["Dispatch", "A friend of a friend", "anon@onion", "Kowalski's Deli", "A lawyer who won't give a name",
	"The Super", "Someone from the docks", "A guy named Solomon", "An E Corp middle manager (off the books)",
	"A worried landlord", "Leon's cousin", "A voice with a Brooklyn accent"]
const GANGS := ["the Ghost Street crew", "the 4th Ave Boys", "Vera's leftovers", "the Tunnel Rats", "some Jersey muscle", "the Eastside Kings"]

## Airfields a freight run can end at: map -> [name, runway centre (local)].
const AIRFIELDS := {
	"nyc": ["Bowery Bay Airfield", Vector2(1570.0, -1280.0)],
	"chicago": ["Meigs Field", Vector2(640.0, -180.0)],
	"township": ["Kearney Strip", Vector2(-548.0, 0.0)],
	"port": ["Ramsey Field", Vector2(-730.0, -300.0)],
	"gary": ["Gary/Chicago Airport", Vector2(560.0, -300.0)],
}
## Out-of-town addresses for long hauls: door -> [map, where, interior].
const HAUL_DOORS := {
	"d_hw_diner": ["highway", "the Big Rig Diner on I-80", "hw_diner"],
	"d_chi_diner": ["chicago", "Lou's Red Hots on Chicago's South Side", "chi_diner"],
	"d_tw_diner": ["township", "the Township Diner on Main Street, Washington Township", "tw_diner"],
	"d_pt_bar": ["port", "the Barnacle on Water Street, Port Ramsey", "pt_bar"],
	"d_bodega": ["nyc", "the bodega on the Lower East Side", "bodega"],
	"d_gy_diner": ["gary", "the Steel City Grill on Broadway in Gary", "gy_diner"],
}
const CARGO := ["engine parts for a crop duster", "lobster on ice", "a church organ's pipes, packed in straw", "server blades with no paperwork", "somebody's grandmother's piano bench",
	"a case of insulin", "two hundred pounds of red-hot relish", "a used jet ski", "seed corn", "a wedding dress in a garment bag", "a box of vinyl that 'cannot get warm'"]

var game: Node = null
var _tick: float = 0.0


func _st() -> Dictionary:
	var s: Dictionary = GameState.jobs_state
	if not s.has("board"):
		s["board"] = []
		s["active"] = []
		s["day"] = -1
		s["n"] = 0
		s["done"] = 0
	return s


func board() -> Array:
	_refresh_board()
	return _st()["board"]


func active() -> Array:
	return _st()["active"]


func _refresh_board() -> void:
	var s := _st()
	if int(s["day"]) == GameState.day() and not (s["board"] as Array).is_empty():
		return
	s["day"] = GameState.day()
	var b: Array = []
	var r := RandomNumberGenerator.new()
	r.seed = hash("jobs" + str(GameState.day()) + str(int(s["done"])))
	var kinds := ["delivery", "bounty", "heist", "repo", "hit", "delivery", "bounty"]
	var used := {}
	for i in 4:
		var k: String = kinds[r.randi() % kinds.size()]
		var off := _make_offer(k, r, used)
		if not off.is_empty():
			b.append(off)
	# Out-of-town work: a long haul always, and air freight once you can fly.
	var haul := _make_offer("haul", r, used)
	if not haul.is_empty():
		b.append(haul)
	if _can_fly():
		var air := _make_offer("air", r, used)
		if not air.is_empty():
			b.append(air)
	s["board"] = b


func _can_fly() -> bool:
	for f in ["pilot_license", "gus_plane_ok", "walt_plane_ok", "jet_owned"]:
		if GameState.flags.has(f):
			return true
	return false


## Straight-line distance between two places on different maps (world metres).
func _world_dist(ra: String, a: Vector2, rb: String, b: Vector2) -> float:
	return Regions.to_world(ra, a).distance_to(Regions.to_world(rb, b))


func _pick_door(kinds: Array, r: RandomNumberGenerator, used: Dictionary) -> Dictionary:
	if game == null or game.gen_doors.is_empty():
		return {}
	var ids: Array = game.gen_doors.keys()
	var pp: Vector3 = game.player.global_position if game.player != null else Vector3.ZERO
	for tries in 60:
		var gd: Dictionary = game.gen_doors[ids[r.randi() % ids.size()]]
		if not (str(gd["kind"]) in kinds) or used.has(gd["id"]):
			continue
		if GameState.flags.has("cleared:bld:" + str(gd["id"])):
			continue # nobody left to hit / rob / repo there
		var dd := (gd["pos"] as Vector3).distance_to(pp)
		if dd < 220.0 and tries < 50:
			continue
		used[gd["id"]] = true
		return gd
	return {}


func _dist_name(gd: Dictionary) -> String:
	return str(WorldLayout.DISTRICT_NAMES.get(str(gd.get("district", "")), str(gd.get("district", ""))))


func _pay(base: int, r: RandomNumberGenerator) -> int:
	return int(float(base) * r.randf_range(0.85, 1.25) * (1.0 + float(GameState.level) * 0.07))


func _make_offer(k: String, r: RandomNumberGenerator, used: Dictionary) -> Dictionary:
	var s := _st()
	var id := "job%d" % int(s["n"])
	s["n"] = int(s["n"]) + 1
	var client: String = CLIENTS[r.randi() % CLIENTS.size()]
	match k:
		"delivery":
			var gd := _pick_door(["apartment", "grocery", "liquor", "pawnshop", "bar", "office", "diner", "hardware", "electronics"], r, used)
			if gd.is_empty():
				return {}
			return {"id": id, "kind": k, "client": client, "door": gd["id"], "pay": _pay(80, r), "xp": 25,
				"title": "Delivery: %s" % str(gd["name"]),
				"desc": "Carry a sealed package to %s (%s). Don't open it. Don't ask. The door will be unlocked for you." % [str(gd["name"]), _dist_name(gd)]}
		"bounty":
			var gd2 := _pick_door(["apartment", "squat", "grocery", "liquor", "bar"], r, used)
			if gd2.is_empty():
				return {}
			var gang: String = GANGS[r.randi() % GANGS.size()]
			var n := r.randi_range(3, 5)
			return {"id": id, "kind": k, "client": client, "door": gd2["id"], "pay": _pay(170, r), "xp": 60, "n": n, "gang": gang,
				"title": "Bounty: %s" % gang,
				"desc": "%s have been shaking people down outside %s in %s. %d of them. Make them stop. Permanently is fine." % [gang.capitalize(), str(gd2["name"]), _dist_name(gd2), n]}
		"heist":
			var gd3 := _pick_door(["office"], r, used)
			if gd3.is_empty():
				return {}
			return {"id": id, "kind": k, "client": client, "door": gd3["id"], "pay": _pay(230, r), "xp": 70,
				"title": "Data heist: %s" % str(gd3["name"]),
				"desc": "Get into %s (%s) and pull the encrypted drive from their server room. After hours is easier. After hours has guards." % [str(gd3["name"]), _dist_name(gd3)]}
		"repo":
			var gd4 := _pick_door(["apartment"], r, used)
			if gd4.is_empty():
				return {}
			var what: String = ["a laptop that isn't his", "a watch that was pawned without asking", "a hard drive full of somebody's secrets", "a ring that belonged to someone's grandmother"][r.randi() % 4]
			return {"id": id, "kind": k, "client": client, "door": gd4["id"], "pay": _pay(130, r), "xp": 45, "what": what,
				"title": "Recovery: %s" % str(gd4["name"]),
				"desc": "Someone at %s (%s) has %s. It's in a marked box. Get it back." % [str(gd4["name"]), _dist_name(gd4), what]}
		"hit":
			var gd5 := _pick_door(["hideout"], r, used)
			if gd5.is_empty():
				return {}
			return {"id": id, "kind": k, "client": client, "door": gd5["id"], "pay": _pay(320, r), "xp": 90,
				"title": "Hit: the crew at %s" % str(gd5["name"]),
				"desc": "A crew runs guns out of %s in %s. The door's locked and they're armed. Clear the place and whatever's in their safe is yours too." % [str(gd5["name"]), _dist_name(gd5)]}
		"air":
			var here := WorldLayout.region
			var dests: Array = []
			for reg in AIRFIELDS.keys():
				if str(reg) != here:
					dests.append(str(reg))
			var dest: String = dests[r.randi() % dests.size()]
			var from_pt: Vector2 = (AIRFIELDS.get(here, AIRFIELDS["nyc"]) as Array)[1]
			var d := _world_dist(here if AIRFIELDS.has(here) else "nyc", from_pt, dest, (AIRFIELDS[dest] as Array)[1])
			var what: String = CARGO[r.randi() % CARGO.size()]
			return {"id": id, "kind": k, "client": client, "region": dest, "pay": _pay(int(150.0 + d * 0.14), r), "xp": 80 + int(d / 100.0),
				"title": "Air freight: %s" % str((AIRFIELDS[dest] as Array)[0]),
				"desc": "Fly %s to %s in %s, about %.1f km as the crow flies. Take any plane you're allowed in, land on their runway and stop. The ground crew takes it from there." % [what, str((AIRFIELDS[dest] as Array)[0]), Regions.region_name(dest), d / 1000.0]}
		"haul":
			var keys: Array = []
			for did in HAUL_DOORS.keys():
				if str((HAUL_DOORS[did] as Array)[0]) != WorldLayout.region:
					keys.append(str(did))
			var hd: String = keys[r.randi() % keys.size()]
			var H: Array = HAUL_DOORS[hd]
			var here2 := WorldLayout.region
			var d2 := _world_dist(here2, Vector2.ZERO, str(H[0]), Vector2.ZERO)
			var what2: String = CARGO[r.randi() % CARGO.size()]
			return {"id": id, "kind": k, "client": client, "door": hd, "region": str(H[0]), "interior": str(H[2]), "pay": _pay(int(180.0 + d2 * 0.08), r), "xp": 60 + int(d2 / 150.0),
				"title": "Long haul: %s" % Regions.region_name(str(H[0])),
				"desc": "Drive %s to %s. It won't fit on a bike. Take the travel gates out of town and follow the signs." % [what2, str(H[1])]}
	return {}


# ---------------------------------------------------------------- actions
func accept(job_id: String) -> bool:
	var s := _st()
	if (s["active"] as Array).size() >= MAX_ACTIVE:
		GameState.emit_signal("notify", "You can only juggle %d jobs at once." % MAX_ACTIVE, "warn")
		return false
	var b: Array = s["board"]
	for i in b.size():
		var j: Dictionary = b[i]
		if str(j["id"]) != job_id:
			continue
		b.remove_at(i)
		(s["active"] as Array).append(j)
		match str(j["kind"]):
			"delivery":
				GameState.give("job_package", 1)
				GameState.unlocked[str(j["door"])] = true
			"air":
				GameState.give("air_cargo", 1)
			"haul":
				GameState.give("haul_crate", 1)
			"heist", "repo":
				# Make sure the target interior is rebuilt with the marked container.
				_invalidate(str(j["door"]))
		GameState.emit_signal("notify", "Job accepted: %s" % str(j["title"]), "quest")
		AudioManager.play_success()
		return true
	return false


func abandon(job_id: String) -> void:
	var a: Array = _st()["active"]
	for i in a.size():
		var j: Dictionary = a[i]
		if str(j["id"]) == job_id:
			a.remove_at(i)
			if str(j["kind"]) == "delivery":
				GameState.take("job_package", 1, true)
			elif str(j["kind"]) == "air":
				GameState.take("air_cargo", 1, true)
			elif str(j["kind"]) == "haul":
				GameState.take("haul_crate", 1, true)
			GameState.emit_signal("notify", "Job dropped: %s" % str(j["title"]), "warn")
			return


func _complete(j: Dictionary) -> void:
	var a: Array = _st()["active"]
	a.erase(j)
	var s := _st()
	s["done"] = int(s["done"]) + 1
	GameState.add_cash(int(j["pay"]))
	GameState.add_xp(int(j["xp"]))
	GameState.add_fame("locals", 1)
	GameState.stat_add("jobs")
	if game != null:
		game.hud.center("JOB COMPLETE  —  %s  —  +$%d" % [str(j["title"]).to_upper(), int(j["pay"])], 4.0)
	AudioManager.play_success()


func _invalidate(gid: String) -> void:
	if game == null:
		return
	var cell := "bld:" + gid
	if GameState.cell != cell and game.built_interiors.has(cell):
		(game.built_interiors[cell] as Node).queue_free()
		game.built_interiors.erase(cell)


## Extra containers a job plants inside a generated interior.
func extra_containers(gid: String) -> Array:
	var out: Array = []
	for j in active():
		var jd: Dictionary = j
		if str(jd["door"]) != gid:
			continue
		match str(jd["kind"]):
			"heist":
				out.append({"id": "jobc:" + str(jd["id"]), "title": "Marked Server", "pos": [13.6, -3.4], "y": 1.05, "size": [0.8, 2.2, 1.1], "items": {"job_data": 1}, "cash": 0, "owner": "locals"})
			"repo":
				out.append({"id": "jobc:" + str(jd["id"]), "title": "Marked Box", "pos": [6.4, 2.6], "y": 0.3, "size": [0.7, 0.6, 0.6], "items": {"job_item": 1}, "cash": 0, "owner": "locals", "lock": 25})
	return out


## Street crews for bounty jobs (only while you're within a few blocks).
func spawns() -> Array:
	var out: Array = []
	if game == null or game.player == null:
		return out
	var pp: Vector3 = game.player.global_position
	for j in active():
		var jd: Dictionary = j
		if str(jd["kind"]) != "bounty":
			continue
		var gd: Dictionary = game.gen_doors.get(str(jd["door"]), {})
		if gd.is_empty():
			continue
		var base: Vector3 = (gd["pos"] as Vector3) + (gd["out"] as Vector3) * 2.6
		if base.distance_to(pp) > 160.0:
			continue
		var crew := ["gang_smg", "thug_gun", "gang_shotgun", "thug", "gang_45"]
		for k in int(jd.get("n", 3)):
			var off := Vector3(-3.0 + float(k) * 1.6, 0, (0.8 if k % 2 == 0 else -0.6))
			out.append({"id": "job:%s#%d" % [str(jd["id"]), k], "template": crew[k % crew.size()], "pos": base + off, "yaw": 0.0, "wander": 2.5, "name": str(jd.get("gang", "Crew")).capitalize()})
	return out


func on_npc_died(n: NPC) -> void:
	if not n.id.begins_with("job:"):
		return
	var jid := n.id.substr(4).split("#")[0]
	for j in active():
		var jd: Dictionary = j
		if str(jd["id"]) != jid:
			continue
		for k in int(jd.get("n", 3)):
			if not GameState.is_dead("job:%s#%d" % [jid, k]):
				return
		_complete(jd)
		return


## Called by the Game whenever the player changes cell.
func on_enter(cell: String) -> void:
	for j in active().duplicate():
		var jd: Dictionary = j
		var gid := str(jd["door"])
		match str(jd["kind"]):
			"haul":
				if cell == str(jd.get("interior", "")) and GameState.has_item("haul_crate"):
					GameState.take("haul_crate", 1, true)
					if game != null:
						game.hud.subtitle("ELLIOT (V.O.)", "Crate on the floor. Somebody signs for it with a pen on a string and says 'long way, huh.' Long way.", 4.0)
					_complete(jd)
			"delivery":
				if cell == "bld:" + gid and GameState.has_item("job_package"):
					GameState.take("job_package", 1, true)
					if game != null:
						game.hud.subtitle("ELLIOT (V.O.)", "Package on the table. Nobody here, just an envelope with my name spelled wrong.", 4.0)
					_complete(jd)
			"heist", "repo":
				if cell == "world":
					var cid := "jobc:" + str(jd["id"])
					var item := "job_data" if str(jd["kind"]) == "heist" else "job_item"
					var c: Dictionary = GameState.containers.get(cid, {})
					if not c.is_empty() and not (c.get("items", {}) as Dictionary).has(item) and GameState.has_item(item):
						GameState.take(item, 1, true)
						_complete(jd)


func _process(delta: float) -> void:
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = 1.0
	for j in active().duplicate():
		var jd: Dictionary = j
		if str(jd["kind"]) == "hit" and GameState.flags.has("cleared:bld:" + str(jd["door"])):
			_complete(jd)


## A plane stopped on an airfield (Game._check_wings_landing): air freight
## for this map is delivered.
func on_landed(region: String) -> void:
	for j in active().duplicate():
		var jd: Dictionary = j
		if str(jd["kind"]) == "air" and str(jd.get("region", "")) == region and GameState.has_item("air_cargo"):
			GameState.take("air_cargo", 1, true)
			if game != null:
				game.hud.subtitle("GROUND CREW", "That's ours? Long way in a little plane. Sign here, and here, and... that's it. Go get a coffee, you look windblown.", 4.0)
			_complete(jd)


## Compass/map markers for active jobs (out-of-town ones point at the road
## or sky toward that town).
func marker_positions() -> Array:
	var out: Array = []
	if game == null:
		return out
	for j in active():
		var jd: Dictionary = j
		var reg := str(jd.get("region", WorldLayout.region))
		if reg != WorldLayout.region:
			var gid := RegionContent.gate_toward(WorldLayout.region, reg)
			var g: Dictionary = Regions.gates(WorldLayout.region).get(gid, {})
			if not g.is_empty():
				var gp: Array = g["pos"]
				out.append(Vector3(float(gp[0]), 0, float(gp[1])))
			continue
		match str(jd["kind"]):
			"air":
				var ap: Vector2 = (AIRFIELDS.get(reg, AIRFIELDS["nyc"]) as Array)[1]
				out.append(Vector3(ap.x, 0, ap.y))
			"haul":
				var dw := WorldLayout.door_world(str(jd["door"]))
				if not dw.is_empty():
					out.append(dw["pos"])
			_:
				var gd: Dictionary = game.gen_doors.get(str(jd.get("door", "")), {})
				if not gd.is_empty():
					out.append(gd["pos"])
	return out
