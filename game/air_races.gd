class_name AirRaces
extends Node
## Air races: courses flown from one airfield to another, most of them across
## a map border or two. Rings sit in shared world coordinates (Regions.WORLD),
## so a course can leave Kearney Strip, cross I-80 and finish at Ramsey Field;
## you see whichever rings lie over the map you're flying above. Fly every ring
## in order, then land and stop on the destination field. The clock and your
## place on the course live in GameState flags, so they survive the handover
## from one map's airspace to the next.

const RING_R := 16.0
## rings: [world x, altitude, world z]. medal: gold / silver / bronze seconds.
## dir: which way you take off from the start runway ("n" or "s").
const RACES := {
	"hop": {"name": "The Hop", "from": "township", "to": "port", "dir": "n", "host": "WALT", "fee": 100, "pay": [900, 500, 250], "medal": [240, 295, 385],
		"go": "Main Street, the plant, over I-80 at Lennox, round the Ramsey Point light, and down at Ramsey Field. Marisol's got the stopwatch on the other end. Don't scare her cows.",
		"rings": [[-5038, 90, -3700], [-4340, 70, -3400], [-3300, 140, -3350], [-1900, 150, -3400], [-390, 80, -3400], [1300, 150, -3450], [2700, 120, -3300], [4300, 95, -3600], [4462, 80, -3940]]},
	"lakefront": {"name": "The Lakefront", "from": "gary", "to": "chicago", "dir": "n", "host": "LENA", "fee": 100, "pay": [700, 400, 200], "medal": [150, 190, 250],
		"go": "Out over the lake, along the shore, high over the Loop, a lap of the water and down at the Chicago field. The towers are taller than they look. They always are.",
		"rings": [[-3930, 90, -6650], [-3200, 130, -6400], [-2200, 180, -6100], [-800, 265, -5900], [1100, 150, -5600]]},
	"express": {"name": "I-80 Express", "from": "chicago", "to": "nyc", "dir": "s", "host": "TOWER", "fee": 100, "pay": [700, 400, 200], "medal": [140, 180, 240],
		"go": "Chicago to New York down the interstate, low over Lennox, and land at Bowery Bay. Gus has a coffee waiting. It'll be cold. Make it warm.",
		"rings": [[230, 120, -5200], [-390, 110, -4200], [-390, 70, -3400], [-390, 120, -2650], [600, 180, -2150], [1570, 90, -2300]]},
	"commuter": {"name": "The Commuter", "from": "nyc", "to": "township", "dir": "n", "host": "GUS", "fee": 100, "pay": [750, 420, 220], "medal": [165, 205, 275],
		"go": "Bowery Bay to Kearney Strip. North out of the city, west along I-80, and right down Main Street before you land. Walt says buzz the diner. Walt says a lot of things.",
		"rings": [[1570, 120, -1900], [700, 160, -2400], [-1000, 140, -2900], [-2500, 120, -3300], [-3400, 100, -3450], [-4340, 60, -3400]]},
	"ore_run": {"name": "The Ore Run", "from": "gary", "to": "township", "dir": "s", "host": "LENA", "fee": 60, "pay": [500, 280, 150], "medal": [110, 140, 190],
		"go": "South along the shore, over the township's water tower and down Main Street to Kearney Strip. Short and sweet. Like my patience.",
		"rings": [[-3930, 100, -5500], [-4690, 90, -5100], [-4800, 100, -4100], [-4310, 75, -3700], [-4340, 60, -3150]]},
	"harbor": {"name": "Harbor Lap", "from": "port", "to": "port", "dir": "n", "host": "MARISOL", "fee": 60, "pay": [500, 280, 150], "medal": [115, 145, 195],
		"go": "Up the coast, round Silas's light, along the cranes, out over the harbor and home. If you clip a crane, the union will want a word, and so will I.",
		"rings": [[2980, 90, -4150], [3810, 100, -4050], [4462, 80, -3966], [4392, 95, -3550], [4310, 70, -3000], [3510, 80, -3050]]},
}
const MEDALS := ["GOLD", "SILVER", "BRONZE"]

var game: Node = null
var countdown := 0.0
var _grace := 3.0 # after a map change the plane takes a moment to be back under you
var _rings: Node3D = null
var _drawn := "" # ring index and map currently drawn, so we only rebuild on change
var _last_count := -1


func active() -> String:
	return str(GameState.flags.get("ar_on", ""))


func is_racing() -> bool:
	return active() != ""


## Races that start from this map's airfield.
static func from_here(region: String) -> Array:
	var out: Array = []
	for id in RACES.keys():
		if str((RACES[id] as Dictionary)["from"]) == region:
			out.append(str(id))
	return out


static func field_name(region: String) -> String:
	return str({"nyc": "Bowery Bay", "chicago": "the Chicago field", "township": "Kearney Strip", "port": "Ramsey Field", "gary": "Gary/Chicago Airport"}.get(region, "the airfield"))


## A ring's position on this map, or null when it's over another one.
static func ring_local(r: Array, region: String) -> Variant:
	var lp := Regions.to_local(region, Vector2(float(r[0]), float(r[2])))
	if not (Regions.SKY.get(region, Rect2()) as Rect2).has_point(lp):
		return null
	return Vector3(lp.x, float(r[1]), lp.y)


func start(id: String) -> void:
	if is_racing() or not RACES.has(id) or game == null or GameState.cell != "world":
		return
	var R: Dictionary = RACES[id]
	if str(R["from"]) != WorldLayout.region:
		return
	if GameState.cash < int(R["fee"]):
		game.hud.notify("The entry fee is $%d." % int(R["fee"]), "warn")
		return
	GameState.add_cash(-int(R["fee"]))
	if game.player.driving != null:
		game.exit_vehicle(true)
	var south := str(R.get("dir", "n")) == "s"
	var pos := Vector3(WorldLayout.RUNWAY_X, 0.5, WorldLayout.RUNWAY_Z0 + 40.0 if south else WorldLayout.RUNWAY_Z1 - 40.0)
	var a := Aircraft.new().setup_plane("skyhawk", pos, PI if south else 0.0, game)
	a.locked = false
	a.lock_dc = 0
	a.owner_tag = "player"
	a.set_meta("race_loaner", true)
	game.vehicles_root.add_child(a)
	await get_tree().process_frame
	game.enter_vehicle(a)
	GameState.flags["ar_on"] = id
	GameState.flags["ar_ring"] = 0
	GameState.flags["ar_t"] = 0.0
	countdown = 3.5
	_grace = 1.0
	_last_count = -1
	_drawn = ""
	var best := float(GameState.flags.get("ar_best_" + id, 0.0))
	game.hud.subtitle(str(R["host"]), str(R["go"]), 6.0)
	game.hud.notify("%s: %d rings, then land at %s.%s" % [str(R["name"]), (R["rings"] as Array).size(), field_name(str(R["to"])), ("  Your best: %s." % _clock(best)) if best > 0.0 else ""], "")


func _physics_process(delta: float) -> void:
	if game == null or game.player == null:
		return
	var id := active()
	if id == "" or not RACES.has(id):
		_clear_rings()
		return
	if _grace > 0.0:
		_grace -= delta
	var v: Variant = game.player.driving
	if v == null or not is_instance_valid(v) or not (v is Aircraft) or (v as Aircraft).dead or GameState.cell != "world":
		if _grace <= 0.0 and not game.busy_transition:
			_fail("You left the plane. Race over." if GameState.cell == "world" else "")
		return
	var a := v as Aircraft
	var R: Dictionary = RACES[id]
	if countdown > 0.0:
		countdown -= delta
		a.speed = 0.0
		var n := int(ceil(countdown - 0.5))
		if n != _last_count:
			_last_count = n
			game.hud.center("GO!" if n <= 0 else str(n), 0.9)
			AudioManager.play_key()
		_draw()
		return
	var t := float(GameState.flags.get("ar_t", 0.0)) + delta
	GameState.flags["ar_t"] = t
	if t > float((R["medal"] as Array)[2]) * 2.0:
		_fail("Out of time. The stopwatch went home.")
		return
	var rings: Array = R["rings"]
	var ri := int(GameState.flags.get("ar_ring", 0))
	if ri < rings.size():
		var lp: Variant = ring_local(rings[ri], WorldLayout.region)
		if lp != null and a.airborne and a.global_position.distance_to(lp as Vector3) < RING_R:
			ri += 1
			GameState.flags["ar_ring"] = ri
			AudioManager.play_success()
			Pad.rumble(0.3, 0.2, 0.15)
			if ri >= rings.size():
				game.hud.center("LAST RING  ·  LAND AT %s" % field_name(str(R["to"])).to_upper(), 2.5)
			else:
				game.hud.notify("Ring %d / %d   %s" % [ri, rings.size(), _clock(t)], "")
	elif WorldLayout.region == str(R["to"]) and not a.airborne and absf(a.speed) < 2.0 and WorldLayout.airfield_rect().has_point(Vector2(a.global_position.x, a.global_position.z)):
		_finish(t)
		return
	_draw()


## One line for the HUD under the speedometer.
func status() -> String:
	var id := active()
	if id == "" or not RACES.has(id):
		return ""
	var R: Dictionary = RACES[id]
	var ri := int(GameState.flags.get("ar_ring", 0))
	var n := (R["rings"] as Array).size()
	var where := "RING %d / %d" % [ri + 1, n] if ri < n else "LAND AT %s" % field_name(str(R["to"])).to_upper()
	var next_map := ""
	if ri < n and ring_local((R["rings"] as Array)[ri], WorldLayout.region) == null:
		next_map = "  ·  NEXT RING OVER %s" % Regions.region_name(_ring_region((R["rings"] as Array)[ri])).to_upper()
	return "AIR RACE  ·  %s  ·  %s  ·  %s%s" % [str(R["name"]).to_upper(), where, _clock(float(GameState.flags.get("ar_t", 0.0))), next_map]


## The next ring (or the destination runway) for the compass, even when it's
## over another map: it points the way you have to fly.
func marker_positions() -> Array:
	var id := active()
	if id == "" or not RACES.has(id):
		return []
	var R: Dictionary = RACES[id]
	var rings: Array = R["rings"]
	var ri := int(GameState.flags.get("ar_ring", 0))
	var w := Vector2.ZERO
	if ri < rings.size():
		var r: Array = rings[ri]
		w = Vector2(float(r[0]), float(r[2]))
	else:
		w = Regions.to_world(str(R["to"]), _runway_mid(str(R["to"])))
	var lp := Regions.to_local(WorldLayout.region, w)
	return [Vector3(lp.x, 0, lp.y)]


func _finish(t: float) -> void:
	var id := active()
	var R: Dictionary = RACES[id]
	_end()
	var m := 3
	for k in 3:
		if t <= float((R["medal"] as Array)[k]):
			m = k
			break
	var best := float(GameState.flags.get("ar_best_" + id, 0.0))
	if best <= 0.0 or t < best:
		GameState.flags["ar_best_" + id] = snappedf(t, 0.1)
	GameState.add_flag("air_races_flown", 1)
	if m >= 3:
		game.hud.center("%s  ·  %s\nNO MEDAL" % [str(R["name"]).to_upper(), _clock(t)], 4.0)
		game.hud.subtitle(str(R["host"]), "You got here. That counts for something. Not money, but something.", 4.0)
		return
	var tier := 3 - m # 3 gold, 2 silver, 1 bronze
	var had := int(GameState.flags.get("ar_medal_" + id, 0))
	var pay := int((R["pay"] as Array)[m])
	if tier <= had:
		pay = int(pay * 0.25) # you've already been paid for this medal; a tip for flying it again
	else:
		GameState.flags["ar_medal_" + id] = tier
	GameState.add_cash(pay)
	GameState.add_xp(40 + 30 * tier)
	AudioManager.play_levelup()
	game.hud.center("%s  ·  %s\n%s  +$%d" % [str(R["name"]).to_upper(), _clock(t), MEDALS[m], pay], 4.5)
	game.hud.subtitle(str(R["host"]), ["Gold. Clean lines, no wasted air. I'll put your name on the board in pen.", "Silver. Good flying. Somebody out there is still faster, and that should bother you.", "Bronze. You made every ring. Next time make them faster."][m], 5.0)


func _fail(msg: String) -> void:
	if msg != "" and game != null:
		game.hud.notify(msg, "warn")
	_end()


func _end() -> void:
	GameState.flags.erase("ar_on")
	GameState.flags.erase("ar_ring")
	GameState.flags.erase("ar_t")
	countdown = 0.0
	_clear_rings()


func _clear_rings() -> void:
	if _rings != null and is_instance_valid(_rings):
		_rings.queue_free()
	_rings = null
	_drawn = ""


## The current ring bright, the one after it dim, both only if they're over
## this map; on the final leg, a beacon on the destination runway.
func _draw() -> void:
	var id := active()
	var R: Dictionary = RACES[id]
	var rings: Array = R["rings"]
	var ri := int(GameState.flags.get("ar_ring", 0))
	var key := "%d@%s" % [ri, WorldLayout.region]
	if key == _drawn and _rings != null:
		return
	_clear_rings()
	_drawn = key
	_rings = Node3D.new()
	_rings.name = "AirRaceRings"
	game.add_child(_rings)
	for k in [ri, ri + 1]:
		if k >= rings.size():
			continue
		var lp: Variant = ring_local(rings[k], WorldLayout.region)
		if lp == null:
			continue
		var c: Vector3 = lp
		var pr: Array = rings[k - 1] if k > 0 else []
		var prev_w := Vector2(float(pr[0]), float(pr[2])) if k > 0 else Regions.to_world(str(R["from"]), _runway_mid(str(R["from"])))
		var prev := Regions.to_local(WorldLayout.region, prev_w)
		var dir := Vector3(c.x - prev.x, 0, c.z - prev.y)
		if dir.length() < 1.0:
			dir = Vector3(0, 0, -1)
		var bas := Basis.looking_at(dir.normalized(), Vector3.UP)
		var mb := MeshBatch.new()
		var col := Color(0.2, 0.85, 1.0) if k == ri else Color(0.08, 0.3, 0.38)
		for i in 28:
			var ang := TAU * float(i) / 28.0
			var xf := Transform3D(bas * Basis(Vector3.BACK, ang), c + bas * Vector3(cos(ang) * 15.0, sin(ang) * 15.0, 0))
			mb.box_xf(xf, Vector3(0.9, 3.6, 0.9), col)
		var mi := mb.commit(_rings, Mats.glow, 0.0, "AirRing%d" % k)
		mi.visibility_range_end = 4000.0
	if ri >= rings.size() and WorldLayout.region == str(R["to"]):
		var mid := _runway_mid(WorldLayout.region)
		var mb2 := MeshBatch.new()
		mb2.box(Vector3(mid.x, 40.0, mid.y), Vector3(2.0, 80.0, 2.0), Color(0.2, 0.85, 1.0))
		mb2.commit(_rings, Mats.glow, 0.0, "AirRaceFinish").visibility_range_end = 4000.0


func _ring_region(r: Array) -> String:
	var w := Vector2(float(r[0]), float(r[2]))
	return Regions.region_at(w, "")


## The middle of a map's runway (local).
static func _runway_mid(region: String) -> Vector2:
	if region == "nyc":
		return Vector2(1570.0, -1280.0) # Bowery Bay
	var d: Dictionary = Regions.DEFS.get(region, {})
	return Vector2(float(d.get("RUNWAY_X", 0.0)), (float(d.get("RUNWAY_Z0", 0.0)) + float(d.get("RUNWAY_Z1", 0.0))) * 0.5)


static func _clock(t: float) -> String:
	return "%d:%04.1f" % [int(t / 60.0), fmod(t, 60.0)]


# ------------------------------------------------------------------ the board
## A race board on the apron of any airfield that has races out of it.
func spawn_board(parent: Node3D) -> void:
	if from_here(WorldLayout.region).is_empty():
		return
	var p := board_pos()
	var it := Interactable.new().setup("convo", "air_board", "Air Race Board", "Read", p + Vector3(0, 1.2, 0), Vector3(2.2, 2.0, 1.0), {"convo": "air_board"})
	parent.add_child(it)
	var mb := MeshBatch.new()
	for sx in [-1.0, 1.0]:
		mb.box(p + Vector3(sx * 0.9, 0.9, 0), Vector3(0.1, 1.8, 0.1), Color(0.45, 0.32, 0.2))
	mb.box(p + Vector3(0, 1.45, 0), Vector3(2.0, 1.1, 0.08), Color(0.92, 0.92, 0.9))
	mb.box(p + Vector3(0, 2.05, 0), Vector3(2.0, 0.12, 0.12), Color(0.85, 0.2, 0.1))
	mb.commit(parent, Mats.lit, 160.0, "AirRaceBoardMesh")
	var lb := Label3D.new()
	lb.text = "AIR RACES"
	lb.font_size = 48
	lb.pixel_size = 0.006
	lb.modulate = Color(0.1, 0.12, 0.2)
	lb.outline_size = 0
	lb.double_sided = false
	parent.add_child(lb)
	lb.global_position = p + Vector3(0, 1.75, -0.06)
	lb.rotation.y = PI
	var lb2 := lb.duplicate() as Label3D
	parent.add_child(lb2)
	lb2.global_position = p + Vector3(0, 1.75, 0.06)
	lb2.rotation.y = 0.0


## On the apron, between the parked planes (Bowery Bay: by the taxiway).
static func board_pos() -> Vector3:
	if WorldLayout.region == "nyc":
		return Vector3(1482.0, 0.0, -1180.0)
	var r := WorldLayout.airfield_rect()
	var rx := WorldLayout.RUNWAY_X
	var hw := WorldLayout.RUNWAY_HW
	var east := (r.end.x - (rx + hw)) >= ((rx - hw) - r.position.x)
	var side := 1.0 if east else -1.0
	var ax := rx + side * (hw + 30.0)
	var az := (WorldLayout.RUNWAY_Z0 + WorldLayout.RUNWAY_Z1) * 0.5
	return Vector3(ax + side * 14.0, 0.0, az - 5.0)
