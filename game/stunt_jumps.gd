class_name StuntJumps
extends Node
## Stunt jumps: plywood-and-steel ramps on Coney Island's beach and on the
## grass beside every airfield's runway. Hit one fast in a car and the world
## slows down while you fly; come down on your wheels far enough away and it
## counts. Each one pays once. All of them is AIR TIME.

const MIN_SPEED := 16.0
const NEED := 22.0 # metres from the lip of the ramp to where you land
const RAMP_L := 9.0
const RAMP_W := 5.0
const RAMP_H := 2.6
const PAY := 150
const SLOWMO := 0.45

var game: Node = null
var jumps: Array = [] # [{id, start: Vector3, lip: Vector3, yaw}]
var _jump_id := ""
var _lip := Vector3.ZERO
var _slow_t := 0.0
var _prev_launched := false


## Where the ramps go on a map: [id, start x, start z, yaw] (start = the low
## end, on the ground; yaw = the way you drive up it).
static func spots(region: String) -> Array:
	var out: Array = []
	if region == "nyc":
		# Coney Island beach, both ends, along the sand.
		out.append(["nyc_beach_w", -520.0, 752.0, -PI * 0.5])
		out.append(["nyc_beach_e", 460.0, 752.0, PI * 0.5])
	var has_field := region == "nyc" or (Regions.DEFS.get(region, {}) as Dictionary).has("AIRFIELD")
	if has_field:
		var rx := WorldLayout.RUNWAY_X
		var hw := WorldLayout.RUNWAY_HW
		var side := 1.0
		if region == "nyc":
			side = 1.0 # Bowery Bay's apron is west of the runway; the grass east is clear
		else:
			var r := WorldLayout.airfield_rect()
			side = 1.0 if (r.end.x - (rx + hw)) >= ((rx - hw) - r.position.x) else -1.0
		var x := rx + side * (hw + 16.0)
		out.append([region + "_field_n", x, WorldLayout.RUNWAY_Z1 - 30.0, 0.0])
		out.append([region + "_field_s", x, WorldLayout.RUNWAY_Z0 + 30.0, PI])
	return out


static func total() -> int:
	return 14


func build(parent: Node3D) -> void:
	jumps.clear()
	for sp in spots(WorldLayout.region):
		var a: Array = sp
		var yaw := float(a[3])
		var f := Vector3(-sin(yaw), 0, -cos(yaw))
		var start := Vector3(float(a[1]), 0.0, float(a[2]))
		var lip := start + f * RAMP_L + Vector3(0, RAMP_H, 0)
		_ramp(parent, start, lip, yaw, str(a[0]))
		jumps.append({"id": str(a[0]), "start": start, "lip": lip, "yaw": yaw})


func _ramp(parent: Node3D, start: Vector3, lip: Vector3, yaw: float, id: String) -> void:
	var f := Vector3(-sin(yaw), 0, -cos(yaw))
	var theta := atan2(RAMP_H, RAMP_L)
	var b := Basis.looking_at(f, Vector3.UP) * Basis(Vector3.RIGHT, theta)
	var t := 0.5
	var length := sqrt(RAMP_L * RAMP_L + RAMP_H * RAMP_H)
	var top_mid := (start + Vector3(0, -0.03, 0) + lip) * 0.5
	var center := top_mid - b.y * (t * 0.5)
	var body := StaticBody3D.new()
	body.name = "Ramp_" + id
	body.collision_layer = Phys.WORLD
	body.collision_mask = 0
	parent.add_child(body)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(RAMP_W, t, length)
	cs.shape = bs
	body.add_child(cs)
	cs.global_transform = Transform3D(b, center)
	var mb := MeshBatch.new()
	mb.box_xf(Transform3D(b, center), Vector3(RAMP_W, t, length), Color(0.55, 0.42, 0.28))
	# Chevrons up the deck and steel rails along the edges.
	for k in 4:
		var p := start.lerp(lip, (float(k) + 0.5) / 4.0) + b.y * 0.02
		mb.box_xf(Transform3D(b, p + b.x * 0.9), Vector3(1.6, 0.02, 0.35), Color(0.95, 0.78, 0.1))
		mb.box_xf(Transform3D(b, p - b.x * 0.9), Vector3(1.6, 0.02, 0.35), Color(0.95, 0.78, 0.1))
	for s in [-1.0, 1.0]:
		mb.box_xf(Transform3D(b, center + b.x * (RAMP_W * 0.5 + 0.06) * float(s) + b.y * 0.2), Vector3(0.12, 0.4, length), Color(0.35, 0.36, 0.38))
	# A frame under the high end.
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	for s2 in [-1.0, 1.0]:
		mb.box(lip - f * 0.3 + right * (RAMP_W * 0.5 - 0.3) * float(s2) + Vector3(0, -RAMP_H * 0.5, 0), Vector3(0.25, RAMP_H, 0.25), Color(0.3, 0.3, 0.32))
	mb.commit(parent, Mats.lit, 400.0, "RampMesh_" + id)
	var done := GameState.has_flag("jump_" + id)
	var flag := MeshBatch.new()
	var pole := Vector3(lip.x, 0, lip.z) + right * (RAMP_W * 0.5 + 0.8)
	flag.box(pole + Vector3(0, 2.0, 0), Vector3(0.1, 4.0, 0.1), Color(0.4, 0.4, 0.42))
	flag.box(pole + Vector3(0, 3.6, 0) + f * 0.45, Vector3(0.05, 0.6, 0.9), Color(0.2, 0.9, 0.3) if done else Color(1.0, 0.55, 0.1))
	flag.commit(parent, Mats.glow, 400.0, "RampFlag_" + id)


func _physics_process(delta: float) -> void:
	if game == null or game.player == null:
		return
	if _slow_t > 0.0:
		_slow_t -= delta / maxf(Engine.time_scale, 0.05)
		if _slow_t <= 0.0:
			Engine.time_scale = 1.0
	var v: Variant = game.player.driving
	if v == null or not is_instance_valid(v) or v is Aircraft or GameState.cell != "world":
		if _jump_id != "":
			_end(false, "")
		_prev_launched = false
		return
	var car := v as Vehicle
	if car.launched and not _prev_launched and _jump_id == "":
		_maybe_start(car)
	_prev_launched = car.launched
	if _jump_id != "":
		if car.dead:
			_end(false, "Wrecked it.")
		elif not car.launched and car.is_on_floor():
			var d := Vector2(car.global_position.x - _lip.x, car.global_position.z - _lip.z).length()
			if d >= NEED:
				_end(true, "%d m" % int(d))
			else:
				_end(false, "Short. %d of %d metres." % [int(d), int(NEED)])


func _maybe_start(car: Vehicle) -> void:
	for j in jumps:
		var jd: Dictionary = j
		var lip: Vector3 = jd["lip"]
		if Vector2(car.global_position.x - lip.x, car.global_position.z - lip.z).length() < 6.0:
			if absf(car.speed) < MIN_SPEED:
				return
			_jump_id = str(jd["id"])
			_lip = lip
			Engine.time_scale = SLOWMO
			_slow_t = 1.1
			game.hud.center("STUNT JUMP", 1.0)
			AudioManager.play_key()
			return


func _end(ok: bool, why: String) -> void:
	var id := _jump_id
	_jump_id = ""
	Engine.time_scale = 1.0
	_slow_t = 0.0
	if not ok:
		if why != "" and game != null:
			game.hud.notify("STUNT JUMP FAILED. " + why, "warn")
		return
	var first := not GameState.has_flag("jump_" + id)
	GameState.set_flag("jump_" + id)
	if first:
		GameState.add_flag("jumps_done", 1)
		GameState.add_cash(PAY)
		GameState.add_xp(60)
		game.hud.center("STUNT JUMP COMPLETE  ·  %s\n%d / %d  +$%d" % [why, int(GameState.flags.get("jumps_done", 0)), total(), PAY], 3.0)
		AudioManager.play_levelup()
	else:
		game.hud.center("STUNT JUMP  ·  %s" % why, 2.0)
		AudioManager.play_success()
