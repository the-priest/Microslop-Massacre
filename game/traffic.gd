class_name Traffic
extends Node3D
## Car traffic on the street grid. Right-hand lanes, turns at intersections,
## yields to cars already in an intersection, stops (and honks) for the player.

const AVE_LANE := 2.2
const ST_LANE := 1.3

var game: Node = null
var cars: Array = []
var target_count: int = 16
var active: bool = true
var _spawn_t: float = 0.0
var _occupied: Dictionary = {} # "i,j" -> car
const TYPES := ["sedan", "sedan", "sedan", "taxi", "taxi", "suv", "van", "hatch", "police", "truck"]


class Car:
	extends AnimatableBody3D
	var axis: String = "ave" # ave: moving along z at x=ax(i); st: along x at z=sz(j)
	var idx: int = 0
	var dirn: float = 1.0
	var coord: float = 0.0 # position along the axis
	var speed: float = 0.0
	var max_speed: float = 11.0
	var honk_t: float = 0.0
	var in_inter: String = ""
	var yaw_target: float = 0.0
	var kind: String = "sedan"
	var color_idx: int = 0

	## Stopped in traffic: you can pull the driver out.
	func interact_info() -> Dictionary:
		var g = get_parent().get("game")
		if speed > 3.0 or g == null or g.player.driving != null:
			return {}
		var nm: String = {"sedan": "Sedan", "hatch": "Hatchback", "suv": "SUV", "van": "Van", "taxi": "Taxi", "police": "NYPD Cruiser", "truck": "Box Truck"}.get(kind, "Car")
		return {"verb": "Carjack", "name": nm + ("  (a cop's in it)" if kind == "police" else "")}

	func world_pos() -> Vector3:
		if axis == "ave":
			var x := WorldLayout.ax(idx) - dirn * Traffic.AVE_LANE
			return Vector3(x, 0, coord)
		var z := WorldLayout.sz(idx) + dirn * Traffic.ST_LANE
		return Vector3(coord, 0, z)

	func heading() -> Vector3:
		return Vector3(0, 0, dirn) if axis == "ave" else Vector3(dirn, 0, 0)


func _ready() -> void:
	target_count = Settings.traffic_count()
	Settings.applied.connect(func() -> void: target_count = Settings.traffic_count())


func set_active(on: bool) -> void:
	active = on
	visible = on
	for c in cars:
		(c as Node).process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
		(c as Car).collision_layer = (Phys.CAR | Phys.INTERACT) if on else 0


func _physics_process(delta: float) -> void:
	if not active or game == null or game.player == null:
		return
	var pp: Vector3 = game.player.global_position
	for c in cars.duplicate():
		var car := c as Car
		if car.global_position.distance_to(pp) > 320.0:
			_remove(car)
	_spawn_t -= delta
	var want := target_count
	if GameState.is_night():
		want = int(float(want) * 0.7)
	if _spawn_t <= 0.0 and cars.size() < want:
		_spawn_t = 0.3
		_try_spawn(pp)
	for c in cars:
		_drive(c as Car, delta, pp)


func remove_car(car: Car) -> void:
	_remove(car)


func _remove(car: Car) -> void:
	cars.erase(car)
	for k in _occupied.keys():
		if _occupied[k] == car:
			_occupied.erase(k)
	car.queue_free()


func _try_spawn(pp: Vector3) -> void:
	var axis := "ave" if randf() < 0.55 else "st"
	var car := Car.new()
	car.axis = axis
	car.dirn = 1.0 if randf() < 0.5 else -1.0
	if axis == "ave":
		car.idx = clampi(int(round((pp.x - WorldLayout.AX0) / WorldLayout.AXS)) + randi_range(-2, 2), 0, WorldLayout.NA - 1)
		var j := randi_range(0, WorldLayout.NS - 2)
		if not WorldLayout.avenue_segment_exists(car.idx, j):
			car.free()
			return
		car.coord = randf_range(WorldLayout.sz(j) + 10.0, WorldLayout.sz(j + 1) - 10.0)
	else:
		car.idx = clampi(int(round((pp.z - WorldLayout.SZ0) / WorldLayout.SZS)) + randi_range(-3, 3), 0, WorldLayout.NS - 1)
		var i := randi_range(0, WorldLayout.NA - 2)
		if not WorldLayout.street_segment_exists(car.idx, i):
			car.free()
			return
		car.coord = randf_range(WorldLayout.ax(i) + 12.0, WorldLayout.ax(i + 1) - 12.0)
	var wp := car.world_pos()
	var d := wp.distance_to(pp)
	if d < 60.0 or d > 250.0:
		car.free()
		return
	for other in cars:
		if (other as Car).global_position.distance_to(wp) < 14.0:
			car.free()
			return
	car.kind = TYPES[randi() % TYPES.size()]
	car.max_speed = randf_range(9.0, 13.0)
	car.speed = car.max_speed * 0.6
	car.collision_layer = Phys.CAR | Phys.INTERACT
	car.collision_mask = 0
	car.sync_to_physics = false
	car.color_idx = randi() % Props.CAR_COLORS.size()
	var name := "car_%s_%d" % [car.kind, car.color_idx]
	var meshes := Props.car_meshes(name)
	var mi := MeshInstance3D.new()
	mi.mesh = meshes[0]
	mi.material_override = Mats.lit
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = 260.0
	car.add_child(mi)
	var gi := MeshInstance3D.new()
	gi.mesh = meshes[1]
	gi.material_override = Mats.glow
	gi.visibility_range_end = 400.0
	car.add_child(gi)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(2.0, 1.6, 4.6) if car.kind != "truck" else Vector3(2.4, 3.0, 7.6)
	cs.shape = bs
	cs.position = Vector3(0, 0.8 if car.kind != "truck" else 1.5, 0)
	car.add_child(cs)
	add_child(car)
	car.global_position = wp
	var h := car.heading()
	car.rotation.y = atan2(-h.x, -h.z)
	car.yaw_target = car.rotation.y
	cars.append(car)


func _drive(car: Car, delta: float, pp: Vector3) -> void:
	var h := car.heading()
	var pos := car.global_position
	var want := car.max_speed
	# Player in the lane ahead?
	var to_p := pp - pos
	to_p.y = 0.0
	var ahead := to_p.dot(h)
	var lateral := (to_p - h * ahead).length()
	if ahead > 0.0 and ahead < 11.0 and lateral < 1.8:
		want = 0.0
		car.honk_t -= delta
		if car.honk_t <= 0.0 and car.speed < 1.0:
			car.honk_t = randf_range(2.5, 5.0)
			AudioManager.play_3d("horn", pos, -4.0)
	# Car ahead?
	for o in cars:
		var oc := o as Car
		if oc == car:
			continue
		var d := oc.global_position - pos
		var a := d.dot(h)
		if a > 0.0 and a < 10.0 and (d - h * a).length() < 1.5:
			want = minf(want, maxf(0.0, (a - 6.0) * 1.5))
	# Next intersection.
	var grid_next := _next_grid(car)
	var dist_to := absf(grid_next - car.coord)
	var ikey := _inter_key(car, grid_next)
	if dist_to < 14.0 and car.in_inter != ikey:
		var occ: Variant = _occupied.get(ikey)
		if occ != null and occ != car and is_instance_valid(occ) and (occ as Car).axis != car.axis:
			want = minf(want, maxf(0.0, (dist_to - 9.0) * 2.0))
		elif dist_to < 9.0:
			_occupied[ikey] = car
			car.in_inter = ikey
	car.speed = move_toward(car.speed, want, (6.0 if want > car.speed else 14.0) * delta)
	var step := car.speed * delta * car.dirn
	var prev := car.coord
	car.coord += step
	# Crossed the intersection center: decide the next leg.
	if (car.dirn > 0.0 and prev < grid_next and car.coord >= grid_next) or (car.dirn < 0.0 and prev > grid_next and car.coord <= grid_next):
		_choose_turn(car, grid_next)
	# Leave intersection bookkeeping.
	if car.in_inter != "" and _occupied.get(car.in_inter) == car:
		var ic := _inter_center(car.in_inter)
		if car.global_position.distance_to(ic) > 12.0:
			_occupied.erase(car.in_inter)
			car.in_inter = ""
	car.global_position = car.world_pos()
	var hh := car.heading()
	car.yaw_target = atan2(-hh.x, -hh.z)
	car.rotation.y = lerp_angle(car.rotation.y, car.yaw_target, minf(1.0, delta * 6.0))


func _next_grid(car: Car) -> float:
	if car.axis == "ave":
		var j := (car.coord - WorldLayout.SZ0) / WorldLayout.SZS
		var nj: float = floor(j) + 1.0 if car.dirn > 0.0 else ceil(j) - 1.0
		if is_equal_approx(j, round(j)):
			nj = round(j) + car.dirn
		return WorldLayout.SZ0 + WorldLayout.SZS * nj
	var i := (car.coord - WorldLayout.AX0) / WorldLayout.AXS
	var ni: float = floor(i) + 1.0 if car.dirn > 0.0 else ceil(i) - 1.0
	if is_equal_approx(i, round(i)):
		ni = round(i) + car.dirn
	return WorldLayout.AX0 + WorldLayout.AXS * ni


func _inter_key(car: Car, grid: float) -> String:
	if car.axis == "ave":
		var j := int(round((grid - WorldLayout.SZ0) / WorldLayout.SZS))
		return "%d,%d" % [car.idx, j]
	var i := int(round((grid - WorldLayout.AX0) / WorldLayout.AXS))
	return "%d,%d" % [i, car.idx]


func _inter_center(key: String) -> Vector3:
	var p := key.split(",")
	return Vector3(WorldLayout.ax(int(p[0])), 0, WorldLayout.sz(int(p[1])))


func _choose_turn(car: Car, grid: float) -> void:
	var i: int
	var j: int
	if car.axis == "ave":
		i = car.idx
		j = int(round((grid - WorldLayout.SZ0) / WorldLayout.SZS))
	else:
		i = int(round((grid - WorldLayout.AX0) / WorldLayout.AXS))
		j = car.idx
	var options: Array = []
	# Straight.
	if car.axis == "ave":
		var nj := j if car.dirn > 0.0 else j - 1
		if j + (1 if car.dirn > 0.0 else -1) >= 0 and j + (1 if car.dirn > 0.0 else -1) < WorldLayout.NS and nj >= 0 and nj < WorldLayout.NS - 1 and WorldLayout.avenue_segment_exists(i, nj):
			options.append(["ave", i, car.dirn, 3.0])
		# Turn onto street j, east or west.
		if i < WorldLayout.NA - 1 and WorldLayout.street_segment_exists(j, i):
			options.append(["st", j, 1.0, 1.0])
		if i > 0 and WorldLayout.street_segment_exists(j, i - 1):
			options.append(["st", j, -1.0, 1.0])
	else:
		var ni := i if car.dirn > 0.0 else i - 1
		if i + (1 if car.dirn > 0.0 else -1) >= 0 and i + (1 if car.dirn > 0.0 else -1) < WorldLayout.NA and ni >= 0 and ni < WorldLayout.NA - 1 and WorldLayout.street_segment_exists(j, ni):
			options.append(["st", j, car.dirn, 3.0])
		if j < WorldLayout.NS - 1 and WorldLayout.avenue_segment_exists(i, j):
			options.append(["ave", i, 1.0, 1.0])
		if j > 0 and WorldLayout.avenue_segment_exists(i, j - 1):
			options.append(["ave", i, -1.0, 1.0])
	if options.is_empty():
		# Dead end: U-turn.
		car.dirn = -car.dirn
		return
	var total := 0.0
	for o in options:
		total += float(o[3])
	var r := randf() * total
	var pick: Array = options[0]
	for o in options:
		r -= float(o[3])
		if r <= 0.0:
			pick = o
			break
	var new_axis := str(pick[0])
	if new_axis != car.axis:
		# Position along the new axis = the crossing coordinate.
		if new_axis == "ave":
			car.coord = WorldLayout.sz(j)
		else:
			car.coord = WorldLayout.ax(i)
		car.speed *= 0.6
	car.axis = new_axis
	car.idx = int(pick[1])
	car.dirn = float(pick[2])
