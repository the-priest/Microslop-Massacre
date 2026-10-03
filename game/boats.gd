class_name Boats
extends Node
## Water, docks and regattas. Each waterfront map has docks (a spot on the
## shore you board from, a mooring out on the water) with boats tied up at
## them; you get in and out at docks. Boats only go where there is water
## (is_water, per map, in that map's local coordinates), and like planes they
## cross into the next map when it has water on the other side of the line:
## Chicago's lakefront runs straight into Redmont's reservoir, and Port
## Ramsey's harbour opens onto the Atlantic and Price Island.

## Open water you can sail on, per map (local x, z). The edges of the city
## itself are dry; DRY carves out piers and the like.
const WATER := {
	"nyc": [Rect2(-1045.0, -1660.0, 172.0, 2570.0), Rect2(1781.0, -1660.0, 189.0, 2570.0), Rect2(-1690.0, 905.0, 4280.0, 490.0), Rect2(-1045.0, 795.0, 3015.0, 110.0)],
	"chicago": [Rect2(863.0, -1495.0, 1437.0, 2990.0)],
	"redmont": [Rect2(-1820.0, -1460.0, 917.0, 2990.0)],
	"gary": [Rect2(-1700.0, -1460.0, 3480.0, 815.0)],
	"port": [Rect2(703.0, -895.0, 997.0, 1790.0)],
	"island": [Rect2(-1600.0, -900.0, 3200.0, 1800.0)],
}
const DRY := {
	"nyc": [Rect2(-44.0, 700.0, 28.0, 186.0)], # Coney Island pier
	"port": [Rect2(700.0, -573.0, 64.0, 14.0), Rect2(745.0, -575.0, 18.0, 18.0)], # the lighthouse jetty and its light
	"island": [Rect2(-366.0, -366.0, 732.0, 732.0)], # the island and its beach
}

## id -> where you board (land), where the boat ties up (water), which way
## it points, and what's tied up there: [model, lock (0 = keys in it)].
const DOCKS := {
	"nyc_coney": {"region": "nyc", "name": "Coney Island Pier", "land": [-24.0, 872.0], "water": [-13.0, 866.0], "yaw": PI, "boats": [["speedboat", 0]]},
	"nyc_hudson": {"region": "nyc", "name": "Pier 76, Hudson River", "land": [-862.0, -300.0], "water": [-879.0, -300.0], "yaw": 0.0, "boats": [["speedboat", 0]], "float": true},
	"nyc_east": {"region": "nyc", "name": "East River Landing", "land": [1772.0, -560.0], "water": [1788.0, -560.0], "yaw": PI, "boats": [["skiff", 0], ["patrol", 60]], "float": true},
	"chi_harbor": {"region": "chicago", "name": "Monroe Harbor", "land": [856.0, -60.0], "water": [872.0, -60.0], "yaw": PI, "boats": [["speedboat", 0], ["skiff", 0]], "float": true},
	"gy_marina": {"region": "gary", "name": "Buffington Harbor", "land": [250.0, -636.0], "water": [250.0, -653.0], "yaw": -PI * 0.5, "boats": [["skiff", 0]], "float": true},
	"pt_harbor": {"region": "port", "name": "Ramsey Harbor", "land": [697.0, 92.0], "water": [707.0, 92.0], "yaw": 0.0, "boats": [["skiff", 0], ["speedboat", 30]]},
	"rm_launch": {"region": "redmont", "name": "Reservoir Pier", "land": [-899.0, 300.0], "water": [-911.0, 304.0], "yaw": PI * 0.5, "boats": [["skiff", 0]]},
	"isl_dock": {"region": "island", "name": "Price's Dock", "land": [404.0, 40.0], "water": [404.0, 33.0], "yaw": -PI * 0.5, "boats": [["tender", 45]]},
}
## A walkable pier out over the water, where the shore is too far from it:
## the map's edge wall gets a gap and the pier gets railings (CityBuilder).
const PIERS := {
	"redmont": [Rect2(-905.0, 298.0, 166.0, 4.0)],
	"island": [Rect2(326.0, 37.5, 84.0, 5.0)],
}


static func is_water(region: String, p: Vector2) -> bool:
	for r in DRY.get(region, []):
		if (r as Rect2).has_point(p):
			return false
	for r in WATER.get(region, []):
		if (r as Rect2).has_point(p):
			return true
	return false


## Water at a point local to `region`, even just past its edge (where the
## next map's water takes over, if it has any there).
static func water_at(region: String, p: Vector2) -> bool:
	if Regions.sky(region).has_point(p):
		return is_water(region, p)
	var w := Regions.to_world(region, p)
	var nb := Regions.region_at(w, region)
	return nb != "" and is_water(nb, Regions.to_local(nb, w))


static func docks_in(region: String) -> Array:
	var out: Array = []
	for id in DOCKS.keys():
		if str((DOCKS[id] as Dictionary)["region"]) == region:
			out.append(str(id))
	return out


static func land_pos(id: String) -> Vector3:
	var a: Array = (DOCKS[id] as Dictionary)["land"]
	return Vector3(float(a[0]), 0.0, float(a[1]))


static func water_pos(id: String) -> Vector3:
	var a: Array = (DOCKS[id] as Dictionary)["water"]
	return Vector3(float(a[0]), Boat.WATER_Y, float(a[1]))


## The dock (on this map) nearest a point, within max_d of its mooring.
static func nearest_dock(region: String, p: Vector3, max_d: float = INF) -> String:
	var best := ""
	var bd := max_d
	for id in docks_in(region):
		var d := Vector2(p.x, p.z).distance_to(Vector2(water_pos(id).x, water_pos(id).z))
		if d < bd:
			bd = d
			best = id
	return best


# ------------------------------------------------------------------ runtime
var game: Node = null
var boats: Dictionary = {} # mooring slot -> Boat


## Docks on this map: the boarding spot, a float or a few bollards, a sign.
func spawn_docks(parent: Node3D) -> void:
	var mb := MeshBatch.new()
	for id in docks_in(WorldLayout.region):
		var d: Dictionary = DOCKS[id]
		var lp := land_pos(id)
		var wp := water_pos(id)
		var it := Interactable.new().setup("dock", id, str(d["name"]), "Board", lp + Vector3(0, 1.2, 0), Vector3(2.4, 2.4, 2.4), {"dock": id})
		parent.add_child(it)
		var yaw := float(d["yaw"])
		var shore := Vector3(lp.x - wp.x, 0, lp.z - wp.z).normalized()
		var along := Vector3(-sin(yaw), 0, -cos(yaw))
		var pont := Vector3(wp.x, 0, wp.z) + shore * 1.9
		if bool(d.get("float", false)):
			# A walkway from the shore to a pontoon alongside the mooring.
			var a := Vector2(lp.x, lp.z)
			var e := Vector2(pont.x, pont.z)
			var mid := (a + e) * 0.5
			mb.box(Vector3(mid.x, 0.12, mid.y), Vector3(1.8, 0.3, a.distance_to(e) + 1.0), Color(0.45, 0.36, 0.26), atan2(e.x - a.x, e.y - a.y))
			mb.box(pont + Vector3(0, 0.12, 0), Vector3(1.4, 0.3, 4.0 + float((d["boats"] as Array).size()) * 9.0), Color(0.45, 0.36, 0.26), yaw)
		for k in 3:
			var bp := pont + along * (float(k) - 1.0) * 3.0
			mb.cyl(bp + Vector3(0, 0.5, 0), 0.12, 0.14, 1.0, Color(0.2, 0.18, 0.16), 6)
		# The sign, on the shore.
		mb.box(lp + Vector3(0, 1.2, 0), Vector3(0.12, 2.4, 0.12), Color(0.3, 0.3, 0.32))
		mb.box(lp + Vector3(0, 2.4, 0), Vector3(1.8, 0.6, 0.08), Color(0.08, 0.2, 0.38), yaw)
		var lb := Label3D.new()
		lb.text = "⚓ " + str(d["name"]).to_upper()
		lb.font_size = 40
		lb.pixel_size = 0.004
		lb.modulate = Color(0.95, 0.95, 0.9)
		lb.double_sided = true
		lb.visibility_range_end = 60.0
		lb.font = UI.font_sign()
		parent.add_child(lb)
		lb.global_position = lp + Vector3(0, 2.4, 0) + Vector3(sin(yaw), 0, cos(yaw)) * 0.06
		lb.rotation.y = yaw
	mb.commit(parent, Mats.lit, 300.0, "Docks")
	spawn_boats()


## Tie up each dock's boats, unless you've taken that one somewhere else.
func spawn_boats() -> void:
	if game == null or game.vehicles_root == null:
		return
	for id in docks_in(WorldLayout.region):
		var d: Dictionary = DOCKS[id]
		var list: Array = d["boats"]
		for i in list.size():
			var sid := "%s_%d" % [id, i]
			var b: Boat = boats.get(sid)
			if b != null and is_instance_valid(b) and not b.dead:
				continue
			if game.has_method("_ride_in_slot") and game._ride_in_slot(sid):
				continue
			var e: Array = list[i]
			var yaw := float(d["yaw"])
			var p := water_pos(id) + Vector3(-sin(yaw), 0, -cos(yaw)) * (float(i) * 9.0 - float(list.size() - 1) * 4.5)
			var nb := Boat.new().setup_boat(str(e[0]), p, yaw, game)
			nb.slot = sid
			nb.lock_dc = int(e[1])
			nb.locked = int(e[1]) > 0
			if str(e[0]) == "patrol":
				nb.set_meta("police", true)
			game.vehicles_root.add_child(nb)
			boats[sid] = nb


## The boat waiting at a dock, if any (yours, or one tied up there).
func boat_at(id: String) -> Boat:
	var wp := water_pos(id)
	var best: Boat = null
	var bd := 26.0
	for v in game.vehicles_root.get_children():
		if v is Boat and not (v as Boat).dead and not (v as Boat).driving:
			var d := Vector2((v as Boat).global_position.x - wp.x, (v as Boat).global_position.z - wp.z).length()
			if d < bd:
				bd = d
				best = v
	return best


func board(id: String) -> void:
	var b := boat_at(id)
	if b == null:
		game.hud.notify("Nothing tied up at %s right now." % str((DOCKS[id] as Dictionary)["name"]), "warn")
		return
	await game._use_vehicle(b)


## Where you step off a boat: the nearest dock's shore end, if you're
## alongside one (forced: swim to the nearest dock on this map).
func exit_point(b: Boat, forced: bool) -> Variant:
	var id := nearest_dock(WorldLayout.region, b.global_position, 32.0 if not forced else INF)
	if id == "":
		return null
	return land_pos(id) + Vector3(0, 0.3, 0)
