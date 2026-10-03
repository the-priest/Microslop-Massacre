class_name Emergency
extends Node
## Paramedic and vigilante calls, on any map.
##
## Ambulance: dispatch sends you to someone down on the sidewalk. Pull up
## beside them and stop, then get them to the hospital (or the clinic, or in
## Lennox the pharmacy's urgent care) before the clock runs out.
## Police cruiser, with no heat of your own: dispatch calls in a car fleeing
## a crime. Run it down and ram it until it gives up.
## Each call answered in a shift is a level: tighter clocks, better pay.
## Get out of the vehicle and the shift's over.

const STOP_SPEED := 2.2
## Where the sick get taken on each map: [name, x, z] (a spot on the sidewalk
## outside the door).
const HOSPITALS := {
	"nyc": ["Mercy General", 325.0, 156.0],
	"chicago": ["Lakeside General", 200.0, 161.0],
	"township": ["Township Medical Clinic", 65.0, 4.0],
	"port": ["Port Ramsey Urgent Care", 65.0, 4.0],
	"gary": ["St. Margaret's", 200.0, 4.0],
	"highway": ["Lennox Pharmacy Urgent Care", 18.0, 654.0],
}
## Service vehicles parked outside: [kind, x, z, yaw]. Ambulances are left
## open; cruisers are locked.
const PARKED := {
	"nyc": [["ambulance", 334.0, 156.7, -PI * 0.5], ["police", -222.0, 243.3, PI * 0.5]],
	"chicago": [["ambulance", 210.0, 158.3, PI * 0.5], ["police", 188.0, -255.3, -PI * 0.5]],
	"township": [["ambulance", 76.0, 3.3, PI * 0.5], ["police", -96.0, 3.3, PI * 0.5]],
	"port": [["ambulance", 76.0, 3.3, PI * 0.5]],
	"gary": [["ambulance", 211.0, 3.3, PI * 0.5]],
	"highway": [["ambulance", 5.2, 640.0, 0.0]],
}
const MED_IN := ["(A groan.) Is it bad? Don't tell me if it's bad.", "I'm fine. I'm totally fine. Why is the sky spinning.", "Do you take E Corp Health? Please say you take E Corp Health.",
	"Tell my landlord I died. It's the only way he'll fix the radiator.", "Is this an ambulance or a very fast van? Either way, thank you."]
const MED_OUT := ["They wheel them in. One of them squeezes your hand on the way through the doors.", "A nurse nods at you, the way nurses nod: you did the one thing right today.",
	"The ER doors swallow them up. Somebody on a smoke break claps, once."]
const COP_GO := ["Dispatch: stolen sedan headed your way. Driver's armed with a bad attitude.", "Dispatch: hit and run, suspect vehicle fleeing. Bring it in.",
	"Dispatch: armed robbery at a bodega, suspect in a car, driving like it. Stop them.", "Dispatch: E Corp exec ran a red with a cyclist on his hood. Nobody else will stop him. You will."]

var game: Node = null
var mode := "" # "", "medic", "cop": what you're sitting in
var state := "" # medic: "", "pickup", "ride"   cop: "", "chase"
var level := 0 # calls answered this shift
var shift_pay := 0
var call_pos := Vector3.ZERO
var timer := 0.0
var suspect: Vehicle = null
var _flee: Node3D = null
var _patient: MeshInstance3D = null
var _dest_dist := 0.0
var _cool := 2.0
var _tick := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


## What you're driving that answers calls, or "".
func vehicle_mode() -> String:
	if game == null or game.player == null or GameState.cell != "world":
		return ""
	var v: Variant = game.player.driving
	if v == null or not is_instance_valid(v) or v is Aircraft:
		return ""
	match (v as Vehicle).kind:
		"ambulance": return "medic"
		"police": return "cop"
	return ""


func status() -> String:
	var lv := "   ·   LEVEL %d" % (level + 1)
	match mode:
		"medic":
			match state:
				"pickup": return "PARAMEDIC  ·  get to the patient and stop beside them%s" % lv
				"ride": return "PARAMEDIC  ·  %s  ·  %ds%s" % [str(HOSPITALS.get(WorldLayout.region, ["THE HOSPITAL"])[0]).to_upper(), int(maxf(0.0, timer)), lv]
			return "PARAMEDIC  ·  waiting on dispatch..."
		"cop":
			if GameState.is_wanted():
				return "VIGILANTE  ·  dispatch won't talk to a cruiser that's being chased"
			if state == "chase" and is_instance_valid(suspect):
				var d := suspect.global_position.distance_to(game.player.driving.global_position)
				return "VIGILANTE  ·  SUSPECT %d m  ·  %d%%  ·  %ds%s" % [int(d), int(maxf(0.0, suspect.hp)), int(maxf(0.0, timer)), lv]
			return "VIGILANTE  ·  waiting on dispatch..."
	return ""


func marker_positions() -> Array:
	if mode == "medic" and state == "pickup":
		return [call_pos]
	if mode == "medic" and state == "ride":
		return [_hospital()]
	if mode == "cop" and state == "chase" and is_instance_valid(suspect):
		return [suspect.global_position]
	return []


func _physics_process(delta: float) -> void:
	if game == null:
		return
	if state != "":
		timer -= delta
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = 0.25
	var m := vehicle_mode()
	if m != mode:
		_end_shift()
		mode = m
		_cool = 2.0
	if mode == "":
		return
	var car: Vehicle = game.player.driving
	var p := car.global_position
	if mode == "medic":
		_medic(car, p)
	else:
		_cop(car, p)


# ------------------------------------------------------------------ paramedic
func _medic(car: Vehicle, p: Vector3) -> void:
	match state:
		"":
			_cool -= 0.25
			if _cool <= 0.0:
				_new_patient(p)
		"pickup":
			if timer < 0.0:
				_fail_medic("Too slow. Another rig got there first.")
			elif Vector2(p.x - call_pos.x, p.z - call_pos.z).length() < 9.0 and absf(car.speed) < STOP_SPEED:
				_load_patient(p)
		"ride":
			if timer < 0.0:
				_fail_medic("They needed a hospital ten seconds ago. The patient's stable, no thanks to you: the next rig took over.")
				return
			var h := _hospital()
			if Vector2(p.x - h.x, p.z - h.z).length() < 12.0 and absf(car.speed) < STOP_SPEED:
				_deliver()


func _hospital() -> Vector3:
	var h: Array = HOSPITALS.get(WorldLayout.region, HOSPITALS["nyc"])
	return Vector3(float(h[1]), 0, float(h[2]))


func _new_patient(p: Vector3) -> void:
	var spot := _sidewalk_spot(p, 80.0, 320.0)
	if spot == Vector3.INF or _hospital().distance_to(spot) > 900.0:
		_cool = 2.0
		return
	call_pos = spot
	state = "pickup"
	timer = p.distance_to(spot) / 8.0 + 30.0
	_show_patient()
	game.hud.notify("Dispatch: person down on %s. Get there." % str(WorldLayout.DISTRICT_NAMES.get(WorldLayout.district_at(spot.x, spot.z), "the street")), "")
	AudioManager.play_key()


func _load_patient(p: Vector3) -> void:
	_hide_patient()
	state = "ride"
	_dest_dist = Vector2(p.x - _hospital().x, p.z - _hospital().z).length()
	timer = _dest_dist / maxf(7.0, 9.5 + level * 0.3) + maxf(12.0, 30.0 - level * 1.5)
	game.hud.subtitle("PATIENT", MED_IN[_rng.randi() % MED_IN.size()], 3.5)
	game.hud.center("%s\n%d m  ·  %d seconds" % [str(HOSPITALS.get(WorldLayout.region, ["THE HOSPITAL"])[0]).to_upper(), int(_dest_dist), int(timer)], 3.0)


func _deliver() -> void:
	var pay := 40 + int(_dest_dist * 0.06) + level * 15 + int(maxf(0.0, timer))
	level += 1
	shift_pay += pay
	state = ""
	_cool = 3.0
	GameState.add_cash(pay)
	GameState.add_xp(12 + level * 3)
	GameState.add_flag("medic_calls", 1)
	game.hud.subtitle("", MED_OUT[_rng.randi() % MED_OUT.size()], 3.5)
	game.hud.center("PATIENT DELIVERED  +$%d\nLEVEL %d" % [pay, level], 2.5)
	AudioManager.play_success()
	if level == 10:
		GameState.set_flag("medic_10")
		GameState.add_cash(1000)
		game.hud.notify("Ten patients in one shift. The night supervisor at %s sends you a card. It says 'thank you' and, smaller, 'please get licensed.'  +$1000" % str(HOSPITALS.get(WorldLayout.region, ["the hospital"])[0]), "")


func _fail_medic(msg: String) -> void:
	game.hud.notify(msg, "warn")
	_hide_patient()
	state = ""
	level = 0
	_cool = 5.0


func _show_patient() -> void:
	_hide_patient()
	_patient = MeshInstance3D.new()
	_patient.mesh = PersonMesh.mesh(PersonMesh.random_look(_rng))
	_patient.material_override = Mats.npc
	_patient.name = "Patient"
	game.add_child(_patient)
	_patient.global_position = call_pos + Vector3(0, 0.18, 0)
	_patient.rotation = Vector3(-PI * 0.5, _rng.randf() * TAU, 0) # lying on the pavement


func _hide_patient() -> void:
	if _patient != null and is_instance_valid(_patient):
		_patient.queue_free()
	_patient = null


# ------------------------------------------------------------------ vigilante
func _cop(car: Vehicle, p: Vector3) -> void:
	if GameState.is_wanted():
		if state == "chase":
			_lose_suspect("Dispatch: we're calling it off. You're the one with the sirens on you now.")
		return
	match state:
		"":
			_cool -= 0.25
			if _cool <= 0.0:
				_new_suspect(p)
		"chase":
			if not is_instance_valid(suspect):
				_lose_suspect("")
				return
			if suspect.dead or suspect.hp <= 35.0:
				_suspect_down(suspect.dead)
				return
			var d := suspect.global_position.distance_to(p)
			if d > 650.0 or timer < 0.0:
				_lose_suspect("Suspect got away. Dispatch sighs over the radio.")
				return
			# Keep running: pick somewhere new once it gets where it was going.
			if _flee != null and suspect.global_position.distance_to(_flee.global_position) < 25.0:
				_pick_flee(p)


func _new_suspect(p: Vector3) -> void:
	var at := Vector3.INF
	var yaw := 0.0
	for tries in 30:
		var i := clampi(int(round((p.x - WorldLayout.AX0) / WorldLayout.AXS)) + _rng.randi_range(-3, 3), 0, WorldLayout.NA - 1)
		var j := clampi(int(floor((p.z - WorldLayout.SZ0) / WorldLayout.SZS)) + _rng.randi_range(-3, 3), 0, WorldLayout.NS - 2)
		if not WorldLayout.avenue_segment_exists(i, j):
			continue
		var c := Vector3(WorldLayout.ax(i) + (2.6 if _rng.randf() < 0.5 else -2.6), 0.4, (WorldLayout.sz(j) + WorldLayout.sz(j + 1)) * 0.5)
		var d := Vector2(c.x - p.x, c.z - p.z).length()
		if d < 140.0 or d > 320.0 or not WorldLayout.in_bounds(c.x, c.z):
			continue
		if _blocked(c):
			continue
		at = c
		yaw = 0.0 if c.x > WorldLayout.ax(i) else PI
		break
	if at == Vector3.INF:
		_cool = 2.0
		return
	var kinds := ["sedan", "hatch", "suv", "van"]
	suspect = Vehicle.new().setup(kinds[_rng.randi() % kinds.size()], _rng.randi() % Props.CAR_COLORS.size(), at, yaw, game)
	suspect.locked = true
	suspect.lock_dc = 95
	suspect.ai_race = true
	suspect.ai_speed_mul = minf(0.95, 0.8 + level * 0.02)
	suspect.set_meta("suspect", true)
	game.vehicles_root.add_child(suspect)
	if _flee == null:
		_flee = Node3D.new()
		add_child(_flee)
	_pick_flee(p)
	suspect.ai_target = _flee
	state = "chase"
	timer = 120.0
	game.hud.notify(COP_GO[_rng.randi() % COP_GO.size()], "")
	AudioManager.play_key()


## Somewhere far from you to run to.
func _pick_flee(p: Vector3) -> void:
	var best := Vector3.ZERO
	var best_d := -1.0
	for tries in 12:
		var i := _rng.randi_range(0, WorldLayout.NA - 1)
		var j := _rng.randi_range(0, WorldLayout.NS - 1)
		if not WorldLayout.intersection_exists(i, j):
			continue
		var c := Vector3(WorldLayout.ax(i), 0, WorldLayout.sz(j))
		var from_suspect := c.distance_to(suspect.global_position)
		if from_suspect < 120.0 or from_suspect > 700.0:
			continue
		var d := c.distance_to(p)
		if d > best_d:
			best_d = d
			best = c
	if best_d > 0.0:
		_flee.global_position = best


func _suspect_down(wrecked: bool) -> void:
	var pay := 60 + level * 30 + (0 if wrecked else 40)
	level += 1
	shift_pay += pay
	GameState.add_cash(pay)
	GameState.add_xp(15 + level * 3)
	GameState.add_flag("suspects_down", 1)
	game.hud.center("SUSPECT DOWN  +$%d\nLEVEL %d" % [pay, level], 2.5)
	game.hud.subtitle("DISPATCH", "Messy. But they're not going anywhere." if wrecked else "Suspect's out of the car with their hands up. Nice driving, officer. You are an officer, right?", 3.5)
	AudioManager.play_success()
	_release_suspect()
	state = ""
	_cool = 4.0
	if level == 10:
		GameState.set_flag("vigilante_10")
		GameState.add_cash(1000)
		game.hud.notify("Ten suspects in one shift. Somebody at the precinct has started a betting pool on who you are.  +$1000", "")


func _lose_suspect(msg: String) -> void:
	if msg != "":
		game.hud.notify(msg, "warn")
	if is_instance_valid(suspect):
		suspect.queue_free()
	suspect = null
	state = ""
	level = 0
	_cool = 5.0


## Leave the stopped car where it is for a while, then clean it up.
func _release_suspect() -> void:
	if not is_instance_valid(suspect):
		suspect = null
		return
	var s := suspect
	s.ai_target = null
	s.speed = 0.0
	var t := Timer.new()
	t.wait_time = 25.0
	t.one_shot = true
	t.autostart = true
	s.add_child(t)
	t.timeout.connect(func() -> void:
		if not s.driving:
			s.queue_free())
	suspect = null


func _end_shift() -> void:
	if level > 0 and game != null and game.hud != null:
		game.hud.notify("Shift over: %d call%s, $%d." % [level, "" if level == 1 else "s", shift_pay], "")
	_hide_patient()
	if is_instance_valid(suspect):
		suspect.queue_free()
	suspect = null
	state = ""
	level = 0
	shift_pay = 0


# ------------------------------------------------------------------ shared
## A spot on an avenue sidewalk at least `lo` and at most `hi` from p.
func _sidewalk_spot(p: Vector3, lo: float, hi: float) -> Vector3:
	var ci := int(round((p.x - WorldLayout.AX0) / WorldLayout.AXS))
	var cj := int(floor((p.z - WorldLayout.SZ0) / WorldLayout.SZS))
	var ri := int(ceil(hi / WorldLayout.AXS))
	var rj := int(ceil(hi / WorldLayout.SZS))
	for tries in 40:
		var i := clampi(ci + _rng.randi_range(-ri, ri), 1, WorldLayout.NA - 2)
		var j := clampi(cj + _rng.randi_range(-rj, rj), 0, WorldLayout.NS - 2)
		if not WorldLayout.avenue_segment_exists(i, j):
			continue
		var side := 1.0 if _rng.randf() < 0.5 else -1.0
		var x := WorldLayout.ax(i) + side * (WorldLayout.AVE_ROAD + 1.6)
		var z := (WorldLayout.sz(j) + WorldLayout.sz(j + 1)) * 0.5 + _rng.randf_range(-12.0, 12.0)
		var d := Vector2(x - p.x, z - p.z).length()
		if d < lo or d > hi or not WorldLayout.in_bounds(x, z):
			continue
		var dist := WorldLayout.district_at(x, z)
		if dist == "airfield" or str(WorldLayout.DISTRICT_NAMES.get(dist, "")) == "":
			continue
		return Vector3(x, 0, z)
	return Vector3.INF


func _blocked(pos: Vector3) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(2.4, 1.2, 5.6)
	q.shape = bs
	q.transform = Transform3D(Basis.IDENTITY, pos + Vector3(0, 0.9, 0))
	q.collision_mask = Phys.WORLD | Phys.CAR
	return not game.get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty()


## The ambulances and cruisers parked outside this map's hospital and police
## station. If the curb's taken, slide along it.
func spawn_parked() -> void:
	# Give the freshly built map a physics tick so the curb checks can see it.
	for i in 2:
		await get_tree().physics_frame
	if game == null or not is_instance_valid(game.vehicles_root):
		return
	for e in PARKED.get(WorldLayout.region, []):
		var pe: Array = e
		var yaw := float(pe[3])
		var along := Vector3(-sin(yaw), 0, -cos(yaw))
		for off in [0.0, 8.0, -8.0, 16.0, -16.0]:
			var pos := Vector3(float(pe[1]), 0.4, float(pe[2])) + along * float(off)
			if _blocked(pos) or _near_city_car(pos):
				continue
			var v := Vehicle.new().setup(str(pe[0]), 0, pos, yaw, game)
			if str(pe[0]) == "ambulance":
				v.locked = false
				v.lock_dc = 0
			else:
				v.locked = true
				v.lock_dc = 45
			v.set_meta("service", true)
			game.vehicles_root.add_child(v)
			break


func _near_city_car(pos: Vector3) -> bool:
	if game.get("loot_index") == null or game.loot_index == null:
		return false
	for le in game.loot_index.near(pos, 4.5):
		var ep: Vector3 = (le as Dictionary)["p"]
		if Vector2(ep.x - pos.x, ep.z - pos.z).length() < 4.5:
			return true
	return false
