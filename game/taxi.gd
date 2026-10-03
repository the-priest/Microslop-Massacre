class_name Taxi
extends Node
## Taxi fares: sit in any taxi on any map and the dispatch radio finds you a
## fare. Drive to the person flagging you down and stop; they get in and name
## an address; get them there before the meter's patience runs out and stop
## at the door. Fast and smooth pays a tip; a streak of fares pays more.
## Get out of the cab, or take too long, and the fare's gone.

const PICKUP_MIN := 70.0
const PICKUP_MAX := 260.0
const DEST_MIN := 260.0
const DEST_MAX := 900.0
const STOP_SPEED := 2.2
const LINES_IN := ["Thank God. Step on it, I'm late for everything.", "Is this the one with the TV in the back? No? Fine.", "Don't take the highway. Or do. I don't care. Just go.", "You're the first cab that stopped in twenty minutes. I could kiss you. I won't.",
	"I'll tip if you don't talk. I'll tip more if you don't sing.", "My app says surge pricing. You say what?", "Is it true the cab drivers in this town are all secretly hackers? ...Why are you looking at me like that."]
const LINES_OUT := ["Keep the change. Actually, keep all of it.", "Five stars. Do they still do stars? Five of whatever.", "That was terrifying. Here, take double.", "Same time tomorrow?", "You drive like you're being chased. Respect."]
const LINES_LATE := ["Forget it. Let me out here. I'll walk.", "I've been in this cab longer than my last relationship. Stop the car.", "This is not the way. This is not ANY way. Let me out."]

var game: Node = null
var state := "" # "", "pickup", "ride"
var fare_pos := Vector3.ZERO
var dest_pos := Vector3.ZERO
var dest_name := ""
var dest_dist := 0.0
var timer := 0.0
var streak := 0
var shift_pay := 0 # earned since you last got into a cab
var shift_fares := 0
var _cool := 2.0
var _rider: MeshInstance3D = null
var _rng := RandomNumberGenerator.new()
var _tick := 0.0


func _ready() -> void:
	_rng.randomize()


func in_taxi() -> bool:
	if game == null or game.player == null or GameState.cell != "world":
		return false
	var v: Variant = game.player.driving
	return v != null and is_instance_valid(v) and not (v is Aircraft) and (v as Vehicle).kind == "taxi"


## One line for the HUD under the speedometer.
func status() -> String:
	match state:
		"pickup":
			return "TAXI  ·  pick up the fare (stop beside them)%s" % ("   ·   STREAK %d" % streak if streak > 0 else "")
		"ride":
			return "TAXI  ·  %s  ·  %ds%s" % [dest_name.to_upper(), int(maxf(0.0, timer)), "   ·   STREAK %d" % streak if streak > 0 else ""]
	if in_taxi():
		return "TAXI  ·  dispatch is looking for a fare..."
	return ""


func marker_positions() -> Array:
	match state:
		"pickup":
			return [fare_pos]
		"ride":
			return [dest_pos]
	return []


func _physics_process(delta: float) -> void:
	if game == null:
		return
	_tick -= delta
	if state == "ride":
		timer -= delta
	if _tick > 0.0:
		return
	_tick = 0.25
	if not in_taxi():
		if state != "":
			_cancel("You left the cab. The fare's gone." if GameState.cell == "world" else "")
		if shift_fares > 0:
			game.hud.notify("Shift over: %d fare%s, $%d." % [shift_fares, "" if shift_fares == 1 else "s", shift_pay], "")
		streak = 0
		shift_fares = 0
		shift_pay = 0
		return
	var car: Vehicle = game.player.driving
	var p := car.global_position
	match state:
		"":
			_cool -= 0.25
			if _cool <= 0.0:
				_new_fare(p)
		"pickup":
			if Vector2(p.x - fare_pos.x, p.z - fare_pos.z).length() < 9.0 and absf(car.speed) < STOP_SPEED:
				_pick_up(p)
		"ride":
			if timer < -0.01:
				game.hud.subtitle("PASSENGER", LINES_LATE[_rng.randi() % LINES_LATE.size()], 3.5)
				streak = 0
				_end_fare()
				return
			if Vector2(p.x - dest_pos.x, p.z - dest_pos.z).length() < 12.0 and absf(car.speed) < STOP_SPEED:
				_drop_off()


## A street-side spot on the grid, a short drive away, where someone's waving.
func _new_fare(p: Vector3) -> void:
	# Only look at the blocks around the cab; the big maps are mostly too far.
	var ci := int(round((p.x - WorldLayout.AX0) / WorldLayout.AXS))
	var cj := int(floor((p.z - WorldLayout.SZ0) / WorldLayout.SZS))
	var ri := int(ceil(PICKUP_MAX / WorldLayout.AXS))
	var rj := int(ceil(PICKUP_MAX / WorldLayout.SZS))
	for tries in 40:
		var i := clampi(ci + _rng.randi_range(-ri, ri), 1, WorldLayout.NA - 2)
		var j := clampi(cj + _rng.randi_range(-rj, rj), 0, WorldLayout.NS - 2)
		if not WorldLayout.avenue_segment_exists(i, j):
			continue
		var side := 1.0 if _rng.randf() < 0.5 else -1.0
		var x := WorldLayout.ax(i) + side * (WorldLayout.AVE_ROAD + 1.6)
		var z := (WorldLayout.sz(j) + WorldLayout.sz(j + 1)) * 0.5 + _rng.randf_range(-12.0, 12.0)
		var d := Vector2(x - p.x, z - p.z).length()
		if d < PICKUP_MIN or d > PICKUP_MAX or not WorldLayout.in_bounds(x, z):
			continue
		var dname := str(WorldLayout.DISTRICT_NAMES.get(WorldLayout.district_at(x, z), ""))
		if dname == "" or WorldLayout.district_at(x, z) == "airfield":
			continue
		fare_pos = Vector3(x, 0, z)
		state = "pickup"
		_show_rider()
		game.hud.notify("Dispatch: fare waving on %s. Pull up beside them and stop." % dname, "")
		AudioManager.play_key()
		return
	_cool = 3.0


func _pick_up(p: Vector3) -> void:
	# Somewhere worth going: a real door a good drive away.
	var best: Dictionary = {}
	var cands: Array = []
	for gid in game.gen_doors.keys():
		var gd: Dictionary = game.gen_doors[gid]
		var dp: Vector3 = gd["pos"]
		var d := Vector2(dp.x - p.x, dp.z - p.z).length()
		if d >= DEST_MIN and d <= DEST_MAX:
			cands.append(gd)
	for did in WorldLayout.DOORS.keys():
		var dw := WorldLayout.door_world(str(did))
		if dw.is_empty():
			continue
		var dp2: Vector3 = dw["pos"]
		var d2 := Vector2(dp2.x - p.x, dp2.z - p.z).length()
		if d2 >= DEST_MIN and d2 <= DEST_MAX:
			cands.append({"pos": dp2, "out": dw.get("out", Vector3.ZERO), "name": str(WorldLayout.DOORS[did].get("name", did))})
	if cands.is_empty():
		_cancel("They take one look at the cab and change their mind.")
		return
	best = cands[_rng.randi() % cands.size()]
	var out: Vector3 = best.get("out", Vector3.ZERO)
	dest_pos = (best["pos"] as Vector3) + out * 4.0
	dest_name = str(best.get("name", "an address"))
	dest_dist = Vector2(dest_pos.x - p.x, dest_pos.z - p.z).length()
	timer = dest_dist / 10.0 + 25.0
	state = "ride"
	_hide_rider()
	game.hud.subtitle("PASSENGER", LINES_IN[_rng.randi() % LINES_IN.size()], 3.5)
	game.hud.center("%s\n%d m  ·  %d seconds" % [dest_name.to_upper(), int(dest_dist), int(timer)], 3.0)


func _drop_off() -> void:
	var tip := int(maxf(0.0, timer) * 1.5)
	var pay := 15 + int(dest_dist * 0.07) + tip + streak * 8
	streak += 1
	shift_fares += 1
	shift_pay += pay
	GameState.add_cash(pay)
	GameState.add_xp(10 + streak * 2)
	GameState.add_flag("taxi_fares", 1)
	GameState.stat_add("taxi_fares")
	game.hud.subtitle("PASSENGER", LINES_OUT[_rng.randi() % LINES_OUT.size()], 3.0)
	game.hud.center("FARE  +$%d%s" % [pay, ("   (tip $%d)" % tip) if tip > 0 else ""], 2.5)
	AudioManager.play_success()
	if streak == 5:
		game.hud.notify("Five fares in a row. Dispatch has started calling you 'the quiet one.'", "")
	_end_fare()


func _cancel(msg: String) -> void:
	if msg != "" and game != null:
		game.hud.notify(msg, "warn")
	streak = 0
	_end_fare()


func _end_fare() -> void:
	state = ""
	_cool = 4.0
	_hide_rider()


func _show_rider() -> void:
	_hide_rider()
	_rider = MeshInstance3D.new()
	_rider.mesh = PersonMesh.mesh(PersonMesh.random_look(_rng))
	_rider.material_override = Mats.npc
	_rider.name = "TaxiFare"
	game.add_child(_rider)
	_rider.global_position = fare_pos
	# Facing the road, arm out.
	var road_x := WorldLayout.ax(int(round((fare_pos.x - WorldLayout.AX0) / WorldLayout.AXS)))
	_rider.rotation.y = PI * 0.5 if road_x < fare_pos.x else -PI * 0.5


func _hide_rider() -> void:
	if _rider != null and is_instance_valid(_rider):
		_rider.queue_free()
	_rider = null
