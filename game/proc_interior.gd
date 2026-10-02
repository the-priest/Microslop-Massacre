class_name ProcInterior
extends RefCounted
## Interiors for the city's generic buildings, generated on demand from the
## door's kind and seed. Same door, same seed, same rooms, forever.
## Output matches the InteriorData schema (rooms/doors/exits/furn/containers/
## spots/pickups) plus `npcs`: occupants spawned by the NPCManager.
##
## Coordinates: local meters, floor y=0. The street exit is always on the
## south wall of the first room. Furniture faces +Z at rot 0 (rot 90 = +X).

const WALLS := [Color(0.55, 0.5, 0.44), Color(0.5, 0.52, 0.48), Color(0.6, 0.55, 0.48), Color(0.45, 0.42, 0.46),
	Color(0.52, 0.44, 0.38), Color(0.4, 0.46, 0.5), Color(0.58, 0.54, 0.5), Color(0.36, 0.4, 0.36)]
const FLOORS := [Color(0.34, 0.24, 0.15), Color(0.4, 0.3, 0.2), Color(0.28, 0.2, 0.14), Color(0.3, 0.26, 0.22)]
const TILES := [Color(0.5, 0.5, 0.52), Color(0.45, 0.42, 0.38), Color(0.55, 0.52, 0.48), Color(0.3, 0.32, 0.34)]
const CLOTH := [Color(0.18, 0.2, 0.28), Color(0.4, 0.12, 0.12), Color(0.2, 0.3, 0.22), Color(0.35, 0.3, 0.25), Color(0.25, 0.22, 0.3)]
const STOCK_LOOT := {"grocery": "stockroom", "liquor": "liquor_stock", "electronics": "electronics_stock",
	"clothing": "clothing_stock", "hardware": "hardware_stock", "pawnshop": "pawn_case"}
const SHOP_OF := {"grocery": "gen_grocery", "liquor": "gen_liquor", "electronics": "gen_electronics",
	"clothing": "gen_clothing", "hardware": "gen_hardware", "pawnshop": "gen_pawn", "diner": "gen_diner",
	"restaurant": "gen_restaurant", "bar": "gen_bar", "arcade": "gen_arcade"}

var g: Dictionary
var r := RandomNumberGenerator.new()
var gid: String = ""
var rooms: Array = []
var doors: Array = []
var exits: Array = []
var furn: Array = []
var containers: Array = []
var spots: Array = []
var npcs: Array = []
var pickups: Array = []
var ambient := Color(0.3, 0.28, 0.26)
var amb := "interior"
var _cn := 0
var _nn := 0


static func generate(door: Dictionary) -> Dictionary:
	var p := ProcInterior.new()
	return p._gen(door)


func _gen(door: Dictionary) -> Dictionary:
	g = door
	gid = str(g["id"])
	r.seed = int(g.get("seed", 1))
	var kind := str(g.get("kind", "apartment"))
	match kind:
		"apartment":
			if r.randf() < 0.55:
				_apartment()
			else:
				_studio()
		"hideout":
			_hideout()
		"squat":
			_squat()
		"office":
			_office()
		"warehouse":
			_warehouse()
		"bar":
			_bar()
		"diner", "restaurant":
			_diner(kind == "restaurant")
		"arcade":
			_arcade()
		_:
			_store(kind)
	return {
		"name": str(g.get("name", "Building")), "kind": kind, "gen": true,
		"ambient": ambient, "amb": amb,
		"rooms": rooms, "doors": doors, "exits": exits, "furn": furn,
		"containers": containers, "spots": spots, "npcs": npcs, "pickups": pickups,
	}


# ------------------------------------------------------------------ helpers
func _pick(a: Array) -> Variant:
	return a[r.randi() % a.size()]


func room(x0: float, z0: float, x1: float, z1: float, wall: Color, flo: Color, extra: Dictionary = {}) -> void:
	var d := {"r": [x0, z0, x1, z1], "h": 3.0, "wall": wall, "floor": flo, "light": Color(1.0, 0.86, 0.66), "energy": 1.0}
	for k in extra.keys():
		d[k] = extra[k]
	rooms.append(d)


func f(type: String, x: float, z: float, rot: float = 0.0, prm: Dictionary = {}) -> void:
	furn.append([type, x, z, rot, prm])


## A searchable container. size = Area box (make it enclose the furniture solid).
func cont(title: String, x: float, z: float, y: float, size: Array, loot: String, extra: Dictionary = {}) -> String:
	var id := "bld:%s:c%d" % [gid, _cn]
	_cn += 1
	var d := {"id": id, "title": title, "pos": [x, z], "y": y, "size": size, "loot": loot}
	for k in extra.keys():
		d[k] = extra[k]
	containers.append(d)
	return id


func npc(template: String, x: float, z: float, yaw: float, when: String = "", extra: Dictionary = {}) -> String:
	var id := "bld:%s#%d" % [gid, _nn]
	_nn += 1
	var d := {"id": id, "t": template, "pos": [x, z], "yaw": yaw, "when": when}
	for k in extra.keys():
		d[k] = extra[k]
	npcs.append(d)
	return id


func exit_at(x: float, z: float) -> void:
	exits.append({"pos": [x, z], "face": "s", "to": "world:" + gid, "label": "Street"})


func _owned() -> Dictionary:
	return {"owner": "locals"}


func open_cond() -> String:
	var h: Array = g.get("hours", [])
	if h.is_empty():
		return ""
	var a := int(h[0])
	var b := int(h[1])
	if a < b:
		return "hour>=%d & hour<%d" % [a, b]
	return "hour>=%d | hour<%d" % [a, b]


func closed_cond() -> String:
	var h: Array = g.get("hours", [])
	if h.is_empty():
		return "false"
	var a := int(h[0])
	var b := int(h[1])
	if a < b:
		return "hour<%d | hour>=%d" % [a, b]
	return "hour>=%d & hour<%d" % [b, a]


func _safe(x: float, z: float, rot: float, loot: String, dc_lo: int, dc_hi: int, extra: Dictionary = {}) -> void:
	f("safe", x, z, rot)
	var e := {"lock": r.randi_range(dc_lo / 5, dc_hi / 5) * 5}
	for k in extra.keys():
		e[k] = extra[k]
	cont("Safe", x, z, 0.48, [0.8, 1.0, 0.8], loot, e)


# ================================================================ HOMES
func _apartment() -> void:
	var wall: Color = _pick(WALLS)
	var flo: Color = _pick(FLOORS)
	var lc := Color(1.0, 0.84, 0.62) if r.randf() < 0.7 else Color(0.85, 0.9, 1.0)
	ambient = Color(0.3, 0.27, 0.25)
	room(0, 0, 8, 6, wall, flo, {"h": 2.9, "light": lc, "energy": 0.95})
	room(8, 0, 12.5, 6, wall.darkened(0.05), flo, {"h": 2.9, "light": lc, "energy": 0.8})
	room(0, -3, 3, 0, Color(0.7, 0.72, 0.72), _pick(TILES), {"h": 2.9, "floor_kind": "tile", "light": Color(0.9, 0.95, 1.0), "energy": 0.8})
	doors.append([8, 1.2, 1.1])
	doors.append([1.6, 0, 0.9])
	exit_at(1.8, 6)
	var own := _owned()
	# Kitchen along the north wall.
	f("kitchen", 4.6, 0.37, 0, {"w": 2.4})
	cont("Kitchen Cabinets", 4.6, 0.37, 0.5, [2.5, 1.0, 0.74], "kitchen", own)
	f("fridge", 6.6, 0.42, 0)
	cont("Refrigerator", 6.6, 0.42, 0.95, [0.85, 1.9, 0.8], "fridge", own)
	f("table", 4.6, 2.5, 0, {"w": 1.2, "d": 0.8})
	Furniture_chairs(4.6, 2.5)
	# Living corner.
	f("rug", 6.2, 4.2, 0, {"w": 2.6, "d": 2.2, "col": _pick(CLOTH)})
	f("sofa", 5.2, 4.2, 90, {"col": _pick(CLOTH)})
	f("coffee_table", 6.4, 4.2, 90)
	f("tv", 7.55, 4.2, -90, {"screen": Color(0.3, 0.4, 0.6)})
	cont("TV Stand", 7.55, 4.2, 0.62, [0.5, 1.3, 1.3], "electronics_home", own)
	f("bookshelf", 0.3, 4.0, 90)
	f("lamp", 0.5, 5.5, 0)
	f("plant", 7.4, 5.5, 0)
	f("radiator", 3.5, 5.85, 180)
	# Bedroom.
	f("bed_double" if r.randf() < 0.6 else "bed", 10.9, 4.85, 180, {"col": _pick(CLOTH)})
	if r.randf() < 0.35:
		cont("Under the Mattress", 10.9, 4.85, 0.45, [1.8, 0.95, 2.2], "apt_stash", own)
	f("wardrobe", 12.15, 1.4, -90)
	cont("Wardrobe", 12.15, 1.4, 1.05, [0.7, 2.1, 1.3], "wardrobe", own)
	f("dresser", 9.9, 0.35, 0)
	cont("Dresser", 9.9, 0.35, 0.48, [1.3, 1.0, 0.6], "dresser", own)
	f("window", 11.6, 5.85, 180, {"w": 1.0, "col": Color(0.1, 0.12, 0.2)})
	if r.randf() < 0.5:
		f("desk_pc", 8.9, 5.3, 180, {"screen": _pick([Color(0.2, 0.9, 0.5), Color(0.3, 0.6, 1.0), Color(0.9, 0.9, 0.9)])})
		cont("Desk", 8.9, 5.3, 0.48, [1.6, 1.0, 0.85], "desk", own)
	elif r.randf() < 0.3:
		_safe(8.5, 5.5, 180, "safe", 35, 65, own)
	# Bathroom.
	f("toilet", 0.5, -2.5, 0)
	f("sink", 2.3, -2.75, 0)
	cont("Medicine Cabinet", 2.3, -2.84, 1.4, [0.6, 0.6, 0.3], "medcab", own)
	# Someone's home in the evening.
	if r.randf() < 0.55:
		npc("resident", 10.0, 3.0 if r.randf() < 0.5 else 2.0, r.randf_range(0, 360), "hour>=17 | hour<9")


func _studio() -> void:
	var wall: Color = _pick(WALLS)
	var flo: Color = _pick(FLOORS)
	ambient = Color(0.28, 0.26, 0.26)
	room(0, 0, 9, 6.5, wall, flo, {"h": 2.8, "light": Color(1.0, 0.82, 0.6), "energy": 0.9})
	room(6.5, -2.8, 9, 0, Color(0.72, 0.72, 0.7), _pick(TILES), {"h": 2.8, "floor_kind": "tile", "light": Color(0.9, 0.95, 1.0), "energy": 0.7})
	doors.append([7.7, 0, 0.9])
	exit_at(4.5, 6.5)
	var own := _owned()
	f("bed", 0.75, 1.25, 0, {"col": _pick(CLOTH)})
	cont("Under the Mattress", 0.75, 1.25, 0.45, [1.25, 0.95, 2.2], "apt_stash" if r.randf() < 0.3 else "squat_pile", own)
	f("dresser", 2.3, 0.35, 0)
	cont("Dresser", 2.3, 0.35, 0.48, [1.3, 1.0, 0.6], "dresser", own)
	f("kitchen", 4.6, 0.37, 0, {"w": 2.2})
	cont("Kitchen Cabinets", 4.6, 0.37, 0.5, [2.3, 1.0, 0.74], "kitchen", own)
	f("fridge", 6.1, 0.8, 0)
	cont("Refrigerator", 6.1, 0.8, 0.95, [0.85, 1.9, 0.8], "fridge", own)
	f("armchair", 7.8, 4.0, -90, {"col": _pick(CLOTH)})
	f("tv", 5.8, 3.6, 90, {"screen": Color(0.35, 0.5, 0.9)})
	f("wardrobe", 8.55, 5.2, -90)
	cont("Wardrobe", 8.55, 5.2, 1.05, [0.7, 2.1, 1.3], "wardrobe", own)
	f("poster", 0.1, 4.0, 90, {"col": _pick([Color(0.6, 0.1, 0.1), Color(0.1, 0.2, 0.5), Color(0.8, 0.6, 0.1)])})
	f("lamp", 0.5, 5.8, 0)
	f("toilet", 7.2, -2.4, 0)
	f("sink", 8.4, -2.55, 0)
	cont("Medicine Cabinet", 8.4, -2.64, 1.4, [0.6, 0.6, 0.3], "medcab", own)
	if r.randf() < 0.5:
		npc("resident", 3.0, 3.2, r.randf_range(0, 360), "hour>=18 | hour<8")


func Furniture_chairs(x: float, z: float) -> void:
	f("chair", x - 0.35, z - 0.65, 0)
	f("chair", x + 0.35, z + 0.65, 180)


# ================================================================ CRIMINAL
func _hideout() -> void:
	ambient = Color(0.22, 0.16, 0.14)
	var wall := Color(0.3, 0.26, 0.24)
	room(0, 0, 12, 8, wall, Color(0.22, 0.2, 0.18), {"h": 3.0, "light": Color(1.0, 0.55, 0.35), "energy": 0.75, "lights": [[3, 2.6, 4], [9, 2.6, 4]]})
	room(0, -5, 7, 0, wall.darkened(0.1), Color(0.2, 0.18, 0.16), {"h": 3.0, "light": Color(0.9, 0.3, 0.25), "energy": 0.6})
	doors.append([3.5, 0, 1.2])
	exit_at(10.0, 8)
	f("sofa", 3.0, 6.6, 180, {"col": Color(0.25, 0.18, 0.12)})
	f("tv", 3.0, 4.6, 0, {"screen": Color(0.4, 0.5, 0.7)})
	f("table", 8.0, 3.0, 0, {"w": 1.6, "d": 1.0})
	f("chair", 7.4, 2.2, 0)
	f("chair", 8.6, 3.8, 180)
	f("trash_pile", 11.0, 1.0, 0)
	f("mattress", 1.1, 3.0, 90)
	f("poster", 6.0, 0.1, 0, {"col": Color(0.6, 0.1, 0.1)})
	f("lamp", 11.4, 7.4, 0, {"col": Color(1.0, 0.4, 0.3)})
	f("crate", 11.3, 4.5, 0)
	cont("Crate", 11.3, 4.5, 0.52, [1.1, 1.1, 1.1], "warehouse_crate")
	# Back room: the armory and the money.
	f("gun_rack", 3.5, -4.8, 0)
	f("crate", 1.0, -4.2, 0)
	cont("Gun Crate", 1.0, -4.2, 0.52, [1.1, 1.1, 1.1], "hideout_crate")
	f("crate", 1.0, -2.8, 0)
	cont("Gun Crate", 1.0, -2.8, 0.52, [1.1, 1.1, 1.1], "hideout_crate")
	f("boxes", 4.8, -4.4, 0)
	f("duffel", 5.8, -1.0, 90)
	cont("Duffel Bag", 5.8, -1.0, 0.22, [0.55, 0.45, 0.95], "street_stash")
	_safe(6.3, -4.4, 180, "hideout_safe", 45, 70)
	# The crew.
	var crew := ["gang_smg", "gang_shotgun", "gang_45", "thug_gun", "thug", "gang_rifle"]
	var n := r.randi_range(3, 5)
	# Deep in the room, away from the street door (you enter at ~[10, 6.7]).
	var spots_xy := [[2.5, 5.2], [7.6, 1.3], [1.8, 1.6], [2.0, -2.5], [5.0, -3.2]]
	for i in n:
		var p: Array = spots_xy[i]
		npc(str(_pick(crew)), float(p[0]), float(p[1]), r.randf_range(90, 270), "", {"wander": 1.5})
	if r.randf() < 0.35:
		npc("gang_boss", 4.5, -2.0, 0.0)


func _squat() -> void:
	ambient = Color(0.18, 0.17, 0.16)
	var wall := Color(0.34, 0.32, 0.3)
	room(0, 0, 10, 8, wall, Color(0.24, 0.22, 0.2), {"h": 3.0, "light": Color(0.8, 0.7, 0.5), "energy": 0.45})
	room(0, -4, 5, 0, wall.darkened(0.12), Color(0.2, 0.19, 0.18), {"h": 3.0, "light": Color(0.7, 0.6, 0.45), "energy": 0.3})
	doors.append([2.5, 0, 1.1])
	exit_at(7.5, 8)
	f("mattress", 1.2, 5.5, 0)
	f("mattress", 3.6, 1.5, 90)
	f("trash_pile", 5.5, 4.0, 0)
	f("trash_pile", 8.8, 1.2, 0)
	f("trash_pile", 1.0, -3.0, 0)
	f("sofa", 8.4, 4.4, -90, {"col": Color(0.3, 0.26, 0.18)})
	f("boxes", 6.0, 0.6, 0)
	f("crate", 3.8, -3.3, 0)
	f("poster", 5.0, 0.1, 0, {"col": Color(0.2, 0.2, 0.2)})
	cont("Pile of Junk", 5.5, 4.0, 0.3, [1.4, 0.6, 1.0], "squat_pile")
	cont("Pile of Junk", 8.8, 1.2, 0.3, [1.4, 0.6, 1.0], "squat_pile")
	cont("Crate", 3.8, -3.3, 0.52, [1.1, 1.1, 1.1], "crate")
	cont("Dirty Mattress", 1.2, 5.5, 0.15, [1.0, 0.4, 1.95], "street_stash" if r.randf() < 0.4 else "squat_pile")
	var hostile := r.randf() < 0.5
	var n := r.randi_range(1, 3)
	var pos := [[4.5, 6.0], [2.0, -1.8], [7.0, 2.5]]
	for i in n:
		var p: Array = pos[i]
		npc("squatter" if hostile else "squatter_calm", float(p[0]), float(p[1]), r.randf_range(0, 360), "", {"wander": 1.5})


# ================================================================ STORES
func _store(kind: String) -> void:
	var wall: Color = _pick([Color(0.62, 0.6, 0.55), Color(0.55, 0.58, 0.6), Color(0.6, 0.55, 0.5), Color(0.5, 0.5, 0.46)])
	ambient = Color(0.36, 0.35, 0.33)
	room(0, 0, 10, 8, wall, _pick(TILES), {"h": 3.2, "floor_kind": "tile", "light": Color(0.95, 0.97, 1.0), "energy": 1.2, "lights": [[3, 2.8, 4], [7, 2.8, 4]]})
	room(0, -4.5, 10, 0, wall.darkened(0.15), Color(0.3, 0.3, 0.3), {"h": 3.0, "light": Color(1.0, 0.85, 0.6), "energy": 0.7})
	doors.append([8.5, 0, 1.2])
	exit_at(2.0, 8)
	var own := _owned()
	var armed := kind == "pawnshop" or (kind == "liquor" and r.randf() < 0.5)
	# Counter + register + clerk.
	f("counter", 7.2, 1.6, 0, {"w": 3.0})
	f("register", 7.8, 1.5, 0)
	cont("Cash Register", 7.8, 1.5, 1.15, [0.6, 0.45, 0.6], "register_small", own)
	var clerk := npc("clerk_armed" if armed else "clerk", 7.2, 0.75, 180.0, open_cond())
	var stock_loot := str(STOCK_LOOT.get(kind, "stockroom"))
	match kind:
		"grocery", "liquor":
			for z in [1.5, 3.1, 4.7]:
				f("shelf", 0.35, z, 90)
			f("shelf", 3.2, 3.9, 180)
			f("shelf", 4.8, 3.9, 180)
			f("shelf", 3.2, 4.35, 0)
			f("shelf", 4.8, 4.35, 0)
			f("fridge_glass", 9.55, 4.5, -90)
			cont("Store Shelves", 4.0, 4.12, 0.95, [3.2, 1.9, 0.95], stock_loot, own)
			cont("Cooler", 9.55, 4.5, 1.0, [0.8, 2.1, 1.5], "kitchen" if kind == "grocery" else "liquor_stock", own)
		"electronics":
			f("display_case", 3.0, 3.2, 0, {"w": 2.0})
			f("display_case", 3.0, 5.2, 0, {"w": 2.0})
			f("shelf", 0.35, 2.0, 90)
			f("shelf", 0.35, 3.6, 90)
			f("tv", 9.6, 3.2, -90, {"screen": Color(0.3, 0.6, 1.0)})
			f("tv", 9.6, 4.8, -90, {"screen": Color(0.9, 0.3, 0.5)})
			f("monitor_wall", 4.5, 0.12, 0)
			cont("Display Case", 3.0, 3.2, 0.5, [2.1, 1.1, 0.7], stock_loot, own)
			cont("Display Case", 3.0, 5.2, 0.5, [2.1, 1.1, 0.7], "electronics_home", own)
		"clothing":
			f("clothes_rack", 2.8, 3.0, 0, {"w": 1.8})
			f("clothes_rack", 2.8, 5.0, 0, {"w": 1.8})
			f("clothes_rack", 5.4, 4.0, 0, {"w": 1.6})
			f("mannequin", 9.2, 5.5, -90, {"col": _pick(CLOTH)})
			f("mannequin", 9.2, 3.5, -90, {"col": _pick(CLOTH)})
			f("wardrobe", 0.35, 3.0, 90)
			cont("Clothes Rack", 2.8, 3.0, 0.9, [1.9, 1.9, 0.6], stock_loot, own)
			cont("Stockroom Wardrobe", 0.35, 3.0, 1.05, [0.7, 2.1, 1.3], "wardrobe", own)
		"hardware":
			f("shelf_industrial", 1.3, 2.2, 90)
			f("shelf_industrial", 1.3, 5.0, 90)
			f("shelf_industrial", 4.6, 4.2, 0)
			f("crate", 9.3, 5.4, 0)
			cont("Tool Shelves", 4.6, 4.2, 1.5, [2.5, 3.1, 1.0], stock_loot, own)
			cont("Crate", 9.3, 5.4, 0.52, [1.1, 1.1, 1.1], "warehouse_crate", own)
		"pawnshop":
			f("display_case", 3.0, 3.2, 0, {"w": 2.4})
			f("display_case", 3.0, 5.2, 0, {"w": 2.4})
			f("gun_rack", 7.2, 0.12, 0)
			f("bookshelf", 0.3, 2.2, 90)
			f("tv", 9.6, 4.0, -90)
			cont("Display Case", 3.0, 3.2, 0.5, [2.5, 1.1, 0.7], stock_loot, own)
			cont("Jewelry Case", 3.0, 5.2, 0.5, [2.5, 1.1, 0.7], "pawn_case", own)
	f("plant", 9.4, 7.3, 0)
	f("poster", 5.0, 7.88, 180, {"col": _pick([Color(0.8, 0.2, 0.1), Color(0.2, 0.5, 0.8), Color(0.9, 0.8, 0.2)])})
	# Stockroom.
	f("shelf_industrial", 1.4, -3.95, 0)
	cont("Stockroom Shelf", 1.4, -3.95, 1.5, [2.5, 3.1, 1.0], "stockroom", own)
	f("boxes", 4.2, -3.8, 0)
	f("desk", 6.0, -0.6, 180)
	cont("Desk", 6.0, -0.6, 0.45, [1.6, 1.0, 0.8], "desk", own)
	_safe(9.4, -3.95, 180, "safe", 35, 65, own)
	# Shop counter.
	spots.append({"id": "bld:%s:shop" % gid, "kind": "shop", "title": str(g.get("name", "Store")), "verb": "Shop", "pos": [7.2, 0.55, 2.35], "size": [3.0, 1.1, 0.8], "shop": str(SHOP_OF.get(kind, "gen_grocery")), "stock_key": "%s@%s" % [str(SHOP_OF.get(kind, "gen_grocery")), gid], "clerk": clerk})
	# Customers.
	var nc := r.randi_range(0, 2)
	for i in nc:
		npc("patron", r.randf_range(3.6, 6.4), r.randf_range(5.3, 6.4), r.randf_range(0, 360), open_cond(), {"wander": 2.0, "name": "Customer"})


func _diner(asian: bool) -> void:
	ambient = Color(0.36, 0.32, 0.28)
	var wall: Color = Color(0.6, 0.2, 0.15) if asian else _pick([Color(0.6, 0.55, 0.45), Color(0.4, 0.5, 0.45), Color(0.62, 0.5, 0.4)])
	room(0, 0, 11, 8, wall, _pick(TILES), {"h": 3.2, "floor_kind": "tile", "light": Color(1.0, 0.85, 0.65), "energy": 1.1, "lights": [[3, 2.8, 4], [8, 2.8, 4]]})
	room(0, -4, 11, 0, Color(0.75, 0.75, 0.72), Color(0.4, 0.4, 0.42), {"h": 3.0, "floor_kind": "tile", "light": Color(0.95, 0.97, 1.0), "energy": 1.0})
	doors.append([9.5, 0, 1.2])
	exit_at(2.0, 8)
	var own := _owned()
	f("counter", 5.5, 1.2, 0, {"w": 5.0})
	f("register", 7.5, 1.1, 0)
	cont("Cash Register", 7.5, 1.1, 1.15, [0.6, 0.45, 0.6], "register_small", own)
	for sx in [4.0, 5.0, 6.0]:
		f("stool", sx, 2.1, 0)
	var clerk := npc("clerk", 6.0, 0.45, 180.0, open_cond(), {"name": "Cook" if not asian else "Owner"})
	if asian:
		for p in [[2.2, 3.8], [2.2, 6.2], [5.2, 4.8], [8.5, 3.8], [8.5, 6.3]]:
			f("cafe_table", float(p[0]), float(p[1]), 90)
			f("lantern", float(p[0]), float(p[1]), 0, {"y": 2.5})
		f("screen_fold", 10.3, 5.0, -90)
	else:
		for z in [3.5, 5.5]:
			f("booth", 1.05, z, 90, {"col": _pick([Color(0.45, 0.08, 0.08), Color(0.1, 0.3, 0.35), Color(0.4, 0.3, 0.1)])})
		for p in [[5.2, 4.8], [8.0, 3.8], [8.0, 6.2]]:
			f("cafe_table", float(p[0]), float(p[1]), 0)
		f("jukebox", 10.5, 7.2, -90)
	f("coffee_machine", 3.4, 1.2, 0)
	f("plant", 10.4, 0.6, 0)
	# Kitchen.
	f("kitchen", 3.5, -3.6, 0, {"w": 4.0})
	cont("Kitchen", 3.5, -3.6, 0.5, [4.1, 1.0, 0.74], "kitchen", own)
	f("fridge", 7.0, -3.55, 0)
	cont("Walk-in Fridge", 7.0, -3.55, 0.95, [0.85, 1.9, 0.8], "fridge", own)
	f("shelf", 10.6, -2.0, -90)
	cont("Pantry Shelf", 10.6, -2.0, 0.95, [0.5, 1.9, 1.5], "stockroom", own)
	f("desk", 1.0, -1.0, 90)
	cont("Office Drawer", 1.0, -1.0, 0.45, [0.8, 1.0, 1.6], "register_small", own)
	var sk := str(SHOP_OF["restaurant" if asian else "diner"])
	spots.append({"id": "bld:%s:shop" % gid, "kind": "shop", "title": str(g.get("name", "Diner")), "verb": "Order", "pos": [5.5, 0.55, 1.95], "size": [5.0, 1.1, 0.8], "shop": sk, "stock_key": "%s@%s" % [sk, gid], "clerk": clerk})
	var nc := r.randi_range(1, 3)
	var seats := [[5.2, 5.5], [8.0, 4.5], [2.0, 5.0], [4.5, 2.6]]
	for i in nc:
		var p: Array = seats[i]
		npc("patron", float(p[0]), float(p[1]), r.randf_range(0, 360), open_cond(), {"name": "Diner"})


func _bar() -> void:
	ambient = Color(0.25, 0.18, 0.2)
	amb = "jazz"
	var neon: Color = _pick([Color(1.0, 0.3, 0.7), Color(0.3, 0.7, 1.0), Color(1.0, 0.6, 0.2), Color(0.5, 1.0, 0.4)])
	room(0, 0, 12, 9, Color(0.26, 0.18, 0.16), Color(0.22, 0.15, 0.1), {"h": 3.2, "light": Color(1.0, 0.6, 0.4), "energy": 0.8, "lights": [[3, 2.8, 4.5], [9, 2.8, 4.5]]})
	room(0, -4, 5, 0, Color(0.3, 0.24, 0.2), Color(0.25, 0.2, 0.15), {"h": 3.0, "light": Color(1.0, 0.8, 0.55), "energy": 0.7})
	doors.append([2.5, 0, 1.1])
	exit_at(9.5, 9)
	var own := _owned()
	f("bar_counter", 7.0, 1.6, 0, {"w": 5.0, "neon": neon})
	f("bar_shelf", 7.0, 0.3, 0, {"w": 4.5})
	cont("Behind the Bar", 7.0, 0.3, 1.4, [4.6, 2.3, 0.5], "liquor_stock", own)
	f("register", 9.0, 1.5, 0)
	cont("Cash Register", 9.0, 1.5, 1.25, [0.6, 0.45, 0.6], "register", own)
	for sx in [5.0, 6.0, 7.0, 8.0, 9.0]:
		f("stool", sx, 2.5, 0)
	var keep := npc("bartender", 7.0, 0.85, 180.0, open_cond())
	f("pool_table", 3.0, 5.5, 0)
	f("jukebox", 0.5, 8.4, 90)
	for z in [4.0, 6.5]:
		f("booth", 10.95, z, -90, {"col": Color(0.35, 0.06, 0.08)})
	f("poster", 3.0, 8.88, 180, {"col": neon.darkened(0.3)})
	f("lamp", 11.5, 8.5, 0, {"col": neon})
	# Back office.
	f("desk", 2.5, -3.5, 0)
	cont("Desk", 2.5, -3.5, 0.45, [1.6, 1.0, 0.8], "desk", own)
	f("boxes", 4.2, -1.0, 0)
	_safe(0.6, -1.0, 90, "bar_stash", 35, 60, own)
	spots.append({"id": "bld:%s:shop" % gid, "kind": "shop", "title": str(g.get("name", "Bar")), "verb": "Order", "pos": [7.0, 0.55, 2.35], "size": [5.0, 1.1, 0.7], "shop": "gen_bar", "stock_key": "gen_bar@%s" % gid, "clerk": keep})
	var nc := r.randi_range(2, 4)
	var seats := [[5.0, 3.1], [8.0, 3.1], [3.0, 3.6], [9.4, 4.0], [4.5, 7.2]]
	for i in nc:
		var p: Array = seats[i]
		npc("patron", float(p[0]), float(p[1]), r.randf_range(0, 360), open_cond())


func _arcade() -> void:
	ambient = Color(0.2, 0.16, 0.28)
	room(0, 0, 12, 9, Color(0.18, 0.12, 0.22), Color(0.12, 0.1, 0.14), {"h": 3.2, "light": Color(0.8, 0.5, 1.0), "energy": 0.7, "lights": [[3, 2.8, 4.5], [9, 2.8, 4.5]]})
	exit_at(2.0, 9)
	var own := _owned()
	var glows := [Color(1.0, 0.3, 0.5), Color(0.3, 0.8, 1.0), Color(1.0, 0.8, 0.2), Color(0.4, 1.0, 0.5)]
	for i in 5:
		f("arcade_cab", 1.2 + float(i) * 1.1, 0.5, 0, {"col": _pick([Color(0.1, 0.1, 0.35), Color(0.35, 0.05, 0.1), Color(0.05, 0.25, 0.1)]), "glow": glows[i % 4]})
	for i in 3:
		f("pinball", 10.8, 3.0 + float(i) * 1.8, -90)
	f("counter", 5.5, 6.8, 180, {"w": 3.0})
	f("register", 5.0, 6.9, 180)
	cont("Prize Counter Till", 5.0, 6.9, 1.15, [0.6, 0.45, 0.6], "register_small", own)
	var clerk := npc("clerk", 5.5, 7.6, 0.0, open_cond(), {"name": "Attendant"})
	spots.append({"id": "bld:%s:shop" % gid, "kind": "shop", "title": str(g.get("name", "Arcade")), "verb": "Buy", "pos": [5.5, 0.55, 6.05], "size": [3.0, 1.1, 0.8], "shop": "gen_arcade", "stock_key": "gen_arcade@%s" % gid, "clerk": clerk})
	spots.append({"id": "bld:%s:cab" % gid, "kind": "minigame", "title": "High-Score Cabinet", "verb": "Play ($5 prize pot)", "pos": [2.3, 1.2, 1.2], "size": [1.0, 1.8, 0.8], "game": "invaders", "fx_win": "cash 25 ; xp 5"})
	for i in r.randi_range(1, 3):
		npc("patron", r.randf_range(2.0, 9.0), r.randf_range(2.5, 5.0), 0.0, open_cond(), {"name": "Gamer", "wander": 2.0})


# ================================================================ WORK
func _office() -> void:
	ambient = Color(0.33, 0.35, 0.37)
	amb = "office"
	var wall: Color = _pick([Color(0.66, 0.68, 0.7), Color(0.6, 0.62, 0.6), Color(0.7, 0.66, 0.6)])
	var carpet: Color = _pick([Color(0.25, 0.27, 0.32), Color(0.3, 0.25, 0.24), Color(0.24, 0.28, 0.26)])
	var cool := Color(0.92, 0.96, 1.0)
	room(0, 0, 10, 6, wall, Color(0.6, 0.6, 0.62), {"h": 3.4, "floor_kind": "tile", "light": cool, "energy": 1.1})
	room(0, -10, 10, 0, wall, carpet, {"h": 3.0, "floor_kind": "none", "light": cool, "energy": 1.0, "lights": [[2.5, 2.6, -7.5], [7.5, 2.6, -7.5], [2.5, 2.6, -2.5], [7.5, 2.6, -2.5]]})
	room(10, -10, 14, -4, wall.darkened(0.08), Color(0.3, 0.2, 0.15), {"h": 3.0, "light": Color(1.0, 0.88, 0.7), "energy": 0.9})
	room(10, -4, 14, 0, Color(0.3, 0.32, 0.36), Color(0.28, 0.28, 0.3), {"h": 3.0, "light": Color(0.5, 0.7, 1.0), "energy": 0.7})
	doors.append([8.5, 0, 1.4])
	doors.append([10, -7, 1.1])
	doors.append([10, -2, 1.1])
	exit_at(5.0, 6)
	var own := _owned()
	var logo: Color = _pick([Color(0.35, 0.55, 1.0), Color(1.0, 0.5, 0.2), Color(0.4, 1.0, 0.6), Color(0.9, 0.9, 0.95)])
	f("reception", 5.0, 2.2, 0, {"glow": logo})
	cont("Reception Desk", 5.0, 2.2, 0.55, [3.3, 1.2, 1.0], "office_desk", own)
	f("logo_wall", 3.0, 0.12, 0, {"w": 4.0, "glow": logo})
	f("plant", 0.6, 5.4, 0)
	f("plant", 9.4, 5.4, 0)
	f("water_cooler", 9.5, 1.0, -90)
	f("armchair", 1.2, 3.2, 90, {"col": Color(0.2, 0.2, 0.22)})
	f("armchair", 1.2, 4.3, 90, {"col": Color(0.2, 0.2, 0.22)})
	# Open-plan floor.
	var desk_n := 0
	for z in [-8.2, -5.2]:
		for x in [2.2, 5.0, 7.8]:
			f("office_desk", x, z, 0, {"screen": _pick([Color(0.3, 0.6, 1.0), Color(0.9, 0.9, 0.9), Color(0.2, 0.9, 0.5)])})
			if desk_n % 2 == 0:
				cont("Desk Drawers", x, z, 0.48, [1.6, 1.0, 0.85], "office_desk", own)
			desk_n += 1
	for z in [-9.5, -8.8]:
		f("filing_cabinet", 0.35, z + 0.0, 90)
	cont("Filing Cabinet", 0.35, -9.15, 0.68, [0.7, 1.4, 1.3], "desk", own)
	f("whiteboard", 5.0, -9.9, 0)
	f("vending", 9.4, -5.8, -90)
	cont("Vending Machine", 9.4, -5.8, 0.98, [0.9, 2.0, 1.05], "stockroom", own)
	f("plant", 9.4, -9.4, 0)
	# Manager's office.
	f("desk_pc", 12.0, -8.9, 0, {"screen": Color(0.3, 0.6, 1.0)})
	cont("Executive Desk", 12.0, -8.9, 0.48, [1.6, 1.0, 0.85], "office_desk", own)
	f("bookshelf", 13.8, -6.0, -90)
	f("plant", 10.5, -4.6, 0)
	_safe(13.5, -9.5, 0, "office_safe", 40, 70, own)
	# Server room.
	for x in [11.2, 12.4, 13.6]:
		f("server_rack", x, -3.4, 0, {"led": _pick([Color(0.2, 1.0, 0.4), Color(0.3, 0.6, 1.0)])})
	cont("Server Rack", 12.4, -3.4, 1.05, [3.3, 2.2, 1.1], "server", own)
	var co := str(g.get("name", "Company"))
	var hack: int = int(_pick([25, 35, 45, 55, 65]))
	var take: int = int(float(hack) * r.randf_range(3.0, 6.0))
	spots.append({"id": "bld:%s:term" % gid, "kind": "terminal", "title": co + " Accounts", "verb": "Log in", "pos": [12.4, 1.1, -1.0], "size": [1.2, 1.4, 1.0],
		"hack": hack, "user": "admin", "header": co.to_upper() + " — AUTHORIZED PERSONNEL ONLY",
		"welcome": "%s internal finance node. Last login: accounting@%s." % [co, co.to_lower().replace(" ", "").replace("&", "")],
		"entries": [
			{"title": "mail/q3_bonus.eml", "text": _pick(["Bonuses are frozen this quarter. Partner distributions are not. Please do not forward this.", "Reminder: expense reports without receipts will be approved anyway if they're under $5,000.", "We need to talk about the offshore account before the auditors do."])},
			{"title": "notes/it_passwords.txt", "text": _pick(["Everyone's password is Welcome1 until IT gets back from vacation.", "Remember: the server room door code is the CEO's birthday. Please stop writing it on the door.", "New policy: passwords must be at least 8 characters. 'password' is 8 characters."])},
		],
		"actions": [
			{"title": "Wire petty cash to a mule account", "result": "Transfer queued. Reconciliation runs Friday. By Friday you'll be a rumor.", "fx": "cash %d ; xp 20" % take},
			{"title": "Export client card database", "result": "A few thousand card numbers land on your drive. Somebody at an ATM will want them.", "fx": "give credit_card %d ; xp 10" % r.randi_range(2, 5)},
		]})
	f("desk", 12.4, -1.0, 180)
	# People: workers by day, security by night.
	for p in [[2.2, -7.45], [7.8, -4.45], [5.0, 1.4]]:
		if r.randf() < 0.75:
			npc("office_worker", float(p[0]), float(p[1]), 180.0, open_cond())
	npc("security" if r.randf() < 0.6 else "security_baton", 5.0, -3.0, 0.0, closed_cond(), {"wander": 3.0})
	if r.randf() < 0.5:
		npc("security_baton", 12.0, -6.0, 0.0, closed_cond(), {"wander": 2.0})


func _warehouse() -> void:
	ambient = Color(0.28, 0.27, 0.25)
	var wall := Color(0.42, 0.4, 0.36)
	room(0, 0, 16, 12, wall, Color(0.32, 0.32, 0.33), {"h": 5.5, "floor_kind": "none", "light": Color(1.0, 0.9, 0.7), "energy": 1.0, "lights": [[4, 5.0, 3], [12, 5.0, 3], [4, 5.0, 9], [12, 5.0, 9]]})
	room(16, 0, 20, 5, wall.darkened(0.1), Color(0.3, 0.26, 0.2), {"h": 3.0, "light": Color(1.0, 0.85, 0.6), "energy": 0.9})
	doors.append([16, 2.5, 1.1])
	exit_at(3.0, 12)
	var gang := r.randf() < 0.3
	for z in [2.0, 5.5]:
		for x in [5.0, 8.0, 11.0]:
			f("shelf_industrial", x, z, 0)
	cont("Pallet Rack", 8.0, 2.0, 1.5, [2.5, 3.1, 1.0], "warehouse_crate")
	cont("Pallet Rack", 11.0, 5.5, 1.5, [2.5, 3.1, 1.0], "warehouse_crate")
	for p in [[1.0, 1.0], [1.0, 2.2], [2.2, 1.0], [14.6, 10.5], [13.4, 10.5], [14.6, 9.3]]:
		f("crate", float(p[0]), float(p[1]), 0)
	cont("Crate", 1.0, 1.0, 0.52, [1.1, 1.1, 1.1], "warehouse_crate")
	cont("Crate", 14.6, 10.5, 0.52, [1.1, 1.1, 1.1], "hideout_crate" if gang else "warehouse_crate")
	f("boxes", 8.0, 9.0, 0)
	f("boxes", 10.0, 9.4, 90)
	# Office.
	f("desk", 18.0, 4.3, 180)
	cont("Desk", 18.0, 4.3, 0.45, [1.6, 1.0, 0.8], "desk")
	f("locker_row", 19.7, 2.0, -90, {"n": 3})
	cont("Lockers", 19.7, 2.0, 0.95, [0.6, 2.0, 1.6], "security_locker")
	f("filing_cabinet", 16.6, 0.4, 0)
	if r.randf() < 0.3 or gang:
		_safe(19.4, 0.5, 0, "hideout_safe" if gang else "safe", 30, 60)
	if gang:
		var crew := ["gang_smg", "gang_shotgun", "gang_45", "thug_gun", "gang_rifle"]
		for p in [[11.0, 1.0], [14.0, 8.5], [6.0, 3.8], [14.0, 3.6]]:
			if r.randf() < 0.85:
				npc(str(_pick(crew)), float(p[0]), float(p[1]), r.randf_range(0, 360), "", {"wander": 2.5})
		if r.randf() < 0.4:
			npc("gang_boss", 18.0, 3.0, 0.0)
