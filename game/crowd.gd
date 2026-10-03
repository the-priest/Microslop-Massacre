class_name Crowd
extends Node3D
## Ambient pedestrians. Pooled around the player, walking sidewalk loops
## around city blocks and crossing at corners. Cheap: no world collision.

const BARKS := [
	"Watch where you're going.", "Spare a dollar? No? Figures.", "E Corp just doubled my loan interest. Doubled.",
	"You look like you haven't slept in a week.", "Hey, you seen my dog? Brown, answers to Biscuit.",
	"They say the power grid's gonna go. Stock up on batteries.", "Nice hoodie. Very... criminal.",
	"Don't make eye contact, don't make eye contact...", "Is the L running? Nobody knows if the L is running.",
	"I work three jobs and I still owe E Corp for college.", "Mm-hm. Sure. Whatever you say.",
	"Did you hear? Somebody hacked a hospital. Or a hospital hacked somebody.", "Get a job! Oh wait. Get two.",
	"This city eats people. Chews slow.", "You lost? You look lost.", "Ecoin this, Ecoin that. Give me cash.",
	"My cousin's a cop. Just saying.", "I swear that guy's been following me for three blocks.",
	"Coffee. I need coffee. Is that a bodega? Bless.", "Big storm coming. Can feel it in my knee.",
]
const NIGHT_BARKS := [
	"Walk faster, it's late.", "Nothing good happens after 2 AM. Except bagels.", "You shouldn't be out here alone.",
	"The city sounds different at night. Like it's breathing.", "Keep walking, friend.",
]

var game: Node = null
var peds: Array = []
var _looks: Array = []
var _blocks: Array = [] # Rect2 lanes
var _spawn_t: float = 0.0
var target_count: int = 26
var active: bool = true


func _ready() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 4242
	for i in 28:
		_looks.append(PersonMesh.mesh(PersonMesh.random_look(r)))
	for bj in WorldLayout.NBJ:
		for bi in WorldLayout.NBI:
			var d := WorldLayout.district(bi, bj)
			if d in ["park", "steel", "farm", "airfield", "reststop", "tw_field"]:
				continue
			_blocks.append({"rect": WorldLayout.block_rect(bi, bj).grow(1.2), "d": d})
	# Coney row (New York only).
	for i in (WorldLayout.NA - 1 if WorldLayout.region == "nyc" else 0):
		var x0 := WorldLayout.ax(i) + WorldLayout.AVE_HW
		var x1 := WorldLayout.ax(i + 1) - WorldLayout.AVE_HW
		_blocks.append({"rect": Rect2(x0, WorldLayout.CONEY_ROW_Z0, x1 - x0, WorldLayout.CONEY_ROW_Z1 - WorldLayout.CONEY_ROW_Z0).grow(1.2), "d": "coney"})
	target_count = Settings.crowd_count() if not _blocks.is_empty() else 0
	if WorldLayout.region == "highway":
		target_count = mini(target_count, 6)
	elif WorldLayout.region in ["township", "port"]:
		target_count = mini(target_count, maxi(8, int(target_count * 0.6))) # small towns, quieter streets
	Settings.applied.connect(func() -> void: target_count = Settings.crowd_count())


func set_active(on: bool) -> void:
	active = on
	visible = on
	for p in peds:
		(p as Node).process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
		var pp := p as Node3D
		pp.visible = on
		if not on:
			(p as Pedestrian).collision_layer = 0
		elif not (p as Pedestrian).dead:
			(p as Pedestrian).collision_layer = Phys.NPC


func _process(delta: float) -> void:
	if not active or game == null or game.player == null:
		return
	var pp: Vector3 = game.player.global_position
	_spawn_t -= delta
	# Despawn far ones.
	for p in peds.duplicate():
		var ped := p as Pedestrian
		if ped.global_position.distance_to(pp) > 175.0 or (ped.dead and ped.global_position.distance_to(pp) > 60.0):
			peds.erase(ped)
			ped.queue_free()
	var night := GameState.is_night()
	var want := target_count
	if night:
		want = int(float(want) * 0.55)
	if GameState.weather == "rain":
		want = int(float(want) * 0.6)
	if _spawn_t <= 0.0 and peds.size() < want:
		_spawn_t = 0.15
		_try_spawn(pp)


func _try_spawn(pp: Vector3) -> void:
	# Pick a nearby block, busier districts weigh more.
	var cands: Array = []
	for b in _blocks:
		var r: Rect2 = b["rect"]
		var c := Vector3(r.get_center().x, 0, r.get_center().y)
		var d := c.distance_to(pp)
		if d < 160.0:
			var w := 1.0
			match str(b["d"]):
				"midtown", "chinatown", "les", "coney": w = 2.0
				"industrial", "docks": w = 0.3
			cands.append([b, w])
	if cands.is_empty():
		return
	var total := 0.0
	for c in cands:
		total += float(c[1])
	var pick := randf() * total
	var chosen: Dictionary = cands[0][0]
	for c in cands:
		pick -= float(c[1])
		if pick <= 0.0:
			chosen = c[0]
			break
	var rect: Rect2 = chosen["rect"]
	var per := 2.0 * (rect.size.x + rect.size.y)
	var s := randf() * per
	var pos := Pedestrian.lane_point(rect, s)
	var dist := pos.distance_to(pp)
	if dist < 25.0 or dist > 150.0:
		return
	# Avoid popping in right in front of the camera.
	var cam: Camera3D = game.player.cam
	if dist < 70.0 and cam != null:
		var to := (pos - cam.global_position).normalized()
		if (-cam.global_transform.basis.z).dot(to) > 0.3:
			return
	var ped := Pedestrian.new()
	ped.crowd = self
	ped.rect = rect
	ped.s = s
	ped.dir = 1.0 if randf() < 0.5 else -1.0
	ped.speed = randf_range(1.1, 1.6)
	ped.mesh_res = _looks[randi() % _looks.size()]
	ped.lane_off = randf_range(-0.6, 0.6)
	add_child(ped)
	ped.global_position = pos
	peds.append(ped)


func neighbor_rect(rect: Rect2, corner: Vector2) -> Rect2:
	# Find another block lane-rect whose corner is near this corner (across a road).
	var best := rect
	var best_d := 40.0
	for b in _blocks:
		var r: Rect2 = b["rect"]
		if r == rect:
			continue
		for c in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
			var d := (c as Vector2).distance_to(corner)
			if d < best_d and d > 5.0:
				best_d = d
				best = r
	return best


func random_bark() -> String:
	if GameState.is_night() and randf() < 0.5:
		return NIGHT_BARKS[randi() % NIGHT_BARKS.size()]
	return BARKS[randi() % BARKS.size()]


func scatter(pos: Vector3, radius: float) -> void:
	for p in peds:
		var ped := p as Pedestrian
		if not ped.dead and ped.global_position.distance_to(pos) < radius:
			ped.flee_from(pos)
