class_name LootIndex
extends RefCounted
## Spatial hash of every searchable thing in the city that isn't worth a node
## of its own: dumpsters, trash cans, newsboxes, parked cars, ATMs, shipping
## containers, hidden stashes — and the doors of generic buildings. Thousands
## of entries, zero per-frame cost: the player's interact ray asks `pick()`
## only for the few cells around it and runs an oriented-box slab test.

const CELL := 16.0
const REACH := 7.0 # largest half-extent in the index (shipping containers)

var grid: Dictionary = {} # Vector2i -> Array[Dictionary]
var by_id: Dictionary = {} # id -> entry
var count: int = 0


func _key(x: float, z: float) -> Vector2i:
	return Vector2i(int(floor(x / CELL)), int(floor(z / CELL)))


## e: {id, kind, p: Vector3 center, he: Vector3 half extents, r: rot_y, ...}
func add(e: Dictionary) -> void:
	var p: Vector3 = e["p"]
	var k := _key(p.x, p.z)
	if not grid.has(k):
		grid[k] = []
	(grid[k] as Array).append(e)
	by_id[str(e["id"])] = e
	count += 1


func get_entry(id: String) -> Dictionary:
	return by_id.get(id, {})


## Nearest entry whose box the ray from `from` along unit `dir` enters within
## `max_t`. Returns {} if none.
func pick(from: Vector3, dir: Vector3, max_t: float) -> Dictionary:
	var to := from + dir * max_t
	var x0 := minf(from.x, to.x) - REACH
	var x1 := maxf(from.x, to.x) + REACH
	var z0 := minf(from.z, to.z) - REACH
	var z1 := maxf(from.z, to.z) + REACH
	var k0 := _key(x0, z0)
	var k1 := _key(x1, z1)
	var best: Dictionary = {}
	var best_t := max_t
	for kx in range(k0.x, k1.x + 1):
		for kz in range(k0.y, k1.y + 1):
			var arr: Variant = grid.get(Vector2i(kx, kz))
			if arr == null:
				continue
			for e in arr:
				if e.has("gone"):
					continue # a stolen parked car
				var t := _ray_obb(from, dir, e)
				if t >= 0.0 and t <= best_t:
					best_t = t
					best = e
	return best


## The entry you're roughly facing (within cos_min of `look`, weighing the
## horizontal most), within r of `from`: the forgiving pick.
func pick_cone(from: Vector3, look: Vector3, r: float, cos_min: float) -> Dictionary:
	var fl := Vector3(look.x, look.y * 0.35, look.z).normalized()
	var best: Dictionary = {}
	var best_s := -INF
	for e in near(from, r + 1.0):
		if (e as Dictionary).has("gone"):
			continue
		var d: Vector3 = ((e as Dictionary)["p"] as Vector3) - from
		var dist := d.length()
		if dist < 0.01:
			continue
		var f := Vector3(d.x, d.y * 0.35, d.z).normalized().dot(fl)
		if f < cos_min:
			continue
		var sc := f * 2.0 - dist * 0.35
		if sc > best_s:
			best_s = sc
			best = e
	return best


## Entries within radius r of p (for markers and debugging).
func near(p: Vector3, r: float) -> Array:
	var out: Array = []
	var k0 := _key(p.x - r, p.z - r)
	var k1 := _key(p.x + r, p.z + r)
	for kx in range(k0.x, k1.x + 1):
		for kz in range(k0.y, k1.y + 1):
			var arr: Variant = grid.get(Vector2i(kx, kz))
			if arr == null:
				continue
			for e in arr:
				if ((e["p"] as Vector3) - p).length() <= r:
					out.append(e)
	return out


static func _ray_obb(o: Vector3, d: Vector3, e: Dictionary) -> float:
	var c: Vector3 = e["p"]
	var he: Vector3 = e["he"]
	var rot := float(e.get("r", 0.0))
	var lo := o - c
	var ld := d
	if rot != 0.0:
		var inv := Basis(Vector3.UP, -rot)
		lo = inv * lo
		ld = inv * ld
	var tmin := -INF
	var tmax := INF
	for a in 3:
		var oa := lo[a]
		var da := ld[a]
		var h := he[a]
		if absf(da) < 1e-6:
			if oa < -h or oa > h:
				return -1.0
			continue
		var t1 := (-h - oa) / da
		var t2 := (h - oa) / da
		if t1 > t2:
			var tmp := t1
			t1 = t2
			t2 = tmp
		tmin = maxf(tmin, t1)
		tmax = minf(tmax, t2)
		if tmin > tmax:
			return -1.0
	if tmax < 0.0:
		return -1.0
	return maxf(tmin, 0.0)
