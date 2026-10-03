class_name CityBuilder
extends RefCounted
## CityBuilder — generates the whole city into 200 m chunks. Each chunk commits
## to ~5 draw calls (facade, ground, props, glow, light pools) + one static body.
## Deterministic: same seed, same city.

const CHUNK := 200.0
const ORIGIN := Vector2(-1000.0, -1000.0)

const AVENUE_NAMES := ["12TH AVE", "11TH AVE", "10TH AVE", "9TH AVE", "8TH AVE", "7TH AVE", "6TH AVE",
	"5TH AVE", "MADISON AVE", "PARK AVE", "LEXINGTON AVE", "3RD AVE", "2ND AVE",
	"1ST AVE", "VERNON BLVD", "21ST ST", "CRESCENT ST", "STEINWAY ST", "QUEENS BLVD", "NORTHERN BLVD"]
const STREET_NAMES := ["GUN HILL RD", "238 ST", "231 ST", "FORDHAM RD", "TREMONT AVE", "207 ST", "DYCKMAN ST", "200 ST", "190 ST", "185 ST",
	"181 ST", "165 ST", "145 ST", "125 ST", "96 ST", "72 ST", "59 ST", "53 ST",
	"42 ST", "34 ST", "23 ST", "14 ST", "HOUSTON ST", "DELANCEY ST", "CANAL ST", "CHAMBERS ST", "FULTON ST", "NEPTUNE AVE"]
## Street signs outside New York (west to east, north to south).
const REGION_AVENUES := {
	"highway": ["COUNTY RD 12", "INTERSTATE 80", "COUNTY RD 14"],
	"chicago": ["ASHLAND AVE", "RACINE AVE", "HALSTED ST", "DESPLAINES ST", "CANAL ST", "WACKER DR", "WELLS ST", "LASALLE ST", "CLARK ST", "DEARBORN ST", "STATE ST", "MICHIGAN AVE", "LAKE SHORE DR"],
	"township": ["KEARNEY RD", "PLANT RD", "1ST AVE", "2ND AVE", "3RD AVE", "4TH AVE", "MAPLE AVE", "RIDGE AVE", "COUNTY RTE 9"],
	"port": ["AIRPORT RD", "CAPE RD", "WHALER AVE", "MARKET ST", "ANCHOR AVE", "SCHOONER AVE", "DOCK ST", "TERMINAL AVE", "QUAY ST", "PIER RD"],
	"gary": ["CLARK RD", "CHASE ST", "MADISON ST", "TAFT ST", "BROADWAY", "MASSACHUSETTS ST", "VIRGINIA ST", "GRANT ST", "MLK DR", "AIRPORT RD", "CLINE AVE"],
	"redmont": ["SHORE DR", "INTAKE RD", "CHILLER WAY", "COMMONS AVE", "COPILOT WAY", "ROUTE 9", "SYNERGY AVE", "TEAMS AVE", "OFFICE LN", "FIELD RD", "EDGE ST"],
	"island": ["STRIP RD", "HOUSE DR", "SHORE RD"],
}
const REGION_STREETS := {
	"highway": ["FARM RD 1", "FARM RD 2", "FARM RD 3", "COUNTY RTE 41", "FARM RD 5", "LENNOX RD", "MAIN ST"],
	"chicago": ["DIVISION ST", "CHICAGO AVE", "SUPERIOR ST", "GRAND AVE", "OHIO ST", "KINZIE ST", "LAKE ST", "RANDOLPH ST", "WASHINGTON ST", "MADISON ST", "MONROE ST", "ADAMS ST", "JACKSON BLVD", "VAN BUREN ST", "CONGRESS PKWY", "ROOSEVELT RD"],
	"township": ["QUARRY RD", "MILL ST", "CHURCH ST", "ELM ST", "MAIN ST", "WALNUT ST", "SCHOOL ST", "FARM RD", "CREEK RD"],
	"port": ["LIGHTHOUSE RD", "NORTH ST", "CANNERY ST", "SALT ST", "WATER ST", "FRONT ST", "HARBOR ST", "MARSH RD", "SOUTH ST"],
	"gary": ["DUNES HWY", "5TH AVE", "7TH AVE", "9TH AVE", "11TH AVE", "15TH AVE", "19TH AVE", "21ST AVE", "25TH AVE", "35TH AVE", "RIDGE RD"],
	"redmont": ["CAMPUS NORTH", "INNOVATION DR", "SYNERGY ST", "CLOUD ST", "1ST ST", "MAIN ST", "2ND ST", "3RD ST", "4TH ST", "5TH ST", "RESERVOIR RD"],
	"island": ["NORTH DR", "GARDEN WALK", "SOUTH DR"],
}
## Washington Township's plant stacks and Port Ramsey's cranes and lighthouse
## (local), drawn up close by their own map and from far away by the others.
const TW_STACKS := [Vector2(-262.0, -330.0), Vector2(-218.0, -330.0)]
const PT_CRANES := [Vector2(682.0, -290.0), Vector2(682.0, -170.0), Vector2(682.0, -50.0)]
const PT_LIGHTHOUSE := Vector2(752.0, -566.0)
const GY_FURNACES := [Vector2(-600.0, -540.0), Vector2(-470.0, -540.0), Vector2(-340.0, -540.0)]
## Microslop HQ in Redmont (centre of its tower, local) and the logo on the lawn.
const RM_HQ := Vector2(70.0, -413.0)
const RM_LOGO := Vector2(210.0, -420.0)

var chunks: Dictionary = {} # Vector2i -> BuildCtx
var rng := RandomNumberGenerator.new()
var buildings: Array = [] # for the map: [x0, z0, x1, z1, h, district]
var parked_spots: Array = []
var reserved: Dictionary = {} # "bi,bj" -> Array[Rect2]
var ferris_center := Vector3(100, 26, 660)
var stats := {"buildings": 0, "doors": 0, "lootables": 0}
## Enterable doors on generic buildings: [{id, pos, out, kind, name, lock, hours, closed_lock, seed, district}]
var gen_doors: Array = []
## Searchable world props: [{k, p (center), he (half extents), r (rot y)}]
var lootables: Array = []
var _door_ids: Dictionary = {}

const SURNAMES := ["Rossi", "Kim", "Nguyen", "Patel", "O'Brien", "Kowalski", "Chen", "Gomez", "Singh", "Levy",
	"Park", "Russo", "Ortiz", "Wong", "Khan", "Murphy", "Diaz", "Cohen", "Ali", "Petrov", "Santos", "Lee", "Walsh", "Moreno"]
const DOOR_LEAVES := [Color(0.13, 0.34, 0.2), Color(0.52, 0.13, 0.09), Color(0.12, 0.2, 0.42), Color(0.16, 0.16, 0.17),
	Color(0.46, 0.3, 0.16), Color(0.3, 0.37, 0.34), Color(0.56, 0.43, 0.17)]
const SHOP_NEON := [Color(1, 0.35, 0.3), Color(0.35, 1, 0.55), Color(0.35, 0.75, 1), Color(1, 0.82, 0.3), Color(1, 0.45, 0.9), Color(0.9, 0.95, 1.0)]
const STORE_KINDS := {
	"chinatown": ["restaurant", "restaurant", "grocery", "electronics", "clothing", "liquor", "pawnshop"],
	"les": ["grocery", "liquor", "diner", "bar", "electronics", "clothing", "hardware", "pawnshop", "grocery"],
	"hells": ["bar", "bar", "diner", "liquor", "grocery", "pawnshop", "clothing", "hardware"],
	"coney": ["diner", "bar", "arcade", "arcade", "grocery", "pawnshop"],
	"uptown": ["diner", "clothing", "clothing", "grocery", "electronics", "liquor", "bar"],
	"heights": ["grocery", "diner", "hardware", "liquor", "pawnshop", "bar", "electronics"],
	"east_mid": ["diner", "electronics", "clothing", "bar", "grocery"],
	"midtown": ["diner", "electronics", "clothing", "bar"],
	"civic": ["diner", "grocery", "electronics", "liquor"],
	"harlem": ["diner", "bar", "grocery", "clothing", "liquor", "restaurant", "pawnshop", "bar"],
	"bronx": ["grocery", "grocery", "liquor", "pawnshop", "diner", "hardware", "electronics", "bar"],
	"inwood": ["grocery", "diner", "bar", "liquor", "hardware"],
	"astoria": ["diner", "diner", "restaurant", "bar", "grocery", "clothing", "electronics"],
	"lic": ["diner", "bar", "electronics", "clothing", "grocery"],
	"hunts": ["grocery", "liquor", "hardware", "diner"],
	"tw_main": ["diner", "hardware", "grocery", "bar", "pawnshop", "liquor", "clothing", "diner"],
	"pt_town": ["bar", "bar", "diner", "grocery", "hardware", "liquor", "pawnshop", "restaurant"],
	"gy_town": ["liquor", "pawnshop", "diner", "bar", "grocery", "hardware", "pawnshop", "clothing"],
	"rm_town": ["diner", "grocery", "electronics", "bar", "clothing", "electronics", "hardware", "liquor"],
}


func ctx_at(x: float, z: float) -> BuildCtx:
	var k := Vector2i(int(floor((x - ORIGIN.x) / CHUNK)), int(floor((z - ORIGIN.y) / CHUNK)))
	if not chunks.has(k):
		chunks[k] = BuildCtx.new()
	return chunks[k]


func build_all() -> void:
	rng.seed = WorldLayout.SEED
	if WorldLayout.region != "nyc":
		_build_region()
		_fill_country()
		_neighbour_skylines()
		_finish_graffiti()
		return
	_reserve_landmarks()
	_roads()
	for bj in WorldLayout.NBJ:
		for bi in WorldLayout.NBI:
			_block(bi, bj)
	_park()
	_tryon()
	_steel_compound()
	_airfield()
	_landmarks()
	_subways()
	_coney()
	_edges()
	_chop_shop(Vector3(1105.0, 0.0, -1200.0))
	_body_shops()
	_fill_country()
	_neighbour_skylines()
	_finish_graffiti()


## Every light pool on the map (street lamps, floodlights), for NightLights.
func lamp_points() -> Array:
	var out: Array = []
	for k in chunks.keys():
		out.append_array((chunks[k] as BuildCtx).lamps)
	return out


func commit(parent: Node3D, far: float) -> void:
	for k in chunks.keys():
		var n := Node3D.new()
		n.name = "Chunk_%d_%d" % [k.x, k.y]
		parent.add_child(n)
		var bc := chunks[k] as BuildCtx
		bc.props_mat = Mats.city_lit
		bc.glow_mat = Mats.city_glow
		bc.commit(n, far)


# ------------------------------------------------------------- other regions
## Chicago, the interstate, and anywhere else: the same grid, the same
## building kit, a different map. No NYC set pieces.
func _build_region() -> void:
	_reserve_landmarks()
	_roads()
	for bj in WorldLayout.NBJ:
		for bi in WorldLayout.NBI:
			var d := WorldLayout.district(bi, bj)
			var r := WorldLayout.block_rect(bi, bj)
			match d:
				"airfield":
					pass
				"farm", "reststop", "tw_field":
					_farm_block(bi, bj, r, d == "reststop")
				"loop":
					_midtown_block(bi, bj, r)
				"river", "pt_ind":
					_industrial_block(bi, bj, r)
				"tw_plant":
					_plant_block(bi, bj, r)
				"tw_homes", "pt_homes":
					_houses_block(bi, bj, r, d)
				"tw_memorial":
					_cemetery(r, "MOSS")
					_township_memorial(r)
				"pt_docks":
					_docks_block(bi, bj, r)
				"gy_mill":
					_mill_block(bi, bj, r)
				"gy_depot":
					_depot_block(bi, bj, r)
				"gy_homes", "rm_homes", "rm_shore":
					_houses_block(bi, bj, r, d)
				"rm_dc":
					_datacenter_block(bi, bj, r)
				"rm_campus":
					_campus_block(bi, bj, r)
				"isl_estate":
					_estate_block(bi, bj, r)
				"isl_hill":
					_hill_block(bi, bj, r)
				_:
					_street_wall_block(bi, bj, r, d)
	if WorldLayout.AIRFIELD["bi0"] <= WorldLayout.AIRFIELD["bi1"]:
		_region_airfield()
	match WorldLayout.region:
		"highway":
			_stalled_rig(Vector3(-17.0, 0.0, -300.0))
			_exit_gantries()
		"township":
			_township_extras()
		"port":
			_port_extras()
		"gary":
			_gary_extras()
		"redmont":
			_redmont_extras()
		"island":
			_island_extras()
	_body_shops()
	_landmarks()
	_region_edges()


## Interstate country: fields in strips, tree lines, a barn now and then,
## and billboards that tell you exactly what kind of country this is.
func _farm_block(bi: int, bj: int, r: Rect2, rest: bool) -> void:
	var crops := [Color(0.32, 0.36, 0.14), Color(0.42, 0.38, 0.16), Color(0.24, 0.3, 0.12), Color(0.46, 0.4, 0.24), Color(0.2, 0.26, 0.1)]
	var x := r.position.x
	while x < r.end.x - 1.0:
		var w := minf(rng.randf_range(24.0, 60.0), r.end.x - x)
		var col: Color = crops[rng.randi() % crops.size()]
		var z := r.position.y
		while z < r.end.y - 1.0:
			var dz := minf(100.0, r.end.y - z)
			ctx_at(x + w * 0.5, z + dz * 0.5).ground.flat(Vector3(x + w * 0.5, 0.01, z + dz * 0.5), w - 0.6, dz, col, 0.0, Vector2(1, 0))
			z += dz
		x += w
	if rest:
		return
	# Tree line along the field edge nearest the road.
	var tz := r.position.y + 6.0
	while tz < r.end.y:
		var tx := r.position.x + rng.randf_range(4.0, 10.0)
		var c := ctx_at(tx, tz)
		Props.place(c, ["tree_a", "tree_b", "tree_c"][rng.randi() % 3], Vector3(tx, 0, tz), rng.randf() * TAU, rng.randf_range(1.0, 1.6))
		c.solid(Vector3(tx, 1.4, tz), Vector3(0.5, 2.8, 0.5))
		tz += rng.randf_range(14.0, 30.0)
	# A barn and a silo.
	if rng.randf() < 0.7:
		var bx := r.position.x + rng.randf_range(80.0, r.size.x - 60.0)
		var bz := r.position.y + rng.randf_range(40.0, r.size.y - 60.0)
		var cb := ctx_at(bx, bz)
		_facade_box(cb, Rect2(bx, bz, 18.0, 26.0), 0.0, 9.0, 0, Color(0.5, 0.14, 0.1), 0.0)
		cb.props.box_xf(Transform3D(Basis(Vector3.FORWARD, 0.5), Vector3(bx + 4.5, 10.5, bz + 13.0)), Vector3(10.4, 0.3, 27.0), Color(0.25, 0.25, 0.27))
		cb.props.box_xf(Transform3D(Basis(Vector3.FORWARD, -0.5), Vector3(bx + 13.5, 10.5, bz + 13.0)), Vector3(10.4, 0.3, 27.0), Color(0.25, 0.25, 0.27))
		cb.solid(Vector3(bx + 9.0, 4.5, bz + 13.0), Vector3(18.0, 9.0, 26.0))
		cb.props.cyl(Vector3(bx + 24.0, 8.0, bz + 6.0), 3.2, 3.2, 16.0, Color(0.7, 0.7, 0.68), 12)
		cb.solid(Vector3(bx + 24.0, 8.0, bz + 6.0), Vector3(6.0, 16.0, 6.0))
	# Billboards facing the interstate.
	if rng.randf() < 0.6:
		var by := r.position.y + rng.randf_range(30.0, r.size.y - 30.0)
		var bxx := r.position.x + 22.0
		var cbb := ctx_at(bxx, by)
		cbb.props.box(Vector3(bxx, 4.0, by), Vector3(0.3, 8.0, 0.3), Color(0.3, 0.3, 0.3))
		cbb.props.box(Vector3(bxx, 8.5, by), Vector3(0.3, 4.0, 12.0), Color(0.92, 0.92, 0.88))
		var ads := ["E CORP · OWN NOTHING · OWE EVERYTHING", "E COIN · THE FUTURE OF MONEY IS OURS", "LIVE SERVICE · NEVER FINISHED · NEVER YOURS", "ACCOUNT REQUIRED · FOR YOUR SAFETY", "SUBSCRIBE TO YOUR CAR'S HEATED SEATS", "JESUS SAVES · E CORP CHARGES INTEREST", "NOW WITH AI · YOU DIDN'T ASK"]
		cbb.label(Vector3(bxx - 0.2, 8.5, by), ads[rng.randi() % ads.size()], 64, Color(0.12, 0.12, 0.14), -PI * 0.5, 260.0, 0.02)
		cbb.solid(Vector3(bxx, 4.0, by), Vector3(0.4, 8.0, 0.4))


## Keep Rafi's bay clear of the street's parked cars.
func _in_chop_bay(x: float, z: float) -> bool:
	for b in RegionContent.BODY_SHOPS.get(WorldLayout.region, []):
		var bp: Array = (b as Dictionary)["pos"]
		if absf(x - float(bp[0])) < 9.0 and absf(z - float(bp[1])) < 7.0:
			return true
	return false


## Every body shop on this map that isn't Rafi's: the same painted bay, a
## pole sign, a work light (see RegionContent.BODY_SHOPS).
func _body_shops() -> void:
	for b in RegionContent.BODY_SHOPS.get(WorldLayout.region, []):
		var bd: Dictionary = b
		if bool(bd.get("rafi", false)):
			continue
		var bp: Array = bd["pos"]
		_body_shop(Vector3(float(bp[0]), 0.0, float(bp[1])), str(bd["name"]))


func _body_shop(p: Vector3, title: String) -> void:
	var c := ctx_at(p.x, p.z)
	var y := Color(0.3, 0.75, 1.0)
	for e in [[Vector3(0, 0.03, -4.5), Vector3(9.0, 0.02, 0.25)], [Vector3(0, 0.03, 4.5), Vector3(9.0, 0.02, 0.25)], [Vector3(-4.5, 0.03, 0), Vector3(0.25, 0.02, 9.0)], [Vector3(4.5, 0.03, 0), Vector3(0.25, 0.02, 9.0)]]:
		c.props.box(p + (e[0] as Vector3), e[1], y)
	c.label(p + Vector3(0, 0.05, 0), "RESPRAY", 120, Color(0.3, 0.75, 1.0, 0.8), 0.0, 60.0, 0.02, {"pitch": -PI * 0.5})
	var sp := p + Vector3(-6.0, 0, 6.6)
	c.props.box(sp + Vector3(0, 2.5, 0), Vector3(0.2, 5.0, 0.2), Color(0.25, 0.25, 0.27))
	c.props.box(sp + Vector3(0, 5.2, 0), Vector3(4.6, 1.4, 0.18), Color(0.1, 0.1, 0.12))
	c.glow.box(sp + Vector3(0, 5.2, -0.1), Vector3(4.4, 1.2, 0.04), Color(0.2, 0.55, 0.9), 0.0, Vector2(Props.K_ALWAYS, 0))
	c.glow.box(sp + Vector3(0, 5.2, 0.1), Vector3(4.4, 1.2, 0.04), Color(0.2, 0.55, 0.9), 0.0, Vector2(Props.K_ALWAYS, 0))
	for f in [-1.0, 1.0]:
		c.label(sp + Vector3(0, 5.35, 0.14 * f), title, 38, Color(1, 1, 1), 0.0 if f > 0 else PI, 160.0, 0.02)
		c.label(sp + Vector3(0, 4.85, 0.14 * f), "RESPRAY · REPAIR · NO QUESTIONS", 22, Color(0.85, 0.95, 1.0), 0.0 if f > 0 else PI, 120.0, 0.02)
	c.solid(sp + Vector3(0, 2.5, 0), Vector3(0.3, 5.0, 0.3))
	Props.light_pool(c, p, 7.0, Color(0.85, 0.92, 1.0))


## Rafi's Auto Body, Hunts Point: a painted bay on the street, a pole sign
## and a work light. Drive a stolen car in and stop (Game._chop_tick).
func _chop_shop(p: Vector3) -> void:
	var c := ctx_at(p.x, p.z)
	var y := Color(0.95, 0.75, 0.1)
	for e in [[Vector3(0, 0.03, -4.5), Vector3(9.0, 0.02, 0.25)], [Vector3(0, 0.03, 4.5), Vector3(9.0, 0.02, 0.25)], [Vector3(-4.5, 0.03, 0), Vector3(0.25, 0.02, 9.0)], [Vector3(4.5, 0.03, 0), Vector3(0.25, 0.02, 9.0)]]:
		c.props.box(p + (e[0] as Vector3), e[1], y)
	c.label(p + Vector3(0, 0.05, 0), "CHOP", 160, Color(0.95, 0.75, 0.1, 0.8), 0.0, 60.0, 0.02, {"font": "graffiti", "pitch": -PI * 0.5})
	var sp := p + Vector3(-6.0, 0, 6.6)
	c.props.box(sp + Vector3(0, 2.5, 0), Vector3(0.2, 5.0, 0.2), Color(0.25, 0.25, 0.27))
	c.props.box(sp + Vector3(0, 5.2, 0), Vector3(4.6, 1.4, 0.18), Color(0.1, 0.1, 0.12))
	c.glow.box(sp + Vector3(0, 5.2, -0.1), Vector3(4.4, 1.2, 0.04), Color(0.9, 0.2, 0.15), 0.0, Vector2(Props.K_FLICKER, 0.3))
	c.glow.box(sp + Vector3(0, 5.2, 0.1), Vector3(4.4, 1.2, 0.04), Color(0.9, 0.2, 0.15), 0.0, Vector2(Props.K_FLICKER, 0.3))
	for f in [-1.0, 1.0]:
		c.label(sp + Vector3(0, 5.35, 0.14 * f), "RAFI'S AUTO BODY", 42, Color(1, 1, 1), 0.0 if f > 0 else PI, 160.0, 0.02)
		c.label(sp + Vector3(0, 4.85, 0.14 * f), "WE BUY CARS · NO QUESTIONS", 24, Color(1.0, 0.85, 0.3), 0.0 if f > 0 else PI, 120.0, 0.02)
	c.glow.box(sp + Vector3(1.4, 3.4, -0.3), Vector3(0.6, 0.25, 0.25), Color(1.0, 0.95, 0.8), 0.0, Vector2(Props.K_NIGHT, 0))
	c.solid(sp + Vector3(0, 2.5, 0), Vector3(0.3, 5.0, 0.3))
	Props.light_pool(c, p, 7.0, Color(1.0, 0.85, 0.6))


## Dolores's blue Peterbilt, locked on the west shoulder with its hazards on
## (Last Load). A cab, a reefer trailer, wheels and blinking corner lights.
func _stalled_rig(p: Vector3) -> void:
	var c := ctx_at(p.x, p.z)
	var blue := Color(0.12, 0.25, 0.55)
	c.props.box(p + Vector3(0, 2.0, -6.2), Vector3(2.5, 2.6, 3.2), blue)
	c.props.box(p + Vector3(0, 1.1, -8.4), Vector3(2.4, 1.2, 1.4), blue.darkened(0.2))
	c.props.box(p + Vector3(0, 2.6, -7.75), Vector3(2.2, 0.9, 0.1), Color(0.3, 0.45, 0.6))
	c.props.box(p + Vector3(0, 2.3, 2.0), Vector3(2.6, 3.0, 12.5), Color(0.86, 0.86, 0.84))
	c.label(p + Vector3(1.32, 2.6, 2.0), "LENNOX COMMUNITY CLINIC · KEEP COLD", 26, Color(0.15, 0.3, 0.6), PI * 0.5, 80.0, 0.02)
	for wz in [-7.6, -5.0, 0.0, 6.0, 7.4]:
		for sx in [-1.15, 1.15]:
			c.props.box(Vector3(p.x + sx, 0.55, p.z + wz), Vector3(0.45, 1.1, 1.1), Color(0.08, 0.08, 0.08))
	for corner in [Vector3(-1.2, 1.2, -8.9), Vector3(1.2, 1.2, -8.9), Vector3(-1.25, 1.0, 8.2), Vector3(1.25, 1.0, 8.2)]:
		c.glow.box(p + corner, Vector3(0.25, 0.18, 0.12), Color(1.0, 0.6, 0.1), 0.0, Vector2(Props.K_BLINK, 0))
	c.solid(p + Vector3(0, 2.0, 0.0), Vector3(2.6, 4.0, 17.5))


## A small-town airfield: grass, one north-south runway with numbers,
## threshold bars and edge lights, an apron with two tie-downs on whichever
## side has room, a windsock and a rotating beacon. Meigs Field, Kearney
## Strip and Ramsey Field are all this.
func _region_airfield() -> void:
	var r := WorldLayout.airfield_rect()
	var G := Vector2(1, 0)
	var gz := r.position.y
	while gz < r.end.y:
		var d := minf(100.0, r.end.y - gz)
		ctx_at(r.get_center().x, gz + d * 0.5).ground.flat(Vector3(r.get_center().x, 0.008, gz + d * 0.5), r.size.x, d, Color(0.22, 0.28, 0.15), 0.0, G)
		gz += d
	var rx := WorldLayout.RUNWAY_X
	var hw := WorldLayout.RUNWAY_HW
	var z0 := WorldLayout.RUNWAY_Z0
	var z1 := WorldLayout.RUNWAY_Z1
	var z := z0
	while z < z1:
		var L := minf(60.0, z1 - z)
		var c := ctx_at(rx, z + L * 0.5)
		c.ground.flat(Vector3(rx, 0.02, z + L * 0.5), hw * 2.0, L, Color(0.16, 0.16, 0.17), 0.0, G)
		c.props.flat(Vector3(rx, 0.03, z + L * 0.5), 0.9, L * 0.5, Color(0.85, 0.85, 0.82))
		for s in [-1.0, 1.0]:
			c.glow.box(Vector3(rx + s * (hw + 1.0), 0.45, z + L * 0.5), Vector3(0.22, 0.12, 0.22), Color(1.0, 0.95, 0.75), 0.0, Vector2(Props.K_NIGHT, 0))
		z += 60.0
	# Threshold bars, runway numbers and green/red end lights at both ends.
	for e in [[z1 - 6.0, "36", 0.0, Color(0.3, 1.0, 0.4)], [z0 + 6.0, "18", PI, Color(1.0, 0.25, 0.2)]]:
		var ez := float(e[0])
		var ec := ctx_at(rx, ez)
		var k := -hw + 2.5
		while k < hw - 1.5:
			ec.props.flat(Vector3(rx + k, 0.03, ez), 1.2, 9.0, Color(0.88, 0.88, 0.85))
			k += 2.6
		var inward := -1.0 if ez > (z0 + z1) * 0.5 else 1.0
		ec.label(Vector3(rx, 0.04, ez + inward * 14.0), str(e[1]), 240, Color(0.9, 0.9, 0.86), float(e[2]), 260.0, 0.04, {"pitch": -PI * 0.5})
		var edge_z := z1 if inward < 0.0 else z0
		var x := -hw
		while x <= hw + 0.1:
			ec.glow.box(Vector3(rx + x, 0.4, edge_z), Vector3(0.3, 0.15, 0.3), e[3], 0.0, Vector2(Props.K_NIGHT, 0))
			x += 4.0
		# Approach strobes out past the end, as far as the field goes.
		for q in 3:
			var sz2 := edge_z - inward * (6.0 + float(q) * 5.0)
			if sz2 > r.position.y + 1.0 and sz2 < r.end.y - 1.0:
				ec.glow.box(Vector3(rx, 0.6, sz2), Vector3(0.4, 0.3, 0.4), Color(1.0, 1.0, 1.0), 0.0, Vector2(Props.K_BLINK, float(q) * 0.3))
	# Apron and taxiway on the side with more grass.
	var east := (r.end.x - (rx + hw)) >= ((rx - hw) - r.position.x)
	var side := 1.0 if east else -1.0
	var ax := rx + side * (hw + 30.0)
	var az := (z0 + z1) * 0.5
	var ac := ctx_at(ax, az)
	ac.ground.flat(Vector3(ax, 0.02, az), 40.0, 120.0, Color(0.2, 0.2, 0.21), 0.0, G)
	ac.ground.flat(Vector3(rx + side * (hw + 5.0), 0.02, az), 10.0, 14.0, Color(0.18, 0.18, 0.19), 0.0, G)
	ac.props.flat(Vector3((rx + ax) * 0.5 + side * 2.0, 0.03, az), 30.0, 0.3, Color(0.85, 0.7, 0.15))
	var pre := str({"chicago": "chi"}.get(WorldLayout.region, WorldLayout.region))
	var face := PI * 0.5 * side # nose toward the runway
	for q in 2:
		var pz := az - 40.0 + float(q) * 70.0
		airfield_planes.append({"slot": "%s_%s" % [pre, ["a", "b"][q]], "model": "skyhawk", "pos": Vector3(ax, 0.0, pz), "yaw": face})
		for t in [-4.0, 4.0]:
			ac.props.box(Vector3(ax + side * 2.0, 0.2, pz + t), Vector3(0.3, 0.4, 0.3), Color(0.85, 0.75, 0.1))
	# Windsock on a pole at the apron edge, and a beacon tower.
	var wp := Vector3(ax + side * 24.0, 0.0, az - 70.0)
	ac.props.box(wp + Vector3(0, 3.0, 0), Vector3(0.15, 6.0, 0.15), Color(0.6, 0.6, 0.62))
	ac.props.cyl(wp + Vector3(1.4, 5.8, 0), 0.25, 0.5, 2.6, Color(1.0, 0.45, 0.1), 8)
	ac.solid(wp + Vector3(0, 3.0, 0), Vector3(0.3, 6.0, 0.3))
	var bp := Vector3(ax + side * 24.0, 0.0, az + 70.0)
	for lx in [-1.0, 1.0]:
		for lz in [-1.0, 1.0]:
			ac.props.box(bp + Vector3(lx, 6.0, lz), Vector3(0.2, 12.0, 0.2), Color(0.55, 0.55, 0.58))
	ac.props.box(bp + Vector3(0, 12.2, 0), Vector3(2.6, 0.3, 2.6), Color(0.4, 0.4, 0.42))
	ac.glow.sphere(bp + Vector3(0, 12.9, 0), 0.5, Color(0.3, 1.0, 0.4), 6, 3, Vector2(Props.K_BLINK, 0))
	ac.glow.sphere(bp + Vector3(0, 12.9, 0), 0.45, Color(1.0, 1.0, 0.9), 6, 3, Vector2(Props.K_BLINK, 0.5))
	ac.solid(bp + Vector3(0, 6.0, 0), Vector3(2.4, 12.0, 2.4))
	Props.light_pool(ac, Vector3(ax, 0, az - 30.0), 12.0, Color(1.0, 0.9, 0.7))
	Props.light_pool(ac, Vector3(ax, 0, az + 30.0), 12.0, Color(1.0, 0.9, 0.7))
	ac.label(Vector3(ax - side * 19.5, 0.04, az), str(WorldLayout.DISTRICT_NAMES.get("airfield", "AIRFIELD")).to_upper(), 120, Color(0.95, 0.85, 0.3), face, 200.0, 0.02, {"pitch": -PI * 0.5})


## An edge-of-map wall (tag "bounds"), with gaps wherever a pier crosses it.
func _bounds_wall(c: BuildCtx, center: Vector3, size: Vector3, gaps: Array) -> void:
	var pieces: Array = [Rect2(center.x - size.x * 0.5, center.z - size.z * 0.5, size.x, size.z)]
	for g in gaps:
		var gr: Rect2 = g
		var nxt: Array = []
		for pc in pieces:
			var pr: Rect2 = pc
			if not pr.intersects(gr):
				nxt.append(pr)
			elif pr.size.x < pr.size.y: # runs along z
				if gr.position.y > pr.position.y:
					nxt.append(Rect2(pr.position.x, pr.position.y, pr.size.x, gr.position.y - pr.position.y))
				if gr.end.y < pr.end.y:
					nxt.append(Rect2(pr.position.x, gr.end.y, pr.size.x, pr.end.y - gr.end.y))
			else: # runs along x
				if gr.position.x > pr.position.x:
					nxt.append(Rect2(pr.position.x, pr.position.y, gr.position.x - pr.position.x, pr.size.y))
				if gr.end.x < pr.end.x:
					nxt.append(Rect2(gr.end.x, pr.position.y, pr.end.x - gr.end.x, pr.size.y))
		pieces = nxt
	for pc in pieces:
		var pr2: Rect2 = pc
		c.solid(Vector3(pr2.get_center().x, center.y, pr2.get_center().y), Vector3(pr2.size.x, size.y, pr2.size.y), 0.0, "bounds")


## A plank pier over the mud or the sand and out over the water, with
## railings down both sides and across the far end (the near end is open).
func _walk_pier(r: Rect2, reg: String) -> void:
	var along_x := r.size.x >= r.size.y
	var c := ctx_at(r.get_center().x, r.get_center().y)
	var wood := Color(0.42, 0.33, 0.23)
	# On the island the old dock already covers the seaward part.
	var vis_r := r
	if reg == "island":
		vis_r = Rect2(r.position.x, r.position.y, 24.0, r.size.y)
	c.props.box(Vector3(vis_r.get_center().x, -0.05, vis_r.get_center().y), Vector3(vis_r.size.x, 0.3, vis_r.size.y), wood, 0.0, Vector2.ZERO, 61)
	c.solid(Vector3(r.get_center().x, -0.2, r.get_center().y), Vector3(r.size.x, 0.6, r.size.y))
	var L := r.size.x if along_x else r.size.y
	var far_x := r.position.x if reg == "redmont" else r.end.x # which end is out at sea
	for sd in [-1.0, 1.0]:
		var off := float(sd) * ((r.size.y if along_x else r.size.x) * 0.5)
		if along_x:
			c.solid(Vector3(r.get_center().x, 1.2, r.get_center().y + off), Vector3(L, 2.4, 0.3))
			c.props.box(Vector3(r.get_center().x, 1.0, r.get_center().y + off), Vector3(L, 0.08, 0.08), Color(0.3, 0.26, 0.2))
			var k := 0.0
			while k < L:
				c.props.box(Vector3(r.position.x + k, 0.5, r.get_center().y + off), Vector3(0.12, 1.0, 0.12), Color(0.3, 0.26, 0.2))
				k += 4.0
	c.solid(Vector3(far_x, 1.2, r.get_center().y), Vector3(0.3, 2.4, r.size.y))
	c.props.box(Vector3(far_x, 1.0, r.get_center().y), Vector3(0.08, 0.08, r.size.y), Color(0.3, 0.26, 0.2))
	for k2 in int(L / 10.0):
		Props.light_pool(c, Vector3(r.position.x + 5.0 + float(k2) * 10.0, 0.1, r.get_center().y), 4.0, Color(1.0, 0.85, 0.6))
	if reg == "redmont":
		# The pier keeps getting longer, because the water keeps leaving.
		var sp := Vector3(r.end.x - 4.0, 0, r.position.y - 0.3)
		c.props.box(sp + Vector3(0, 1.3, 0), Vector3(2.6, 1.2, 0.08), Color(0.95, 0.95, 0.92))
		c.label(sp + Vector3(0, 1.45, -0.05), "RESERVOIR PIER", 30, Color(0.1, 0.3, 0.6), PI, 40.0, 0.01)
		c.label(sp + Vector3(0, 1.15, -0.05), "EXTENDED 2026 · 2027 · 2028 · 2029", 16, Color(0.25, 0.25, 0.27), PI, 30.0, 0.01)


## Edge of a non-NYC map: walls, water (Chicago's lake, the Atlantic off
## Port Ramsey), hills or suburbs on whichever horizons no other map fills,
## and the travel gates with their highway signs.
func _region_edges() -> void:
	var reg := WorldLayout.region
	var x0 := -WorldLayout.WORLD_X
	var x1 := WorldLayout.WORLD_XE
	var z0 := WorldLayout.WORLD_ZN
	var z1 := WorldLayout.BEACH_Z1
	var root_c := ctx_at(0, 0)
	# Walkable piers out to the water get a gap in the wall (Boats.PIERS).
	var gaps: Array = Boats.PIERS.get(reg, [])
	_bounds_wall(root_c, Vector3(x0 - 1.0, 10.0, (z0 + z1) * 0.5), Vector3(2.0, 40.0, z1 - z0 + 20.0), gaps)
	_bounds_wall(root_c, Vector3(x1 + 1.0, 10.0, (z0 + z1) * 0.5), Vector3(2.0, 40.0, z1 - z0 + 20.0), gaps)
	_bounds_wall(root_c, Vector3((x0 + x1) * 0.5, 10.0, z0 - 1.0), Vector3(x1 - x0 + 20.0, 40.0, 2.0), gaps)
	_bounds_wall(root_c, Vector3((x0 + x1) * 0.5, 10.0, z1 + 1.0), Vector3(x1 - x0 + 20.0, 40.0, 2.0), gaps)
	for pr in gaps:
		_walk_pier(pr as Rect2, reg)
	var grass := Color(0.26, 0.26, 0.27) if reg == "chicago" else Color(0.2, 0.26, 0.13)
	var wb := MeshBatch.new()
	match reg:
		"chicago":
			# Lake Michigan to the east, as far as you can see.
			wb.flat(Vector3(x1 + 1500.0, -0.4, (z0 + z1) * 0.5), 3000.0, 6000.0, Color(0.1, 0.22, 0.32))
		"port":
			var sea: Rect2 = Regions.SEA["port"]
			wb.flat(Vector3(sea.position.x + 1500.0, -0.4, 0.0), 3000.0, 6000.0, Color(0.09, 0.19, 0.28))
		"island":
			# The Atlantic, all the way round.
			wb.flat(Vector3(0.0, -0.4, 0.0), 7000.0, 7000.0, Color(0.08, 0.18, 0.27))
			for s4 in 4:
				var e := [Rect2(x0 - 34.0, z0 - 34.0, x1 - x0 + 68.0, 34.0), Rect2(x0 - 34.0, z1, x1 - x0 + 68.0, 34.0), Rect2(x0 - 34.0, z0, 34.0, z1 - z0), Rect2(x1, z0, 34.0, z1 - z0)][s4] as Rect2
				landmark_far.props.flat(Vector3(e.get_center().x, 0.004, e.get_center().y), e.size.x, e.size.y, Color(0.78, 0.7, 0.5), 0.0, Vector2(1, 0))
		"redmont":
			# The reservoir to the west, past a strip of cracked mud where the
			# water used to be.
			var res: Rect2 = Regions.SEA["redmont"]
			wb.flat(Vector3(res.end.x - 1500.0, -0.4, 0.0), 3000.0, 6000.0, Color(0.1, 0.2, 0.27))
			var mud_w := res.end.x - x0
			landmark_far.props.flat(Vector3(x0 + mud_w * 0.5, 0.006, (z0 + z1) * 0.5), absf(mud_w), z1 - z0 + 200.0, Color(0.4, 0.34, 0.25), 0.0, Vector2(1, 0))
			var mr := RandomNumberGenerator.new()
			mr.seed = 77
			for k in 60:
				var mx := mr.randf_range(res.end.x + 4.0, x0 - 4.0)
				var mz := mr.randf_range(z0, z1)
				landmark_far.props.flat(Vector3(mx, 0.01, mz), mr.randf_range(0.2, 0.5), mr.randf_range(6.0, 24.0), Color(0.3, 0.25, 0.18), mr.randf() * PI, Vector2(1, 0))
		"gary":
			# Lake Michigan along the north shore, out past the furnaces.
			var lake: Rect2 = Regions.SEA["gary"]
			wb.flat(Vector3(lake.get_center().x - 1500.0, -0.4, lake.end.y - 1500.0), lake.size.x + 3000.0, 3000.0, Color(0.1, 0.21, 0.3))
	wb.commit(_water_parent_holder(), Mats.water, 0.0, "Water")
	var far := BuildCtx.new()
	var r2 := RandomNumberGenerator.new()
	r2.seed = WorldLayout.SEED + 7
	var a := 0.0
	while a < TAU:
		var dist := r2.randf_range(2200.0, 2800.0)
		var cx := (x0 + x1) * 0.5 + cos(a) * dist
		var cz := (z0 + z1) * 0.5 + sin(a) * dist
		var skip := false
		match reg:
			"chicago":
				skip = cx > x1 + 200.0 or cos(a) < -0.6 # the lake east, Gary west
			"highway":
				skip = true # cities and towns on every side now
			"township":
				skip = cos(a) > 0.3 # I-80 is east
			"port":
				skip = cos(a) > 0.2 or cos(a) < -0.5 # ocean east, I-80 west
			"gary":
				skip = cos(a) > -0.4 or sin(a) < -0.3 # Chicago east, the lake north, the township south
			"redmont":
				skip = cos(a) < -0.3 or sin(a) > 0.4 # the reservoir west, Port Ramsey south
			"island":
				skip = true # open ocean
		if skip:
			a += 0.08
			continue
		if reg == "chicago":
			var w := r2.randf_range(30.0, 70.0)
			_facade_box(far, Rect2(cx, cz, w, w), 0.0, r2.randf_range(12.0, 60.0), [1, 2, 8][r2.randi() % 3], _palette("brick").darkened(0.35), r2.randf_range(1, 90))
		else:
			far.props.box(Vector3(cx, r2.randf_range(10.0, 40.0), cz), Vector3(r2.randf_range(200.0, 500.0), r2.randf_range(40.0, 110.0), r2.randf_range(200.0, 400.0)), Color(0.16, 0.22, 0.12), a)
		a += 0.08
	far_skyline = far
	_gate_signs(grass)


## Green highway signs and a ramp of asphalt at every travel gate.
func _gate_signs(_grass: Color) -> void:
	for gid in Regions.gates(WorldLayout.region).keys():
		var g: Dictionary = Regions.gates(WorldLayout.region)[gid]
		var gp: Array = g["pos"]
		var p := Vector3(float(gp[0]), 0.0, float(gp[1]))
		var c := ctx_at(p.x, p.z)
		var yaw := float(g.get("yaw", 0.0))
		c.ground.flat(p, 16.0, 60.0, Color(0.15, 0.15, 0.16), yaw, Vector2(1, 0))
		var side := Vector3(cos(yaw), 0, -sin(yaw))
		for s in [-1.0, 1.0]:
			c.props.box(p + side * (9.0 * s) + Vector3(0, 3.5, 0), Vector3(0.3, 7.0, 0.3), Color(0.35, 0.35, 0.37))
		c.props.box(p + Vector3(0, 7.2, 0), Vector3(18.0, 2.4, 0.2), Color(0.05, 0.35, 0.2), yaw)
		c.label(p + Vector3(0, 7.2, 0) + Vector3(sin(yaw), 0, cos(yaw)) * 0.15, str(g["sign"]), 96, Color(0.95, 0.95, 0.95), yaw, 600.0, 0.02)
		c.label(p + Vector3(0, 7.2, 0) - Vector3(sin(yaw), 0, cos(yaw)) * 0.15, str(g["sign"]), 96, Color(0.95, 0.95, 0.95), yaw + PI, 600.0, 0.02)
		_gate_stub(p, yaw)


## A gate past the end of the street grid gets a lit two-lane road from the
## grid's edge out through the gate, to meet the county road beyond.
func _gate_stub(p: Vector3, yaw: float) -> void:
	var inward := Vector3(sin(yaw), 0, cos(yaw))
	var d := 0.0
	while d < 700.0 and not WorldLayout.in_bounds(p.x + inward.x * d, p.z + inward.z * d):
		d += 2.0
	if d < 4.0:
		return
	var a := p + inward * d
	var b := p - inward * 30.0
	var L := a.distance_to(b)
	var steps := int(ceil(L / 40.0))
	for k in steps:
		var t0 := float(k) / float(steps)
		var t1 := float(k + 1) / float(steps)
		var q0 := a.lerp(b, t0)
		var q1 := a.lerp(b, t1)
		var qm := (q0 + q1) * 0.5
		var seg := q0.distance_to(q1)
		var c := ctx_at(qm.x, qm.z)
		c.ground.flat(Vector3(qm.x, 0.015, qm.z), 13.0, seg + 0.2, Color(0.09, 0.09, 0.1), yaw, Vector2(1, 0))
		c.props.flat(Vector3(qm.x, 0.025, qm.z), 0.35, seg * 0.5, Color(0.8, 0.62, 0.15), yaw)
		for s in [-1.0, 1.0]:
			var side: Vector3 = Vector3(cos(yaw), 0, -sin(yaw)) * (6.2 * float(s))
			c.props.flat(Vector3(qm.x, 0.025, qm.z) + side, 0.2, seg, Color(0.75, 0.75, 0.7), yaw)
		if k % 2 == 0:
			var lp := qm + Vector3(cos(yaw), 0, -sin(yaw)) * (7.6 * (1.0 if k % 4 == 0 else -1.0))
			street_lamp_pair(lp.x, lp.z, yaw + (-PI * 0.5 if k % 4 == 0 else PI * 0.5))


# ------------------------------------------------------- the world between
## The country between the cities: patchwork fields over every bit of land
## in the whole world's airspace (this map's and its neighbours') that no
## city covers, so from anywhere you see farmland run on to the next skyline.
func _fill_country() -> void:
	var here := WorldLayout.region
	var crops := [Color(0.3, 0.34, 0.13), Color(0.4, 0.36, 0.16), Color(0.23, 0.29, 0.12), Color(0.44, 0.39, 0.23), Color(0.19, 0.25, 0.1), Color(0.34, 0.31, 0.2)]
	var burbs := [Color(0.3, 0.32, 0.22), Color(0.36, 0.36, 0.3), Color(0.26, 0.3, 0.18), Color(0.4, 0.38, 0.3)]
	var T := 200.0
	var fc := landmark_far
	var my_city: Rect2 = Regions.CITY.get(here, Rect2())
	var far_water := MeshBatch.new()
	for reg in Regions.SKY.keys():
		var rs: Rect2 = Regions.SKY[reg]
		var r2 := RandomNumberGenerator.new()
		r2.seed = hash(str(reg)) + 31
		var sea: Rect2 = Regions.SEA.get(str(reg), Rect2())
		var sea_here := Rect2(Regions.to_local(here, Regions.to_world(str(reg), sea.position)), sea.size)
		if sea.size.x > 0.0 and str(reg) != here:
			# Someone else's lake or ocean, seen from here.
			var sv := sea_here.intersection(Rect2(Regions.to_local(here, Regions.to_world(str(reg), rs.position)), rs.size))
			if sv.size.x > 0.0:
				far_water.flat(Vector3(sv.get_center().x, -0.4, sv.get_center().y), sv.size.x, sv.size.y, Color(0.08, 0.17, 0.25))
		var gz := rs.position.y
		while gz < rs.end.y - 1.0:
			var gx := rs.position.x
			while gx < rs.end.x - 1.0:
				var tw := minf(T, rs.end.x - gx)
				var td := minf(T, rs.end.y - gz)
				var tile_r := Rect2(gx, gz, tw, td) # local to `reg`
				var roll := r2.randf()
				var pick := r2.randi()
				var vertical := r2.randf() < 0.5
				var n := 2 + r2.randi() % 2
				# I-80's own farm blocks are only built on its own map; from the
				# cities it's just more country.
				var country := Regions.is_country(str(reg), tile_r.get_center()) or (str(reg) == "highway" and here != "highway")
				if country:
					# Into this map's coordinates.
					var o := Regions.to_local(here, Regions.to_world(str(reg), tile_r.position))
					var tile := Rect2(o, tile_r.size)
					var pal: Array = burbs if str(reg) == "chicago" else crops
					var pieces: Array = [tile]
					if str(reg) == here and my_city.intersects(tile):
						pieces = _minus_all(pieces, my_city)
					if sea.size.x > 0.0 and sea_here.intersects(tile):
						pieces = _minus_all(pieces, sea_here)
					if pieces.size() != 1 or (pieces[0] as Rect2) != tile:
						for piece in pieces:
							var pr: Rect2 = piece
							if pr.size.x > 2.0 and pr.size.y > 2.0:
								fc.props.flat(Vector3(pr.get_center().x, 0.005, pr.get_center().y), pr.size.x - 1.0, pr.size.y - 1.0, pal[pick % pal.size()], 0.0, Vector2(1, 0))
					else:
						var w := (tile.size.x if vertical else tile.size.y) / float(n)
						for k in n:
							var col: Color = pal[(pick + k * 7) % pal.size()]
							if vertical:
								fc.props.flat(Vector3(tile.position.x + w * (float(k) + 0.5), 0.005, tile.get_center().y), w - 1.5, tile.size.y - 1.5, col, 0.0, Vector2(1, 0))
							else:
								fc.props.flat(Vector3(tile.get_center().x, 0.005, tile.position.y + w * (float(k) + 0.5)), tile.size.x - 1.5, w - 1.5, col, 0.0, Vector2(1, 0))
						# Now and then a farmhouse and silo, or a wood lot.
						var c := tile.get_center()
						if roll < 0.16:
							fc.props.box(Vector3(c.x - 30.0, 3.5, c.y), Vector3(12.0, 7.0, 18.0), Color(0.55, 0.16, 0.1))
							fc.props.cyl(Vector3(c.x - 18.0, 7.5, c.y), 3.0, 3.0, 15.0, Color(0.7, 0.7, 0.68), 10)
						elif roll < 0.3:
							for t in 7:
								fc.props.box(Vector3(c.x + r2.randf_range(-24.0, 24.0), 5.0, c.y + r2.randf_range(-24.0, 24.0)), Vector3(7.0, 10.0, 7.0), Color(0.12, 0.2, 0.09))
				gx += T
			gz += T
	far_water.commit(_water_parent_holder(), Mats.water, 0.0, "FarWater")
	# The interstate itself, seen from the cities: a ribbon of asphalt north
	# to south through the country, so you can follow it from the air.
	if here != "highway":
		var hs: Rect2 = Regions.SKY["highway"]
		var a := Regions.to_local(here, Regions.to_world("highway", Vector2(0.0, hs.position.y)))
		fc.props.flat(Vector3(a.x, 0.02, a.y + hs.size.y * 0.5), 14.0, hs.size.y, Color(0.14, 0.14, 0.15), 0.0, Vector2(1, 0))
		fc.props.flat(Vector3(a.x, 0.03, a.y + hs.size.y * 0.5), 0.5, hs.size.y, Color(0.75, 0.62, 0.2))
	# County roads and on-ramps: asphalt from every travel gate to the gate it
	# leads to, so from the air you can follow the road to the next town.
	var done := {}
	for ra in Regions.GATES.keys():
		for gid in Regions.GATES[ra].keys():
			var g: Dictionary = Regions.GATES[ra][gid]
			var to: Array = g["to"]
			var key := [str(gid), str(to[1])]
			key.sort()
			if done.has(str(key)):
				continue
			done[str(key)] = true
			var gb: Dictionary = (Regions.GATES.get(str(to[0]), {}) as Dictionary).get(str(to[1]), {})
			if gb.is_empty():
				continue
			var pa: Array = g["pos"]
			var pb: Array = gb["pos"]
			var la := Regions.to_local(here, Regions.to_world(str(ra), Vector2(float(pa[0]), float(pa[1]))))
			var lb := Regions.to_local(here, Regions.to_world(str(to[0]), Vector2(float(pb[0]), float(pb[1]))))
			var horiz := absf(lb.x - la.x) > absf(lb.y - la.y)
			var rr := Rect2(la, Vector2.ZERO).expand(lb).grow_individual(0.0 if horiz else 6.5, 6.5 if horiz else 0.0, 0.0 if horiz else 6.5, 6.5 if horiz else 0.0)
			for piece in _rect_minus(rr, my_city.grow(-2.0)):
				var pr: Rect2 = piece
				if pr.size.x < 1.0 or pr.size.y < 1.0:
					continue
				fc.props.flat(Vector3(pr.get_center().x, 0.02, pr.get_center().y), pr.size.x, pr.size.y, Color(0.12, 0.12, 0.13), 0.0, Vector2(1, 0))
				if horiz:
					fc.props.flat(Vector3(pr.get_center().x, 0.03, pr.get_center().y), pr.size.x, 0.35, Color(0.75, 0.62, 0.2))
				else:
					fc.props.flat(Vector3(pr.get_center().x, 0.03, pr.get_center().y), 0.35, pr.size.y, Color(0.75, 0.62, 0.2))


func _minus_all(pieces: Array, c: Rect2) -> Array:
	var out: Array = []
	for p in pieces:
		out.append_array(_rect_minus(p, c))
	return out


## The parts of rectangle `r` outside rectangle `c` (up to four pieces).
func _rect_minus(r: Rect2, c: Rect2) -> Array:
	var out: Array = []
	var i := r.intersection(c)
	if i.size.x <= 0.0 or i.size.y <= 0.0:
		return [r]
	if i.position.x > r.position.x:
		out.append(Rect2(r.position.x, r.position.y, i.position.x - r.position.x, r.size.y))
	if i.end.x < r.end.x:
		out.append(Rect2(i.end.x, r.position.y, r.end.x - i.end.x, r.size.y))
	if i.position.y > r.position.y:
		out.append(Rect2(i.position.x, r.position.y, i.size.x, i.position.y - r.position.y))
	if i.end.y < r.end.y:
		out.append(Rect2(i.position.x, i.end.y, i.size.x, r.end.y - i.end.y))
	return out


## The other cities, where they really are: a skyline of lit towers on the
## horizon (only drawn at long range, so it costs a handful of boxes).
func _neighbour_skylines() -> void:
	for reg in Regions.SKYLINE.keys():
		if str(reg) == WorldLayout.region:
			continue
		var S: Dictionary = Regions.SKYLINE[reg]
		var cw := Regions.to_world(str(reg), S["c"])
		var c := Regions.to_local(WorldLayout.region, cw)
		var r2 := RandomNumberGenerator.new()
		r2.seed = hash(str(reg)) + WorldLayout.SEED
		var spread := float(S["spread"])
		for i in int(S["n"]):
			var ang := r2.randf() * TAU
			var d := sqrt(r2.randf()) * spread
			var px := c.x + cos(ang) * d
			var pz := c.y + sin(ang) * d * 0.7
			# Taller in the middle, like any downtown.
			var h := float(S["h"]) * lerpf(1.0, 0.2, d / spread) * r2.randf_range(0.45, 1.0)
			var w := r2.randf_range(28.0, 60.0)
			_facade_box(landmark_far, Rect2(px - w * 0.5, pz - w * 0.5, w, w * r2.randf_range(0.7, 1.3)), 0.0, maxf(18.0, h), [2, 3, 4, 8][r2.randi() % 4], Color(0.32, 0.33, 0.36).lerp(Color(0.45, 0.3, 0.25), r2.randf()), r2.randf_range(1.0, 90.0))
			# Lit floors at night, so the next city glows on the horizon.
			var fy := 8.0
			while fy < h - 4.0:
				if r2.randf() < 0.45:
					landmark_far.glow.box(Vector3(px, fy, pz), Vector3(w + 0.6, 1.2, w * 0.9), Color(1.0, 0.82, 0.55).lerp(Color(0.7, 0.85, 1.0), r2.randf() * 0.5), 0.0, Vector2(Props.K_NIGHT, 0))
				fy += r2.randf_range(6.0, 14.0)
			if h > float(S["h"]) * 0.7:
				Props.place(landmark_far, "beacon", Vector3(px, maxf(18.0, h) + 0.5, pz))
		# The township's plant stacks and the port's cranes and lighthouse are
		# how you find them from the air.
		if bool(S.get("stacks", false)):
			for st in TW_STACKS:
				var sp := Regions.to_local(WorldLayout.region, Regions.to_world(str(reg), st))
				_smokestack(landmark_far, Vector3(sp.x, 0, sp.y))
		if bool(S.get("cranes", false)):
			for cr in PT_CRANES:
				var cp := Regions.to_local(WorldLayout.region, Regions.to_world(str(reg), cr))
				Props.place(landmark_far, "crane", Vector3(cp.x - 14.0, 0, cp.y), PI * 0.5, 1.6)
			var lh := Regions.to_local(WorldLayout.region, Regions.to_world(str(reg), PT_LIGHTHOUSE))
			_lighthouse_tower(landmark_far, Vector3(lh.x, 0, lh.y), 28.0)
		if bool(S.get("furnaces", false)):
			for fu in GY_FURNACES:
				var fp := Regions.to_local(WorldLayout.region, Regions.to_world(str(reg), fu))
				_blast_furnace(landmark_far, Vector3(fp.x, 0, fp.y))
		if bool(S.get("isle", false)):
			# From the coast: a low green island on the horizon, a white house on it.
			var ic := Regions.to_local(WorldLayout.region, Regions.to_world(str(reg), Vector2.ZERO))
			landmark_far.props.flat(Vector3(ic.x, 0.02, ic.y), 720.0, 720.0, Color(0.24, 0.32, 0.16), 0.0, Vector2(1, 0))
			landmark_far.props.sphere(Vector3(ic.x + 200.0, -40.0, ic.y + 210.0), 95.0, Color(0.2, 0.3, 0.14), 10, 5)
		if bool(S.get("campus", false)):
			var hp := Regions.to_local(WorldLayout.region, Regions.to_world(str(reg), RM_HQ))
			_facade_box(landmark_far, Rect2(hp.x - 40.0, hp.y - 37.0, 80.0, 74.0), 0.0, 96.0, 7, Color(0.2, 0.26, 0.32), 17.0)
			_hq_crown(landmark_far, Vector3(hp.x, 96.0, hp.y))



# ------------------------------------------------------------- small towns
## A plant stack: banded concrete, aircraft-warning lights, a lazy plume.
func _smokestack(c: BuildCtx, p: Vector3) -> void:
	c.props.cyl(p + Vector3(0, 36.0, 0), 2.6, 4.2, 72.0, Color(0.55, 0.53, 0.5), 12)
	for k in 3:
		c.props.cyl(p + Vector3(0, 62.0 + float(k) * 3.4, 0), 2.75 - float(k) * 0.05, 2.8 - float(k) * 0.05, 1.6, Color(0.7, 0.18, 0.12) if k % 2 == 0 else Color(0.85, 0.85, 0.82), 12)
	c.glow.sphere(p + Vector3(0, 72.6, 0), 0.6, Color(1.0, 0.12, 0.1), 6, 3, Vector2(Props.K_BLINK, 0))
	c.glow.sphere(p + Vector3(2.7, 40.0, 0), 0.4, Color(1.0, 0.12, 0.1), 6, 3, Vector2(Props.K_BLINK, 0.5))
	for k in 4:
		c.props.sphere(p + Vector3(float(k) * 3.5, 76.0 + float(k) * 2.5, float(k) * 1.2), 3.2 + float(k) * 1.4, Color(0.62, 0.62, 0.6), 7, 4, Vector2.ZERO, 0.7)


## A white lighthouse with a red band and a lantern that sweeps at night.
func _lighthouse_tower(c: BuildCtx, p: Vector3, h: float) -> void:
	c.props.cyl(p + Vector3(0, 1.0, 0), 6.5, 7.5, 2.0, Color(0.32, 0.3, 0.28), 12)
	c.props.cyl(p + Vector3(0, 2.0 + h * 0.5, 0), 3.0, 4.6, h, Color(0.92, 0.92, 0.9), 14)
	c.props.cyl(p + Vector3(0, 2.0 + h * 0.62, 0), 3.5, 3.75, h * 0.16, Color(0.75, 0.12, 0.1), 14)
	c.props.cyl(p + Vector3(0, h + 2.4, 0), 4.0, 4.0, 0.5, Color(0.15, 0.15, 0.16), 14)
	c.glow.cyl(p + Vector3(0, h + 4.0, 0), 2.4, 2.4, 2.8, Color(1.0, 0.92, 0.6), 10, Vector2(Props.K_NIGHT, 0))
	c.glow.sphere(p + Vector3(0, h + 4.0, 0), 1.6, Color(1.0, 1.0, 0.85), 8, 4, Vector2(Props.K_BLINK, 0))
	c.props.cyl(p + Vector3(0, h + 6.2, 0), 0.4, 2.8, 1.8, Color(0.12, 0.12, 0.13), 10)


## The E Corp plant: generator halls, tanks, the stacks, a retention pond
## that glows a little at night, and the office with its safety board.
func _plant_block(bi: int, bj: int, r: Rect2) -> void:
	var c := ctx_at(r.get_center().x, r.get_center().y)
	var G := Vector2(1, 0)
	if bi == 2 and bj == 1:
		c.ground.flat(Vector3(r.get_center().x, 0.012, r.get_center().y), r.size.x, r.size.y, Color(0.24, 0.23, 0.22), 0.0, G)
		var hall := Rect2(r.position.x + 4.0, r.end.y - 40.0, r.size.x - 8.0, 34.0)
		_building(hall, 18.0, 5, Color(0.5, 0.5, 0.48), false, 1.0, "industrial", "mech")
		for st in TW_STACKS:
			_smokestack(landmark_far, Vector3(st.x, 0, st.y))
			c.solid(Vector3(st.x, 36.0, st.y), Vector3(7.0, 72.0, 7.0))
		# Pipe rack from the hall to the pond next door.
		for k in 6:
			var px := r.position.x + 6.0 + float(k) * 4.0
			c.props.box(Vector3(px, 3.0, r.end.y - 44.0), Vector3(0.3, 6.0, 0.3), Color(0.35, 0.35, 0.37))
		c.props.cyl(Vector3(r.position.x + 16.0, 6.2, r.end.y - 44.0), 0.6, 0.6, 24.0, Color(0.55, 0.5, 0.2), 8)
		Props.fence_line(c, Vector3(r.position.x, 0, r.end.y), Vector3(r.end.x, 0, r.end.y), 3.0)
		Props.light_pool(c, Vector3(r.get_center().x, 0, r.end.y - 4.0), 10.0, Color(1.0, 0.8, 0.5))
		return
	if bi == 1 and bj == 2:
		# Retention Pond 3. Nobody is supposed to call it that out loud.
		c.ground.flat(Vector3(r.get_center().x, 0.012, r.get_center().y), r.size.x, r.size.y, Color(0.2, 0.22, 0.14), 0.0, G)
		var pond := r.grow(-12.0)
		c.ground.flat(Vector3(pond.get_center().x, 0.03, pond.get_center().y), pond.size.x, pond.size.y, Color(0.36, 0.42, 0.16), 0.0, G)
		c.ground.flat(Vector3(pond.get_center().x, 0.035, pond.get_center().y), pond.size.x - 8.0, pond.size.y - 8.0, Color(0.42, 0.5, 0.14), 0.0, G)
		c.glow.box(Vector3(pond.get_center().x, 0.05, pond.get_center().y), Vector3(pond.size.x - 14.0, 0.01, pond.size.y - 14.0), Color(0.22, 0.4, 0.08), 0.0, Vector2(Props.K_NIGHT, 0))
		for e in [[pond.position, Vector2(pond.end.x, pond.position.y)], [Vector2(pond.end.x, pond.position.y), pond.end], [pond.end, Vector2(pond.position.x, pond.end.y)], [Vector2(pond.position.x, pond.end.y), pond.position]]:
			var ea: Vector2 = e[0]
			var eb: Vector2 = e[1]
			Props.fence_line(c, Vector3(ea.x, 0, ea.y), Vector3(eb.x, 0, eb.y), 2.6)
		for k in 3:
			var sx := pond.position.x + 20.0 + float(k) * 40.0
			c.props.box(Vector3(sx, 1.6, pond.end.y + 0.2), Vector3(2.6, 1.4, 0.06), Color(0.9, 0.85, 0.2))
			c.label(Vector3(sx, 1.75, pond.end.y + 0.25), ["DANGER", "NO SWIMMING", "NO FISHING"][k], 40, Color(0.1, 0.1, 0.1), 0.0, 40.0, 0.01)
			c.label(Vector3(sx, 1.35, pond.end.y + 0.25), "E CORP ENVIRONMENTAL", 18, Color(0.1, 0.1, 0.1), 0.0, 30.0, 0.01)
		c.props.cyl(Vector3(pond.end.x + 4.0, 0.6, pond.position.y + 10.0), 0.7, 0.7, 1.2, Color(0.4, 0.38, 0.3), 8)
		return
	if bi == 3 and bj == 2:
		# Visitor lot in front of the plant office (the office is a landmark).
		c.ground.flat(Vector3(r.get_center().x, 0.014, r.get_center().y), r.size.x, r.size.y, Color(0.13, 0.13, 0.14), 0.0, G)
		var y := r.end.y - 8.0
		var x := r.position.x + 6.0
		while x < r.end.x - 6.0:
			c.props.flat(Vector3(x, 0.02, y), 0.15, 5.0, Color(0.8, 0.8, 0.75))
			if rng.randf() < 0.45:
				var ci := rng.randi() % Props.CAR_COLORS.size()
				Props.place(c, "car_%s_%d" % [["sedan", "suv", "hatch"][rng.randi() % 3], ci], Vector3(x + 1.5, 0, y), 0.0)
				c.solid(Vector3(x + 1.5, 0.8, y), Vector3(1.9, 1.6, 4.6))
			x += 3.0
		var bp := Vector3(r.end.x - 14.0, 0, r.end.y - 2.0)
		c.props.box(bp + Vector3(0, 2.2, 0), Vector3(6.0, 2.6, 0.25), Color(0.1, 0.25, 0.5))
		c.props.box(bp + Vector3(-2.6, 0.5, 0), Vector3(0.2, 1.0, 0.2), Color(0.3, 0.3, 0.3))
		c.props.box(bp + Vector3(2.6, 0.5, 0), Vector3(0.2, 1.0, 0.2), Color(0.3, 0.3, 0.3))
		c.label(bp + Vector3(0, 2.8, 0.15), "DAYS WITHOUT AN INCIDENT", 26, Color(1, 1, 1), 0.0, 50.0, 0.01)
		c.label(bp + Vector3(0, 1.85, 0.15), "0", 90, Color(1.0, 0.3, 0.25), 0.0, 60.0, 0.01)
		c.solid(bp + Vector3(0, 1.8, 0), Vector3(6.0, 3.6, 0.4))
		for fx in [-30.0, -24.0]:
			c.props.box(Vector3(r.end.x + fx, 6.0, r.end.y - 3.0), Vector3(0.15, 12.0, 0.15), Color(0.7, 0.7, 0.72))
		c.props.box(Vector3(r.end.x - 29.0, 11.0, r.end.y - 3.0), Vector3(2.0, 1.2, 0.04), Color(0.7, 0.15, 0.15))
		c.props.box(Vector3(r.end.x - 23.0, 11.0, r.end.y - 3.0), Vector3(2.0, 1.2, 0.04), Color(0.15, 0.3, 0.7))
		Props.light_pool(c, Vector3(r.get_center().x, 0, r.get_center().y + 20.0), 12.0, Color(1.0, 0.85, 0.6))
		return
	_industrial_block(bi, bj, r)
	# Storage tanks behind the halls.
	if rng.randf() < 0.6:
		for k in 2:
			var tp := Vector3(r.position.x + 18.0 + float(k) * 22.0, 0, r.position.y + 14.0)
			if _is_free(bi, bj, Rect2(tp.x - 9.0, tp.z - 9.0, 18.0, 18.0)):
				c.props.cyl(tp + Vector3(0, 5.0, 0), 8.0, 8.0, 10.0, Color(0.78, 0.78, 0.75), 14)
				c.props.cyl(tp + Vector3(0, 10.4, 0), 2.0, 8.0, 1.0, Color(0.7, 0.7, 0.68), 14)
				c.solid(tp + Vector3(0, 5.0, 0), Vector3(15.0, 10.0, 15.0))


## Detached houses on lawns, two rows back to back: siding, gable roofs,
## porches with a light on, driveways with the family car, mailboxes.
func _houses_block(bi: int, bj: int, r: Rect2, d: String) -> void:
	var c0 := ctx_at(r.get_center().x, r.get_center().y)
	var lawn := Color(0.19, 0.27, 0.13) if d == "tw_homes" else Color(0.22, 0.26, 0.16)
	c0.ground.flat(Vector3(r.get_center().x, 0.01, r.get_center().y), r.size.x, r.size.y, lawn, 0.0, Vector2(1, 0))
	var siding := [Color(0.85, 0.84, 0.78), Color(0.8, 0.74, 0.55), Color(0.55, 0.65, 0.72), Color(0.6, 0.66, 0.55), Color(0.62, 0.6, 0.58), Color(0.7, 0.6, 0.48), Color(0.72, 0.5, 0.42)]
	if d == "pt_homes":
		siding = [Color(0.5, 0.5, 0.5), Color(0.62, 0.6, 0.56), Color(0.4, 0.45, 0.5), Color(0.85, 0.84, 0.8), Color(0.35, 0.42, 0.5), Color(0.55, 0.3, 0.25)]
	elif d == "rm_homes":
		# Employee housing: one floor plan, one colour, one hundred times.
		siding = [Color(0.78, 0.76, 0.7), Color(0.78, 0.76, 0.7), Color(0.75, 0.74, 0.7)]
		lawn = Color(0.24, 0.32, 0.15)
	elif d == "rm_shore":
		siding = [Color(0.55, 0.6, 0.62), Color(0.72, 0.7, 0.64), Color(0.45, 0.38, 0.32), Color(0.62, 0.58, 0.5)]
	elif d == "gy_homes":
		# Brick bungalows, some of them long empty.
		siding = [Color(0.45, 0.22, 0.16), Color(0.5, 0.3, 0.22), Color(0.38, 0.2, 0.15), Color(0.55, 0.42, 0.32), Color(0.62, 0.6, 0.55), Color(0.42, 0.36, 0.3)]
		lawn = Color(0.22, 0.25, 0.14)
	var roofs := [Color(0.22, 0.2, 0.2), Color(0.3, 0.22, 0.18), Color(0.2, 0.24, 0.28), Color(0.35, 0.33, 0.3)]
	for face in [-1.0, 1.0]:
		var x := r.position.x + 2.0
		while x < r.end.x - 16.0:
			var lot := minf(rng.randf_range(19.0, 25.0), r.end.x - x)
			if r.end.x - (x + lot) < 16.0:
				lot = r.end.x - x - 1.0
			var hw := minf(lot - 7.0, rng.randf_range(9.0, 13.0))
			var hd := rng.randf_range(8.0, 11.0)
			var setback := rng.randf_range(7.0, 10.0)
			var z0 := (r.position.y + setback) if face < 0.0 else (r.end.y - setback - hd)
			var hx := x + 1.0 + rng.randf_range(0.0, 1.5)
			var hr := Rect2(hx, z0, hw, hd)
			var drive_x := hx + hw + 2.6
			if not _is_free(bi, bj, hr.grow(1.0)):
				x += lot
				continue
			var c := ctx_at(hr.get_center().x, hr.get_center().y)
			var col: Color = siding[rng.randi() % siding.size()]
			var h := 5.4 if rng.randf() < 0.45 else 7.6
			_facade_box(c, hr, 0.0, h, 2, col, -rng.randf_range(1.0, 97.0))
			c.solid(Vector3(hr.get_center().x, h * 0.5, hr.get_center().y), Vector3(hr.size.x, h, hr.size.y))
			buildings.append([hr.position.x, hr.position.y, hr.end.x, hr.end.y, h, d])
			stats["buildings"] = int(stats["buildings"]) + 1
			# Gable roof, ridge parallel to the street.
			var pitch := 0.55
			var rc: Color = roofs[rng.randi() % roofs.size()]
			var half := hd * 0.5
			var slab := half / cos(pitch) + 0.6
			var rise := half * tan(pitch)
			for s in [-1.0, 1.0]:
				var zc: float = hr.get_center().y + float(s) * half * 0.5
				c.props.box_xf(Transform3D(Basis(Vector3.RIGHT, s * pitch), Vector3(hr.get_center().x, h + rise * 0.5, zc)), Vector3(hw + 0.8, 0.22, slab), rc)
			c.props.box(Vector3(hr.get_center().x, h + rise * 0.25, hr.get_center().y), Vector3(hw - 0.1, rise * 0.5, half), col.darkened(0.05))
			if rng.randf() < 0.5:
				c.props.box(Vector3(hr.position.x + hw * 0.75, h + rise * 0.6, hr.get_center().y), Vector3(0.9, rise * 1.2 + 1.0, 0.9), Color(0.4, 0.22, 0.18))
			# Porch, door and porch light.
			var fz := hr.position.y if face < 0.0 else hr.end.y
			var dx := hr.position.x + hw * rng.randf_range(0.3, 0.45)
			c.props.box(Vector3(dx, 0.2, fz + face * 1.2), Vector3(3.6, 0.4, 2.4), Color(0.45, 0.4, 0.34))
			c.props.box(Vector3(dx - 1.6, 1.5, fz + face * 2.2), Vector3(0.14, 2.6, 0.14), Color(0.9, 0.9, 0.88))
			c.props.box(Vector3(dx + 1.6, 1.5, fz + face * 2.2), Vector3(0.14, 2.6, 0.14), Color(0.9, 0.9, 0.88))
			c.props.box(Vector3(dx, 2.85, fz + face * 1.2), Vector3(4.0, 0.15, 2.8), rc)
			c.glow.box(Vector3(dx + 0.9, 2.2, fz + face * 0.08), Vector3(0.18, 0.25, 0.1), Color(1.0, 0.85, 0.55), 0.0, Vector2(Props.K_NIGHT, 0))
			Props.light_pool(c, Vector3(dx, 0, fz + face * 2.5), 3.5, Color(1.0, 0.85, 0.6))
			_gen_door(hr, face, 2, false, d, "apartment", dx)
			# Front walk, driveway, mailbox.
			var edge := r.position.y if face < 0.0 else r.end.y
			var wl := absf(edge - (fz + face * 2.4))
			c.ground.flat(Vector3(dx, 0.02, fz + face * 2.4 + face * wl * 0.5), 1.4, wl, Color(0.5, 0.48, 0.45), 0.0, Vector2(1, 0))
			if drive_x + 1.8 < x + lot:
				var dl := absf(edge - fz) + hd * 0.6
				c.ground.flat(Vector3(drive_x, 0.018, edge - face * dl * 0.5), 3.4, dl, Color(0.36, 0.35, 0.34), 0.0, Vector2(1, 0))
				if rng.randf() < 0.55:
					var ci := rng.randi() % Props.CAR_COLORS.size()
					var typ: String = ["sedan", "suv", "hatch", "van", "suv"][rng.randi() % 5]
					var cz: float = edge - float(face) * (setback * 0.5 + 1.0)
					var yaw := 0.0 if face > 0.0 else PI
					Props.place(c, "car_%s_%d" % [typ, ci], Vector3(drive_x, 0, cz), yaw)
					c.solid(Vector3(drive_x, 0.8, cz), Vector3(1.9, 1.6, 4.6))
					_lootable("car", Vector3(drive_x, 0.8, cz), Vector3(1.0, 0.86, 2.36), 0.0, {"car": typ, "ci": ci, "yaw": yaw})
			Props.place(c, "mailbox", Vector3(dx + 2.2, 0, edge - face * 0.8), 0.0, 0.8)
			# A tree in the yard and a hedge on the lot line.
			if rng.randf() < 0.7:
				var tx := x + lot * rng.randf_range(0.2, 0.8)
				var tz: float = r.position.y + r.size.y * 0.5 - float(face) * 8.0
				Props.place(c, ["tree_a", "tree_b", "pine"][rng.randi() % 3], Vector3(tx, 0, tz), rng.randf() * TAU, rng.randf_range(1.0, 1.4))
				c.solid(Vector3(tx, 1.4, tz), Vector3(0.5, 2.8, 0.5))
			for k in 3:
				Props.place(c, "bush", Vector3(x + 0.6, 0, z0 + float(k) * 3.0), 0.0)
			if rng.randf() < 0.25:
				var shp := Vector3(hr.get_center().x, 0, r.get_center().y - face * 3.0)
				c.props.box(shp + Vector3(0, 1.2, 0), Vector3(3.0, 2.4, 2.4), Color(0.45, 0.35, 0.25))
				c.solid(shp + Vector3(0, 1.2, 0), Vector3(3.0, 2.4, 2.4))
			x += lot
	# A street tree or two and a hydrant at the corners.
	Props.place(c0, "hydrant", Vector3(r.position.x + 1.0, 0, r.position.y + 1.0))
	Props.place(c0, "hydrant", Vector3(r.end.x - 1.0, 0, r.end.y - 1.0))


## The township memorial: a black granite wall with the names of the people
## the leak killed, an eternal flame, flowers, and a bench nobody sits on.
func _township_memorial(r: Rect2) -> void:
	var c := ctx_at(r.get_center().x, r.get_center().y)
	var p := Vector3(r.get_center().x, 0, r.position.y + 22.0)
	c.ground.flat(p + Vector3(0, 0.03, 4.0), 30.0, 16.0, Color(0.42, 0.4, 0.38), 0.0, Vector2(1, 0))
	c.props.box(p + Vector3(0, 1.4, 0), Vector3(22.0, 2.8, 0.6), Color(0.06, 0.06, 0.07))
	c.solid(p + Vector3(0, 1.4, 0), Vector3(22.0, 2.8, 0.8))
	c.label(p + Vector3(0, 2.45, 0.32), "WASHINGTON TOWNSHIP · NEVER FORGET", 30, Color(0.85, 0.8, 0.6), 0.0, 60.0, 0.01)
	var names := ["EDWARD ALDERSON", "EMILY MOSS", "JAMES HARMON", "LILA PRICE", "TOMAS RUIZ", "ANNE KEARNEY", "BILLY KEARNEY", "DORIS WEBB", "MARK ODELL", "RUTH ODELL", "SAM PELL", "JANET COYLE", "OWEN FISK", "CARLA DIAZ", "HENRY LOWE", "PAT GRADY", "MAY GRADY", "LEO BRANDT", "NORA BRANDT", "ED SIMMS", "GRACE TULL", "IVAN PETROV", "BETH HALE", "RAY MOORE", "JOAN YATES", "KYLE YATES"]
	for k in names.size():
		var col := k % 6
		var row := int(k / 6.0)
		c.label(p + Vector3(-9.0 + float(col) * 3.6, 1.95 - float(row) * 0.38, 0.32), str(names[k]), 14, Color(0.75, 0.72, 0.62), 0.0, 14.0, 0.01)
	c.label(p + Vector3(0, 0.25, 0.32), "26 NAMES · 1993 – ", 16, Color(0.6, 0.58, 0.5), 0.0, 20.0, 0.01)
	var fp := p + Vector3(0, 0, 4.0)
	c.props.cyl(fp + Vector3(0, 0.4, 0), 0.8, 1.0, 0.8, Color(0.3, 0.3, 0.32), 10)
	c.glow.cyl(fp + Vector3(0, 1.1, 0), 0.05, 0.35, 0.8, Color(1.0, 0.6, 0.2), 8, Vector2(Props.K_FLICKER, 0.0))
	c.solid(fp + Vector3(0, 0.4, 0), Vector3(2.0, 0.8, 2.0))
	Props.light_pool(c, fp, 6.0, Color(1.0, 0.65, 0.35))
	for k in 6:
		Furniture.build(c, "candles", p + Vector3(-8.0 + float(k) * 3.2, 0.0, 0.8), 0.0)
	Props.place(c, "bench", p + Vector3(-6.0, 0, 9.0), PI)
	Props.place(c, "bench", p + Vector3(6.0, 0, 9.0), PI)


## Things only Washington Township has: the water tower, the welcome sign
## (and what somebody painted under it), Main Street's festival banner.
func _township_extras() -> void:
	var wt := Vector3(180.0, 0, -300.0)
	var c := ctx_at(wt.x, wt.z)
	var lf := landmark_far
	for lx in [-4.0, 4.0]:
		for lz in [-4.0, 4.0]:
			lf.props.box(wt + Vector3(lx, 11.0, lz), Vector3(0.5, 22.0, 0.5), Color(0.5, 0.52, 0.55))
	lf.props.cyl(wt + Vector3(0, 27.0, 0), 7.0, 7.0, 10.0, Color(0.72, 0.76, 0.8), 16)
	lf.props.cyl(wt + Vector3(0, 33.0, 0), 0.6, 7.2, 2.4, Color(0.6, 0.64, 0.68), 16)
	lf.props.cyl(wt + Vector3(0, 21.6, 0), 7.0, 2.0, 1.4, Color(0.6, 0.64, 0.68), 16)
	for f in [0.0, PI * 0.5, PI, -PI * 0.5]:
		var o := Vector3(sin(f), 0, cos(f)) * 7.05
		c.label(wt + Vector3(0, 27.5, 0) + o, "WASHINGTON TWP", 110, Color(0.1, 0.2, 0.45), f, 900.0, 0.03)
	lf.glow.sphere(wt + Vector3(0, 34.6, 0), 0.4, Color(1.0, 0.12, 0.1), 6, 3, Vector2(Props.K_BLINK, 0))
	c.solid(wt + Vector3(0, 11.0, 0), Vector3(9.0, 22.0, 9.0))
	# Welcome sign at the county road.
	var ws := Vector3(640.0, 0, 14.0)
	var cw := ctx_at(ws.x, ws.z)
	cw.props.box(ws + Vector3(0, 1.2, 0), Vector3(0.6, 2.4, 9.0), Color(0.35, 0.22, 0.12))
	cw.props.box(ws + Vector3(0, 2.6, 0), Vector3(0.3, 2.4, 8.4), Color(0.9, 0.88, 0.8))
	cw.label(ws + Vector3(0.2, 3.3, 0), "WELCOME TO WASHINGTON TOWNSHIP", 30, Color(0.15, 0.25, 0.45), PI * 0.5, 80.0, 0.01)
	cw.label(ws + Vector3(0.2, 2.8, 0), "A NICE PLACE TO RAISE A FAMILY · EST. 1798", 20, Color(0.2, 0.2, 0.2), PI * 0.5, 60.0, 0.01)
	cw.label(ws + Vector3(0.22, 2.0, 0.3), "E CORP KILLED US", 64, Color(0.9, 0.12, 0.12, 0.9), PI * 0.5, 90.0, 0.01, {"font": "graffiti", "tilt": 0.06})
	cw.solid(ws + Vector3(0, 1.8, 0), Vector3(0.8, 3.6, 9.0))
	Props.light_pool(cw, ws + Vector3(2.0, 0, 0), 5.0, Color(1.0, 0.9, 0.7))
	# Fall festival banner across Main Street.
	for bx in [-75.0, 225.0]:
		var bp := Vector3(bx, 0, 0)
		var cb := ctx_at(bp.x, bp.z)
		cb.props.box(bp + Vector3(0, 6.2, 0), Vector3(0.12, 0.9, 13.0), Color(0.75, 0.3, 0.1))
		cb.label(bp + Vector3(0.08, 6.2, 0), "TOWNSHIP FALL FESTIVAL · SAT 10/17", 32, Color(1.0, 0.95, 0.8), PI * 0.5, 80.0, 0.01)
		cb.label(bp + Vector3(-0.08, 6.2, 0), "SPONSORED BY E CORP · POWERING COMMUNITIES", 26, Color(1.0, 0.95, 0.8), -PI * 0.5, 80.0, 0.01)
		for s in [-1.0, 1.0]:
			cb.props.box(bp + Vector3(0, 3.3, 6.6 * s), Vector3(0.2, 6.6, 0.2), Color(0.3, 0.3, 0.3))
			cb.solid(bp + Vector3(0, 3.3, 6.6 * s), Vector3(0.3, 6.6, 0.3))
		var lx := -6.0
		while lx <= 6.0:
			cb.glow.sphere(bp + Vector3(0, 6.8 - absf(lx) * 0.05, lx), 0.12, Color(1.0, 0.8, 0.45), 4, 3, Vector2(Props.K_NIGHT, 0))
			lx += 1.0


## Things only Port Ramsey has: the quay and its gantry cranes, a container
## ship tied up, fishing boats, the lighthouse jetty, the fish market sign.
func _port_extras() -> void:
	var sea: Rect2 = Regions.SEA["port"]
	var qx := sea.position.x
	var z0 := WorldLayout.WORLD_ZN
	var z1 := WorldLayout.BEACH_Z1
	var root_c := ctx_at(qx, 0.0)
	# Quay apron, edge and a wall at the waterline (with a gap for the jetty).
	var gz := z0
	while gz < z1:
		var L := minf(100.0, z1 - gz)
		var c := ctx_at(qx - 25.0, gz + L * 0.5)
		c.ground.flat(Vector3(qx - 25.0, 0.012, gz + L * 0.5), 50.0, L, Color(0.3, 0.29, 0.27), 0.0, Vector2(1, 0))
		c.props.box(Vector3(qx - 0.5, 0.25, gz + L * 0.5), Vector3(1.0, 0.5, L), Color(0.45, 0.43, 0.4))
		c.props.flat(Vector3(qx - 3.0, 0.02, gz + L * 0.5), 0.3, L, Color(0.85, 0.7, 0.15))
		gz += L
	var jz := PT_LIGHTHOUSE.y
	root_c.solid(Vector3(qx + 0.5, 3.0, (z0 + jz - 6.0) * 0.5), Vector3(1.0, 6.0, (jz - 6.0) - z0))
	root_c.solid(Vector3(qx + 0.5, 3.0, (jz + 6.0 + z1) * 0.5), Vector3(1.0, 6.0, z1 - (jz + 6.0)))
	var jl := PT_LIGHTHOUSE.x - qx
	var jc := ctx_at(qx + jl * 0.5, jz)
	jc.ground.flat(Vector3(qx + jl * 0.5, 0.03, jz), jl, 10.0, Color(0.42, 0.4, 0.37), 0.0, Vector2(1, 0))
	for s in [-1.0, 1.0]:
		jc.props.box(Vector3(qx + jl * 0.5, 0.4, jz + 5.2 * s), Vector3(jl, 0.8, 0.5), Color(0.32, 0.3, 0.28))
		jc.solid(Vector3(qx + jl * 0.5, 3.0, jz + 5.5 * s), Vector3(jl, 6.0, 1.0))
		for k in int(jl / 12.0):
			var lp := Vector3(qx + 6.0 + float(k) * 12.0, 0, jz + 4.6 * s)
			jc.props.box(lp + Vector3(0, 0.6, 0), Vector3(0.2, 1.2, 0.2), Color(0.2, 0.2, 0.2))
			jc.glow.sphere(lp + Vector3(0, 1.25, 0), 0.15, Color(1.0, 0.85, 0.55), 4, 3, Vector2(Props.K_NIGHT, 0))
	jc.solid(Vector3(PT_LIGHTHOUSE.x + 9.0, 3.0, jz), Vector3(1.0, 6.0, 12.0))
	# Gantry cranes on rails along the quay.
	for k in 2:
		var rc := ctx_at(qx - 18.0 + float(k) * 8.0, -170.0)
		rc.props.flat(Vector3(qx - 22.0 + float(k) * 9.0, 0.03, -170.0), 0.3, 360.0, Color(0.5, 0.48, 0.45))
	for cr in PT_CRANES:
		var cc := ctx_at(cr.x, cr.y)
		Props.place(landmark_far, "crane", Vector3(cr.x - 14.0, 0, cr.y), PI * 0.5, 1.6)
		for lz in [-4.8, 4.8]:
			cc.solid(Vector3(cr.x - 14.0, 19.0, cr.y + lz), Vector3(1.4, 38.0, 1.4))
		Props.light_pool(cc, Vector3(cr.x - 10.0, 0, cr.y), 10.0, Color(1.0, 0.85, 0.55))
	# The gangway up to the ship's deck at berth 2.
	var gw := ctx_at(qx, -150.0)
	gw.props.box_xf(Transform3D(Basis(Vector3.BACK, 0.62), Vector3(qx + 6.0, 4.5, -150.0)), Vector3(15.0, 0.25, 2.0), Color(0.45, 0.46, 0.48))
	for s5 in [-1.0, 1.0]:
		gw.props.box_xf(Transform3D(Basis(Vector3.BACK, 0.62), Vector3(qx + 6.0, 5.4, -150.0 + 1.0 * float(s5))), Vector3(15.0, 0.08, 0.08), Color(0.8, 0.8, 0.78))
	Props.light_pool(gw, Vector3(qx - 2.0, 0, -150.0), 6.0, Color(1.0, 0.85, 0.55))
	# The ship: a long hull, a white bridge at the stern, boxes stacked on deck.
	var sx := qx + 26.0
	var sz0 := -330.0
	var sz1 := -20.0
	var hc := ctx_at(sx, (sz0 + sz1) * 0.5)
	var hull := Color(0.12, 0.16, 0.22)
	landmark_far.props.box(Vector3(sx, 4.0, (sz0 + sz1) * 0.5), Vector3(28.0, 10.0, sz1 - sz0), hull)
	landmark_far.props.box(Vector3(sx, -0.6, (sz0 + sz1) * 0.5), Vector3(28.4, 1.6, sz1 - sz0 + 0.4), Color(0.5, 0.12, 0.1))
	landmark_far.props.cyl(Vector3(sx, 4.0, sz0 - 2.0), 0.0, 14.0, 10.0, hull, 3)
	hc.solid(Vector3(sx, 4.0, (sz0 + sz1) * 0.5), Vector3(28.0, 12.0, sz1 - sz0))
	var bz := sz1 - 22.0
	landmark_far.facade.box(Vector3(sx, 17.0, bz), Vector3(24.0, 16.0, 12.0), Color(0.9, 0.9, 0.88), 0.0, Vector2(8, 11))
	landmark_far.props.box(Vector3(sx, 27.0, bz + 2.0), Vector3(3.0, 6.0, 3.0), Color(0.75, 0.15, 0.1))
	landmark_far.glow.box(Vector3(sx, 22.0, bz - 6.05), Vector3(22.0, 1.4, 0.1), Color(1.0, 0.85, 0.55), 0.0, Vector2(Props.K_NIGHT, 0))
	hc.label(Vector3(sx - 14.1, 6.0, (sz0 + sz1) * 0.5 - 60.0), "E CORP LOGISTICS · MV EVERBRIGHT", 160, Color(0.95, 0.95, 0.95), -PI * 0.5, 600.0, 0.03)
	hc.label(Vector3(sx + 14.1, 6.0, (sz0 + sz1) * 0.5 - 60.0), "E CORP LOGISTICS · MV EVERBRIGHT", 160, Color(0.95, 0.95, 0.95), PI * 0.5, 600.0, 0.03)
	var ccols := [Color(0.6, 0.15, 0.1), Color(0.15, 0.3, 0.55), Color(0.2, 0.45, 0.25), Color(0.75, 0.55, 0.15), Color(0.5, 0.5, 0.52), Color(0.85, 0.85, 0.82)]
	var z := sz0 + 10.0
	while z < bz - 12.0:
		for row in 4:
			var stack := 1 + rng.randi() % 4
			for st in stack:
				landmark_far.props.box(Vector3(sx - 9.0 + float(row) * 6.0, 9.0 + 1.3 + float(st) * 2.6, z), Vector3(2.5, 2.6, 12.0), ccols[rng.randi() % ccols.size()])
		z += 13.0
	for lzz in [sz0 + 5.0, bz]:
		landmark_far.glow.sphere(Vector3(sx, 31.0 if lzz == bz else 12.0, lzz), 0.5, Color(1.0, 0.15, 0.1), 6, 3, Vector2(Props.K_BLINK, 0))
	# Fishing boats tied up south of the terminal.
	for k in 4:
		var fb := Vector3(qx + 8.0, 0, 120.0 + float(k) * 34.0)
		var fc := ctx_at(fb.x, fb.z)
		fc.props.box(fb + Vector3(0, 0.6, 0), Vector3(5.0, 2.4, 16.0), [Color(0.7, 0.15, 0.1), Color(0.15, 0.3, 0.5), Color(0.85, 0.85, 0.8), Color(0.2, 0.4, 0.3)][k])
		fc.props.box(fb + Vector3(0, 2.8, 3.0), Vector3(3.6, 2.4, 4.0), Color(0.9, 0.9, 0.88))
		fc.props.box(fb + Vector3(0, 5.0, -3.0), Vector3(0.2, 6.0, 0.2), Color(0.3, 0.3, 0.3))
		fc.props.box(fb + Vector3(0, 7.0, -4.0), Vector3(0.1, 0.1, 6.0), Color(0.3, 0.3, 0.3))
		fc.glow.sphere(fb + Vector3(0, 8.1, -3.0), 0.15, Color(0.3, 1.0, 0.4), 4, 3, Vector2(Props.K_NIGHT, 0))
		fc.label(fb + Vector3(-2.55, 1.0, 0), ["MISS RUTHIE", "SEA WITCH", "PORT RAMSEY III", "NO REFUNDS"][k], 40, Color(0.95, 0.95, 0.9), -PI * 0.5, 60.0, 0.01)
		fc.solid(fb + Vector3(0, 1.5, 0), Vector3(5.0, 3.0, 16.0))
	# The fish market sign on the south quay.
	var ms := Vector3(qx - 30.0, 0, 200.0)
	var mc := ctx_at(ms.x, ms.z)
	mc.props.box(ms + Vector3(0, 3.0, 0), Vector3(0.3, 6.0, 0.3), Color(0.3, 0.3, 0.3))
	mc.props.box(ms + Vector3(0, 6.2, 0), Vector3(0.25, 1.8, 8.0), Color(0.1, 0.25, 0.4))
	for f in [-1.0, 1.0]:
		mc.label(ms + Vector3(0.15 * f, 6.4, 0), "RAMSEY FISH MARKET", 44, Color(1.0, 1.0, 0.95), PI * 0.5 * f, 120.0, 0.02)
		mc.label(ms + Vector3(0.15 * f, 5.75, 0), "OPEN 4AM · CASH ONLY", 26, Color(1.0, 0.85, 0.3), PI * 0.5 * f, 80.0, 0.02)
	mc.solid(ms + Vector3(0, 3.0, 0), Vector3(0.4, 6.0, 0.4))
	Props.light_pool(mc, ms + Vector3(-3.0, 0, 0), 6.0, Color(1.0, 0.85, 0.6))


## Overhead exit signs on I-80 before the county road junction.
func _exit_gantries() -> void:
	for e in [[160.0, 0.0], [-160.0, PI]]:
		var p := Vector3(0.0, 0.0, float(e[0]))
		var yaw := float(e[1])
		var c := ctx_at(p.x, p.z)
		for s in [-1.0, 1.0]:
			c.props.box(p + Vector3(9.5 * s, 3.6, 0), Vector3(0.4, 7.2, 0.4), Color(0.4, 0.4, 0.42))
			c.solid(p + Vector3(9.5 * s, 3.6, 0), Vector3(0.5, 7.2, 0.5))
		c.props.box(p + Vector3(0, 7.0, 0), Vector3(19.4, 0.4, 0.4), Color(0.4, 0.4, 0.42))
		var north := yaw == 0.0
		for k in 2:
			var sx := -4.6 + float(k) * 9.2
			c.props.box(p + Vector3(sx, 8.0, 0), Vector3(8.6, 2.4, 0.2), Color(0.05, 0.35, 0.2))
			# k 0 is the west sign: on your left heading north, your right heading south.
			var txt := ""
			if k == 0:
				txt = "< EXIT 41  WASHINGTON TWP" if north else "EXIT 41  WASHINGTON TWP >"
			else:
				txt = "EXIT 42  PORT RAMSEY >" if north else "< EXIT 42  PORT RAMSEY"
			c.label(p + Vector3(sx, 8.0, 0.12 if yaw == 0.0 else -0.12), txt, 44, Color(0.95, 0.95, 0.95), yaw, 300.0, 0.02)


# ------------------------------------------------------------------- gary
## A blast furnace on the lakeshore: the stack, its stoves, the downcomer,
## a flare that still flickers at night although nothing's been poured here
## for a year.
func _blast_furnace(c: BuildCtx, p: Vector3) -> void:
	var rust := Color(0.42, 0.24, 0.16)
	c.props.cyl(p + Vector3(0, 22.0, 0), 7.0, 10.0, 44.0, rust, 14)
	c.props.cyl(p + Vector3(0, 46.0, 0), 4.0, 7.2, 5.0, rust.darkened(0.2), 12)
	c.props.box(p + Vector3(0, 30.0, 0), Vector3(22.0, 1.0, 22.0), Color(0.3, 0.3, 0.32))
	for k in 3:
		c.props.cyl(p + Vector3(-18.0, 18.0, -12.0 + float(k) * 12.0), 4.4, 4.4, 36.0, Color(0.5, 0.5, 0.5), 10)
	c.props.box_xf(Transform3D(Basis(Vector3.FORWARD, 0.7), p + Vector3(9.0, 40.0, 0)), Vector3(22.0, 2.2, 2.2), rust.darkened(0.1))
	c.props.cyl(p + Vector3(16.0, 30.0, 6.0), 1.0, 1.4, 60.0, Color(0.35, 0.33, 0.32), 8)
	c.glow.cyl(p + Vector3(16.0, 61.5, 6.0), 0.2, 1.4, 3.0, Color(1.0, 0.55, 0.15), 8, Vector2(Props.K_FLICKER, 0.4))
	c.glow.cyl(p + Vector3(0, 48.8, 0), 3.8, 3.8, 0.3, Color(1.0, 0.4, 0.1), 12, Vector2(Props.K_NIGHT, 0))
	c.glow.sphere(p + Vector3(0, 49.5, 0), 0.5, Color(1.0, 0.12, 0.1), 6, 3, Vector2(Props.K_BLINK, 0))


## Gary Works: long sheds gone to rust, conveyor gantries, ore heaps, rail.
func _mill_block(bi: int, bj: int, r: Rect2) -> void:
	var c := ctx_at(r.get_center().x, r.get_center().y)
	c.ground.flat(Vector3(r.get_center().x, 0.012, r.get_center().y), r.size.x, r.size.y, Color(0.2, 0.17, 0.15), 0.0, Vector2(1, 0))
	if bj == 0:
		# The lakeshore row: the furnaces themselves, their solids and a
		# cast house between them.
		for fu in GY_FURNACES:
			if r.has_point(fu):
				_blast_furnace(landmark_far, Vector3(fu.x, 0, fu.y))
				c.solid(Vector3(fu.x, 22.0, fu.y), Vector3(18.0, 44.0, 18.0))
				for k in 3:
					c.solid(Vector3(fu.x - 18.0, 18.0, fu.y - 12.0 + float(k) * 12.0), Vector3(8.8, 36.0, 8.8))
				var ch := Rect2(fu.x - 20.0, fu.y + 14.0, 40.0, 20.0)
				if _is_free(bi, bj, ch) and r.encloses(ch):
					_building(ch, 16.0, 5, Color(0.36, 0.22, 0.16), false, 1.0, "industrial", "none", false)
		return
	var shed := Rect2(r.position.x + 6.0, r.position.y + 8.0, r.size.x - 12.0, r.size.y * rng.randf_range(0.45, 0.6))
	if _is_free(bi, bj, shed):
		var col: Color = [Color(0.38, 0.22, 0.16), Color(0.32, 0.3, 0.28), Color(0.44, 0.3, 0.22), Color(0.3, 0.26, 0.24)][rng.randi() % 4]
		_building(shed, rng.randf_range(18.0, 26.0), 5, col, false, 1.0, "industrial", "mech")
		# Roof monitor along the ridge.
		c.facade.box(Vector3(shed.get_center().x, 0.0, shed.get_center().y) + Vector3(0, 26.0, 0), Vector3(shed.size.x * 0.9, 3.0, 6.0), col.darkened(0.15), 0.0, Vector2(5, 3))
	# A conveyor gantry across the yard, and heaps of ore and slag.
	var gy := r.end.y - 18.0
	for k in 4:
		var gx := r.position.x + 12.0 + float(k) * (r.size.x - 24.0) / 3.0
		c.props.box(Vector3(gx, 5.0, gy), Vector3(0.6, 10.0, 0.6), Color(0.3, 0.3, 0.32))
		c.solid(Vector3(gx, 5.0, gy), Vector3(0.8, 10.0, 0.8))
	c.props.box(Vector3(r.get_center().x, 10.4, gy), Vector3(r.size.x - 20.0, 1.6, 2.4), Color(0.45, 0.3, 0.15))
	for k in 2:
		var hp := Vector3(r.position.x + 20.0 + float(k) * 50.0, 0, r.end.y - 6.0)
		if _is_free(bi, bj, Rect2(hp.x - 8.0, hp.z - 8.0, 16.0, 8.0)):
			c.props.cyl(hp + Vector3(0, 2.5, 0), 1.0, 8.0, 5.0, [Color(0.3, 0.16, 0.12), Color(0.2, 0.2, 0.22)][k], 10)
			c.solid(hp + Vector3(0, 2.0, 0), Vector3(10.0, 4.0, 10.0))
	# Rail spur along the north side of the yard.
	for t in [-0.7, 0.7]:
		c.ground.flat(Vector3(r.get_center().x, 0.02, r.position.y + 3.0 + t), r.size.x, 0.1, Color(0.4, 0.38, 0.35))
	Props.fence_line(c, Vector3(r.position.x, 0, r.end.y), Vector3(r.get_center().x - 7.0, 0, r.end.y), 2.6)
	Props.fence_line(c, Vector3(r.get_center().x + 7.0, 0, r.end.y), Vector3(r.end.x, 0, r.end.y), 2.6)
	Props.light_pool(c, Vector3(r.get_center().x, 0, r.end.y - 4.0), 9.0, Color(1.0, 0.75, 0.45))


## FreightOS's depot: rows of white trucks with nobody in them, charging
## gantries, light masts, a fence that hums.
func _depot_block(bi: int, bj: int, r: Rect2) -> void:
	var c := ctx_at(r.get_center().x, r.get_center().y)
	c.ground.flat(Vector3(r.get_center().x, 0.013, r.get_center().y), r.size.x, r.size.y, Color(0.16, 0.16, 0.17), 0.0, Vector2(1, 0))
	var z := r.position.y + 10.0
	while z < r.end.y - 8.0:
		var x := r.position.x + 6.0
		while x < r.end.x - 6.0:
			var spot := Rect2(x - 1.6, z - 4.2, 3.2, 8.4)
			c.props.flat(Vector3(x + 2.0, 0.02, z), 0.15, 8.0, Color(0.8, 0.8, 0.75))
			if rng.randf() < 0.7 and _is_free(bi, bj, spot.grow(1.0)):
				Props.place(c, "car_truck_%d" % [0, 4, 6][rng.randi() % 3], Vector3(x, 0, z), 0.0)
				c.solid(Vector3(x, 1.5, z), Vector3(2.4, 3.0, 7.6))
				c.glow.box(Vector3(x, 3.4, z - 3.0), Vector3(0.6, 0.1, 0.1), Color(0.3, 0.8, 1.0), 0.0, Vector2(Props.K_BLINK, rng.randf()))
			x += 4.0
		# A charging gantry over each row.
		if _is_free(bi, bj, Rect2(r.position.x, z - 5.0, 2.0, 2.0)):
			c.props.box(Vector3(r.position.x + 2.0, 3.5, z - 5.0), Vector3(0.3, 7.0, 0.3), Color(0.5, 0.52, 0.55))
			c.props.box(Vector3(r.end.x - 2.0, 3.5, z - 5.0), Vector3(0.3, 7.0, 0.3), Color(0.5, 0.52, 0.55))
			c.props.box(Vector3(r.get_center().x, 7.0, z - 5.0), Vector3(r.size.x - 4.0, 0.4, 0.4), Color(0.5, 0.52, 0.55))
		z += 22.0
	for k in 2:
		var mp := Vector3(r.position.x + r.size.x * (0.3 + 0.4 * float(k)), 0, r.get_center().y)
		if _is_free(bi, bj, Rect2(mp.x - 1.0, mp.z - 1.0, 2.0, 2.0)):
			c.props.box(mp + Vector3(0, 8.0, 0), Vector3(0.4, 16.0, 0.4), Color(0.4, 0.4, 0.42))
			c.glow.box(mp + Vector3(0, 16.2, 0), Vector3(2.4, 0.4, 0.8), Color(0.95, 0.95, 1.0), 0.0, Vector2(Props.K_NIGHT, 0))
			c.solid(mp + Vector3(0, 8.0, 0), Vector3(0.6, 16.0, 0.6))
			Props.light_pool(c, mp, 16.0, Color(0.9, 0.95, 1.0))
	Props.fence_line(c, Vector3(r.position.x, 0, r.end.y), Vector3(r.get_center().x - 8.0, 0, r.end.y), 3.0, Color(0.5, 0.52, 0.55))
	Props.fence_line(c, Vector3(r.get_center().x + 8.0, 0, r.end.y), Vector3(r.end.x, 0, r.end.y), 3.0, Color(0.5, 0.52, 0.55))


## Things only Gary has: the ore boat on the lake, the mill gate sign, the
## welcome sign, FreightOS's billboard.
func _gary_extras() -> void:
	var lf := landmark_far
	# An ore boat laid up off the furnaces, rusting at anchor.
	var bp := Vector3(-420.0, 0, -720.0)
	lf.props.box(bp + Vector3(0, 3.0, 0), Vector3(190.0, 9.0, 22.0), Color(0.42, 0.18, 0.12))
	lf.props.box(bp + Vector3(0, -0.8, 0), Vector3(190.4, 1.6, 22.4), Color(0.12, 0.12, 0.14))
	lf.facade.box(bp + Vector3(84.0, 12.0, 0), Vector3(16.0, 10.0, 18.0), Color(0.88, 0.88, 0.85), 0.0, Vector2(8, 21))
	lf.props.box(bp + Vector3(-86.0, 10.0, 0), Vector3(12.0, 5.0, 16.0), Color(0.88, 0.88, 0.85))
	lf.props.box(bp + Vector3(84.0, 20.0, 4.0), Vector3(2.0, 6.0, 2.0), Color(0.1, 0.1, 0.12))
	lf.glow.sphere(bp + Vector3(84.0, 24.0, 0), 0.4, Color(1.0, 0.15, 0.1), 6, 3, Vector2(Props.K_BLINK, 0))
	ctx_at(bp.x, bp.z).label(bp + Vector3(0, 5.0, 11.1), "EDMUND J. KOWALSKI · GARY", 140, Color(0.95, 0.95, 0.9), 0.0, 500.0, 0.03)
	ctx_at(bp.x, bp.z).solid(bp + Vector3(0, 3.0, 0), Vector3(190.0, 9.0, 22.0))
	# The mill's gate on Broadway and Dunes Highway.
	var gp := Vector3(-140.0, 0, -40.0)
	var gc := ctx_at(gp.x, gp.z)
	for sx in [-9.0, 9.0]:
		gc.props.box(gp + Vector3(sx, 4.5, 0), Vector3(1.2, 9.0, 1.2), Color(0.35, 0.3, 0.28))
		gc.solid(gp + Vector3(sx, 4.5, 0), Vector3(1.4, 9.0, 1.4))
	gc.props.box(gp + Vector3(0, 9.4, 0), Vector3(20.0, 1.8, 0.4), Color(0.25, 0.22, 0.2))
	gc.label(gp + Vector3(0, 9.4, 0.25), "GARY WORKS", 120, Color(0.9, 0.75, 0.4), 0.0, 300.0, 0.02)
	gc.label(gp + Vector3(0, 9.4, -0.25), "GARY WORKS", 120, Color(0.9, 0.75, 0.4), PI, 300.0, 0.02)
	gc.label(gp + Vector3(0, 6.5, 0.7), "PRODUCTION PAUSED · E CORP STEEL", 32, Color(0.95, 0.95, 0.95), 0.0, 60.0, 0.01)
	# Welcome sign on the I-90 stub.
	var ws := Vector3(746.0, 0, 14.0)
	var cw := ctx_at(ws.x, ws.z)
	cw.props.box(ws + Vector3(0, 1.2, 0), Vector3(0.6, 2.4, 9.0), Color(0.3, 0.3, 0.32))
	cw.props.box(ws + Vector3(0, 2.6, 0), Vector3(0.3, 2.4, 8.4), Color(0.12, 0.25, 0.45))
	cw.label(ws + Vector3(-0.2, 3.2, 0), "GARY, INDIANA", 40, Color(1, 1, 1), -PI * 0.5, 80.0, 0.01)
	cw.label(ws + Vector3(-0.2, 2.6, 0), "CITY OF THE CENTURY · EST. 1906", 22, Color(0.95, 0.85, 0.4), -PI * 0.5, 60.0, 0.01)
	cw.label(ws + Vector3(-0.22, 1.9, 0.3), "WHO'S DRIVING?", 56, Color(1.0, 0.85, 0.2, 0.9), -PI * 0.5, 80.0, 0.01, {"font": "graffiti", "tilt": -0.05})
	cw.solid(ws + Vector3(0, 1.8, 0), Vector3(0.8, 3.6, 9.0))
	Props.light_pool(cw, ws + Vector3(-2.0, 0, 0), 5.0, Color(1.0, 0.9, 0.7))
	# FreightOS's billboard over the depot fence.
	var fb := Vector3(280.0, 0, -112.0)
	var fc := ctx_at(fb.x, fb.z)
	for sx in [-6.0, 6.0]:
		fc.props.box(fb + Vector3(sx, 5.0, 0), Vector3(0.4, 10.0, 0.4), Color(0.3, 0.3, 0.32))
		fc.solid(fb + Vector3(sx, 5.0, 0), Vector3(0.5, 10.0, 0.5))
	fc.props.box(fb + Vector3(0, 11.5, 0), Vector3(16.0, 4.0, 0.3), Color(0.95, 0.95, 0.95))
	fc.label(fb + Vector3(0, 12.2, 0.2), "FREIGHTOS", 90, Color(0.1, 0.4, 0.8), 0.0, 400.0, 0.02)
	fc.label(fb + Vector3(0, 10.9, 0.2), "THE ROAD DRIVES ITSELF", 44, Color(0.2, 0.2, 0.22), 0.0, 300.0, 0.02)
	fc.glow.box(fb + Vector3(0, 13.8, 0.3), Vector3(15.0, 0.2, 0.2), Color(1.0, 0.95, 0.85), 0.0, Vector2(Props.K_NIGHT, 0))

# ------------------------------------------------------------- redmont
## East-1: windowless halls the size of aircraft carriers, rows of chillers
## on the roofs breathing steam, a substation, floodlights and a fence.
func _datacenter_block(bi: int, bj: int, r: Rect2) -> void:
	var c := ctx_at(r.get_center().x, r.get_center().y)
	c.ground.flat(Vector3(r.get_center().x, 0.012, r.get_center().y), r.size.x, r.size.y, Color(0.3, 0.3, 0.31), 0.0, Vector2(1, 0))
	var halls := 2 if r.size.y > 80.0 else 1
	var hd := (r.size.y - 14.0 - 10.0 * float(halls - 1)) / float(halls)
	for k in halls:
		var hr := Rect2(r.position.x + 8.0, r.position.y + 7.0 + float(k) * (hd + 10.0), r.size.x - 16.0, hd)
		if not _is_free(bi, bj, hr.grow(1.0)):
			hr = Rect2(hr.position.x, hr.position.y, hr.size.x * 0.5, hr.size.y)
			if not _is_free(bi, bj, hr.grow(1.0)):
				continue
		var H := 14.0
		var hc := Vector3(hr.get_center().x, 0, hr.get_center().y)
		landmark_far.props.box(hc + Vector3(0, H * 0.5, 0), Vector3(hr.size.x, H, hr.size.y), Color(0.82, 0.83, 0.84))
		landmark_far.props.box(hc + Vector3(0, H + 0.2, 0), Vector3(hr.size.x + 0.4, 0.4, hr.size.y + 0.4), Color(0.5, 0.52, 0.55))
		c.solid(hc + Vector3(0, H * 0.5, 0), Vector3(hr.size.x, H, hr.size.y))
		buildings.append([hr.position.x, hr.position.y, hr.end.x, hr.end.y, H, "rm_dc"])
		# A blue stripe and the hall number, both ends.
		for sz in [-1.0, 1.0]:
			c.props.box(hc + Vector3(0, H - 2.0, sz * (hr.size.y * 0.5 + 0.03)), Vector3(hr.size.x, 0.6, 0.04), Color(0.1, 0.45, 0.85))
			c.label(hc + Vector3(-hr.size.x * 0.5 + 12.0, H - 4.0, sz * (hr.size.y * 0.5 + 0.08)), "EAST-1 · HALL %d" % (bi * 4 + bj * 2 + k + 1), 90, Color(0.15, 0.2, 0.3), 0.0 if sz > 0.0 else PI, 200.0, 0.02)
		# Chillers on the roof, fans turning, steam over the lot of them.
		var fx := hr.position.x + 6.0
		while fx < hr.end.x - 6.0:
			for fz in [hr.position.y + hr.size.y * 0.3, hr.position.y + hr.size.y * 0.7]:
				landmark_far.props.box(Vector3(fx, H + 1.4, fz), Vector3(5.0, 2.4, 5.0), Color(0.6, 0.62, 0.64))
				c.props.cyl(Vector3(fx, H + 2.7, fz), 1.9, 1.9, 0.2, Color(0.15, 0.15, 0.16), 10)
				if rng.randf() < 0.35:
					landmark_far.props.sphere(Vector3(fx, H + 6.0 + rng.randf() * 3.0, fz), 2.6 + rng.randf() * 1.6, Color(0.85, 0.86, 0.88), 6, 3, Vector2.ZERO, 0.55)
			fx += 9.0
		landmark_far.glow.box(hc + Vector3(hr.size.x * 0.5 - 1.0, H + 0.6, 0), Vector3(0.4, 0.4, 0.4), Color(1.0, 0.15, 0.1), 0.0, Vector2(Props.K_BLINK, rng.randf()))
	for k2 in 2:
		var lp := Vector3(r.position.x + 4.0 + float(k2) * (r.size.x - 8.0), 0, r.get_center().y)
		if _is_free(bi, bj, Rect2(lp.x - 1.0, lp.z - 1.0, 2.0, 2.0)):
			c.props.box(lp + Vector3(0, 7.0, 0), Vector3(0.3, 14.0, 0.3), Color(0.45, 0.46, 0.48))
			c.glow.box(lp + Vector3(0, 14.2, 0), Vector3(1.8, 0.3, 0.6), Color(0.9, 0.95, 1.0), 0.0, Vector2(Props.K_NIGHT, 0))
			c.solid(lp + Vector3(0, 7.0, 0), Vector3(0.5, 14.0, 0.5))
			Props.light_pool(c, lp, 15.0, Color(0.9, 0.95, 1.0))
	Props.fence_line(c, Vector3(r.position.x, 0, r.end.y), Vector3(r.get_center().x - 7.0, 0, r.end.y), 3.2, Color(0.55, 0.57, 0.6))
	Props.fence_line(c, Vector3(r.get_center().x + 7.0, 0, r.end.y), Vector3(r.end.x, 0, r.end.y), 3.2, Color(0.55, 0.57, 0.6))


## The Microslop campus: mown lawn, white paths, glass pavilions three or
## four floors high with their team names on them, benches nobody sits on.
func _campus_block(bi: int, bj: int, r: Rect2) -> void:
	if r.has_point(RM_LOGO):
		_reserve(bi, bj, Rect2(RM_LOGO.x - 10.0, RM_LOGO.y - 4.0, 20.0, 12.0))
	var c := ctx_at(r.get_center().x, r.get_center().y)
	c.ground.flat(Vector3(r.get_center().x, 0.011, r.get_center().y), r.size.x, r.size.y, Color(0.2, 0.36, 0.14), 0.0, Vector2(1, 0))
	c.ground.flat(Vector3(r.get_center().x, 0.016, r.get_center().y), 4.0, r.size.y, Color(0.75, 0.75, 0.72), 0.0, Vector2(1, 0))
	c.ground.flat(Vector3(r.get_center().x, 0.016, r.get_center().y), r.size.x, 4.0, Color(0.75, 0.75, 0.72), 0.0, Vector2(1, 0))
	var teams := ["COPILOT", "AZURE-ISH", "TEAMS (NEW)", "EDGE", "SLOP 365", "RECALL", "GAME PASS AWAY", "BING (STILL)", "CLIPPY LEGACY", "STRATEGIC REALIGNMENT"]
	for qx in [0, 1]:
		for qz in [0, 1]:
			var w := r.size.x * 0.5 - 12.0
			var d := r.size.y * 0.5 - 12.0
			if w < 14.0 or d < 14.0:
				continue
			var pr := Rect2(r.position.x + 6.0 + float(qx) * (r.size.x * 0.5 + 2.0), r.position.y + 6.0 + float(qz) * (r.size.y * 0.5 + 2.0), w * rng.randf_range(0.75, 1.0), d * rng.randf_range(0.7, 1.0))
			if not _is_free(bi, bj, pr.grow(2.0)):
				continue
			var h := rng.randf_range(11.0, 16.0)
			_facade_box(c, pr, 0.0, h, 7, Color(0.22, 0.32, 0.38).lerp(Color(0.6, 0.66, 0.7), rng.randf() * 0.4), rng.randf_range(1, 90))
			c.solid(Vector3(pr.get_center().x, h * 0.5, pr.get_center().y), Vector3(pr.size.x, h, pr.size.y))
			buildings.append([pr.position.x, pr.position.y, pr.end.x, pr.end.y, h, "rm_campus"])
			var face := 1.0 if qz == 0 else -1.0
			var fz := pr.end.y + 0.06 if face > 0.0 else pr.position.y - 0.06
			c.label(Vector3(pr.get_center().x, h - 1.6, fz), str(teams[rng.randi() % teams.size()]), 64, Color(0.95, 0.97, 1.0), 0.0 if face > 0.0 else PI, 160.0, 0.02)
			c.glow.box(Vector3(pr.get_center().x, h + 0.3, pr.get_center().y), Vector3(pr.size.x * 0.6, 0.15, 0.3), Color(0.6, 0.85, 1.0), 0.0, Vector2(Props.K_NIGHT, 0))
	for k in 4:
		var bp := Vector3(r.get_center().x + rng.randf_range(-r.size.x * 0.3, r.size.x * 0.3), 0, r.get_center().y + (6.0 if k % 2 == 0 else -6.0))
		if _is_free(bi, bj, Rect2(bp.x - 1.5, bp.z - 1.0, 3.0, 2.0)):
			Furniture.build(c, "bench", bp, 0.0 if k % 2 == 0 else PI)
	Props.light_pool(c, Vector3(r.get_center().x, 0, r.get_center().y), 10.0, Color(0.85, 0.92, 1.0))


## A helipad: a painted circle and an H, with lights round the edge.
func _helipad(c: BuildCtx, p: Vector3) -> void:
	c.props.flat(Vector3(p.x, 0.026, p.z), 14.0, 14.0, Color(0.22, 0.22, 0.23))
	for k in 16:
		var a := TAU * float(k) / 16.0
		c.props.flat(Vector3(p.x + cos(a) * 6.2, 0.03, p.z + sin(a) * 6.2), 1.4, 0.35, Color(0.95, 0.8, 0.2), -a - PI * 0.5)
		if k % 2 == 0:
			c.glow.box(Vector3(p.x + cos(a) * 7.0, 0.15, p.z + sin(a) * 7.0), Vector3(0.2, 0.15, 0.2), Color(0.3, 1.0, 0.4), 0.0, Vector2(Props.K_NIGHT, 0))
	c.props.flat(Vector3(p.x - 1.4, 0.032, p.z), 0.5, 4.0, Color(0.95, 0.95, 0.92))
	c.props.flat(Vector3(p.x + 1.4, 0.032, p.z), 0.5, 4.0, Color(0.95, 0.95, 0.92))
	c.props.flat(Vector3(p.x, 0.032, p.z), 2.4, 0.5, Color(0.95, 0.95, 0.92))


## Microslop's crown: the four squares, lit, and a beacon on the mast.
func _hq_crown(c: BuildCtx, top: Vector3) -> void:
	var cols := [Color(0.95, 0.3, 0.15), Color(0.45, 0.8, 0.2), Color(0.1, 0.65, 0.95), Color(1.0, 0.75, 0.1)]
	for k in 4:
		var off := Vector3(-3.3 + float(k % 2) * 6.6, 7.0 - float(k >> 1) * 6.6, 0)
		c.glow.box(top + off + Vector3(0, 0, 0), Vector3(6.0, 6.0, 1.0), cols[k], 0.0, Vector2(Props.K_ALWAYS, 0))
	c.props.box(top + Vector3(0, 4.0, 0), Vector3(14.0, 8.0, 0.6), Color(0.12, 0.12, 0.14))
	c.props.box(top + Vector3(0, 14.0, 0), Vector3(0.4, 12.0, 0.4), Color(0.3, 0.3, 0.32))
	c.glow.sphere(top + Vector3(0, 20.4, 0), 0.6, Color(1.0, 0.12, 0.1), 6, 3, Vector2(Props.K_BLINK, 0))


## Things only Redmont has: the HQ's crown and the logo on the lawn, the
## welcome sign, Microslop Security's checkpoint and Copilot's billboard on
## Route 9, and the boat launch that ends in mud.
func _redmont_extras() -> void:
	var lf := landmark_far
	_hq_crown(lf, Vector3(RM_HQ.x, 96.0, RM_HQ.y + 37.2))
	# The executive helicopter, on its own pad beside the field.
	var hp := Vector3(646.0, 0, 300.0)
	_helipad(ctx_at(hp.x, hp.z), hp)
	airfield_planes.append({"slot": "redmont_heli", "model": "heli", "pos": hp, "yaw": PI * 0.5})
	# The logo, fourteen metres high, the four squares running a little at
	# the bottom like they've been left out in the rain.
	var lg := Vector3(RM_LOGO.x, 0, RM_LOGO.y)
	var cl := ctx_at(lg.x, lg.z)
	var cols := [Color(0.95, 0.3, 0.15), Color(0.45, 0.8, 0.2), Color(0.1, 0.65, 0.95), Color(1.0, 0.75, 0.1)]
	lf.props.box(lg + Vector3(0, 0.6, 0), Vector3(16.0, 1.2, 4.0), Color(0.75, 0.75, 0.72))
	cl.solid(lg + Vector3(0, 7.0, 0), Vector3(14.0, 14.0, 2.0))
	for k in 4:
		var off := Vector3(-3.4 + float(k % 2) * 6.8, 10.2 - float(k >> 1) * 6.8, 0)
		lf.props.box(lg + off, Vector3(6.2, 6.2, 1.2), cols[k])
		for dk in 3:
			lf.props.box(lg + off + Vector3(-2.0 + float(dk) * 2.0, -3.6 - float(dk % 2) * 0.8, 0.0), Vector3(0.5, 1.4 + float(dk % 2) * 1.6, 1.0), cols[k])
	cl.label(lg + Vector3(0, 1.8, 2.05), "MICROSLOP", 160, Color(0.2, 0.2, 0.22), 0.0, 300.0, 0.02)
	cl.label(lg + Vector3(0, 1.8, -2.05), "MICROSLOP", 160, Color(0.2, 0.2, 0.22), PI, 300.0, 0.02)
	Props.light_pool(cl, lg + Vector3(0, 0, 5.0), 9.0, Color(0.9, 0.95, 1.0))
	# Welcome sign on the Route 9 stub.
	var ws := Vector3(14.0, 0, 646.0)
	var cw := ctx_at(ws.x, ws.z)
	cw.props.box(ws + Vector3(0, 1.2, 0), Vector3(9.0, 2.4, 0.6), Color(0.3, 0.3, 0.32))
	cw.props.box(ws + Vector3(0, 2.6, 0), Vector3(8.4, 2.4, 0.3), Color(0.1, 0.45, 0.85))
	cw.label(ws + Vector3(0, 3.2, 0.2), "REDMONT", 44, Color(1, 1, 1), 0.0, 80.0, 0.01)
	cw.label(ws + Vector3(0, 2.6, 0.2), "A MICROSLOP COMMUNITY · WHERE YOUR FUTURE IS SAVED", 18, Color(0.9, 0.95, 1.0), 0.0, 60.0, 0.01)
	cw.label(ws + Vector3(0.3, 1.9, 0.22), "GIVE US BACK THE WATER", 40, Color(1.0, 0.3, 0.3, 0.9), 0.0, 80.0, 0.01, {"font": "graffiti", "tilt": -0.05})
	cw.solid(ws + Vector3(0, 1.8, 0), Vector3(9.0, 3.6, 0.8))
	# Microslop Security's checkpoint: a booth, a barrier arm (up), a sign.
	var cp := Vector3(-11.5, 0, 662.0)
	var cc := ctx_at(cp.x, cp.z)
	cc.props.box(cp + Vector3(0, 1.4, 0), Vector3(3.0, 2.8, 3.0), Color(0.85, 0.86, 0.88))
	cc.props.box(cp + Vector3(0, 2.95, 0), Vector3(3.4, 0.3, 3.4), Color(0.1, 0.45, 0.85))
	cc.glow.box(cp + Vector3(1.52, 1.8, 0), Vector3(0.05, 1.0, 2.2), Color(0.8, 0.9, 1.0), 0.0, Vector2(Props.K_ALWAYS, 0))
	cc.solid(cp + Vector3(0, 1.4, 0), Vector3(3.0, 2.8, 3.0))
	cc.props.box(cp + Vector3(2.0, 3.6, 0), Vector3(0.25, 7.0, 0.25), Color(0.9, 0.2, 0.15), 0.0)
	cc.label(cp + Vector3(0, 3.4, 1.72), "MICROSLOP SECURITY · VEHICLE INSPECTION", 22, Color(1, 1, 1), 0.0, 50.0, 0.01)
	Props.light_pool(cc, cp + Vector3(4.0, 0, 0), 7.0, Color(0.9, 0.95, 1.0))
	# The boat launch, on the west shore, that ends in mud.
	var bl := Vector3(-720.0, 0, 300.0)
	var cb := ctx_at(bl.x, bl.z)
	cb.ground.flat(bl + Vector3(0, 0.02, 0), 30.0, 10.0, Color(0.48, 0.47, 0.44), 0.0, Vector2(1, 0))
	cb.props.box(bl + Vector3(8.0, 1.2, -6.5), Vector3(0.2, 2.4, 0.2), Color(0.35, 0.3, 0.25))
	cb.props.box(bl + Vector3(8.0, 2.4, -6.5), Vector3(3.6, 1.2, 0.1), Color(0.95, 0.95, 0.92))
	cb.label(bl + Vector3(8.0, 2.4, -6.42), "BOAT LAUNCH · CLOSED", 22, Color(0.7, 0.1, 0.1), 0.0, 40.0, 0.01)
	for k2 in 3:
		cb.props.sphere(bl + Vector3(-6.0 + float(k2) * 3.5, 0.35, 5.0 + float(k2 % 2)), 0.35, Color(0.95, 0.5, 0.1), 6, 3)
	# Copilot's billboard on Route 9, for everyone driving in.
	var fb := Vector3(-30.0, 0, 632.0)
	var fc := ctx_at(fb.x, fb.z)
	for sx in [-6.0, 6.0]:
		fc.props.box(fb + Vector3(sx, 5.0, 0), Vector3(0.4, 10.0, 0.4), Color(0.3, 0.3, 0.32))
		fc.solid(fb + Vector3(sx, 5.0, 0), Vector3(0.5, 10.0, 0.5))
	fc.props.box(fb + Vector3(0, 11.5, 0), Vector3(16.0, 4.0, 0.3), Color(0.95, 0.97, 1.0))
	fc.label(fb + Vector3(0, 12.2, 0.2), "COPILOT FOR GOVERNMENT", 70, Color(0.1, 0.45, 0.85), 0.0, 400.0, 0.02)
	fc.label(fb + Vector3(0, 10.9, 0.2), "91 VOTES. 0 COMPLAINTS.", 44, Color(0.2, 0.2, 0.22), 0.0, 300.0, 0.02)
	fc.glow.box(fb + Vector3(0, 13.8, 0.3), Vector3(15.0, 0.2, 0.2), Color(1.0, 0.95, 0.85), 0.0, Vector2(Props.K_NIGHT, 0))


# ------------------------------------------------------------- the island
## Price's estate: a long lawn, a pool, clipped hedges, the rose garden, a
## helipad, gravel paths and lamps that are always on for nobody.
func _estate_block(bi: int, bj: int, r: Rect2) -> void:
	var c := ctx_at(r.get_center().x, r.get_center().y)
	c.ground.flat(Vector3(r.get_center().x, 0.011, r.get_center().y), r.size.x, r.size.y, Color(0.22, 0.38, 0.15), 0.0, Vector2(1, 0))
	# The pool and its terrace, south of the house.
	var pool := Rect2(80.0, -120.0, 60.0, 22.0)
	if _is_free(bi, bj, pool.grow(4.0)):
		c.ground.flat(Vector3(pool.get_center().x, 0.016, pool.get_center().y), pool.size.x + 8.0, pool.size.y + 8.0, Color(0.85, 0.82, 0.74), 0.0, Vector2(1, 0))
		c.props.flat(Vector3(pool.get_center().x, 0.03, pool.get_center().y), pool.size.x, pool.size.y, Color(0.25, 0.65, 0.85))
		_reserve(bi, bj, pool.grow(4.0))
	# Hedge rows and the rose garden.
	for k in 6:
		var hz := -60.0 + float(k) * 9.0
		var hr := Rect2(30.0, hz, 40.0, 1.6)
		if _is_free(bi, bj, hr):
			c.props.box(Vector3(hr.get_center().x, 0.8, hr.get_center().y), Vector3(hr.size.x, 1.6, hr.size.y), Color(0.12, 0.26, 0.1))
			c.solid(Vector3(hr.get_center().x, 0.8, hr.get_center().y), Vector3(hr.size.x, 1.6, hr.size.y))
			for rk in 8:
				c.props.sphere(Vector3(hr.position.x + 2.5 + float(rk) * 5.0, 1.7, hr.get_center().y), 0.35, [Color(0.85, 0.15, 0.2), Color(0.95, 0.85, 0.9), Color(0.95, 0.6, 0.2)][rk % 3], 5, 3)
	# Lamps along the drive.
	for k2 in 6:
		var lp := Vector3(200.0, 0, -260.0 + float(k2) * 40.0)
		if _is_free(bi, bj, Rect2(lp.x - 1.0, lp.z - 1.0, 2.0, 2.0)):
			street_lamp_pair(lp.x, lp.z, PI * 0.5)


## The hill: woods, and the bunker in it.
func _hill_block(bi: int, bj: int, r: Rect2) -> void:
	var c := ctx_at(r.get_center().x, r.get_center().y)
	c.ground.flat(Vector3(r.get_center().x, 0.011, r.get_center().y), r.size.x, r.size.y, Color(0.18, 0.28, 0.12), 0.0, Vector2(1, 0))
	# The hill itself, a grassy mound behind the bunker door.
	landmark_far.props.sphere(Vector3(140.0, -26.0, 215.0), 52.0, Color(0.2, 0.32, 0.14), 12, 6)
	c.solid(Vector3(140.0, 6.0, 215.0), Vector3(60.0, 12.0, 60.0))
	_reserve(bi, bj, Rect2(100.0, 165.0, 80.0, 100.0))
	var tr := RandomNumberGenerator.new()
	tr.seed = 4410
	for k in 90:
		var p := Vector2(tr.randf_range(r.position.x + 4.0, r.end.x - 4.0), tr.randf_range(r.position.y + 4.0, r.end.y - 4.0))
		if not _is_free(bi, bj, Rect2(p.x - 2.0, p.y - 2.0, 4.0, 4.0)):
			continue
		var h := tr.randf_range(6.0, 11.0)
		c.props.box(Vector3(p.x, h * 0.35, p.y), Vector3(0.5, h * 0.7, 0.5), Color(0.3, 0.22, 0.14))
		c.props.sphere(Vector3(p.x, h * 0.8, p.y), tr.randf_range(2.2, 3.4), Color(0.12, 0.26, 0.1).lerp(Color(0.2, 0.34, 0.12), tr.randf()), 7, 4)
		c.solid(Vector3(p.x, 2.0, p.y), Vector3(0.6, 4.0, 0.6))


## Things only the island has: the dock and Price's yacht, his helicopter on
## its pad by the house, and the sign that tells you you're not welcome.
func _island_extras() -> void:
	var lf := landmark_far
	# The dock on the east shore and the yacht, LEVERAGE, moored to it.
	var dk := Vector3(380.0, 0, 40.0)
	var cd := ctx_at(dk.x, dk.z)
	lf.props.box(dk + Vector3(0.0, -0.05, 0), Vector3(60.0, 0.3, 5.0), Color(0.45, 0.34, 0.22))
	for k in 6:
		lf.props.box(dk + Vector3(-8.0 + float(k) * 7.0, -0.6, 2.4), Vector3(0.4, 2.0, 0.4), Color(0.3, 0.24, 0.16))
		lf.props.box(dk + Vector3(-8.0 + float(k) * 7.0, -0.6, -2.4), Vector3(0.4, 2.0, 0.4), Color(0.3, 0.24, 0.16))
	var yb := dk + Vector3(14.0, 0, 13.0)
	lf.props.box(yb + Vector3(0, 1.5, 0), Vector3(36.0, 4.0, 8.0), Color(0.95, 0.95, 0.94))
	lf.props.box(yb + Vector3(-2.0, 4.6, 0), Vector3(20.0, 2.4, 6.4), Color(0.9, 0.9, 0.9))
	lf.props.box(yb + Vector3(-3.0, 6.8, 0), Vector3(10.0, 2.0, 5.0), Color(0.88, 0.88, 0.88))
	lf.props.box(yb + Vector3(-2.0, 4.6, 0), Vector3(20.2, 1.0, 6.5), Color(0.1, 0.12, 0.16))
	lf.props.box(yb + Vector3(0, -0.2, 0), Vector3(36.2, 0.8, 8.2), Color(0.12, 0.14, 0.2))
	cd.label(yb + Vector3(16.0, 2.2, 4.05), "LEVERAGE", 120, Color(0.12, 0.14, 0.2), 0.0, 300.0, 0.02)
	cd.solid(yb + Vector3(0, 1.5, 0), Vector3(36.0, 4.0, 8.0))
	# The helicopter's pad on the lawn.
	var hp := Vector3(230.0, 0, -60.0)
	_helipad(ctx_at(hp.x, hp.z), hp)
	airfield_planes.append({"slot": "island_heli", "model": "heli", "pos": hp, "yaw": PI})
	# The sign at the strip.
	var sg := Vector3(-95.0, 0, 150.0)
	var cs := ctx_at(sg.x, sg.z)
	cs.props.box(sg + Vector3(0, 1.2, 0), Vector3(0.6, 2.4, 6.0), Color(0.25, 0.25, 0.27))
	cs.props.box(sg + Vector3(0, 2.4, 0), Vector3(0.3, 2.0, 5.6), Color(0.95, 0.95, 0.93))
	cs.label(sg + Vector3(-0.2, 2.8, 0), "PRIVATE ISLAND", 40, Color(0.7, 0.1, 0.1), -PI * 0.5, 80.0, 0.01)
	cs.label(sg + Vector3(-0.2, 2.2, 0), "NO LANDING WITHOUT PRIOR AUTHORIZATION · E CORP SECURITY", 16, Color(0.2, 0.2, 0.22), -PI * 0.5, 50.0, 0.01)
	cs.solid(sg + Vector3(0, 1.4, 0), Vector3(0.8, 2.8, 6.0))


# ------------------------------------------------------------ reservations
func _reserve(bi: int, bj: int, r: Rect2) -> void:
	var key := "%d,%d" % [bi, bj]
	if not reserved.has(key):
		reserved[key] = []
	(reserved[key] as Array).append(r)


func _is_free(bi: int, bj: int, r: Rect2) -> bool:
	var key := "%d,%d" % [bi, bj]
	if not reserved.has(key):
		return true
	for rr in reserved[key]:
		if (rr as Rect2).grow(0.5).intersects(r):
			return false
	return true


func _block_of(x: float, z: float) -> Vector2i:
	return Vector2i(int(floor((x - WorldLayout.AX0) / WorldLayout.AXS)), int(floor((z - WorldLayout.SZ0) / WorldLayout.SZS)))


func _reserve_landmarks() -> void:
	for id in WorldLayout.LANDMARKS.keys():
		var L: Dictionary = WorldLayout.LANDMARKS[id]
		var r: Array = L.get("plaza", L["rect"])
		var rect := Rect2(float(r[0]), float(r[1]), float(r[2]) - float(r[0]), float(r[3]) - float(r[1]))
		var b := _block_of(rect.get_center().x, rect.get_center().y)
		_reserve(b.x, b.y, rect)
		# Keep a walkway clear in front of the door to the block edge.
		for did in WorldLayout.landmark_doors(L):
			var dw := WorldLayout.door_world(did)
			if not dw.is_empty():
				var p: Vector3 = dw["pos"]
				var o: Vector3 = dw["out"]
				var a := Vector2(p.x, p.z)
				var e := a + Vector2(o.x, o.z) * 20.0
				_reserve(b.x, b.y, Rect2(minf(a.x, e.x) - 2.5, minf(a.y, e.y) - 2.5, absf(e.x - a.x) + 5.0, absf(e.y - a.y) + 5.0))
	for sid in WorldLayout.SUBWAYS.keys():
		var s: Dictionary = WorldLayout.SUBWAYS[sid]
		var r2: Array = s["rect"]
		var rect2 := Rect2(float(r2[0]) - 1.0, float(r2[1]) - 1.0, float(r2[2]) - float(r2[0]) + 2.0, float(r2[3]) - float(r2[1]) + 5.0)
		var b2 := _block_of(rect2.get_center().x, rect2.get_center().y)
		_reserve(b2.x, b2.y, rect2)
	# Neon Square: block (4,4) is an open plaza.
	_reserve(4, 4 + WorldLayout.BJ0, WorldLayout.block_rect(4, 4 + WorldLayout.BJ0))
	# Cemetery and rail yard.
	_reserve(0, WorldLayout.BJ0, WorldLayout.block_rect(0, WorldLayout.BJ0))
	_reserve(11, WorldLayout.BJ0, WorldLayout.block_rect(11, WorldLayout.BJ0))


# -------------------------------------------------------------------- roads
func _roads() -> void:
	var asphalt := Color(0.085, 0.085, 0.095)
	var walk := Color(0.26, 0.255, 0.25)
	var curb := Color(0.36, 0.35, 0.33)
	var paint := Color(0.75, 0.75, 0.7)
	var yellow := Color(0.8, 0.62, 0.15)
	var G := Vector2(1, 0) # ground wettable
	# Avenues.
	for i in WorldLayout.NA:
		var x := WorldLayout.ax(i)
		for j in WorldLayout.NS - 1:
			if not WorldLayout.avenue_segment_exists(i, j):
				continue
			var z0 := WorldLayout.sz(j) + WorldLayout.ST_HW
			var z1 := WorldLayout.sz(j + 1) - WorldLayout.ST_HW
			_avenue_segment(x, z0, z1, i, j, asphalt, walk, curb, paint, yellow, G)
		# Coney extension down to the boardwalk (not on the island: that's sea).
		if WorldLayout.region != "island":
			var zc0 := WorldLayout.sz(WorldLayout.NS - 1) + WorldLayout.ST_HW
			_avenue_segment(x, zc0, WorldLayout.SURF_Z - WorldLayout.ST_HW, i, 99, asphalt, walk, curb, paint, yellow, G)
	# Streets.
	for j in WorldLayout.NS:
		var z := WorldLayout.sz(j)
		for i in WorldLayout.NA - 1:
			if not WorldLayout.street_segment_exists(j, i):
				continue
			var x0 := WorldLayout.ax(i) + WorldLayout.AVE_HW
			var x1 := WorldLayout.ax(i + 1) - WorldLayout.AVE_HW
			_street_segment(z, x0, x1, i, j, asphalt, walk, curb, paint, G)
	# Surf Avenue (Coney).
	for i in (WorldLayout.NA - 1 if WorldLayout.region != "island" else 0):
		var x0s := WorldLayout.ax(i) + WorldLayout.AVE_HW
		var x1s := WorldLayout.ax(i + 1) - WorldLayout.AVE_HW
		_street_segment(WorldLayout.SURF_Z, x0s, x1s, i, 98, asphalt, walk, curb, paint, G)
	# Intersections.
	for i in WorldLayout.NA:
		for j in WorldLayout.NS:
			if WorldLayout.intersection_exists(i, j):
				_intersection(WorldLayout.ax(i), WorldLayout.sz(j), i, j, asphalt, walk, paint, G)
		if WorldLayout.region != "island":
			_intersection(WorldLayout.ax(i), WorldLayout.SURF_Z, i, 98, asphalt, walk, paint, G)


func _avenue_segment(x: float, z0: float, z1: float, i: int, j: int, asphalt: Color, walk: Color, curb: Color, paint: Color, yellow: Color, G: Vector2) -> void:
	var L := z1 - z0
	if L <= 1.0:
		return
	var zc := (z0 + z1) * 0.5
	var c := ctx_at(x, zc)
	var R := WorldLayout.AVE_ROAD
	var H := WorldLayout.AVE_HW
	c.ground.flat(Vector3(x, 0.0, zc), R * 2.0, L, asphalt, 0.0, G)
	c.ground.flat(Vector3(x - (R + H) * 0.5, 0.012, zc), H - R, L, walk, 0.0, G)
	c.ground.flat(Vector3(x + (R + H) * 0.5, 0.012, zc), H - R, L, walk, 0.0, G)
	c.props.flat(Vector3(x - R - 0.1, 0.04, zc), 0.2, L, curb, 0.0, G)
	c.props.flat(Vector3(x + R + 0.1, 0.04, zc), 0.2, L, curb, 0.0, G)
	# Double yellow + lane dashes.
	c.props.flat(Vector3(x - 0.12, 0.025, zc), 0.1, L, yellow)
	c.props.flat(Vector3(x + 0.12, 0.025, zc), 0.1, L, yellow)
	var z := z0 + 2.0
	while z < z1 - 2.0:
		c.props.flat(Vector3(x - 3.6, 0.025, z), 0.12, 2.6, paint)
		c.props.flat(Vector3(x + 3.6, 0.025, z), 0.12, 2.6, paint)
		z += 7.0
	# Lamps both sides, every 34 m.
	var dist := WorldLayout.district_at(x, zc)
	z = z0 + 8.0
	var k := 0
	while z < z1 - 4.0:
		street_lamp_pair(x - R - 0.5, z, PI * 0.5)
		street_lamp_pair(x + R + 0.5, z + 17.0 if z + 17.0 < z1 - 4.0 else z, -PI * 0.5)
		# Sidewalk clutter.
		var side := -1.0 if k % 2 == 0 else 1.0
		var sx: float = x + side * (R + 0.9)
		var pick := rng.randi() % 10
		var cc := ctx_at(sx, z + 8.0)
		if pick < 2:
			Props.place(cc, "trash", Vector3(sx, 0, z + 8.0))
			cc.solid(Vector3(sx, 0.45, z + 8.0), Vector3(0.6, 0.9, 0.6))
			_lootable("trash", Vector3(sx, 0.45, z + 8.0), Vector3(0.36, 0.5, 0.36))
		elif pick == 2:
			Props.place(cc, "hydrant", Vector3(sx, 0, z + 8.0))
		elif pick == 3:
			Props.place(cc, "newsbox", Vector3(sx, 0, z + 8.0), PI * 0.5 * side)
			cc.solid(Vector3(sx, 0.55, z + 8.0), Vector3(0.5, 1.1, 0.5))
			_lootable("newsbox", Vector3(sx, 0.55, z + 8.0), Vector3(0.3, 0.6, 0.3))
		elif pick == 4 and dist in ["midtown", "civic", "east_mid"]:
			Props.place(cc, "bus_shelter", Vector3(x + side * (R + 1.2), 0, z + 10.0), PI * 0.5 * side)
			cc.solid(Vector3(x + side * (R + 1.2), 1.2, z + 10.0), Vector3(1.6, 2.4, 4.0))
		elif pick == 5 and dist in ["uptown", "heights", "hells", "civic"]:
			Props.place(cc, "tree_pit", Vector3(sx, 0, z + 8.0))
			cc.solid(Vector3(sx, 1.2, z + 8.0), Vector3(0.3, 2.4, 0.3))
		elif pick == 6:
			Props.place(cc, "mailbox", Vector3(sx, 0, z + 8.0))
			cc.solid(Vector3(sx, 0.55, z + 8.0), Vector3(0.5, 1.1, 0.5))
			_lootable("mailbox", Vector3(sx, 0.55, z + 8.0), Vector3(0.3, 0.6, 0.3))
		elif pick == 7 and dist in ["midtown", "chinatown", "les", "coney"]:
			Props.place(cc, "food_cart", Vector3(sx, 0, z + 8.0), PI * 0.5 * side)
			cc.solid(Vector3(sx, 0.8, z + 8.0), Vector3(1.2, 1.6, 2.2))
			_lootable("food_cart", Vector3(sx, 0.8, z + 8.0), Vector3(0.66, 0.85, 1.16))
		elif pick == 8:
			Props.place(cc, "phone_booth", Vector3(sx, 0, z + 8.0), PI * 0.5 * side)
			cc.solid(Vector3(sx, 1.1, z + 8.0), Vector3(0.4, 2.2, 1.0))
			_lootable("phone", Vector3(sx, 1.1, z + 8.0), Vector3(0.26, 1.12, 0.56))
		elif pick == 9 and dist in ["midtown", "civic", "les", "chinatown", "hells", "east_mid", "uptown", "heights"]:
			Props.atm(cc, Vector3(sx, 0, z + 8.0), PI * 0.5 * side)
			_lootable("atm", Vector3(sx, 0.8, z + 8.0), Vector3(0.45, 0.85, 0.45), PI * 0.5 * side)
		z += 34.0
		k += 1
	# Parked cars along the parking lanes (not in Coney extension and not in midtown east side).
	if j != 99 and dist != "park":
		for side2 in [-1.0, 1.0]:
			var pz := z0 + 10.0 + rng.randf() * 6.0
			while pz < z1 - 10.0:
				if rng.randf() < 0.55:
					var typ: String = ["sedan", "sedan", "sedan", "hatch", "suv", "van", "taxi"][rng.randi() % 7]
					var ci := rng.randi() % Props.CAR_COLORS.size()
					var px: float = x + side2 * 5.2
					var cc2 := ctx_at(px, pz)
					var rot := 0.0 if side2 > 0 else PI
					Props.place(cc2, "car_%s_%d" % [typ, ci], Vector3(px, 0, pz), rot)
					cc2.solid(Vector3(px, 0.8, pz), Vector3(1.9, 1.6, 4.6))
					_lootable("taxi" if typ == "taxi" else "car", Vector3(px, 0.8, pz), Vector3(1.0, 0.86, 2.36), 0.0, {"car": typ, "ci": ci, "yaw": rot})
				pz += 7.5 + rng.randf() * 6.0
	# Street name sign at the segment start.
	if j >= 0 and j < WorldLayout.NS and j != 99:
		c.label(Vector3(x + H - 0.3, 3.1, z0 + 1.0), _ave_name(i), 42, Color(0.9, 0.95, 0.9), -PI * 0.5, 45.0, 0.01)
		c.props.box(Vector3(x + H - 0.35, 3.1, z0 + 1.0), Vector3(0.04, 0.34, 1.8), Color(0.05, 0.3, 0.15))
		c.props.box(Vector3(x + H - 0.3, 1.6, z0 + 0.3), Vector3(0.08, 3.2, 0.08), Color(0.12, 0.13, 0.12))


func street_lamp_pair(x: float, z: float, rot: float) -> void:
	var c := ctx_at(x, z)
	Props.street_lamp(c, Vector3(x, 0, z), rot)


func _street_segment(z: float, x0: float, x1: float, i: int, j: int, asphalt: Color, walk: Color, curb: Color, paint: Color, G: Vector2) -> void:
	var L := x1 - x0
	var xc := (x0 + x1) * 0.5
	var c := ctx_at(xc, z)
	var R := WorldLayout.ST_ROAD
	var H := WorldLayout.ST_HW
	c.ground.flat(Vector3(xc, 0.0, z), L, R * 2.0, asphalt, 0.0, G)
	c.ground.flat(Vector3(xc, 0.012, z - (R + H) * 0.5), L, H - R, walk, 0.0, G)
	c.ground.flat(Vector3(xc, 0.012, z + (R + H) * 0.5), L, H - R, walk, 0.0, G)
	c.props.flat(Vector3(xc, 0.04, z - R - 0.1), L, 0.2, curb, 0.0, G)
	c.props.flat(Vector3(xc, 0.04, z + R + 0.1), L, 0.2, curb, 0.0, G)
	var x := x0 + 2.0
	while x < x1 - 2.0:
		c.props.flat(Vector3(x, 0.025, z), 2.4, 0.12, paint)
		x += 6.0
	# Lamps alternate sides.
	x = x0 + 12.0
	var s := 1.0
	while x < x1 - 6.0:
		street_lamp_pair(x, z + s * (R + 0.5), PI if s > 0 else 0.0)
		s = -s
		x += 30.0
	var dist := WorldLayout.district_at(xc, z)
	if j < 98 and dist != "park" and dist != "steel":
		for side in [-1.0, 1.0]:
			var px := x0 + 8.0 + rng.randf() * 6.0
			while px < x1 - 8.0:
				if rng.randf() < 0.5:
					var typ: String = ["sedan", "sedan", "hatch", "suv", "van", "taxi", "sedan"][rng.randi() % 7]
					var ci := rng.randi() % Props.CAR_COLORS.size()
					var pz: float = z + side * 3.3
					var cc := ctx_at(px, pz)
					if not _in_chop_bay(px, pz):
						Props.place(cc, "car_%s_%d" % [typ, ci], Vector3(px, 0, pz), PI * 0.5 if side > 0 else -PI * 0.5)
						cc.solid(Vector3(px, 0.8, pz), Vector3(4.6, 1.6, 1.9))
						_lootable("taxi" if typ == "taxi" else "car", Vector3(px, 0.8, pz), Vector3(2.36, 0.86, 1.0), 0.0, {"car": typ, "ci": ci, "yaw": PI * 0.5 if side > 0 else -PI * 0.5})
				px += 7.0 + rng.randf() * 7.0
		# Chinatown: lanterns strung across the street.
		if dist == "chinatown":
			var lx := x0 + 10.0
			while lx < x1 - 5.0:
				c.props.box(Vector3(lx, 6.5, z), Vector3(0.02, 0.02, H * 2.0), Color(0.1, 0.1, 0.1))
				for k in 5:
					c.glow.sphere(Vector3(lx, 6.2, z - H + 1.5 + float(k) * (H * 2.0 - 3.0) / 4.0), 0.3, Color(1.0, 0.2, 0.12), 6, 4, Vector2(Props.K_ALWAYS, 0), 1.2)
				lx += 14.0
	if j < WorldLayout.NS:
		var nm := _st_name(j)
		if j == 98:
			nm = "SURF AVE"
		c.label(Vector3(x0 + 1.0, 3.1, z - H + 0.3), nm, 42, Color(0.9, 0.95, 0.9), 0.0, 45.0, 0.01)
		c.props.box(Vector3(x0 + 1.0, 3.1, z - H + 0.25), Vector3(1.8, 0.34, 0.04), Color(0.05, 0.3, 0.15))
		c.props.box(Vector3(x0 + 0.3, 1.6, z - H + 0.3), Vector3(0.08, 3.2, 0.08), Color(0.12, 0.13, 0.12))


func _intersection(x: float, z: float, i: int, j: int, asphalt: Color, walk: Color, paint: Color, G: Vector2) -> void:
	var c := ctx_at(x, z)
	var AH := WorldLayout.AVE_HW
	var AR := WorldLayout.AVE_ROAD
	var SH := WorldLayout.ST_HW
	var SR := WorldLayout.ST_ROAD
	c.ground.flat(Vector3(x, 0.0, z), AR * 2.0, SH * 2.0, asphalt, 0.0, G)
	c.ground.flat(Vector3(x - (AR + AH) * 0.5, 0.0, z), AH - AR, SR * 2.0, asphalt, 0.0, G)
	c.ground.flat(Vector3(x + (AR + AH) * 0.5, 0.0, z), AH - AR, SR * 2.0, asphalt, 0.0, G)
	# Sidewalk corners.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			c.ground.flat(Vector3(x + sx * (AR + AH) * 0.5, 0.012, z + sz * (SR + SH) * 0.5), AH - AR, SH - SR, walk, 0.0, G)
	# Crosswalks.
	for sz2 in [-1.0, 1.0]:
		var zz: float = z + sz2 * (SR - 1.2)
		var k := -AR + 0.6
		while k < AR:
			c.props.flat(Vector3(x + k, 0.025, zz), 0.5, 2.0, paint)
			k += 1.1
	for sx2 in [-1.0, 1.0]:
		var xx: float = x + sx2 * (AR - 1.2)
		var k2 := -SR + 0.6
		while k2 < SR:
			c.props.flat(Vector3(xx, 0.025, z + k2), 2.0, 0.5, paint)
			k2 += 1.1
	# Traffic lights on two opposite corners.
	if j < 98 or j == 98:
		Props.place(c, "tl_ns", Vector3(x - AR - 0.8, 0, z - SR - 0.8), PI * 0.5)
		Props.place(c, "tl_ew", Vector3(x + AR + 0.8, 0, z + SR + 0.8), -PI * 0.5)
		c.solid(Vector3(x - AR - 0.8, 2.0, z - SR - 0.8), Vector3(0.3, 4.0, 0.3))
		c.solid(Vector3(x + AR + 0.8, 2.0, z + SR + 0.8), Vector3(0.3, 4.0, 0.3))
	if rng.randf() < 0.12:
		Props.place(c, "steam", Vector3(x + rng.randf_range(-3, 3), 0, z + rng.randf_range(-2, 2)))
	elif rng.randf() < 0.3:
		Props.place(c, "manhole", Vector3(x + rng.randf_range(-3, 3), 0, z + rng.randf_range(-2, 2)))


# ------------------------------------------------------------------- blocks
const DIST_PARAMS := {
	"les": {"lot": [9.0, 16.0], "depth": [24.0, 30.0], "h": [13.0, 22.0], "styles": [1, 1, 1, 6], "fe": 0.7, "shops": 0.75, "tall": 0.05, "tall_h": [30.0, 45.0], "alley": 0.45, "cols": "brick"},
	"heights": {"lot": [8.0, 13.0], "depth": [22.0, 28.0], "h": [11.0, 20.0], "styles": [2, 2, 1, 8], "fe": 0.35, "shops": 0.3, "tall": 0.15, "tall_h": [28.0, 40.0], "alley": 0.35, "cols": "brown"},
	"hells": {"lot": [10.0, 18.0], "depth": [24.0, 30.0], "h": [14.0, 28.0], "styles": [1, 2, 8, 3], "fe": 0.5, "shops": 0.6, "tall": 0.15, "tall_h": [36.0, 60.0], "alley": 0.4, "cols": "mixed"},
	"uptown": {"lot": [14.0, 26.0], "depth": [26.0, 30.0], "h": [24.0, 46.0], "styles": [2, 8, 8, 4], "fe": 0.0, "shops": 0.35, "tall": 0.25, "tall_h": [60.0, 95.0], "alley": 0.2, "cols": "stone"},
	"civic": {"lot": [22.0, 40.0], "depth": [26.0, 30.0], "h": [26.0, 55.0], "styles": [8, 3, 3], "fe": 0.0, "shops": 0.4, "tall": 0.3, "tall_h": [70.0, 110.0], "alley": 0.15, "cols": "stone"},
	"chinatown": {"lot": [8.0, 14.0], "depth": [24.0, 30.0], "h": [11.0, 24.0], "styles": [6, 6, 1], "fe": 0.55, "shops": 0.95, "tall": 0.05, "tall_h": [30.0, 40.0], "alley": 0.5, "cols": "china"},
	"east_mid": {"lot": [20.0, 36.0], "depth": [26.0, 30.0], "h": [30.0, 70.0], "styles": [3, 8, 4], "fe": 0.0, "shops": 0.5, "tall": 0.35, "tall_h": [80.0, 130.0], "alley": 0.1, "cols": "stone"},
	# The new boroughs.
	"harlem": {"lot": [7.0, 11.0], "depth": [20.0, 26.0], "h": [12.0, 20.0], "styles": [2, 2, 1, 8], "fe": 0.45, "shops": 0.45, "tall": 0.08, "tall_h": [30.0, 45.0], "alley": 0.4, "cols": "brown"},
	"bronx": {"lot": [10.0, 18.0], "depth": [24.0, 30.0], "h": [14.0, 24.0], "styles": [1, 1, 2], "fe": 0.6, "shops": 0.55, "tall": 0.22, "tall_h": [40.0, 70.0], "alley": 0.45, "cols": "brick"},
	"inwood": {"lot": [10.0, 16.0], "depth": [22.0, 28.0], "h": [12.0, 22.0], "styles": [2, 1, 8], "fe": 0.4, "shops": 0.4, "tall": 0.1, "tall_h": [25.0, 40.0], "alley": 0.35, "cols": "stone"},
	"astoria": {"lot": [7.0, 12.0], "depth": [18.0, 24.0], "h": [8.0, 14.0], "styles": [1, 2, 6], "fe": 0.3, "shops": 0.55, "tall": 0.03, "tall_h": [20.0, 30.0], "alley": 0.5, "cols": "mixed"},
	# Chicago and the road.
	"west": {"lot": [10.0, 18.0], "depth": [24.0, 30.0], "h": [10.0, 22.0], "styles": [1, 1, 5, 2], "fe": 0.4, "shops": 0.5, "tall": 0.08, "tall_h": [30.0, 45.0], "alley": 0.6, "cols": "brick"},
	"south": {"lot": [8.0, 14.0], "depth": [22.0, 28.0], "h": [8.0, 16.0], "styles": [1, 2, 1], "fe": 0.35, "shops": 0.55, "tall": 0.04, "tall_h": [20.0, 30.0], "alley": 0.55, "cols": "brick"},
	"lake": {"lot": [18.0, 30.0], "depth": [26.0, 30.0], "h": [28.0, 60.0], "styles": [8, 2, 4], "fe": 0.0, "shops": 0.3, "tall": 0.35, "tall_h": [70.0, 120.0], "alley": 0.1, "cols": "stone"},
	"town": {"lot": [8.0, 14.0], "depth": [18.0, 22.0], "h": [6.0, 11.0], "styles": [1, 2], "fe": 0.1, "shops": 0.7, "tall": 0.0, "tall_h": [12.0, 14.0], "alley": 0.4, "cols": "mixed"},
	"lic": {"lot": [16.0, 30.0], "depth": [26.0, 30.0], "h": [14.0, 30.0], "styles": [5, 4, 3, 1], "fe": 0.1, "shops": 0.35, "tall": 0.35, "tall_h": [80.0, 160.0], "alley": 0.2, "cols": "stone"},
	# The small towns off the interstate.
	"tw_main": {"lot": [8.0, 14.0], "depth": [16.0, 22.0], "h": [6.0, 11.0], "styles": [1, 2, 1], "fe": 0.1, "shops": 0.9, "tall": 0.0, "tall_h": [12.0, 14.0], "alley": 0.45, "cols": "brick"},
	"pt_town": {"lot": [7.0, 12.0], "depth": [16.0, 24.0], "h": [6.0, 12.0], "styles": [1, 2, 6], "fe": 0.15, "shops": 0.6, "tall": 0.04, "tall_h": [15.0, 20.0], "alley": 0.5, "cols": "mixed"},
	"rm_town": {"lot": [10.0, 16.0], "depth": [16.0, 24.0], "h": [7.0, 12.0], "styles": [2, 2, 8], "fe": 0.0, "shops": 0.85, "tall": 0.0, "tall_h": [12.0, 14.0], "alley": 0.3, "cols": "stone"},
	"gy_town": {"lot": [9.0, 16.0], "depth": [18.0, 26.0], "h": [7.0, 16.0], "styles": [1, 1, 2, 8], "fe": 0.3, "shops": 0.55, "tall": 0.06, "tall_h": [24.0, 40.0], "alley": 0.4, "cols": "brick"},
}


func _palette(kind: String) -> Color:
	match kind:
		"brick":
			return [Color(0.38, 0.18, 0.13), Color(0.32, 0.2, 0.16), Color(0.42, 0.26, 0.2), Color(0.28, 0.16, 0.14), Color(0.36, 0.3, 0.26), Color(0.5, 0.32, 0.22)][rng.randi() % 6]
		"brown":
			return [Color(0.34, 0.22, 0.16), Color(0.3, 0.2, 0.15), Color(0.42, 0.3, 0.22), Color(0.46, 0.4, 0.34), Color(0.36, 0.2, 0.15)][rng.randi() % 5]
		"stone":
			return [Color(0.52, 0.5, 0.46), Color(0.46, 0.44, 0.4), Color(0.6, 0.56, 0.5), Color(0.4, 0.4, 0.42), Color(0.55, 0.47, 0.38)][rng.randi() % 5]
		"china":
			return [Color(0.42, 0.3, 0.22), Color(0.5, 0.42, 0.32), Color(0.35, 0.2, 0.16), Color(0.45, 0.45, 0.42), Color(0.55, 0.3, 0.2)][rng.randi() % 5]
		"glass":
			return [Color(0.18, 0.22, 0.28), Color(0.25, 0.3, 0.34), Color(0.3, 0.3, 0.3), Color(0.14, 0.18, 0.22)][rng.randi() % 4]
		"warehouse":
			return [Color(0.34, 0.3, 0.26), Color(0.3, 0.3, 0.3), Color(0.4, 0.32, 0.24), Color(0.28, 0.3, 0.32)][rng.randi() % 4]
	return _palette(["brick", "stone", "brown"][rng.randi() % 3])


func _block(bi: int, bj: int) -> void:
	var d := WorldLayout.district(bi, bj)
	var r := WorldLayout.block_rect(bi, bj)
	if d == "park" or d == "steel" or d == "tryon" or d == "airfield":
		return
	var lj := bj - WorldLayout.BJ0
	if bi == 4 and lj == 4:
		_neon_square(r)
		return
	if bi == 0 and lj == 0:
		_cemetery(r)
		return
	if bi == 11 and lj == 0:
		_rail_yard(r)
		return
	match d:
		"midtown":
			_midtown_block(bi, bj, r)
		"industrial", "hunts":
			_industrial_block(bi, bj, r)
		"docks":
			_docks_block(bi, bj, r)
		_:
			_street_wall_block(bi, bj, r, d)


func _street_wall_block(bi: int, bj: int, r: Rect2, d: String) -> void:
	var P: Dictionary = DIST_PARAMS.get(d, DIST_PARAMS["les"])
	var alley := rng.randf() < float(P["alley"])
	var small_town := d in ["tw_main", "pt_town", "gy_town", "rm_town"]
	if small_town:
		alley = false # deep small-town blocks get a parking lot out back instead
	var depth_n := rng.randf_range(float(P["depth"][0]), float(P["depth"][1]))
	var depth_s := rng.randf_range(float(P["depth"][0]), float(P["depth"][1]))
	if alley:
		depth_n = (r.size.y - 6.0) * 0.5
		depth_s = depth_n
	depth_n = minf(depth_n, r.size.y * 0.5 - 1.0)
	depth_s = minf(depth_s, r.size.y * 0.5 - 1.0)
	# North row faces north (-Z), south row faces south (+Z).
	_fill_row(bi, bj, r.position.x, r.end.x, r.position.y, r.position.y + depth_n, -1.0, P, d)
	_fill_row(bi, bj, r.position.x, r.end.x, r.end.y - depth_s, r.end.y, 1.0, P, d)
	# Backyard / alley clutter.
	var yz0 := r.position.y + depth_n
	var yz1 := r.end.y - depth_s
	if small_town and yz1 - yz0 > 24.0:
		_town_lot(Rect2(r.position.x, yz0, r.size.x, yz1 - yz0))
		return
	if yz1 - yz0 > 2.0:
		var c := ctx_at(r.get_center().x, (yz0 + yz1) * 0.5)
		var yard := Color(0.14, 0.14, 0.14) if alley else Color(0.18, 0.2, 0.16)
		c.ground.flat(Vector3(r.get_center().x, 0.01, (yz0 + yz1) * 0.5), r.size.x, yz1 - yz0, yard, 0.0, Vector2(1, 0))
		var n := int(r.size.x / 22.0)
		for k in n:
			var px := r.position.x + 8.0 + float(k) * 22.0 + rng.randf() * 6.0
			var pz := yz0 + 1.2 if rng.randf() < 0.5 else yz1 - 1.2
			var pick := rng.randi() % 4
			var cc := ctx_at(px, pz)
			if pick == 0:
				Props.place(cc, "dumpster", Vector3(px, 0, pz), 0.0 if pz < (yz0 + yz1) * 0.5 else PI)
				cc.solid(Vector3(px, 0.7, pz), Vector3(2.0, 1.4, 1.2))
				_lootable("dumpster", Vector3(px, 0.7, pz), Vector3(1.05, 0.74, 0.66))
			elif pick == 1:
				Props.place(cc, "bags", Vector3(px, 0, pz))
				_lootable("bags", Vector3(px + 0.2, 0.35, pz), Vector3(0.65, 0.4, 0.5))
			elif pick == 2:
				Props.place(cc, "crate", Vector3(px, 0, pz), rng.randf() * TAU)
				cc.solid(Vector3(px, 0.5, pz), Vector3(1.0, 1.0, 1.0))
				_lootable("crate", Vector3(px, 0.5, pz), Vector3(0.62, 0.55, 0.62))
		# Hidden stash: a tarp-covered box tucked against the back of a building.
		var hr := RandomNumberGenerator.new()
		hr.seed = hash(Vector2i(bi * 131 + 7, bj * 71 + 3))
		if hr.randf() < 0.3:
			var hx := r.position.x + hr.randf_range(6.0, r.size.x - 6.0)
			var hz := yz0 + 0.5 if hr.randf() < 0.5 else yz1 - 0.5
			var hc := ctx_at(hx, hz)
			hc.props.box(Vector3(hx, 0.2, hz), Vector3(0.7, 0.4, 0.5), Color(0.1, 0.16, 0.3))
			hc.props.box(Vector3(hx + 0.1, 0.42, hz), Vector3(0.5, 0.06, 0.4), Color(0.08, 0.13, 0.25))
			hc.props.box(Vector3(hx - 0.45, 0.08, hz + 0.1), Vector3(0.22, 0.16, 0.12), Color(0.45, 0.2, 0.15))
			_lootable("stash", Vector3(hx, 0.25, hz), Vector3(0.45, 0.3, 0.35))
		if alley:
			# Alley lamps over back doors.
			var ax := r.position.x + 15.0
			while ax < r.end.x - 10.0:
				var cc2 := ctx_at(ax, yz0)
				cc2.glow.box(Vector3(ax, 3.4, yz0 + 0.15), Vector3(0.3, 0.2, 0.2), Color(1.0, 0.85, 0.55), 0.0, Vector2(Props.K_NIGHT, 0))
				Props.light_pool(cc2, Vector3(ax, 0, yz0 + 2.0), 4.0, Color(1.0, 0.8, 0.5))
				ax += 28.0
		else:
			# Low fences split backyards.
			var fx := r.position.x + 20.0
			while fx < r.end.x - 10.0:
				Props.fence_line(ctx_at(fx, (yz0 + yz1) * 0.5), Vector3(fx, 0, yz0), Vector3(fx, 0, yz1), 1.6, Color(0.28, 0.24, 0.2), true)
				fx += 20.0 + rng.randf() * 15.0


## The middle of a small-town block: a municipal lot behind the shops, two
## rows of stalls, a few cars, lamps, a dumpster by the back doors.
func _town_lot(r: Rect2) -> void:
	var c := ctx_at(r.get_center().x, r.get_center().y)
	c.ground.flat(Vector3(r.get_center().x, 0.012, r.get_center().y), r.size.x, r.size.y, Color(0.12, 0.12, 0.13), 0.0, Vector2(1, 0))
	for row in [r.position.y + 7.0, r.end.y - 7.0]:
		var x := r.position.x + 6.0
		while x < r.end.x - 6.0:
			var cc := ctx_at(x, row)
			cc.props.flat(Vector3(x, 0.02, row), 0.15, 5.0, Color(0.78, 0.78, 0.72))
			if rng.randf() < 0.4 and x + 3.0 < r.end.x - 4.0:
				var ci := rng.randi() % Props.CAR_COLORS.size()
				var typ: String = ["sedan", "sedan", "hatch", "suv", "van"][rng.randi() % 5]
				var yaw := 0.0 if row < r.get_center().y else PI
				Props.place(cc, "car_%s_%d" % [typ, ci], Vector3(x + 1.5, 0, row), yaw)
				cc.solid(Vector3(x + 1.5, 0.8, row), Vector3(1.9, 1.6, 4.6))
				_lootable("car", Vector3(x + 1.5, 0.8, row), Vector3(1.0, 0.86, 2.36), 0.0, {"car": typ, "ci": ci, "yaw": yaw})
			x += 3.0
	var lx := r.position.x + 20.0
	while lx < r.end.x - 10.0:
		street_lamp_pair(lx, r.get_center().y, 0.0)
		lx += 40.0
	var dx := r.position.x + rng.randf_range(10.0, r.size.x - 10.0)
	Props.place(c, "dumpster", Vector3(dx, 0, r.position.y + 1.4), 0.0)
	c.solid(Vector3(dx, 0.7, r.position.y + 1.4), Vector3(2.0, 1.4, 1.2))
	_lootable("dumpster", Vector3(dx, 0.7, r.position.y + 1.4), Vector3(1.05, 0.74, 0.66))


func _fill_row(bi: int, bj: int, x0: float, x1: float, z0: float, z1: float, face: float, P: Dictionary, d: String) -> void:
	var x := x0
	while x < x1 - 3.0:
		var w := rng.randf_range(float(P["lot"][0]), float(P["lot"][1]))
		if x1 - (x + w) < float(P["lot"][0]) * 0.7:
			w = x1 - x
		var rect := Rect2(x, z0, w, z1 - z0)
		if _is_free(bi, bj, rect):
			var h := rng.randf_range(float(P["h"][0]), float(P["h"][1]))
			if rng.randf() < float(P["tall"]):
				h = rng.randf_range(float(P["tall_h"][0]), float(P["tall_h"][1]))
			var styles: Array = P["styles"]
			var st := int(styles[rng.randi() % styles.size()])
			var shops := rng.randf() < float(P["shops"])
			var col := _palette(str(P["cols"]))
			if st == 3 or st == 4:
				col = _palette("glass" if st == 4 else "stone")
			_building(Rect2(x + 0.15, z0, w - 0.3, z1 - z0), h, st, col, shops, face, d)
			# Corner lots also open onto the avenue.
			if x <= x0 + 0.01:
				_gen_door(Rect2(x + 0.15, z0, w - 0.3, z1 - z0), face, st, shops, d, "", INF, 0.0, -1.0)
			if x + w >= x1 - 0.01:
				_gen_door(Rect2(x + 0.15, z0, w - 0.3, z1 - z0), face, st, shops, d, "", INF, 0.0, 1.0)
		else:
			# Partially reserved: try to fill the gaps around reservations with narrower lots.
			_fill_gaps(bi, bj, rect, P, face, d)
		x += w


func _fill_gaps(bi: int, bj: int, rect: Rect2, P: Dictionary, face: float, d: String) -> void:
	var step := 4.0
	var cur := rect.position.x
	var start := -1.0
	while cur <= rect.end.x:
		var probe := Rect2(cur, rect.position.y, step, rect.size.y)
		var free := cur + step <= rect.end.x and _is_free(bi, bj, probe)
		if free and start < 0.0:
			start = cur
		if (not free or cur + step > rect.end.x) and start >= 0.0:
			var w := cur - start
			if w >= 6.0:
				var h := rng.randf_range(float(P["h"][0]), float(P["h"][1]))
				var styles: Array = P["styles"]
				_building(Rect2(start + 0.15, rect.position.y, w - 0.3, rect.size.y), h, int(styles[rng.randi() % styles.size()]), _palette(str(P["cols"])), rng.randf() < 0.5, face, d)
			start = -1.0
		cur += step


## Generic building: box with facade UVs, cornice, roof clutter, fire escape.
func _building(r: Rect2, h: float, style: int, col: Color, shops: bool, face: float, d: String, roof_kind: String = "", with_door: bool = true) -> void:
	var c := ctx_at(r.get_center().x, r.get_center().y)
	var seed := rng.randf_range(1.0, 97.0)
	_facade_box(c, r, 0.0, h, style, col, seed if shops else -seed)
	c.solid(Vector3(r.get_center().x, h * 0.5, r.get_center().y), Vector3(r.size.x, h, r.size.y))
	buildings.append([r.position.x, r.position.y, r.end.x, r.end.y, h, d])
	stats["buildings"] = int(stats["buildings"]) + 1
	# Cornice.
	var trim := col.lightened(0.12)
	c.facade.box(Vector3(r.get_center().x, h + 0.25, r.get_center().y), Vector3(r.size.x + 0.5, 0.5, r.size.y + 0.5), trim, 0.0, Vector2(0, 0))
	# Roof clutter.
	var rk := roof_kind
	if rk == "":
		rk = ["tank", "ac", "ac", "none", "stair"][rng.randi() % 5] if h < 50.0 else ["ac", "mech", "antenna", "stair"][rng.randi() % 4]
	var rp := Vector3(r.position.x + r.size.x * rng.randf_range(0.25, 0.75), h + 0.5, r.position.y + r.size.y * rng.randf_range(0.3, 0.7))
	match rk:
		"tank":
			if r.size.x > 6.0 and r.size.y > 6.0:
				Props.place(c, "water_tank", rp)
		"ac":
			Props.place(c, "ac_unit", rp, rng.randf() * 0.3)
		"mech":
			c.facade.box(Vector3(r.get_center().x, h + 2.5, r.get_center().y), Vector3(r.size.x * 0.45, 4.0, r.size.y * 0.45), col.darkened(0.2), 0.0, Vector2(0, 0))
		"antenna":
			Props.place(c, "antenna", rp)
		"stair":
			c.facade.box(rp + Vector3(0, 1.3, 0), Vector3(3.0, 2.6, 3.0), col.darkened(0.15), 0.0, Vector2(0, 0))
	# Fire escapes on the street face.
	var P: Dictionary = DIST_PARAMS.get(d, {})
	if style in [1, 6] and h < 30.0 and rng.randf() < float(P.get("fe", 0.0)) and r.size.x > 7.0:
		var fz := r.position.y if face < 0.0 else r.end.y
		Props.fire_escape(c, r.position.x, r.end.x, fz, face, int(h / 3.1), 3.1, 4.0 if shops else 0.0)
	# Awnings and shop signs on shopfronts.
	var awning_w := 0.0
	if shops and style in [1, 6, 9, 2] and rng.randf() < 0.55:
		var az := r.position.y if face < 0.0 else r.end.y
		var aw := minf(r.size.x - 1.0, 6.0)
		var acol: Color = [Color(0.45, 0.08, 0.06), Color(0.08, 0.3, 0.12), Color(0.1, 0.16, 0.4), Color(0.4, 0.3, 0.05), Color(0.2, 0.2, 0.22)][rng.randi() % 5]
		Props.awning(c, r.get_center().x, az, face, aw, acol)
		awning_w = aw
	var nd := gen_doors.size()
	if with_door:
		_gen_door(r, face, style, shops, d, "", INF, awning_w)
	if h < 70.0:
		# Keep the paint off the door this building just got (if any).
		var door_at := Vector3.INF
		if gen_doors.size() > nd:
			door_at = (gen_doors.back() as Dictionary)["pos"]
		_paint_jobs.append([c, r, face, d, door_at, h])
	if shops and (style == 6 or (d in ["les", "hells", "chinatown", "coney"] and rng.randf() < 0.35)):
		var sz2 := (r.position.y if face < 0.0 else r.end.y) + 0.06 * face
		var sc: Color = [Color(1, 0.3, 0.3), Color(0.3, 1, 0.5), Color(0.3, 0.7, 1), Color(1, 0.8, 0.3), Color(1, 0.4, 0.9)][rng.randi() % 5]
		var sw := minf(r.size.x - 2.0, 5.0)
		# Vertical blade sign or horizontal neon strip.
		if style == 6 and rng.randf() < 0.6:
			c.glow.box(Vector3(r.position.x + 1.0, 6.5, sz2 + 0.5 * face), Vector3(0.12, 3.5, 0.9), sc, 0.0, Vector2(Props.K_FLICKER if rng.randf() < 0.3 else Props.K_ALWAYS, rng.randf()))
		else:
			c.glow.box(Vector3(r.get_center().x, 3.75, sz2), Vector3(sw, 0.12, 0.06), sc, 0.0, Vector2(Props.K_ALWAYS, 0))


## Graffiti: tags, slogans and stencils at street level and down the alley
## walls, with their own RNG (seeded from the lot) so the city's layout is
## untouched. Some of it answers what you've done: the walls are on your side.
const TAGS_NYC := ["FSOCIETY", "HELLO FRIEND", "WAKE UP", "E CORP OWNS YOU", "DEBT IS A LIE", "OWN NOTHING?", "WHO IS MR. ROBOT", "NO GODS NO MASTERS NO E CORP", "THEY KNOW", "LOG OFF", "WE ARE FSOCIETY", "YOUR CREDIT SCORE IS NOT YOU", "E COIN = E CHAINS", "RESPAWN", "PRESS START", "LOOT BOXES = GAMBLING", "QUIT THE APP", "NOBODY OWNS ME", "ROOT", "0WN3D", "ARE YOU A 1 OR A 0", "REAL NEW YORK", "RENT IS THEFT", "STAY WOKE STAY LOGGED OUT"]
const TAGS_CREW := ["RICO", "C.H.", "VERA'S", "LES KINGS", "DUTCH WAS HERE", "KAOS", "SPYDA", "M3KA", "ZEPH", "TOXIK", "SKIP", "NOVA", "ROACH"]
const TAGS_CHI := ["LOU 4EVER", "WINDY CITY HACKS", "NOT ON THE APP", "PHONY STOLE MY GAMES", "PRINT THE ODDS", "SOUTH SIDE", "CHI-TOWN", "RESPAWN CHI", "YOU OWN WHAT YOU PAID FOR"]
const TAGS_ROAD := ["JESUS SAVES", "KEEP DRIVING", "TRUCKERS AGAINST FREIGHTOS", "TURN BACK", "E.A. WAS HERE", "LENNOX PA"]
const TAGS_TOWNSHIP := ["E CORP KILLED US", "26", "WHAT'S IN THE POND", "REMEMBER 1993", "THE STACKS RUN AT NIGHT", "WALT WAS RIGHT", "WTWP", "WE STILL DRINK THIS WATER"]
const TAGS_PORT := ["ASK TEDDY GRIECO", "NO FISH NO PEACE", "DARK SHIPS", "BERTH 2 KNOWS", "RAMSEY POINT", "WE FISHED HERE FIRST", "E CORP LOGISTICS = PIRATES"]
const TAGS_REDMONT := ["GIVE US BACK THE WATER", "SCRIP IS THEFT", "COPILOT DIDN'T VOTE FOR THIS", "UNINSTALL", "CTRL+ALT+DEL THEM", "RECALL THIS", "WE ARE NOT USERS", "EAST-1 DRINKS", "EMBER SAGA DESERVED BETTER"]
const TAGS_GARY := ["LOCAL 1014", "WE BUILT THIS", "WHO'S DRIVING?", "GARY 4 LIFE", "CITY OF THE CENTURY", "AN INJURY TO ONE", "THE MILL WILL RISE", "STEEL CITY", "BLINK"]
const SPRAY := [Color(1.0, 0.22, 0.25), Color(0.2, 0.95, 0.4), Color(0.25, 0.7, 1.0), Color(1.0, 0.85, 0.2), Color(1.0, 0.4, 0.95), Color(0.95, 0.95, 0.95), Color(1.0, 0.55, 0.15), Color(0.6, 0.4, 1.0)]


func _graffiti_pool(d: String) -> Array:
	var pool: Array = []
	match WorldLayout.region:
		"chicago":
			pool.append_array(TAGS_CHI)
			pool.append_array(TAGS_CREW.slice(5))
		"highway":
			pool.append_array(TAGS_ROAD)
		"township":
			pool.append_array(TAGS_TOWNSHIP)
			pool.append_array(TAGS_ROAD.slice(0, 3))
		"port":
			pool.append_array(TAGS_PORT)
		"gary":
			pool.append_array(TAGS_GARY)
			pool.append_array(TAGS_CREW.slice(0, 5))
		"redmont":
			pool.append_array(TAGS_REDMONT)
		_:
			pool.append_array(TAGS_NYC)
			pool.append_array(TAGS_CREW)
			if d in ["bronx", "hunts", "harlem"]:
				pool.append_array(["CANDY KILLS", "DANNY R.I.P.", "BRONX 4 LIFE", "WE MISS YOU DANNY"])
	# The walls remember.
	if GameState.has_flag("five_nine_done"):
		pool.append_array(["5/9", "5/9 NEVER FORGET", "THE DEBT IS GONE", "THANK YOU FSOCIETY"])
	if GameState.has_flag("rs_done"):
		pool.append_array(["#KENNYQA", "THE PLAYER IS A FUNNEL", "SHARK CARDS R.I.P."])
	if GameState.has_flag("ms_done"):
		pool.append_array(["GAME PASS AWAY? NO.", "MICROSLOP MASSACRE", "WE OWN OUR GAMES"])
	if GameState.has_flag("heat_on"):
		pool.append("THE HEAT IS ON")
	return pool


## Painting waits until the whole map is built (see _finish_graffiti), so
## the walls you can tag yourself are picked first and left clean for you.
var _paint_jobs: Array = [] # [ctx, lot rect, face, district, door position]
## Buffed walls the player can paint: [{id, pos, rot, span}] (see Game).
var tag_spots: Array = []
const TAGS_PER := {"nyc": 24, "chicago": 12, "township": 8, "port": 8, "gary": 8, "redmont": 8, "highway": 4, "island": 0}


## The walls of a lot worth painting: the street face either side of the
## door, and the two side walls (alleys and avenue corners).
func _paint_walls(r: Rect2, face: float, door_at: Vector3, g: RandomNumberGenerator) -> Array:
	var walls: Array = [] # [base pos on the wall, rot, usable width, street face?]
	var zf := (r.end.y if face > 0.0 else r.position.y) + 0.04 * face
	var rf := 0.0 if face > 0.0 else PI
	var dx := door_at.x if door_at != Vector3.INF and absf(door_at.z - zf) < 1.5 else INF
	if dx == INF:
		walls.append([Vector3(r.get_center().x, 0, zf), rf, r.size.x - 1.5, true])
	else:
		var lw := dx - 1.4 - r.position.x
		var rw := r.end.x - (dx + 1.4)
		if lw > 2.2:
			walls.append([Vector3(r.position.x + lw * 0.5 + 0.3, 0, zf), rf, lw - 0.6, true])
		if rw > 2.2:
			walls.append([Vector3(r.end.x - rw * 0.5 - 0.3, 0, zf), rf, rw - 0.6, true])
	if r.size.y > 6.0:
		for sxv in [-1.0, 1.0]:
			var sx: float = sxv
			var x2: float = (r.position.x if sx < 0.0 else r.end.x) + 0.04 * sx
			var dside: bool = door_at != Vector3.INF and absf(door_at.x - x2) < 1.5
			if not dside:
				walls.append([Vector3(x2, 0, r.get_center().y + g.randf_range(-r.size.y * 0.15, r.size.y * 0.15)), PI * 0.5 * sx, minf(r.size.y * 0.55, 7.0), false])
	return walls


func _finish_graffiti() -> void:
	# Pick the buffed walls first: street faces, wide enough, spread out.
	var cands: Array = []
	for j in _paint_jobs:
		var r: Rect2 = j[1]
		var g := RandomNumberGenerator.new()
		g.seed = hash(Vector2i(int(r.position.x * 7.0), int(r.position.y * 13.0))) + 911
		for w in _paint_walls(r, float(j[2]), j[4], g):
			if bool(w[3]) and float(w[2]) >= 3.6 and WorldLayout.in_bounds((w[0] as Vector3).x, (w[0] as Vector3).z):
				cands.append([j[0], w])
	var want := int(TAGS_PER.get(WorldLayout.region, 0))
	var pick := RandomNumberGenerator.new()
	pick.seed = hash("tag_walls_" + WorldLayout.region)
	var gap := 110.0 if WorldLayout.region == "nyc" else 60.0
	var taken: Array = []
	var tries := 0
	while tag_spots.size() < want and not cands.is_empty() and tries < 4000:
		tries += 1
		var k := pick.randi() % cands.size()
		var cw: Array = cands[k]
		cands.remove_at(k)
		var w: Array = cw[1]
		var p: Vector3 = w[0]
		if WorldLayout.district_at(p.x, p.z) in ["airfield", "park", "steel"]:
			continue
		var near := false
		for t in tag_spots:
			if ((t as Dictionary)["pos"] as Vector3).distance_to(p) < gap:
				near = true
				break
		if near:
			continue
		var span := minf(float(w[2]), 6.0)
		tag_spots.append({"id": "tag_%s_%d_%d" % [WorldLayout.region, int(round(p.x)), int(round(p.z))], "pos": p, "rot": float(w[1]), "span": span})
		taken.append(p)
		_buffed_wall(cw[0] as BuildCtx, p, float(w[1]), span)
	for j in _paint_jobs:
		_graffiti(j[0], j[1], float(j[2]), str(j[3]), j[4], taken)
		_heaven_spot(j[0], j[1], float(j[2]), str(j[3]), float(j[5]))
	_paint_jobs.clear()


## Now and then, a piece right up under the roofline where nobody could
## possibly have reached: the ones you see from three blocks away.
func _heaven_spot(c: BuildCtx, r: Rect2, face: float, d: String, h: float) -> void:
	if h < 10.0 or h > 48.0 or r.size.x < 9.0:
		return
	var g := RandomNumberGenerator.new()
	g.seed = hash(Vector2i(int(r.position.x * 3.0), int(r.position.y * 5.0))) + 4242
	var rough := d in ["les", "bronx", "hunts", "harlem", "chinatown", "hells", "west", "south", "inwood", "coney"] or WorldLayout.region in ["gary", "port", "township", "chicago"]
	if g.randf() > (0.16 if rough else 0.04):
		return
	var pool := _graffiti_pool(d)
	var txt: String = pool[g.randi() % pool.size()]
	var zf := (r.end.y if face > 0.0 else r.position.y) + 0.05 * face
	var rot := 0.0 if face > 0.0 else PI
	var span := r.size.x - 2.0
	var px := 0.02
	var fs := int(clampf(span / (float(txt.length()) * 0.6 * px), 60.0, 170.0))
	if float(txt.length()) * 0.6 * px * float(fs) > span:
		return
	var col: Color = SPRAY[g.randi() % SPRAY.size()]
	c.label(Vector3(r.get_center().x, h - 1.3, zf), txt, fs, col, rot, 320.0, px, {"outline": 16, "outline_col": Color(0.03, 0.03, 0.04), "tilt": g.randf_range(-0.05, 0.05), "font": "graffiti"})


## A freshly buffed patch of wall: flat grey primer over the old paint, a
## little E Corp notice, and somebody's abandoned spray cans at the foot of it.
func _buffed_wall(c: BuildCtx, p: Vector3, rot: float, span: float) -> void:
	var fwd := Vector3(sin(rot), 0, cos(rot))
	var right := Vector3(cos(rot), 0, -sin(rot))
	c.props.box(p + fwd * 0.012 + Vector3(0, 1.75, 0), Vector3(span, 2.3, 0.012), Color(0.6, 0.6, 0.58), rot)
	c.label(p + fwd * 0.03 + right * (span * 0.5 - 0.6) + Vector3(0, 0.75, 0), "SURFACE PROTECTED BY\nE CORP COMMUNITY CARE", 18, Color(0.15, 0.25, 0.5), rot, 18.0, 0.006)
	for k in 2:
		var cp := p + fwd * 0.3 + right * (-span * 0.3 + float(k) * 0.25)
		c.props.cyl(cp, 0.035, 0.035, 0.2, [Color(0.9, 0.15, 0.15), Color(0.15, 0.6, 0.95)][k], 6)


func _graffiti(c: BuildCtx, r: Rect2, face: float, d: String, door_at: Vector3 = Vector3.INF, keep_clean: Array = []) -> void:
	var g := RandomNumberGenerator.new()
	g.seed = hash(Vector2i(int(r.position.x * 7.0), int(r.position.y * 13.0))) + 911
	var walls := _paint_walls(r, face, door_at, g)
	var rough := d in ["les", "bronx", "hunts", "harlem", "chinatown", "hells", "west", "south", "inwood", "coney"] or WorldLayout.region != "nyc"
	var chance := 0.85 if rough else 0.4
	if g.randf() > chance:
		return
	var pool := _graffiti_pool(d)
	for wi2 in range(walls.size() - 1, -1, -1):
		for kp in keep_clean:
			if ((walls[wi2] as Array)[0] as Vector3).distance_to(kp) < 1.0:
				walls.remove_at(wi2)
				break
	if walls.is_empty():
		return
	var n := mini(walls.size(), 1 + (1 if g.randf() < 0.6 else 0) + (1 if rough and g.randf() < 0.45 else 0))
	for k in n:
		var wi := g.randi() % walls.size()
		var w: Array = walls[wi]
		walls.remove_at(wi)
		var pos: Vector3 = w[0]
		var rot: float = w[1]
		var span: float = w[2]
		if span < 1.4:
			continue
		var col: Color = SPRAY[g.randi() % SPRAY.size()]
		if g.randf() < 0.18:
			_mask_stencil(c, pos + Vector3(0, g.randf_range(1.4, 2.0), 0), rot, minf(g.randf_range(0.8, 1.2), span * 0.8))
			continue
		var txt: String = pool[g.randi() % pool.size()]
		# Tags (a quick marker scrawl), throw-ups (fat bubble letters, fill and
		# a heavy outline) and, on a wide wall, a proper piece with a backdrop.
		var style := 0 if g.randf() < 0.4 else 1
		if span > 4.5 and g.randf() < 0.45:
			style = 2
		paint_tag(c, pos, rot, span, txt, col, g, style)
		# Writers hit the same wall: a few small marker tags around it.
		if rough and g.randf() < 0.45:
			var right := Vector3(cos(rot), 0, -sin(rot))
			for t in g.randi_range(1, 2):
				var tt: String = TAGS_CREW[g.randi() % TAGS_CREW.size()] if g.randf() < 0.6 else pool[g.randi() % pool.size()]
				var tp := pos + right * g.randf_range(-span * 0.45, span * 0.45)
				var tc: Color = SPRAY[g.randi() % SPRAY.size()]
				var tfs := g.randi_range(36, 60)
				c.label(tp + Vector3(0, g.randf_range(0.5, 2.8), 0) + Vector3(sin(rot), 0, cos(rot)) * 0.005, tt, tfs, tc, rot, 45.0, 0.008, {"outline": 3, "outline_col": tc.darkened(0.6), "tilt": g.randf_range(-0.15, 0.15), "font": "marker"})


## Letters (and drips; for a piece, a backdrop and a shadow) on a wall at
## `pos` facing `rot`. style 0 tag, 1 throw-up, 2 piece. Also used by Game for
## the walls you paint yourself.
static func paint_tag(c: BuildCtx, pos: Vector3, rot: float, span: float, txt: String, col: Color, g: RandomNumberGenerator, style: int) -> void:
	var piece := style == 2
	# Letters about 0.6 of the font size wide: fit the text to the wall.
	var px: float = 0.009 if style == 0 else 0.014
	var fs_max: float = [90.0, 130.0, 150.0][style]
	var fs := int(clampf(span / (float(txt.length()) * 0.6 * px), 40.0, fs_max))
	var tw := float(txt.length()) * 0.6 * px * float(fs)
	if tw > span:
		return
	var y := g.randf_range(1.3, 2.0) if piece else g.randf_range(0.9, 2.5)
	var fwd := Vector3(sin(rot), 0, cos(rot))
	var right := Vector3(cos(rot), 0, -sin(rot))
	var tilt := g.randf_range(-0.1, 0.1)
	if piece:
		var bg: Color = SPRAY[g.randi() % SPRAY.size()].darkened(0.45)
		var bh := float(fs) * px * 1.25
		c.props.box(pos + fwd * 0.012 + Vector3(0, y, 0), Vector3(tw + 0.6, bh, 0.01), bg, rot)
		c.props.box(pos + fwd * 0.014 + Vector3(0, y - bh * 0.32, 0), Vector3(tw + 0.9, bh * 0.36, 0.01), bg.lightened(0.25), rot)
		for b in 6:
			var bp := pos + fwd * 0.013 + right * g.randf_range(-tw * 0.55, tw * 0.55) + Vector3(0, y + g.randf_range(-bh * 0.6, bh * 0.6), 0)
			c.props.box(bp, Vector3(g.randf_range(0.2, 0.5), g.randf_range(0.2, 0.5), 0.01), SPRAY[g.randi() % SPRAY.size()], rot)
		c.label(pos + fwd * 0.02 + right * 0.07 + Vector3(0, y - 0.07, 0), txt, fs, Color(0.04, 0.04, 0.05, 0.9), rot, 110.0, px, {"tilt": tilt, "font": "graffiti", "outline": 16, "outline_col": Color(0.04, 0.04, 0.05, 0.9)})
	match style:
		0:
			c.label(pos + Vector3(0, y, 0), txt, fs, col, rot, 70.0, px, {"outline": 4, "outline_col": col.darkened(0.6), "tilt": tilt, "font": "marker"})
		1:
			var line: Color = Color(0.03, 0.03, 0.04) if g.randf() < 0.6 else Color(0.97, 0.97, 0.94)
			c.label(pos + Vector3(0, y, 0), txt, fs, col, rot, 110.0, px, {"outline": 18, "outline_col": line, "tilt": tilt, "font": "graffiti"})
		_:
			c.label(pos + fwd * 0.03 + Vector3(0, y, 0), txt, fs, col, rot, 110.0, px, {"outline": 14, "outline_col": Color(0.98, 0.98, 0.95), "tilt": tilt, "font": "graffiti"})
	# Drips under the paint.
	for dr in g.randi_range(1, 4):
		var off := right * g.randf_range(-tw * 0.45, tw * 0.45)
		var dl := g.randf_range(0.15, 0.55)
		c.props.box(pos + off + fwd * 0.01 + Vector3(0, y - float(fs) * px * 0.42 - dl * 0.5, 0), Vector3(0.035, dl, 0.01), col.darkened(0.15), rot)


static func _mask_stencil(c: BuildCtx, p: Vector3, rot: float, s: float) -> void:
	var b := Basis(Vector3.UP, rot)
	var fwd := b * Vector3(0, 0, 1)
	var put := func(off: Vector2, size: Vector2, col: Color, depth: float) -> void:
		c.props.box(p + b * Vector3(off.x * s, off.y * s, 0) + fwd * depth, Vector3(size.x * s, size.y * s, 0.01), col, rot)
	var white := Color(0.92, 0.92, 0.88)
	var black := Color(0.04, 0.04, 0.05)
	put.call(Vector2(0, 0), Vector2(0.72, 0.96), white, 0.01)
	put.call(Vector2(0, -0.36), Vector2(0.5, 0.26), white, 0.01)
	put.call(Vector2(-0.17, 0.16), Vector2(0.18, 0.05), black, 0.02)
	put.call(Vector2(0.17, 0.16), Vector2(0.18, 0.05), black, 0.02)
	put.call(Vector2(-0.17, 0.27), Vector2(0.2, 0.04), black, 0.02)
	put.call(Vector2(0.17, 0.27), Vector2(0.2, 0.04), black, 0.02)
	put.call(Vector2(0, -0.12), Vector2(0.44, 0.06), black, 0.02)
	put.call(Vector2(-0.2, -0.17), Vector2(0.06, 0.1), black, 0.02)
	put.call(Vector2(0.2, -0.17), Vector2(0.06, 0.1), black, 0.02)
	put.call(Vector2(0, -0.28), Vector2(0.34, 0.035), black, 0.02)
	put.call(Vector2(0, -0.42), Vector2(0.08, 0.1), black, 0.02)


## Put an enterable door on a generic building's street face and register it.
## Uses its own RNG seeded from the lot position so the rest of the city is
## generated exactly as before. kind_override / x_override for special lots.
## side_x: 0 = door on the street face (north/south, per `face`); -1/+1 =
## a corner door on the west/east avenue face.
func _gen_door(r: Rect2, face: float, style: int, shops: bool, d: String, kind_override: String = "", x_override: float = INF, awning_w: float = 0.0, side_x: float = 0.0) -> void:
	var flen := r.size.x if side_x == 0.0 else r.size.y
	if flen < 4.2 or d == "park" or d == "steel" or d == "airfield":
		return
	var drng := RandomNumberGenerator.new()
	drng.seed = hash(Vector3i(int(r.position.x * 10.0), int(r.position.y * 10.0), int(r.size.x * 10.0) + int(side_x * 7.0)))
	var fz := r.position.y if face < 0.0 else r.end.y
	var out := Vector3(0, 0, -1) if face < 0.0 else Vector3(0, 0, 1)
	var kind := kind_override if kind_override != "" else _door_kind(style, shops, d, drng)
	var x := x_override
	var pos := Vector3.ZERO
	var num := 0
	var street := ""
	if side_x == 0.0:
		if x == INF:
			if shops or kind in ["office", "bar", "diner", "restaurant"]:
				x = r.get_center().x
			else:
				x = drng.randf_range(r.position.x + 1.4, r.end.x - 1.4)
		pos = Vector3(x, 0, fz)
		num = 2 * int((x - WorldLayout.AX0) / 4.0) + (1 if face > 0.0 else 0) + 1
		street = _street_title(fz)
	else:
		var fx := r.position.x if side_x < 0.0 else r.end.x
		out = Vector3(side_x, 0, 0)
		var zz := r.get_center().y if shops else drng.randf_range(r.position.y + 1.4, r.end.y - 1.4)
		pos = Vector3(fx, 0, zz)
		x = fx
		fz = zz
		num = 2 * int((zz - WorldLayout.SZ0) / 4.0) + (1 if side_x > 0.0 else 0) + 1
		var ai := int(round((fx - WorldLayout.AX0) / WorldLayout.AXS))
		street = _ave_name(ai).capitalize()
	# Position-based id: stable across generator changes, so saves keep
	# their looted containers and picked locks.
	# Out of town the ids carry the map, so a door in Washington Township never
	# shares its loot or its lock with one in New York at the same spot.
	var pre := "" if WorldLayout.region == "nyc" else str({"highway": "hw", "chicago": "chi", "township": "tw", "port": "pt"}.get(WorldLayout.region, WorldLayout.region)) + "_"
	var id := "%sg%d_%d" % [pre, int(round(pos.x)), int(round(pos.z))]
	while _door_ids.has(id):
		id += "b"
	_door_ids[id] = true
	var e := {"id": id, "pos": pos, "out": out, "kind": kind, "district": d, "seed": drng.randi(), "addr": "%d %s" % [num, street]}
	e["name"] = _door_name(kind, e["addr"], drng)
	# Locks & hours.
	match kind:
		"apartment":
			if drng.randf() < 0.55:
				var base := {"uptown": 40, "east_mid": 35, "midtown": 35, "heights": 25, "les": 20, "hells": 20, "chinatown": 20, "civic": 30, "coney": 15}
				e["lock"] = clampi(int(base.get(d, 25)) + [0, 0, 10, 20, 35][drng.randi() % 5], 10, 75)
		"hideout":
			e["lock"] = [45, 55, 65, 75][drng.randi() % 4]
		"squat":
			pass
		"office":
			e["hours"] = [8, 19]
			e["closed_lock"] = [40, 50, 60, 70][drng.randi() % 4]
		"warehouse":
			if drng.randf() < 0.5:
				e["lock"] = [25, 35, 45, 55][drng.randi() % 4]
		"bar":
			e["hours"] = [16, 4]
			e["closed_lock"] = [30, 40, 50][drng.randi() % 3]
		"arcade":
			e["hours"] = [10, 2]
			e["closed_lock"] = [30, 40][drng.randi() % 2]
		_:
			e["hours"] = [7, 23] if kind != "diner" else [6, 24]
			e["closed_lock"] = [25, 35, 45, 55][drng.randi() % 4]
	# Visuals.
	var vis := "house"
	var leaf: Color = DOOR_LEAVES[drng.randi() % DOOR_LEAVES.size()]
	var plate := Color(0.95, 0.88, 0.7)
	if kind in ["grocery", "liquor", "electronics", "clothing", "hardware", "pawnshop", "diner", "restaurant", "bar", "arcade"]:
		vis = "shop"
		leaf = Color(0.2, 0.2, 0.22)
		plate = SHOP_NEON[drng.randi() % SHOP_NEON.size()]
	elif kind == "office":
		vis = "office"
		leaf = Color(0.38, 0.4, 0.45)
		plate = Color(0.7, 0.85, 1.0)
	elif kind == "warehouse":
		vis = "warehouse"
		leaf = Color(0.48, 0.46, 0.4)
		plate = Color(1.0, 0.72, 0.3)
	var dc := ctx_at(pos.x, pos.z)
	Props.door(dc, pos, out, plate, kind == "squat", vis, leaf)
	# Store names: printed on the awning valance if there is one, else a neon
	# sign band above the door. Short range so only nearby signs cost a draw.
	if vis == "shop" and (awning_w > 2.5 or drng.randf() < 0.6):
		var rot := atan2(out.x, out.z)
		var nm := str(e["name"]).to_upper()
		if side_x == 0.0 and awning_w > 2.5 and absf(x - r.get_center().x) < 0.5:
			dc.label(Vector3(x, 2.93, fz) + out * 1.43, nm, 44, Color(0.95, 0.95, 0.9), rot, 55.0, 0.01)
		else:
			var sw := minf(float(nm.length()) * 0.22 + 0.6, flen - 1.0)
			if sw > 1.6:
				Props.sign_band(dc, pos + out * 0.12 + Vector3(0, 3.42, 0), rot, sw, nm, plate, 0.5)
	gen_doors.append(e)
	stats["doors"] = int(stats["doors"]) + 1


func _door_kind(style: int, shops: bool, d: String, drng: RandomNumberGenerator) -> String:
	if style == 5:
		return "warehouse"
	if style in [3, 4, 7, 8]:
		return "office"
	if shops:
		var ks: Array = STORE_KINDS.get(d, STORE_KINDS["les"])
		return str(ks[drng.randi() % ks.size()])
	var r := drng.randf()
	if r < 0.1:
		return "squat"
	if r < 0.17:
		return "hideout"
	return "apartment"


func _street_title(z: float) -> String:
	if z > WorldLayout.CONEY_ROW_Z0 - 8.0:
		return "Surf Ave" if z > WorldLayout.CONEY_ROW_Z1 - 4.0 else "Neptune Ave"
	var a: Array = REGION_STREETS.get(WorldLayout.region, STREET_NAMES)
	var j := clampi(int(round((z - WorldLayout.SZ0) / WorldLayout.SZS)), 0, a.size() - 1)
	return str(a[j]).capitalize()


func _ave_name(i: int) -> String:
	var a: Array = REGION_AVENUES.get(WorldLayout.region, AVENUE_NAMES)
	return str(a[clampi(i, 0, a.size() - 1)])


func _st_name(j: int) -> String:
	var a: Array = REGION_STREETS.get(WorldLayout.region, STREET_NAMES)
	return str(a[j]) if j >= 0 and j < a.size() else ""


func _door_name(kind: String, addr: String, drng: RandomNumberGenerator) -> String:
	var sn: String = SURNAMES[drng.randi() % SURNAMES.size()]
	var pick := func(a: Array) -> String: return str(a[drng.randi() % a.size()]).replace("%s", sn)
	match kind:
		"apartment", "hideout":
			return addr
		"squat":
			return "Condemned — " + addr
		"grocery":
			return pick.call(["%s Grocery", "%s Deli & Grocery", "Corner Market", "%s Food Mart", "24/7 Deli", "%s Bros. Deli"])
		"liquor":
			return pick.call(["%s Liquors", "Wine & Spirits", "Discount Liquor", "%s Liquor Store"])
		"electronics":
			return pick.call(["%s Electronics", "Phone Repair", "Tech Fix", "Cell Zone", "%s Computers"])
		"clothing":
			return pick.call(["%s Boutique", "Thrift Store", "Discount Fashion", "Second Hand Rose", "%s Apparel"])
		"hardware":
			return pick.call(["%s Hardware", "Lock & Key", "Tools & Supply", "%s Hardware & Paint"])
		"pawnshop":
			return pick.call(["%s Pawn", "Cash for Gold", "Buy-Sell-Trade", "%s Loans & Pawn"])
		"diner":
			return pick.call(["%s Diner", "%s Pizza", "Halal Grill", "%s Coffee Shop", "Famous Original Ray's"])
		"restaurant":
			return pick.call(["Golden Dragon", "Jade Garden", "Lucky Noodle", "Hong Kong Kitchen", "Canton Palace", "Great Wall Dumplings"])
		"bar":
			return pick.call(["The Anchor", "%s's Tavern", "Last Call", "The Dive", "Blue Moon Lounge", "The Iron Horse", "Rusty Nail"])
		"arcade":
			return pick.call(["Boardwalk Arcade", "Fun Zone", "Skee-Ball Palace", "Pixel Pier"])
		"office":
			return pick.call(["%s & Partners", "%s Holdings", "%s Capital", "%s Consulting", "%s Insurance", "%s Media Group"])
		"warehouse":
			return pick.call(["%s Freight", "%s Storage", "%s Wholesale", "Bonded Warehouse"])
	return addr


## Register a searchable prop in the loot index.
func _lootable(kind: String, center: Vector3, he: Vector3, rot: float = 0.0, extra: Dictionary = {}) -> void:
	var e := {"k": kind, "p": center, "he": he, "r": rot}
	e.merge(extra)
	lootables.append(e)
	stats["lootables"] = int(stats["lootables"]) + 1


## Box with continuous facade UVs. Faces: 4 walls with windows + roof.
func _facade_box(c: BuildCtx, r: Rect2, y0: float, y1: float, style: int, col: Color, seed: float) -> void:
	var x0 := r.position.x
	var x1 := r.end.x
	var z0 := r.position.y
	var z1 := r.end.y
	var uv2 := Vector2(style, seed)
	var h := y1 - y0
	var w := x1 - x0
	var dd := z1 - z0
	var b := c.facade
	# North (-Z) face, seen from -Z: left is +X.
	b.quad(Vector3(x1, y0, z0), Vector3(x0, y0, z0), Vector3(x0, y1, z0), Vector3(x1, y1, z0), Vector3.FORWARD, col, Vector2(0, y0), Vector2(w, y1), uv2)
	# South (+Z).
	b.quad(Vector3(x0, y0, z1), Vector3(x1, y0, z1), Vector3(x1, y1, z1), Vector3(x0, y1, z1), Vector3.BACK, col, Vector2(0, y0), Vector2(w, y1), uv2)
	# East (+X).
	b.quad(Vector3(x1, y0, z1), Vector3(x1, y0, z0), Vector3(x1, y1, z0), Vector3(x1, y1, z1), Vector3.RIGHT, col.darkened(0.08), Vector2(0, y0), Vector2(dd, y1), uv2)
	# West (-X).
	b.quad(Vector3(x0, y0, z0), Vector3(x0, y0, z1), Vector3(x0, y1, z1), Vector3(x0, y1, z0), Vector3.LEFT, col.darkened(0.08), Vector2(0, y0), Vector2(dd, y1), uv2)
	# Roof.
	b.quad(Vector3(x0, y1, z1), Vector3(x1, y1, z1), Vector3(x1, y1, z0), Vector3(x0, y1, z0), Vector3.UP, Color(0.16, 0.16, 0.17), Vector2.ZERO, Vector2(w, dd), Vector2(0, 0))


func _midtown_block(bi: int, bj: int, r: Rect2) -> void:
	var layout := rng.randi() % 3
	var c := ctx_at(r.get_center().x, r.get_center().y)
	var tower_doors: Array = []
	# Plaza pavement.
	c.ground.flat(Vector3(r.get_center().x, 0.015, r.get_center().y), r.size.x, r.size.y, Color(0.3, 0.29, 0.28), 0.0, Vector2(1, 0))
	var towers: Array = []
	if layout == 0:
		towers.append(Rect2(r.position.x + 6, r.position.y + 6, r.size.x * rng.randf_range(0.5, 0.75), r.size.y - 12))
	elif layout == 1:
		var wa := r.size.x * 0.45
		towers.append(Rect2(r.position.x + 2, r.position.y + 2, wa, r.size.y - 4))
		towers.append(Rect2(r.end.x - wa - 2, r.position.y + 2, wa, r.size.y - 4))
	else:
		# Podium + slim tower.
		var pr := Rect2(r.position.x + 1, r.position.y + 1, r.size.x - 2, r.size.y - 2)
		if _is_free(bi, bj, pr):
			var col0 := _palette("stone")
			_building(pr, rng.randf_range(12.0, 20.0), 3, col0, true, 1.0, "midtown", "none")
			towers.append(Rect2(r.position.x + r.size.x * 0.25, r.position.y + 10, r.size.x * 0.5, r.size.y - 20))
	for t in towers:
		var tr: Rect2 = t
		if not _is_free(bi, bj, tr):
			continue
		var hgt := rng.randf_range(55.0, 175.0)
		var st: int = [3, 4, 8, 4][rng.randi() % 4]
		var col := _palette("glass" if st == 4 else "stone")
		# Stepped setbacks.
		var tiers := 1 + (1 if hgt > 90.0 else 0) + (1 if hgt > 140.0 else 0)
		var cur := tr
		var y := 0.0
		var cc := ctx_at(tr.get_center().x, tr.get_center().y)
		for k in tiers:
			var th: float = hgt * (float([1.0, 0.62, 0.4][tiers - 1]) if k == 0 else (0.25 if k == 1 else 0.15))
			if k == tiers - 1:
				th = hgt - y
			_facade_box(cc, cur, y, y + th, st, col, rng.randf_range(1, 90))
			cc.solid(Vector3(cur.get_center().x, y + th * 0.5, cur.get_center().y), Vector3(cur.size.x, th, cur.size.y))
			cc.facade.box(Vector3(cur.get_center().x, y + th + 0.3, cur.get_center().y), Vector3(cur.size.x + 0.6, 0.6, cur.size.y + 0.6), col.lightened(0.1), 0.0, Vector2.ZERO)
			y += th
			cur = cur.grow(-minf(cur.size.x, cur.size.y) * 0.14)
		buildings.append([tr.position.x, tr.position.y, tr.end.x, tr.end.y, hgt, "midtown"])
		stats["buildings"] = int(stats["buildings"]) + 1
		Props.place(cc, "beacon", Vector3(cur.get_center().x, hgt + 1.0, cur.get_center().y))
		if rng.randf() < 0.5:
			Props.place(cc, "antenna", Vector3(cur.get_center().x, hgt + 0.6, cur.get_center().y))
		# Lobby door (the podium layout already has one on the podium).
		if layout != 2:
			_gen_door(tr, 1.0, st, true, "midtown", "office", tr.get_center().x)
			tower_doors.append(tr.get_center().x)
	# Plaza dressing.
	for k in 4:
		var px := r.position.x + rng.randf_range(3, r.size.x - 3)
		var pz := r.end.y - 2.5
		var rr := Rect2(px - 1, pz - 1, 2, 2)
		var blocked := false
		for t in towers:
			if (t as Rect2).intersects(rr):
				blocked = true
		for tdx in tower_doors:
			if absf(float(tdx) - px) < 2.5:
				blocked = true
		if blocked:
			continue
		var pick := rng.randi() % 3
		if pick == 0:
			Props.place(c, "planter", Vector3(px, 0, pz))
			c.solid(Vector3(px, 0.4, pz), Vector3(1.2, 0.8, 1.2))
		elif pick == 1:
			Props.place(c, "bench", Vector3(px, 0, pz), PI)
			c.solid(Vector3(px, 0.4, pz), Vector3(1.8, 0.8, 0.5))
		else:
			Props.place(c, "bollard", Vector3(px, 0, pz))


func _industrial_block(bi: int, bj: int, r: Rect2) -> void:
	var c := ctx_at(r.get_center().x, r.get_center().y)
	c.ground.flat(Vector3(r.get_center().x, 0.012, r.get_center().y), r.size.x, r.size.y, Color(0.22, 0.21, 0.2), 0.0, Vector2(1, 0))
	var n := 1 + rng.randi() % 3
	var x := r.position.x + 2.0
	var ww := (r.size.x - 4.0) / float(n)
	for k in n:
		var wr := Rect2(x + 2.0, r.position.y + rng.randf_range(2, 10), ww - 4.0, r.size.y - rng.randf_range(14, 24))
		if _is_free(bi, bj, wr):
			_building(wr, rng.randf_range(8.0, 16.0), 5, _palette("warehouse"), false, -1.0, "industrial", "ac", false)
			# Loading doors.
			var lc := ctx_at(wr.get_center().x, wr.end.y)
			for q in int(wr.size.x / 8.0):
				lc.props.box(Vector3(wr.position.x + 4.0 + float(q) * 8.0, 2.0, wr.end.y + 0.05), Vector3(4.0, 4.0, 0.1), Color(0.35, 0.33, 0.3))
			# Personnel door beside the loading bays.
			_gen_door(wr, 1.0, 5, false, "industrial", "warehouse", wr.position.x + 1.0)
		x += ww
	# Yard: containers, pallets, a truck.
	for k in 3:
		var px := r.position.x + rng.randf_range(10, r.size.x - 10)
		var pz := r.end.y - rng.randf_range(3, 7)
		var rr := Rect2(px - 6, pz - 1.5, 12, 3)
		if not _is_free(bi, bj, rr):
			continue
		if rng.randf() < 0.5:
			Props.place(c, "container_%s" % ["a", "b", "c", "d"][rng.randi() % 4], Vector3(px, 0, pz), 0.0)
			c.solid(Vector3(px, 1.3, pz), Vector3(12, 2.6, 2.5))
			_lootable("shipping", Vector3(px, 1.3, pz), Vector3(6.1, 1.35, 1.3))
		else:
			Props.place(c, "car_truck_0", Vector3(px, 0, pz), PI * 0.5)
			c.solid(Vector3(px, 1.5, pz), Vector3(7.6, 3.0, 2.4), PI * 0.5)
			_lootable("truck", Vector3(px, 1.5, pz), Vector3(3.85, 1.55, 1.25), PI * 0.5)
	# Perimeter fence along the street edge with a gap.
	Props.fence_line(c, Vector3(r.position.x, 0, r.end.y), Vector3(r.get_center().x - 6.0, 0, r.end.y), 2.4)
	Props.fence_line(c, Vector3(r.get_center().x + 6.0, 0, r.end.y), Vector3(r.end.x, 0, r.end.y), 2.4)


func _docks_block(bi: int, bj: int, r: Rect2) -> void:
	var c := ctx_at(r.get_center().x, r.get_center().y)
	c.ground.flat(Vector3(r.get_center().x, 0.012, r.get_center().y), r.size.x, r.size.y, Color(0.24, 0.22, 0.2), 0.0, Vector2(1, 0))
	var wr := Rect2(r.position.x + 4.0, r.position.y + 4.0, r.size.x * rng.randf_range(0.45, 0.7), r.size.y - 8.0)
	if _is_free(bi, bj, wr):
		_building(wr, rng.randf_range(10.0, 15.0), 5, _palette("warehouse"), false, -1.0, "docks", "ac")
	# Container stacks.
	var sx := wr.end.x + 6.0
	var z := r.position.y + 6.0
	while z < r.end.y - 5.0:
		var cr := Rect2(sx - 1, z - 1.5, 13, 3)
		if sx + 12.0 < r.end.x and _is_free(bi, bj, cr):
			var stack := 1 + rng.randi() % 3
			for s in stack:
				Props.place(c, "container_%s" % ["a", "b", "c", "d"][rng.randi() % 4], Vector3(sx + 6.0, float(s) * 2.6, z), 0.0)
			c.solid(Vector3(sx + 6.0, float(stack) * 1.3, z), Vector3(12, float(stack) * 2.6, 2.5))
			_lootable("shipping", Vector3(sx + 6.0, 1.3, z), Vector3(6.1, 1.35, 1.3))
		z += 4.0


func _neon_square(r: Rect2) -> void:
	var c := ctx_at(r.get_center().x, r.get_center().y)
	c.ground.flat(Vector3(r.get_center().x, 0.016, r.get_center().y), r.size.x, r.size.y, Color(0.3, 0.12, 0.12), 0.0, Vector2(1, 0))
	# Red bleacher steps in the middle.
	for k in 6:
		c.props.box(Vector3(r.get_center().x, 0.25 + float(k) * 0.5, r.get_center().y + 6.0 - float(k) * 1.2), Vector3(18.0, 0.5, 1.2), Color(0.6, 0.08, 0.08))
		c.solid(Vector3(r.get_center().x, 0.25 + float(k) * 0.5, r.get_center().y + 6.0 - float(k) * 1.2), Vector3(18.0, 0.5, 1.2))
	# Walls of giant screens on frames around the edge.
	var cols := [Color(1, 0.2, 0.3), Color(0.2, 0.6, 1), Color(1, 0.8, 0.2), Color(0.3, 1, 0.5), Color(1, 0.4, 0.9), Color(0.9, 0.9, 1)]
	var texts := ["E CORP", "ECOIN", "BANK OF E", "CRAZY GOOD", "FEEL THE E", "E NEWS 24"]
	for k in 6:
		var bx := r.position.x + 10.0 + float(k) * (r.size.x - 20.0) / 5.0
		for side in [-1.0, 1.0]:
			var bz := r.position.y + 3.0 if side < 0 else r.end.y - 3.0
			var rot := 0.0 if side < 0 else PI
			var hh := 10.0 + float((k * 7) % 5) * 3.0
			c.props.box(Vector3(bx, hh * 0.5, bz), Vector3(0.6, hh, 0.6), Color(0.08, 0.08, 0.09))
			c.solid(Vector3(bx, hh * 0.5, bz), Vector3(0.8, hh, 0.8))
			c.glow.box(Vector3(bx, hh + 3.0, bz), Vector3(14.0, 7.0, 0.3), (cols[(k + int(side)) % cols.size()] as Color).darkened(0.35), 0.0, Vector2(Props.K_FLICKER if k % 3 == 0 else Props.K_ALWAYS, float(k)))
			c.label(Vector3(bx, hh + 3.0, bz + (0.2 if side < 0 else -0.2)), texts[(k + (1 if side > 0 else 0)) % texts.size()], 220, Color(1, 1, 1), rot, 420.0, 0.02)
	for k in 8:
		var px := r.position.x + rng.randf_range(8, r.size.x - 8)
		var pz := r.position.y + rng.randf_range(10, r.size.y - 10)
		Props.place(c, "food_cart" if k % 3 == 0 else "planter", Vector3(px, 0, pz), rng.randf() * TAU)
		c.solid(Vector3(px, 0.6, pz), Vector3(1.4, 1.2, 1.4))
		if k % 3 == 0:
			_lootable("food_cart", Vector3(px, 0.7, pz), Vector3(0.9, 0.8, 0.9))


func _cemetery(r: Rect2, family: String = "ALDERSON") -> void:
	var c := ctx_at(r.get_center().x, r.get_center().y)
	c.ground.flat(Vector3(r.get_center().x, 0.02, r.get_center().y), r.size.x, r.size.y, Color(0.12, 0.18, 0.1), 0.0, Vector2(1, 0))
	Props.fence_line(c, Vector3(r.position.x, 0, r.position.y), Vector3(r.end.x, 0, r.position.y), 2.0, Color(0.08, 0.08, 0.08))
	Props.fence_line(c, Vector3(r.position.x, 0, r.end.y), Vector3(r.get_center().x - 4.0, 0, r.end.y), 2.0, Color(0.08, 0.08, 0.08))
	Props.fence_line(c, Vector3(r.get_center().x + 4.0, 0, r.end.y), Vector3(r.end.x, 0, r.end.y), 2.0, Color(0.08, 0.08, 0.08))
	Props.fence_line(c, Vector3(r.position.x, 0, r.position.y), Vector3(r.position.x, 0, r.end.y), 2.0, Color(0.08, 0.08, 0.08))
	Props.fence_line(c, Vector3(r.end.x, 0, r.position.y), Vector3(r.end.x, 0, r.end.y), 2.0, Color(0.08, 0.08, 0.08))
	var z := r.position.y + 5.0
	while z < r.end.y - 5.0:
		var x := r.position.x + 5.0
		while x < r.end.x - 5.0:
			if absf(x - r.get_center().x) > 3.0:
				Props.place(c, "gravestone" if rng.randf() < 0.75 else "cross", Vector3(x + rng.randf_range(-0.4, 0.4), 0, z), rng.randf_range(-0.1, 0.1))
			x += 3.2
		z += 4.0
	for k in 10:
		var tx := r.position.x + rng.randf_range(4, r.size.x - 4)
		var tz := r.position.y + rng.randf_range(4, r.size.y - 4)
		Props.place(c, "tree_c", Vector3(tx, 0, tz), 0, 1.2)
		c.solid(Vector3(tx, 1.4, tz), Vector3(0.4, 2.8, 0.4))
	# Mausoleum.
	var mp := Vector3(r.position.x + 20, 0, r.position.y + 14)
	c.props.box(mp + Vector3(0, 2.0, 0), Vector3(6, 4, 5), Color(0.42, 0.42, 0.4))
	c.props.box(mp + Vector3(0, 4.3, 0), Vector3(6.6, 0.6, 5.6), Color(0.38, 0.38, 0.36))
	c.solid(mp + Vector3(0, 2.0, 0), Vector3(6, 4, 5))
	c.label(mp + Vector3(0, 3.2, 2.55), family, 48, Color(0.75, 0.75, 0.7), 0.0, 40.0, 0.01)


func _rail_yard(r: Rect2) -> void:
	var c := ctx_at(r.get_center().x, r.get_center().y)
	c.ground.flat(Vector3(r.get_center().x, 0.012, r.get_center().y), r.size.x, r.size.y, Color(0.2, 0.18, 0.16), 0.0, Vector2(1, 0))
	for k in 5:
		var tz := r.position.y + 8.0 + float(k) * 12.0
		c.ground.flat(Vector3(r.get_center().x, 0.02, tz - 0.7), r.size.x, 0.1, Color(0.4, 0.38, 0.35))
		c.ground.flat(Vector3(r.get_center().x, 0.02, tz + 0.7), r.size.x, 0.1, Color(0.4, 0.38, 0.35))
		var x := r.position.x + 3.0
		while x < r.end.x:
			c.ground.flat(Vector3(x, 0.015, tz), 0.25, 2.4, Color(0.18, 0.12, 0.08))
			x += 1.0
		if k % 2 == 0:
			var cx := r.position.x + rng.randf_range(15, r.size.x - 20)
			for q in 2:
				Props.place(c, "rail_car", Vector3(cx + float(q) * 17.0, 0, tz), PI * 0.5)
				c.solid(Vector3(cx + float(q) * 17.0, 1.9, tz), Vector3(16, 3.8, 3.0))


# --------------------------------------------------------------------- park
func _park() -> void:
	var x0 := WorldLayout.ax(WorldLayout.PARK["bi0"]) + WorldLayout.AVE_HW
	var x1 := WorldLayout.ax(WorldLayout.PARK["bi1"] + 1) - WorldLayout.AVE_HW
	var z0 := WorldLayout.sz(WorldLayout.PARK["bj0"]) + WorldLayout.ST_HW
	var z1 := WorldLayout.sz(WorldLayout.PARK["bj1"] + 1) - WorldLayout.ST_HW
	var grass := Color(0.2, 0.32, 0.14)
	var path := Color(0.36, 0.34, 0.3)
	var lake := Rect2(-170, 40, 110, 80)
	# Grass in 10 m tiles (skipping the lake) so each chunk owns its piece.
	var tx := x0
	while tx < x1 - 0.01:
		var tz := z0
		var tw := minf(10.0, x1 - tx)
		while tz < z1 - 0.01:
			var td := minf(10.0, z1 - tz)
			if not lake.has_point(Vector2(tx + tw * 0.5, tz + td * 0.5)):
				var c := ctx_at(tx + tw * 0.5, tz + td * 0.5)
				c.ground.flat(Vector3(tx + tw * 0.5, 0.02, tz + td * 0.5), tw, td, grass.lightened(rng.randf() * 0.05), 0.0, Vector2(1, 0))
			tz += 10.0
		tx += 10.0
	# Stone wall around with gates at avenue/street ends.
	var gates_x := [WorldLayout.ax(5), WorldLayout.ax(6)]
	var gates_z := [WorldLayout.sz(10), WorldLayout.sz(11), WorldLayout.sz(12)]
	_park_wall_x(x0, x1, z0, gates_x)
	_park_wall_x(x0, x1, z1, gates_x)
	_park_wall_z(z0, z1, x0, gates_z)
	_park_wall_z(z0, z1, x1, gates_z)
	# Paths: continuations of the avenues/streets as footpaths + a loop.
	for gx in gates_x:
		_path(Vector3(gx, 0, z0), Vector3(gx, 0, z1), 5.0, path)
	for gz in gates_z:
		_path(Vector3(x0, 0, gz), Vector3(x1, 0, gz), 5.0, path)
	# Lake.
	var wc := ctx_at(lake.get_center().x, lake.get_center().y)
	var wb := MeshBatch.new()
	wb.flat(Vector3(lake.get_center().x, -0.15, lake.get_center().y), lake.size.x, lake.size.y, Color(0.1, 0.2, 0.3))
	wb.commit(_water_parent_holder(), Mats.water, 600.0, "Lake")
	wc.ground.flat(Vector3(lake.get_center().x, -0.6, lake.get_center().y), lake.size.x, lake.size.y, Color(0.05, 0.07, 0.06))
	# Lake rim (stone curb) + collision so you don't walk into the water.
	for e in [[lake.position.x, lake.position.y, lake.end.x, lake.position.y], [lake.position.x, lake.end.y, lake.end.x, lake.end.y], [lake.position.x, lake.position.y, lake.position.x, lake.end.y], [lake.end.x, lake.position.y, lake.end.x, lake.end.y]]:
		var a := Vector3(float(e[0]), 0, float(e[1]))
		var b := Vector3(float(e[2]), 0, float(e[3]))
		var mid := (a + b) * 0.5
		var L := a.distance_to(b)
		var along_x := absf(b.x - a.x) > 0.1
		var cc := ctx_at(mid.x, mid.z)
		cc.props.box(mid + Vector3(0, 0.25, 0), Vector3(L + 1.0 if along_x else 1.0, 0.5, 1.0 if along_x else L + 1.0), Color(0.4, 0.4, 0.38))
		cc.solid(mid + Vector3(0, 0.6, 0), Vector3(L + 1.0 if along_x else 1.0, 1.2, 1.0 if along_x else L + 1.0))
	# The paths crossing the lake become a footbridge.
	for gx in gates_x:
		if float(gx) > lake.position.x and float(gx) < lake.end.x:
			var bc := ctx_at(float(gx), lake.get_center().y)
			bc.props.box(Vector3(float(gx), 0.1, lake.get_center().y), Vector3(4.6, 0.3, lake.size.y + 2.0), Color(0.35, 0.26, 0.18))
	# Trees, rocks, bushes.
	var n := 0
	var tries := 0
	while n < 420 and tries < 3000:
		tries += 1
		var px := rng.randf_range(x0 + 3, x1 - 3)
		var pz := rng.randf_range(z0 + 3, z1 - 3)
		if lake.grow(3.0).has_point(Vector2(px, pz)):
			continue
		var on_path := false
		for gx in gates_x:
			if absf(px - float(gx)) < 4.5:
				on_path = true
		for gz in gates_z:
			if absf(pz - float(gz)) < 4.5:
				on_path = true
		if on_path:
			continue
		var c2 := ctx_at(px, pz)
		var pick := rng.randi() % 10
		if pick < 6:
			Props.place(c2, ["tree_a", "tree_b", "pine"][rng.randi() % 3], Vector3(px, 0, pz), rng.randf() * TAU, rng.randf_range(0.9, 1.5))
			c2.solid(Vector3(px, 1.4, pz), Vector3(0.45, 2.8, 0.45))
		elif pick < 8:
			Props.place(c2, "bush", Vector3(px, 0, pz), 0, rng.randf_range(0.8, 1.6))
		else:
			Props.place(c2, "rock", Vector3(px, 0, pz), rng.randf() * TAU, rng.randf_range(0.8, 2.0))
			c2.solid(Vector3(px, 0.4, pz), Vector3(1.6, 0.8, 1.6))
		n += 1
	# Lamps and benches along paths.
	for gx in gates_x:
		var z := z0 + 10.0
		while z < z1 - 5.0:
			if not lake.grow(2.0).has_point(Vector2(float(gx), z)):
				var c3 := ctx_at(float(gx) + 3.2, z)
				Props.place(c3, "park_lamp", Vector3(float(gx) + 3.2, 0, z))
				Props.light_pool(c3, Vector3(float(gx) + 3.2, 0, z), 5.0, Color(1.0, 0.9, 0.7))
				Props.place(c3, "bench", Vector3(float(gx) - 3.4, 0, z + 5.0), PI * 0.5)
				c3.solid(Vector3(float(gx) - 3.4, 0.4, z + 5.0), Vector3(0.5, 0.8, 1.8))
			z += 22.0
	for gz in gates_z:
		var x := x0 + 10.0
		while x < x1 - 5.0:
			if not lake.grow(2.0).has_point(Vector2(x, float(gz))):
				var c4 := ctx_at(x, float(gz) + 3.2)
				Props.place(c4, "park_lamp", Vector3(x, 0, float(gz) + 3.2))
				Props.light_pool(c4, Vector3(x, 0, float(gz) + 3.2), 5.0, Color(1.0, 0.9, 0.7))
			x += 22.0
	# Chess tables POI.
	var cp := Vector3(30, 0, 10)
	for k in 4:
		var p := cp + Vector3(float(k % 2) * 4.0, 0, float(k / 2) * 4.0)
		Props.place(ctx_at(p.x, p.z), "chess_table", p)
		ctx_at(p.x, p.z).solid(p + Vector3(0, 0.4, 0), Vector3(1.0, 0.8, 1.0))
	# Washington Township memorial.
	var mp := Vector3(-150, 0, 150)
	var mc := ctx_at(mp.x, mp.z)
	mc.props.box(mp + Vector3(0, 1.2, 0), Vector3(6.0, 2.4, 0.6), Color(0.15, 0.15, 0.16))
	mc.props.box(mp + Vector3(0, 0.1, 1.0), Vector3(8.0, 0.2, 3.0), Color(0.3, 0.3, 0.3))
	mc.solid(mp + Vector3(0, 1.2, 0), Vector3(6.0, 2.4, 0.6))
	mc.label(mp + Vector3(0, 1.6, 0.31), "WASHINGTON TOWNSHIP", 56, Color(0.8, 0.8, 0.75), 0.0, 40.0, 0.008)
	mc.label(mp + Vector3(0, 1.1, 0.31), "WE REMEMBER", 40, Color(0.7, 0.7, 0.65), 0.0, 40.0, 0.008)
	for k in 9:
		mc.glow.cyl(mp + Vector3(-2.4 + float(k) * 0.6, 0.3, 0.8), 0.04, 0.04, 0.15, Color(1.0, 0.7, 0.3), 5, Vector2(Props.K_FLICKER, float(k)))
	# Bandshell.
	var bp := Vector3(60, 0, 180)
	var bc2 := ctx_at(bp.x, bp.z)
	bc2.props.box(bp + Vector3(0, 0.5, 0), Vector3(16, 1.0, 10), Color(0.4, 0.38, 0.35))
	bc2.props.box(bp + Vector3(0, 5, -4.5), Vector3(16, 9, 1.0), Color(0.5, 0.48, 0.44))
	bc2.solid(bp + Vector3(0, 0.5, 0), Vector3(16, 1.0, 10))
	bc2.solid(bp + Vector3(0, 5, -4.5), Vector3(16, 9, 1.0))


var _water_holder: Node3D = null
var water_nodes: Array = []


## Fort Tryon Park: wooded hills, winding paths, rock outcrops. Uses its own
## RNG so it doesn't shift the rest of the city.
func _tryon() -> void:
	var T := WorldLayout.TRYON
	var x0 := WorldLayout.ax(int(T["bi0"])) + WorldLayout.AVE_HW
	var x1 := WorldLayout.ax(int(T["bi1"]) + 1) - WorldLayout.AVE_HW
	var z0 := WorldLayout.sz(int(T["bj0"])) + WorldLayout.ST_HW
	var z1 := WorldLayout.sz(int(T["bj1"]) + 1) - WorldLayout.ST_HW
	var tr := RandomNumberGenerator.new()
	tr.seed = 4401
	var z := z0
	while z < z1:
		var x := x0
		while x < x1:
			var w := minf(100.0, x1 - x)
			var d := minf(100.0, z1 - z)
			ctx_at(x + w * 0.5, z + d * 0.5).ground.flat(Vector3(x + w * 0.5, 0.02, z + d * 0.5), w, d, Color(0.13, 0.22, 0.1), 0.0, Vector2(1, 0))
			x += 100.0
		z += 100.0
	# Loop path + cross path.
	var cx := (x0 + x1) * 0.5
	var cz := (z0 + z1) * 0.5
	var pts: Array = []
	for k in 24:
		var a := TAU * float(k) / 24.0
		pts.append(Vector3(cx + cos(a) * (x1 - x0) * 0.38, 0, cz + sin(a) * (z1 - z0) * 0.4))
	for k in 24:
		_path(pts[k], pts[(k + 1) % 24], 3.0, Color(0.36, 0.33, 0.28))
		if k % 3 == 0:
			var lp: Vector3 = pts[k]
			var lc := ctx_at(lp.x, lp.z)
			Props.place(lc, "park_lamp", lp + Vector3(2.2, 0, 0))
			Props.light_pool(lc, lp, 6.0, Color(1.0, 0.9, 0.7))
			Props.place(lc, "bench", lp + Vector3(-2.4, 0, 0), PI * 0.5)
	_path(Vector3(x0, 0, cz), Vector3(x1, 0, cz), 3.0, Color(0.36, 0.33, 0.28))
	_path(Vector3(cx, 0, z0), Vector3(cx, 0, z1), 3.0, Color(0.36, 0.33, 0.28))
	# Woods and rock outcrops, clear of the paths.
	for k in 420:
		var p := Vector3(tr.randf_range(x0 + 4.0, x1 - 4.0), 0, tr.randf_range(z0 + 4.0, z1 - 4.0))
		if absf(p.x - cx) < 4.0 or absf(p.z - cz) < 4.0:
			continue
		var ex := (p.x - cx) / ((x1 - x0) * 0.38)
		var ez := (p.z - cz) / ((z1 - z0) * 0.4)
		if absf(sqrt(ex * ex + ez * ez) - 1.0) < 0.06:
			continue
		var c := ctx_at(p.x, p.z)
		if tr.randf() < 0.12:
			var rs := tr.randf_range(1.5, 4.0)
			c.props.box(p + Vector3(0, rs * 0.35, 0), Vector3(rs, rs * 0.7, rs * 0.8), Color(0.36, 0.36, 0.34), tr.randf() * TAU)
			c.solid(p + Vector3(0, rs * 0.35, 0), Vector3(rs * 0.9, rs * 0.7, rs * 0.7))
		else:
			Props.place(c, ["tree_a", "tree_b", "tree_c", "pine"][tr.randi() % 4], p, tr.randf() * TAU, tr.randf_range(0.9, 1.4))
			c.solid(p + Vector3(0, 1.4, 0), Vector3(0.4, 2.8, 0.4))
	# Perimeter wall with gaps at the four path ends.
	for e in [[Vector3(x0, 0, z0), Vector3(cx - 4.0, 0, z0)], [Vector3(cx + 4.0, 0, z0), Vector3(x1, 0, z0)],
			[Vector3(x0, 0, z1), Vector3(cx - 4.0, 0, z1)], [Vector3(cx + 4.0, 0, z1), Vector3(x1, 0, z1)],
			[Vector3(x0, 0, z0), Vector3(x0, 0, cz - 4.0)], [Vector3(x0, 0, cz + 4.0), Vector3(x0, 0, z1)],
			[Vector3(x1, 0, z0), Vector3(x1, 0, cz - 4.0)], [Vector3(x1, 0, cz + 4.0), Vector3(x1, 0, z1)]]:
		Props.fence_line(ctx_at(((e[0] as Vector3) + (e[1] as Vector3)).x * 0.5, ((e[0] as Vector3) + (e[1] as Vector3)).z * 0.5), e[0], e[1], 1.1, Color(0.4, 0.38, 0.34), true)


func _water_parent_holder() -> Node3D:
	if _water_holder == null:
		_water_holder = Node3D.new()
		_water_holder.name = "Water"
	return _water_holder


func take_water_holder() -> Node3D:
	return _water_parent_holder()


func _park_wall_x(x0: float, x1: float, z: float, gates: Array) -> void:
	var x := x0
	var cuts: Array = []
	for g in gates:
		cuts.append([float(g) - 4.0, float(g) + 4.0])
	var segs := _cut_segments(x0, x1, cuts)
	for s in segs:
		var a := float(s[0])
		var b := float(s[1])
		var c := ctx_at((a + b) * 0.5, z)
		c.props.box(Vector3((a + b) * 0.5, 0.45, z), Vector3(b - a, 0.9, 0.7), Color(0.38, 0.36, 0.33))
		c.solid(Vector3((a + b) * 0.5, 0.6, z), Vector3(b - a, 1.2, 0.8))


func _park_wall_z(z0: float, z1: float, x: float, gates: Array) -> void:
	var cuts: Array = []
	for g in gates:
		cuts.append([float(g) - 4.0, float(g) + 4.0])
	var segs := _cut_segments(z0, z1, cuts)
	for s in segs:
		var a := float(s[0])
		var b := float(s[1])
		var c := ctx_at(x, (a + b) * 0.5)
		c.props.box(Vector3(x, 0.45, (a + b) * 0.5), Vector3(0.7, 0.9, b - a), Color(0.38, 0.36, 0.33))
		c.solid(Vector3(x, 0.6, (a + b) * 0.5), Vector3(0.8, 1.2, b - a))


func _cut_segments(a: float, b: float, cuts: Array) -> Array:
	var out: Array = []
	var cur := a
	var sorted := cuts.duplicate()
	sorted.sort_custom(func(p: Array, q: Array) -> bool: return float(p[0]) < float(q[0]))
	for ct in sorted:
		if float(ct[0]) > cur:
			out.append([cur, minf(float(ct[0]), b)])
		cur = maxf(cur, float(ct[1]))
	if cur < b:
		out.append([cur, b])
	return out


func _path(a: Vector3, b: Vector3, w: float, col: Color) -> void:
	var L := a.distance_to(b)
	var n := int(ceil(L / 50.0))
	for k in n:
		var p0 := a.lerp(b, float(k) / float(n))
		var p1 := a.lerp(b, float(k + 1) / float(n))
		var mid := (p0 + p1) * 0.5
		var c := ctx_at(mid.x, mid.z)
		if absf(b.x - a.x) > absf(b.z - a.z):
			c.ground.flat(Vector3(mid.x, 0.06, mid.z), p0.distance_to(p1), w, col, 0.0, Vector2(1, 0))
		else:
			c.ground.flat(Vector3(mid.x, 0.06, mid.z), w, p0.distance_to(p1), col, 0.0, Vector2(1, 0))


# ------------------------------------------------------------------- airfield
## Bowery Bay Airfield: grass, one long runway, a taxiway, an apron with tie-
## downs, two hangars, a control tower and a fence with two gates. The planes
## themselves are live Aircraft nodes spawned by Game.
var airfield_planes: Array = [] # [{slot, model, pos: Vector3, yaw}]


func _airfield() -> void:
	var r := WorldLayout.airfield_rect()
	var grass := Color(0.2, 0.27, 0.14)
	var asphalt := Color(0.16, 0.16, 0.17)
	var white := Color(0.85, 0.85, 0.82)
	var yellow := Color(0.85, 0.7, 0.15)
	var G := Vector2(1, 0)
	# Grass in 100 m tiles (chunk-local geometry).
	var gx := r.position.x
	while gx < r.end.x:
		var gz := r.position.y
		while gz < r.end.y:
			var w := minf(100.0, r.end.x - gx)
			var d := minf(100.0, r.end.y - gz)
			ctx_at(gx + w * 0.5, gz + d * 0.5).ground.flat(Vector3(gx + w * 0.5, 0.008, gz + d * 0.5), w, d, grass, 0.0, G)
			gz += 100.0
		gx += 100.0
	# Runway, in 60 m pieces, with edge lines, centreline dashes and edge lights.
	var rx := WorldLayout.RUNWAY_X
	var hw := WorldLayout.RUNWAY_HW
	var z := WorldLayout.RUNWAY_Z0
	while z < WorldLayout.RUNWAY_Z1:
		var L := minf(60.0, WorldLayout.RUNWAY_Z1 - z)
		var c := ctx_at(rx, z + L * 0.5)
		c.ground.flat(Vector3(rx, 0.02, z + L * 0.5), hw * 2.0, L, asphalt, 0.0, G)
		c.props.flat(Vector3(rx - hw + 0.8, 0.03, z + L * 0.5), 0.5, L, white)
		c.props.flat(Vector3(rx + hw - 0.8, 0.03, z + L * 0.5), 0.5, L, white)
		var dz := z + 6.0
		while dz < z + L:
			if dz > WorldLayout.RUNWAY_Z0 + 40.0 and dz < WorldLayout.RUNWAY_Z1 - 40.0:
				c.props.flat(Vector3(rx, 0.03, dz), 0.9, 12.0, white)
			dz += 24.0
		for s in [-1.0, 1.0]:
			var lz := z
			while lz < z + L:
				c.props.box(Vector3(rx + s * (hw + 1.0), 0.2, lz), Vector3(0.12, 0.4, 0.12), Color(0.25, 0.25, 0.25))
				c.glow.box(Vector3(rx + s * (hw + 1.0), 0.45, lz), Vector3(0.22, 0.12, 0.22), Color(1.0, 0.95, 0.75), 0.0, Vector2(Props.K_NIGHT, 0))
				lz += 30.0
		z += 60.0
	# Threshold "piano keys", aiming blocks and end lights at both ends.
	for e in [[WorldLayout.RUNWAY_Z0, 1.0], [WorldLayout.RUNWAY_Z1, -1.0]]:
		var ez := float(e[0])
		var sgn := float(e[1])
		var c2 := ctx_at(rx, ez)
		for k in 8:
			var off := -hw + 3.0 + float(k) * ((hw * 2.0 - 6.0) / 7.0)
			c2.props.flat(Vector3(rx + off, 0.03, ez + sgn * 14.0), 1.6, 22.0, white)
		for s in [-1.0, 1.0]:
			c2.props.flat(Vector3(rx + s * 6.0, 0.03, ez + sgn * 110.0), 3.0, 40.0, white)
		var lx := -hw
		while lx <= hw:
			c2.glow.box(Vector3(rx + lx, 0.3, ez - sgn * 0.5), Vector3(0.3, 0.15, 0.3), Color(0.2, 1.0, 0.3) if sgn > 0 else Color(1.0, 0.15, 0.1), 0.0, Vector2(Props.K_ALWAYS, 0))
			c2.glow.box(Vector3(rx + lx, 0.3, ez + sgn * (WorldLayout.RUNWAY_Z1 - WorldLayout.RUNWAY_Z0) - sgn * 1.0), Vector3(0.3, 0.15, 0.3), Color(1.0, 0.15, 0.1) if sgn > 0 else Color(0.2, 1.0, 0.3), 0.0, Vector2(Props.K_ALWAYS, 0))
			lx += 5.0
	# Parallel taxiway and two links to the apron.
	var tx := 1512.0
	z = WorldLayout.RUNWAY_Z0 + 20.0
	while z < WorldLayout.RUNWAY_Z1 - 20.0:
		var L2 := minf(60.0, WorldLayout.RUNWAY_Z1 - 20.0 - z)
		var c3 := ctx_at(tx, z + L2 * 0.5)
		c3.ground.flat(Vector3(tx, 0.018, z + L2 * 0.5), 16.0, L2, asphalt.lightened(0.04), 0.0, G)
		c3.props.flat(Vector3(tx, 0.028, z + L2 * 0.5), 0.3, L2, yellow)
		z += 60.0
	for lz2 in [WorldLayout.RUNWAY_Z0 + 28.0, -1210.0, WorldLayout.RUNWAY_Z1 - 28.0]:
		var c4 := ctx_at(1530.0, lz2)
		c4.ground.flat(Vector3((1504.0 + rx - hw) * 0.5 + 4.0, 0.019, lz2), rx - hw - 1504.0 + 8.0, 16.0, asphalt.lightened(0.04), 0.0, G)
		c4.props.flat(Vector3((1504.0 + rx - hw) * 0.5 + 4.0, 0.029, lz2), rx - hw - 1504.0 + 8.0, 0.3, yellow)
	var c5 := ctx_at(1490.0, -1210.0)
	c5.ground.flat(Vector3(1487.0, 0.019, -1210.0), 34.0, 16.0, asphalt.lightened(0.04), 0.0, G)
	# Apron with tie-down boxes.
	var ap := Rect2(1330.0, -1300.0, 140.0, 180.0)
	for ax2 in [0, 1]:
		for az2 in [0, 1]:
			var w2 := ap.size.x * 0.5
			var d2 := ap.size.y * 0.5
			var cxa := ap.position.x + w2 * (float(ax2) + 0.5)
			var cza := ap.position.y + d2 * (float(az2) + 0.5)
			ctx_at(cxa, cza).ground.flat(Vector3(cxa, 0.017, cza), w2, d2, asphalt.lightened(0.02), 0.0, G)
	var slots := [["gus_1", "skyhawk", Vector3(1445, 0, -1282), -PI * 0.5], ["gus_2", "skyhawk", Vector3(1445, 0, -1252), -PI * 0.5], ["gus_3", "skyhawk", Vector3(1445, 0, -1222), -PI * 0.5], ["ecorp_jet", "citation", Vector3(1395, 0, -1150), -PI * 0.5], ["gus_heli", "heli", Vector3(1380, 0, -1268), -PI * 0.5]]
	_helipad(ctx_at(1380.0, -1268.0), Vector3(1380, 0, -1268))
	for sl in slots:
		var sp: Vector3 = sl[2]
		var ca := ctx_at(sp.x, sp.z)
		ca.props.flat(Vector3(sp.x, 0.027, sp.z), 0.25, 14.0, yellow)
		ca.props.flat(Vector3(sp.x, 0.027, sp.z - 7.0), 9.0, 0.25, yellow)
		ca.props.flat(Vector3(sp.x, 0.027, sp.z + 7.0), 9.0, 0.25, yellow)
		airfield_planes.append({"slot": sl[0], "model": sl[1], "pos": sp, "yaw": sl[3]})
	# Hangars: open to the east (toward the apron). Walls are solid; the roof too.
	for hz in [[-1450.0, -1380.0, "HANGAR 1"], [-1110.0, -1040.0, "HANGAR 2  ·  E CORP AVIATION"]]:
		var hr := Rect2(1330.0, float(hz[0]), 70.0, float(hz[1]) - float(hz[0]))
		var ch := ctx_at(hr.get_center().x, hr.get_center().y)
		var wall := Color(0.55, 0.57, 0.58)
		var H := 14.0
		ch.ground.flat(Vector3(hr.get_center().x, 0.02, hr.get_center().y), hr.size.x, hr.size.y, Color(0.3, 0.3, 0.31), 0.0, G)
		# West, north, south walls (double-sided boxes) and the roof.
		ch.facade.box(Vector3(hr.position.x + 0.3, H * 0.5, hr.get_center().y), Vector3(0.6, H, hr.size.y), wall, 0.0, Vector2(0, 0))
		ch.solid(Vector3(hr.position.x + 0.3, H * 0.5, hr.get_center().y), Vector3(0.6, H, hr.size.y))
		for sz2 in [hr.position.y + 0.3, hr.end.y - 0.3]:
			ch.facade.box(Vector3(hr.get_center().x, H * 0.5, sz2), Vector3(hr.size.x, H, 0.6), wall, 0.0, Vector2(0, 0))
			ch.solid(Vector3(hr.get_center().x, H * 0.5, sz2), Vector3(hr.size.x, H, 0.6))
		# Curved-ish roof: three slabs.
		for k2 in 3:
			var kx := hr.position.x + hr.size.x * (float(k2) + 0.5) / 3.0
			var ky := H + (1.6 if k2 == 1 else 0.6)
			ch.props.box(Vector3(kx, ky, hr.get_center().y), Vector3(hr.size.x / 3.0 + 0.4, 0.4, hr.size.y + 0.6), Color(0.42, 0.44, 0.45), 0.0, Vector2.ZERO, 63)
		ch.solid(Vector3(hr.get_center().x, H + 1.0, hr.get_center().y), Vector3(hr.size.x, 1.2, hr.size.y))
		# Header over the open door, with the name.
		ch.props.box(Vector3(hr.end.x - 0.3, H - 1.0, hr.get_center().y), Vector3(0.6, 2.0, hr.size.y), Color(0.45, 0.46, 0.48))
		Props.sign_band(ch, Vector3(hr.end.x + 0.05, H - 1.0, hr.get_center().y), PI * 0.5, 30.0, str(hz[2]), Color(0.9, 0.9, 0.85), 1.1)
		ch.glow.box(Vector3(hr.get_center().x, H - 0.4, hr.get_center().y), Vector3(40.0, 0.1, 0.4), Color(1.0, 0.95, 0.85), 0.0, Vector2(Props.K_ALWAYS, 0))
		Furniture.build(ch, "drums", Vector3(hr.position.x + 3.0, 0, hr.position.y + 4.0), 0.0)
		Furniture.build(ch, "container_a", Vector3(hr.position.x + 8.0, 0, hr.end.y - 4.0), 0.0)
		buildings.append([hr.position.x, hr.position.y, hr.end.x, hr.end.y, H, "airfield"])
	# Control tower.
	var tp := Vector3(1345.0, 0, -995.0)
	var ct := ctx_at(tp.x, tp.z)
	ct.facade.box(Vector3(tp.x, 12.0, tp.z), Vector3(6.0, 24.0, 6.0), Color(0.6, 0.58, 0.55), 0.0, Vector2(3, 17))
	ct.solid(Vector3(tp.x, 12.0, tp.z), Vector3(6.0, 24.0, 6.0))
	ct.props.box(Vector3(tp.x, 24.4, tp.z), Vector3(10.0, 0.8, 10.0), Color(0.35, 0.36, 0.38), 0.0, Vector2.ZERO, 63)
	ct.glow.box(Vector3(tp.x, 26.3, tp.z), Vector3(9.4, 3.0, 9.4), Color(0.35, 0.6, 0.65), 0.0, Vector2(Props.K_NIGHT, 0))
	ct.props.box(Vector3(tp.x, 28.1, tp.z), Vector3(10.6, 0.6, 10.6), Color(0.3, 0.3, 0.32), 0.0, Vector2.ZERO, 63)
	ct.solid(Vector3(tp.x, 26.0, tp.z), Vector3(10.0, 4.6, 10.0))
	ct.props.box(Vector3(tp.x, 30.0, tp.z), Vector3(0.12, 3.2, 0.12), Color(0.2, 0.2, 0.2))
	ct.glow.sphere(Vector3(tp.x, 31.8, tp.z), 0.35, Color(0.3, 1.0, 0.4), 6, 4, Vector2(Props.K_BLINK, 0.3))
	ct.glow.sphere(Vector3(tp.x, 31.8, tp.z), 0.33, Color(1.0, 1.0, 0.9), 6, 4, Vector2(Props.K_BLINK, 0.8))
	buildings.append([tp.x - 5.0, tp.z - 5.0, tp.x + 5.0, tp.z + 5.0, 30.0, "airfield"])
	# Windsock by the runway.
	var wp := Vector3(rx - hw - 14.0, 0, -1280.0)
	var cw := ctx_at(wp.x, wp.z)
	cw.props.box(wp + Vector3(0, 3.0, 0), Vector3(0.14, 6.0, 0.14), Color(0.8, 0.8, 0.8))
	cw.props.cyl(wp + Vector3(1.2, 5.8, 0), 0.25, 0.45, 2.4, Color(1.0, 0.45, 0.1), 8)
	cw.solid(wp + Vector3(0, 3.0, 0), Vector3(0.3, 6.0, 0.3))
	# Fence round the field with two gates: west avenue (by the office) and the
	# south street (straight onto the taxiway).
	var fz0 := r.position.y + 0.5
	var fz1 := r.end.y - 0.5
	var fx0 := r.position.x + 0.5
	var fx1 := r.end.x - 0.5
	var fence := Color(0.45, 0.47, 0.48)
	var seg := func(a: Vector3, b: Vector3) -> void:
		var L3 := a.distance_to(b)
		var n := maxi(1, int(ceil(L3 / 40.0)))
		for i in n:
			var p0 := a.lerp(b, float(i) / float(n))
			var p1 := a.lerp(b, float(i + 1) / float(n))
			Props.fence_line(ctx_at((p0.x + p1.x) * 0.5, (p0.z + p1.z) * 0.5), p0, p1, 2.6, fence)
	seg.call(Vector3(fx0, 0, fz0), Vector3(fx1, 0, fz0))
	seg.call(Vector3(fx1, 0, fz0), Vector3(fx1, 0, fz1))
	seg.call(Vector3(fx0, 0, fz0), Vector3(fx0, 0, -1347.0)) # office sits in the line
	seg.call(Vector3(fx0, 0, -1308.0), Vector3(fx0, 0, -1290.0))
	seg.call(Vector3(fx0, 0, -1268.0), Vector3(fx0, 0, fz1)) # west gate -1290..-1268
	seg.call(Vector3(fx0, 0, fz1), Vector3(1500.0, 0, fz1))
	seg.call(Vector3(1524.0, 0, fz1), Vector3(fx1, 0, fz1)) # south gate 1500..1524
	for gp in [[Vector3(fx0, 0, -1290.0), Vector3(fx0, 0, -1268.0)], [Vector3(1500.0, 0, fz1), Vector3(1524.0, 0, fz1)]]:
		for p2 in gp:
			var cg := ctx_at((p2 as Vector3).x, (p2 as Vector3).z)
			cg.props.box(p2 + Vector3(0, 1.6, 0), Vector3(0.4, 3.2, 0.4), Color(0.3, 0.3, 0.32))
			cg.solid(p2 + Vector3(0, 1.6, 0), Vector3(0.4, 3.2, 0.4))
		var gm: Vector3 = ((gp[0] as Vector3) + (gp[1] as Vector3)) * 0.5
		var cgm := ctx_at(gm.x, gm.z)
		cgm.glow.box(gm + Vector3(0, 3.4, 0), Vector3(0.3, 0.3, 0.3), Color(1.0, 0.6, 0.1), 0.0, Vector2(Props.K_BLINK, 0.5))
	var csg := ctx_at(fx0, -1279.0)
	Props.sign_band(csg, Vector3(fx0 - 0.3, 3.6, -1279.0), -PI * 0.5, 18.0, "AIRSIDE  ·  AUTHORIZED ONLY", Color(1.0, 0.85, 0.3), 0.8)
	# Fuel truck and a couple of baggage carts on the apron.
	var cf := ctx_at(1420.0, -1300.0)
	Props.place(cf, "car_truck_3", Vector3(1395.0, 0, -1292.0), PI * 0.5)
	cf.solid(Vector3(1395.0, 1.2, -1292.0), Vector3(5.4, 2.4, 2.2))
	for bx in [1360.0, 1368.0]:
		cf.props.box(Vector3(bx, 0.6, -1135.0), Vector3(1.6, 0.8, 3.0), Color(0.5, 0.45, 0.2))
		cf.solid(Vector3(bx, 0.6, -1135.0), Vector3(1.6, 1.2, 3.0))


# -------------------------------------------------------------- steel mountain
func _steel_compound() -> void:
	var x0 := WorldLayout.ax(WorldLayout.STEEL["bi0"]) + WorldLayout.AVE_HW
	var x1 := WorldLayout.ax(WorldLayout.STEEL["bi1"] + 1) - WorldLayout.AVE_HW
	var z0 := WorldLayout.sz(WorldLayout.STEEL["bj0"]) + WorldLayout.ST_HW
	var z1 := WorldLayout.sz(WorldLayout.STEEL["bj1"] + 1) - WorldLayout.ST_HW
	var cx := (x0 + x1) * 0.5
	# Ground (tiles).
	var tx := x0
	while tx < x1:
		var tz := z0
		while tz < z1:
			var tw := minf(60.0, x1 - tx)
			var td := minf(60.0, z1 - tz)
			ctx_at(tx + tw * 0.5, tz + td * 0.5).ground.flat(Vector3(tx + tw * 0.5, 0.015, tz + td * 0.5), tw, td, Color(0.24, 0.24, 0.25), 0.0, Vector2(1, 0))
			tz += 60.0
		tx += 60.0
	# Fence with a gate on the south side.
	var fc := Color(0.3, 0.32, 0.33)
	var segs := [[x0, z0, x1, z0], [x0, z0, x0, z1], [x1, z0, x1, z1], [x0, z1, cx - 8.0, z1], [cx + 32.0, z1, x1, z1]]
	for s in segs:
		var a := Vector3(float(s[0]), 0, float(s[1]))
		var b := Vector3(float(s[2]), 0, float(s[3]))
		var L := a.distance_to(b)
		var n := int(ceil(L / 40.0))
		for k in n:
			var p0 := a.lerp(b, float(k) / float(n))
			var p1 := a.lerp(b, float(k + 1) / float(n))
			Props.fence_line(ctx_at((p0.x + p1.x) * 0.5, (p0.z + p1.z) * 0.5), p0, p1, 3.4, fc)
	# Gate boom + gatehouse (enterable: d_steel).
	var gc := ctx_at(cx, z1)
	gc.props.box(Vector3(cx, 1.0, z1), Vector3(16.0, 0.15, 0.15), Color(0.9, 0.2, 0.1))
	gc.props.box(Vector3(cx - 8.0, 0.6, z1), Vector3(0.4, 1.2, 0.4), Color(0.3, 0.3, 0.3))
	gc.solid(Vector3(cx, 1.5, z1), Vector3(16.0, 3.0, 0.3))
	var gh := Rect2(cx + 8.0, z1 - 16.0, 24.0, 16.0)
	_facade_box(gc, gh, 0.0, 6.0, 3, Color(0.55, 0.55, 0.56), 5.0)
	gc.solid(Vector3(gh.get_center().x, 3.0, gh.get_center().y), Vector3(gh.size.x, 6.0, gh.size.y))
	gc.facade.box(Vector3(gh.get_center().x, 6.3, gh.get_center().y), Vector3(gh.size.x + 0.6, 0.6, gh.size.y + 0.6), Color(0.4, 0.4, 0.42))
	Props.door(gc, Vector3(cx + 20.0, 0, z1), Vector3(0, 0, 1), Color(0.8, 0.9, 1.0))
	# The mountain itself: a blank concrete mass with slit windows and a sign.
	var mr := Rect2(cx - 80.0, z0 + 20.0, 160.0, 80.0)
	var mc := ctx_at(mr.get_center().x, mr.get_center().y)
	_facade_box(mc, mr, 0.0, 28.0, 10, Color(0.46, 0.46, 0.47), 3.0)
	mc.solid(Vector3(mr.get_center().x, 14.0, mr.get_center().y), Vector3(mr.size.x, 28.0, mr.size.y))
	mc.facade.box(Vector3(mr.get_center().x, 28.4, mr.get_center().y), Vector3(mr.size.x + 1.0, 0.8, mr.size.y + 1.0), Color(0.36, 0.36, 0.37))
	for k in 12:
		mc.glow.box(Vector3(mr.position.x + 8.0 + float(k) * 13.0, 18.0, mr.end.y + 0.05), Vector3(8.0, 0.4, 0.05), Color(0.7, 0.85, 1.0), 0.0, Vector2(Props.K_NIGHT, 0))
	Props.sign_band(mc, Vector3(mr.get_center().x, 22.5, mr.end.y + 0.1), 0.0, 40.0, "STEEL MOUNTAIN", Color(0.8, 0.9, 1.0), 4.0)
	buildings.append([mr.position.x, mr.position.y, mr.end.x, mr.end.y, 28.0, "steel"])
	buildings.append([gh.position.x, gh.position.y, gh.end.x, gh.end.y, 6.0, "steel"])
	# Parking lot + cameras + floodlights.
	for k in 14:
		var px := x0 + 12.0 + float(k) * 8.0
		var pz := z1 - 34.0
		if absf(px - cx) < 20.0:
			continue
		var cc := ctx_at(px, pz)
		cc.ground.flat(Vector3(px + 3.6, 0.02, pz), 0.12, 5.0, Color(0.8, 0.8, 0.75))
		if rng.randf() < 0.6:
			var lt: String = ["sedan", "suv", "hatch"][rng.randi() % 3]
			var lci := rng.randi() % 8
			Props.place(cc, "car_%s_%d" % [lt, lci], Vector3(px, 0, pz), 0.0)
			cc.solid(Vector3(px, 0.8, pz), Vector3(1.9, 1.6, 4.6))
			_lootable("car", Vector3(px, 0.8, pz), Vector3(1.0, 0.86, 2.36), 0.0, {"car": lt, "ci": lci, "yaw": 0.0})
	for p in [Vector3(x0 + 2, 0, z0 + 2), Vector3(x1 - 2, 0, z0 + 2), Vector3(x0 + 2, 0, z1 - 2), Vector3(x1 - 2, 0, z1 - 2), Vector3(cx - 30, 0, z1 - 50), Vector3(cx + 30, 0, z1 - 50)]:
		var fc2 := ctx_at(p.x, p.z)
		fc2.props.box(p + Vector3(0, 5, 0), Vector3(0.3, 10, 0.3), Color(0.2, 0.2, 0.22))
		fc2.glow.box(p + Vector3(0, 10.2, 0), Vector3(1.4, 0.4, 0.6), Color(0.9, 0.95, 1.0), 0.0, Vector2(Props.K_NIGHT, 0))
		Props.light_pool(fc2, p, 14.0, Color(0.8, 0.9, 1.0))
		fc2.solid(p + Vector3(0, 5, 0), Vector3(0.4, 10, 0.4))


# ---------------------------------------------------------------- landmarks
func _landmarks() -> void:
	# Street memorials (candles, a photo on the wall) in front of some landmarks.
	for mid in WorldLayout.LANDMARKS.keys():
		var LM: Dictionary = WorldLayout.LANDMARKS[mid]
		if LM.has("memorial"):
			var mp: Array = LM["memorial"]
			Furniture.build(ctx_at(float(mp[0]), float(mp[1])), "candles", Vector3(float(mp[0]), 0.0, float(mp[1])), PI)
	for id in WorldLayout.LANDMARKS.keys():
		var L: Dictionary = WorldLayout.LANDMARKS[id]
		var r: Array = L["rect"]
		var rect := Rect2(float(r[0]), float(r[1]), float(r[2]) - float(r[0]), float(r[3]) - float(r[1]))
		var c := ctx_at(rect.get_center().x, rect.get_center().y)
		var h := float(L["h"])
		var st := int(L["style"])
		var col: Color = L["color"]
		var d := WorldLayout.district_at(rect.get_center().x, rect.get_center().y)
		if L.has("twin"):
			_twin_tower(c, rect, h, col, str(L["twin"]) == "north", L)
		elif L.has("plaza"):
			var pr: Array = L["plaza"]
			var prr := Rect2(float(pr[0]), float(pr[1]), float(pr[2]) - float(pr[0]), float(pr[3]) - float(pr[1]))
			c.ground.flat(Vector3(prr.get_center().x, 0.018, prr.get_center().y), prr.size.x, prr.size.y, Color(0.34, 0.34, 0.36), 0.0, Vector2(1, 0))
			# Fountain + flags on the E Corp plaza.
			var fp := Vector3(prr.get_center().x, 0, prr.end.y - 4.0)
			c.props.cyl(fp + Vector3(0, 0.35, 0), 4.0, 4.2, 0.7, Color(0.4, 0.4, 0.42), 12)
			c.glow.cyl(fp + Vector3(0, 0.72, 0), 3.7, 3.7, 0.04, Color(0.3, 0.5, 0.9), 12, Vector2(Props.K_ALWAYS, 0))
			c.props.cyl(fp + Vector3(0, 1.5, 0), 0.4, 0.6, 2.0, Color(0.5, 0.5, 0.52), 8)
			c.solid(fp + Vector3(0, 0.5, 0), Vector3(8.2, 1.0, 8.2))
			for fx in [-20.0, -14.0, 14.0, 20.0]:
				var pp := Vector3(prr.get_center().x + fx, 0, prr.end.y - 3.0)
				c.props.box(pp + Vector3(0, 5, 0), Vector3(0.12, 10, 0.12), Color(0.6, 0.6, 0.62))
				c.props.box(pp + Vector3(0.9, 9, 0), Vector3(1.8, 1.1, 0.04), Color(0.15, 0.3, 0.7))
		if L.has("twin"):
			pass
		elif bool(L.get("pagoda", false)):
			_facade_box(c, rect, 0.0, h, st, col, 9.0)
			var roof_c := Color(0.15, 0.3, 0.2)
			c.props.box_xf(Transform3D(Basis(Vector3.RIGHT, 0.4), Vector3(rect.get_center().x, h + 1.0, rect.position.y + rect.size.y * 0.25)), Vector3(rect.size.x + 3.0, 0.3, rect.size.y * 0.6), roof_c)
			c.props.box_xf(Transform3D(Basis(Vector3.RIGHT, -0.4), Vector3(rect.get_center().x, h + 1.0, rect.position.y + rect.size.y * 0.75)), Vector3(rect.size.x + 3.0, 0.3, rect.size.y * 0.6), roof_c)
			for lx in [-12.0, -6.0, 0.0, 6.0, 12.0]:
				c.glow.sphere(Vector3(rect.get_center().x + lx, 3.2, rect.position.y - 0.9), 0.35, Color(1.0, 0.2, 0.1), 6, 4, Vector2(Props.K_ALWAYS, 0), 1.2)
		elif bool(L.get("lighthouse", false)):
			_lighthouse_tower(landmark_far, Vector3(rect.get_center().x, 0, rect.get_center().y), h)
			c.solid(Vector3(rect.get_center().x, h * 0.5, rect.get_center().y), Vector3(rect.size.x, h, rect.size.y))
		elif h > 150.0:
			# E Corp: tapered glass tower with a lit crown and spire.
			var cur := rect
			var y := 0.0
			var tiers := [0.45, 0.3, 0.25]
			for k in tiers.size():
				var th := h * float(tiers[k])
				_facade_box(landmark_far, cur, y, y + th, st, col, 13.0 + float(k))
				c.solid(Vector3(cur.get_center().x, y + th * 0.5, cur.get_center().y), Vector3(cur.size.x, th, cur.size.y))
				landmark_far.glow.box(Vector3(cur.get_center().x, y + th + 0.2, cur.get_center().y), Vector3(cur.size.x + 0.4, 0.3, cur.size.y + 0.4), Color(0.35, 0.55, 1.0), 0.0, Vector2(Props.K_ALWAYS, 0))
				y += th
				cur = cur.grow(-4.0)
			landmark_far.props.box(Vector3(rect.get_center().x, h + 12.0, rect.get_center().y), Vector3(0.8, 24.0, 0.8), Color(0.3, 0.3, 0.32))
			Props.place(landmark_far, "beacon", Vector3(rect.get_center().x, h + 24.5, rect.get_center().y))
			# Giant logo on two faces.
			c.label(Vector3(rect.get_center().x, h - 20.0, rect.end.y + 0.2), "E", 900, Color(0.45, 0.65, 1.0), 0.0, 1400.0, 0.05)
			c.label(Vector3(rect.get_center().x, h - 20.0, rect.position.y - 0.2), "E", 900, Color(0.45, 0.65, 1.0), PI, 1400.0, 0.05)
		else:
			_facade_box(c, rect, 0.0, h, st, col, 7.0 if st != 1 else 3.0)
			c.solid(Vector3(rect.get_center().x, h * 0.5, rect.get_center().y), Vector3(rect.size.x, h, rect.size.y))
			c.facade.box(Vector3(rect.get_center().x, h + 0.3, rect.get_center().y), Vector3(rect.size.x + 0.6, 0.6, rect.size.y + 0.6), col.lightened(0.12))
			match str(L.get("roof", "")):
				"tank":
					Props.place(c, "water_tank", Vector3(rect.get_center().x + 3.0, h + 0.6, rect.get_center().y))
				"mech":
					c.facade.box(Vector3(rect.get_center().x, h + 3.0, rect.get_center().y), Vector3(rect.size.x * 0.5, 5.0, rect.size.y * 0.5), col.darkened(0.2))
				"antenna":
					Props.place(c, "antenna", Vector3(rect.get_center().x, h + 0.6, rect.get_center().y), 0.0, 2.0)
				"deco":
					c.facade.box(Vector3(rect.get_center().x, h + 5.0, rect.get_center().y), Vector3(rect.size.x * 0.6, 10.0, rect.size.y * 0.6), col.lightened(0.05), 0.0, Vector2(8, 3))
					c.facade.box(Vector3(rect.get_center().x, h + 14.0, rect.get_center().y), Vector3(rect.size.x * 0.3, 8.0, rect.size.y * 0.3), col.lightened(0.1), 0.0, Vector2(8, 4))
					c.glow.box(Vector3(rect.get_center().x, h + 18.2, rect.get_center().y), Vector3(rect.size.x * 0.3 + 0.2, 0.3, rect.size.y * 0.3 + 0.2), Color(1.0, 0.8, 0.45), 0.0, Vector2(Props.K_ALWAYS, 0))
		if bool(L.get("steeple", false)):
			# A white steeple over the door end, with a bell light.
			var sx := rect.get_center().x
			var sz := rect.position.y + 5.0 if str(WorldLayout.DOORS.get(str(L.get("door", "")), {}).get("face", "n")) == "n" else rect.end.y - 5.0
			landmark_far.props.box(Vector3(sx, h + 5.0, sz), Vector3(5.0, 10.0, 5.0), col)
			landmark_far.props.cyl(Vector3(sx, h + 16.0, sz), 0.0, 3.4, 12.0, Color(0.25, 0.27, 0.3), 4)
			landmark_far.props.box(Vector3(sx, h + 23.5, sz), Vector3(0.25, 3.0, 0.25), Color(0.85, 0.75, 0.3))
			landmark_far.props.box(Vector3(sx, h + 24.3, sz), Vector3(1.6, 0.25, 0.25), Color(0.85, 0.75, 0.3))
			c.glow.box(Vector3(sx, h + 6.5, sz), Vector3(5.1, 1.6, 1.0), Color(1.0, 0.85, 0.5), 0.0, Vector2(Props.K_NIGHT, 0))
		if bool(L.get("gable", false)):
			var pitch := 0.55
			var half := rect.size.y * 0.5
			var rise := half * tan(pitch)
			for sgn in [-1.0, 1.0]:
				c.props.box_xf(Transform3D(Basis(Vector3.RIGHT, sgn * pitch), Vector3(rect.get_center().x, h + rise * 0.5, rect.get_center().y + sgn * half * 0.5)), Vector3(rect.size.x + 0.8, 0.22, half / cos(pitch) + 0.6), Color(0.24, 0.22, 0.21))
			c.props.box(Vector3(rect.get_center().x, h + rise * 0.25, rect.get_center().y), Vector3(rect.size.x - 0.1, rise * 0.5, half), col.darkened(0.05))
		buildings.append([rect.position.x, rect.position.y, rect.end.x, rect.end.y, h, d])
		stats["buildings"] = int(stats["buildings"]) + 1
		# Door + sign + extras.
		var did := str(L.get("door", ""))
		if did != "":
			var dw := WorldLayout.door_world(did)
			var dp: Vector3 = dw["pos"]
			var out: Vector3 = dw["out"]
			var dc := ctx_at(dp.x, dp.z)
			Props.door(dc, dp, out, L.get("sign_col", Color(0.9, 0.75, 0.45)), bool(L.get("boarded", false)))
			for did2 in L.get("doors_extra", []):
				var dw2 := WorldLayout.door_world(str(did2))
				if not dw2.is_empty():
					Props.door(ctx_at((dw2["pos"] as Vector3).x, (dw2["pos"] as Vector3).z), dw2["pos"], dw2["out"], Color(0.5, 0.5, 0.45), false)
			if bool(L.get("stoop", false)):
				for k in 4:
					dc.props.box(dp + out * (0.6 + float(k) * 0.35) + Vector3(0, 0.45 - float(k) * 0.13, 0), Vector3(2.4, 0.13, 0.35) if absf(out.z) > 0.5 else Vector3(0.35, 0.13, 2.4), Color(0.4, 0.36, 0.32))
			if L.has("awning"):
				Props.awning(dc, dp.x, dp.z, out.z if absf(out.z) > 0.5 else 1.0, minf(rect.size.x - 1.0, 8.0), L["awning"])
			if L.has("sign"):
				var rot := atan2(out.x, out.z)
				var sy := 4.6 if h > 8.0 else 3.4
				if st == 3 or st == 7 or st == 8:
					sy = 6.8
				var sw := minf(float(str(L["sign"]).length()) * 0.55 + 1.0, (rect.size.x if absf(out.z) > 0.5 else rect.size.y) - 1.0)
				Props.sign_band(dc, dp + out * 0.12 + Vector3(0, sy, 0), rot, sw, str(L["sign"]), L["sign_col"], 0.9, bool(L.get("flicker", false)))
			if bool(L.get("marquee", false)):
				dc.glow.box(dp + out * 1.6 + Vector3(0, 4.2, 0), Vector3(10.0, 1.4, 3.0) if absf(out.z) > 0.5 else Vector3(3.0, 1.4, 10.0), Color(1.0, 0.75, 0.3), 0.0, Vector2(Props.K_FLICKER, 2.0))
			if str(L.get("fire_escape", "")) != "":
				var fz := rect.position.y if out.z < 0.0 else rect.end.y
				Props.fire_escape(dc, rect.position.x, rect.end.x, fz, out.z, int(h / 3.1), 3.1, 4.0)


func _subways() -> void:
	for sid in WorldLayout.SUBWAYS.keys():
		var s: Dictionary = WorldLayout.SUBWAYS[sid]
		var r: Array = s["rect"]
		var cx := (float(r[0]) + float(r[2])) * 0.5
		var cz := (float(r[1]) + float(r[3])) * 0.5
		Props.subway_entrance(ctx_at(cx, cz), r, str(s["face"]))


# ---------------------------------------------------------------- coney island
func _coney() -> void:
	var x0 := WorldLayout.ax(0) - WorldLayout.AVE_HW
	var x1 := WorldLayout.ax(WorldLayout.NA - 1) + WorldLayout.AVE_HW
	# Row of low shops/houses between Neptune Ave and Surf Ave.
	for i in WorldLayout.NA - 1:
		var bx0 := WorldLayout.ax(i) + WorldLayout.AVE_HW
		var bx1 := WorldLayout.ax(i + 1) - WorldLayout.AVE_HW
		var c := ctx_at((bx0 + bx1) * 0.5, 592)
		c.ground.flat(Vector3((bx0 + bx1) * 0.5, 0.006, 592), bx1 - bx0, 48, Color(0.22, 0.21, 0.2), 0.0, Vector2(1, 0))
		var x := bx0
		while x < bx1 - 4.0:
			var w := rng.randf_range(9.0, 16.0)
			if bx1 - (x + w) < 7.0:
				w = bx1 - x
			var rr := Rect2(x + 0.2, WorldLayout.CONEY_ROW_Z0, w - 0.4, rng.randf_range(16.0, 22.0))
			if _rect_free_global(rr):
				_building(rr, rng.randf_range(6.0, 11.0), 9, _palette("brick"), rng.randf() < 0.7, -1.0, "coney")
			var rr2 := Rect2(x + 0.2, WorldLayout.CONEY_ROW_Z1 - rng.randf_range(14.0, 20.0), w - 0.4, 0.0)
			rr2.size.y = WorldLayout.CONEY_ROW_Z1 - rr2.position.y
			if _rect_free_global(rr2):
				_building(rr2, rng.randf_range(6.0, 10.0), 9, _palette("stone"), rng.randf() < 0.8, 1.0, "coney")
			x += w
	# Amusement zone ground.
	var ax := x0
	while ax < x1:
		var w2 := minf(100.0, x1 - ax)
		ctx_at(ax + w2 * 0.5, 660).ground.flat(Vector3(ax + w2 * 0.5, 0.01, (WorldLayout.AMUSE_Z0 + WorldLayout.AMUSE_Z1) * 0.5), w2, WorldLayout.AMUSE_Z1 - WorldLayout.AMUSE_Z0, Color(0.3, 0.27, 0.24), 0.0, Vector2(1, 0))
		# Boardwalk planks.
		ctx_at(ax + w2 * 0.5, 700).ground.flat(Vector3(ax + w2 * 0.5, 0.05, (WorldLayout.BOARD_Z0 + WorldLayout.BOARD_Z1) * 0.5), w2, WorldLayout.BOARD_Z1 - WorldLayout.BOARD_Z0, Color(0.38, 0.28, 0.18), 0.0, Vector2(1, 0))
		var px := ax
		while px < ax + w2:
			ctx_at(px, 700).props.flat(Vector3(px, 0.08, 700), 0.06, WorldLayout.BOARD_Z1 - WorldLayout.BOARD_Z0, Color(0.25, 0.18, 0.12))
			px += 1.2
		# Beach.
		ctx_at(ax + w2 * 0.5, 750).ground.flat(Vector3(ax + w2 * 0.5, 0.0, (WorldLayout.BOARD_Z1 + WorldLayout.BEACH_Z1) * 0.5 + 5.0), w2, WorldLayout.BEACH_Z1 - WorldLayout.BOARD_Z1 + 10.0, Color(0.62, 0.55, 0.42), 0.0, Vector2(1, 0))
		ax += w2
	# Boardwalk railing + lamps.
	var lx := x0 + 5.0
	while lx < x1:
		var c2 := ctx_at(lx, 712)
		c2.props.box(Vector3(lx + 6.0, 0.55, WorldLayout.BOARD_Z1), Vector3(12.0, 0.08, 0.08), Color(0.3, 0.3, 0.3))
		c2.props.box(Vector3(lx, 0.5, WorldLayout.BOARD_Z1), Vector3(0.1, 1.0, 0.1), Color(0.3, 0.3, 0.3))
		if int(lx) % 36 < 12:
			Props.place(c2, "park_lamp", Vector3(lx, 0, WorldLayout.BOARD_Z1 - 1.0))
			Props.light_pool(c2, Vector3(lx, 0, WorldLayout.BOARD_Z1 - 1.0), 6.0, Color(1.0, 0.9, 0.7))
			Props.place(c2, "bench", Vector3(lx + 4.0, 0, WorldLayout.BOARD_Z1 - 1.2), PI)
		lx += 12.0
	# Pier.
	var pc := ctx_at((WorldLayout.PIER_X0 + WorldLayout.PIER_X1) * 0.5, 800)
	var pl := WorldLayout.PIER_Z1 - WorldLayout.BOARD_Z1
	var pzc := (WorldLayout.PIER_Z1 + WorldLayout.BOARD_Z1) * 0.5
	var pier_w := WorldLayout.PIER_X1 - WorldLayout.PIER_X0
	var pxc := (WorldLayout.PIER_X0 + WorldLayout.PIER_X1) * 0.5
	pc.ground.flat(Vector3(pxc, 0.12, pzc), pier_w, pl, Color(0.36, 0.27, 0.18), 0.0, Vector2(1, 0))
	pc.props.box(Vector3(pxc, -0.2, pzc), Vector3(pier_w, 0.6, pl), Color(0.25, 0.18, 0.12), 0.0, Vector2.ZERO, 60)
	var z := WorldLayout.BOARD_Z1 + 6.0
	while z < WorldLayout.PIER_Z1:
		for sx in [WorldLayout.PIER_X0, WorldLayout.PIER_X1]:
			pc.props.box(Vector3(sx, -1.5, z), Vector3(0.5, 3.6, 0.5), Color(0.2, 0.15, 0.1))
			pc.props.box(Vector3(sx, 0.85, z), Vector3(0.1, 1.1, 0.1), Color(0.3, 0.3, 0.3))
		z += 8.0
	pc.solid(Vector3(pxc, -0.2, pzc), Vector3(pier_w, 0.6, pl))
	pc.solid(Vector3(WorldLayout.PIER_X0, 1.2, pzc), Vector3(0.3, 2.4, pl))
	pc.solid(Vector3(WorldLayout.PIER_X1, 1.2, pzc), Vector3(0.3, 2.4, pl))
	pc.solid(Vector3(pxc, 1.2, WorldLayout.PIER_Z1), Vector3(pier_w, 2.4, 0.3))
	pc.props.box(Vector3(pxc, 0.85, WorldLayout.PIER_Z1), Vector3(pier_w, 0.08, 0.08), Color(0.3, 0.3, 0.3))
	for k in 5:
		Props.place(pc, "park_lamp", Vector3(WorldLayout.PIER_X1 - 1.0, 0.1, WorldLayout.BOARD_Z1 + 20.0 + float(k) * 34.0))
	# Parachute Jump tower.
	var pj := Vector3(-400, 0, 660)
	var jc := ctx_at(pj.x, pj.z)
	for k in 6:
		var a0 := TAU * float(k) / 6.0
		var base := pj + Vector3(cos(a0) * 8.0, 0, sin(a0) * 8.0)
		jc.props.tube(base, pj + Vector3(cos(a0) * 2.5, 62.0, sin(a0) * 2.5), 0.35, Color(0.55, 0.2, 0.12), 5)
		jc.solid(base + Vector3(0, 2, 0), Vector3(0.8, 4, 0.8))
	for k in 5:
		jc.props.cyl(pj + Vector3(0, 12.0 + float(k) * 11.0, 0), 7.0 - float(k), 7.0 - float(k), 0.4, Color(0.5, 0.18, 0.1), 12, Vector2.ZERO, false)
	jc.props.cyl(pj + Vector3(0, 66.0, 0), 11.0, 3.0, 4.0, Color(0.55, 0.2, 0.12), 12)
	for k in 12:
		var a1 := TAU * float(k) / 12.0
		jc.glow.sphere(pj + Vector3(cos(a1) * 11.0, 64.0, sin(a1) * 11.0), 0.35, Color(1.0, 0.8, 0.4), 5, 3, Vector2(Props.K_NIGHT, 0))
	# Roller coaster: wooden trusses.
	var cz0 := 640.0
	var cz1 := 684.0
	var cx0 := 250.0
	var cx1 := 420.0
	var cc := ctx_at((cx0 + cx1) * 0.5, 660)
	var t := 0.0
	var prev := Vector3.ZERO
	while t <= 1.0001:
		var ang := t * TAU
		var p := Vector3(lerpf(cx0, cx1, 0.5 + 0.5 * cos(ang)), 0, lerpf(cz0, cz1, 0.5 + 0.5 * sin(ang)))
		var hy := 6.0 + 18.0 * absf(sin(ang * 1.5)) + 6.0 * sin(ang * 3.0 + 1.0)
		hy = maxf(hy, 4.0)
		p.y = hy
		cc.props.box(Vector3(p.x, hy * 0.5, p.z), Vector3(0.3, hy, 0.3), Color(0.8, 0.78, 0.7))
		cc.solid(Vector3(p.x, 1.5, p.z), Vector3(0.5, 3.0, 0.5))
		if t > 0.0:
			cc.props.tube(prev, p, 0.25, Color(0.85, 0.2, 0.15), 4)
			cc.props.tube(prev + Vector3(0, -1.2, 0), p + Vector3(0, -1.2, 0), 0.12, Color(0.8, 0.78, 0.7), 4)
		prev = p
		t += 0.02
	# Wonder Wheel frame (the rotating rim is built by the world at runtime).
	var wc := ctx_at(ferris_center.x, ferris_center.z)
	for s in [-1.0, 1.0]:
		wc.props.tube(Vector3(ferris_center.x - 14.0, 0, ferris_center.z + s * 3.0), ferris_center + Vector3(0, 0, s * 3.0), 0.5, Color(0.9, 0.9, 0.9), 5)
		wc.props.tube(Vector3(ferris_center.x + 14.0, 0, ferris_center.z + s * 3.0), ferris_center + Vector3(0, 0, s * 3.0), 0.5, Color(0.9, 0.9, 0.9), 5)
		wc.solid(Vector3(ferris_center.x - 13.0, 1.5, ferris_center.z + s * 3.0), Vector3(1.0, 3.0, 1.0))
		wc.solid(Vector3(ferris_center.x + 13.0, 1.5, ferris_center.z + s * 3.0), Vector3(1.0, 3.0, 1.0))
	wc.label(Vector3(ferris_center.x, 3.5, ferris_center.z + 4.0), "WONDER WHEEL", 72, Color(1.0, 0.4, 0.6), 0.0, 200.0, 0.02)
	# Carousel building + stalls along the amusement zone.
	for k in 10:
		var sx := -700.0 + float(k) * 150.0 + rng.randf_range(-20, 20)
		var sr := Rect2(sx, 640.0, 18.0, 14.0)
		if absf(sx - ferris_center.x) < 40.0 or (sx > cx0 - 20.0 and sx < cx1 + 5.0) or absf(sx - pj.x) < 20.0 or (sx > -210.0 and sx < -130.0) or not _rect_free_global(sr):
			continue
		var stc := ctx_at(sx, 650)
		_facade_box(stc, sr, 0.0, 5.0, 9, Color(0.9, 0.85, 0.75).darkened(rng.randf() * 0.3), rng.randf_range(1, 50))
		stc.solid(Vector3(sr.get_center().x, 2.5, sr.get_center().y), Vector3(sr.size.x, 5.0, sr.size.y))
		for q in 6:
			stc.glow.sphere(Vector3(sx + 1.5 + float(q) * 3.0, 5.2, sr.end.y + 0.2), 0.18, [Color(1, 0.3, 0.3), Color(1, 0.9, 0.3), Color(0.3, 0.8, 1)][q % 3], 5, 3, Vector2(Props.K_ALWAYS, 0))
		stc.label(Vector3(sr.get_center().x, 4.0, sr.end.y + 0.1), ["HOT DOGS", "GAMES", "CLAMS", "SHOOT THE FREAK", "CANDY", "FORTUNES", "ICE CREAM", "BUMPER CARS", "SIDESHOW", "BEER"][k], 64, Color(1, 0.9, 0.7), 0.0, 120.0, 0.012)


## One of the Twin Towers: pinstriped aluminum facade on the long-range
## layer (visible from anywhere in the city), a walkable roof with a parapet,
## and on the north tower the antenna mast and the express-elevator house.
func _twin_tower(c: BuildCtx, rect: Rect2, h: float, col: Color, north: bool, L: Dictionary) -> void:
	var fc := landmark_far
	_facade_box(fc, rect, 0.0, h, 3, col, 41.0 if north else 43.0)
	# Vertical aluminum pinstripes (the towers' signature), every 2.5 m.
	var stripe := col.lightened(0.18)
	var x := rect.position.x + 1.25
	while x < rect.end.x - 0.5:
		fc.props.box(Vector3(x, h * 0.5 + 6.0, rect.position.y - 0.08), Vector3(0.35, h - 12.0, 0.16), stripe, 0.0, Vector2(0, 0.08), 16 + 32)
		fc.props.box(Vector3(x, h * 0.5 + 6.0, rect.end.y + 0.08), Vector3(0.35, h - 12.0, 0.16), stripe, 0.0, Vector2(0, 0.08), 16 + 32)
		x += 2.5
	var z := rect.position.y + 1.25
	while z < rect.end.y - 0.5:
		fc.props.box(Vector3(rect.position.x - 0.08, h * 0.5 + 6.0, z), Vector3(0.16, h - 12.0, 0.35), stripe, 0.0, Vector2(0, 0.08), 4 + 8)
		fc.props.box(Vector3(rect.end.x + 0.08, h * 0.5 + 6.0, z), Vector3(0.16, h - 12.0, 0.35), stripe, 0.0, Vector2(0, 0.08), 4 + 8)
		z += 2.5
	# Mechanical bands (sky lobbies) that ring the towers.
	for fr in [0.25, 0.5, 0.78]:
		fc.props.box(Vector3(rect.get_center().x, h * float(fr), rect.get_center().y), Vector3(rect.size.x + 0.5, 4.0, rect.size.y + 0.5), col.darkened(0.25))
	# The body collider, the roof deck and a parapet you can lean on.
	c.solid(Vector3(rect.get_center().x, h * 0.5, rect.get_center().y), Vector3(rect.size.x, h, rect.size.y))
	var rc := ctx_at(rect.get_center().x, rect.get_center().y)
	rc.props.box(Vector3(rect.get_center().x, h + 0.02, rect.get_center().y), Vector3(rect.size.x - 0.2, 0.04, rect.size.y - 0.2), Color(0.32, 0.32, 0.34))
	for e in [[Vector3(rect.get_center().x, h + 0.6, rect.position.y + 0.3), Vector3(rect.size.x, 1.2, 0.3)], [Vector3(rect.get_center().x, h + 0.6, rect.end.y - 0.3), Vector3(rect.size.x, 1.2, 0.3)],
			[Vector3(rect.position.x + 0.3, h + 0.6, rect.get_center().y), Vector3(0.3, 1.2, rect.size.y)], [Vector3(rect.end.x - 0.3, h + 0.6, rect.get_center().y), Vector3(0.3, 1.2, rect.size.y)]]:
		rc.solid(e[0], e[1])
		fc.props.box(e[0], e[1], Color(0.5, 0.52, 0.55))
	if north:
		# 110 m antenna mast with a blinking beacon.
		fc.props.cyl(Vector3(rect.get_center().x, h + 55.0, rect.get_center().y), 0.7, 1.6, 110.0, Color(0.72, 0.72, 0.74), 8)
		fc.props.box(Vector3(rect.get_center().x, h + 4.0, rect.get_center().y), Vector3(10.0, 8.0, 10.0), col.darkened(0.2))
		rc.solid(Vector3(rect.get_center().x, h + 4.0, rect.get_center().y), Vector3(10.0, 8.0, 10.0))
		Props.place(fc, "beacon", Vector3(rect.get_center().x, h + 111.0, rect.get_center().y))
		# Elevator house on the roof, door facing south.
		var eh := Vector3(rect.get_center().x, h, rect.get_center().y + 8.0)
		rc.props.box(eh + Vector3(0, 1.6, 0), Vector3(6.0, 3.2, 3.0), Color(0.4, 0.42, 0.45))
		rc.solid(eh + Vector3(0, 1.6, 0), Vector3(6.0, 3.2, 3.0))
		rc.props.box(eh + Vector3(0, 1.1, 1.52), Vector3(1.4, 2.2, 0.04), Color(0.6, 0.62, 0.65))
		rc.glow.box(eh + Vector3(0, 2.5, 1.53), Vector3(0.9, 0.2, 0.02), Color(1.0, 0.8, 0.4), 0.0, Vector2(Props.K_ALWAYS, 0))
		rc.label(eh + Vector3(0, 2.85, 1.56), "EXPRESS ELEVATOR", 40, Color(0.95, 0.95, 0.9), 0.0, 40.0, 0.01)
		# Plaza: pavement, a fountain and the Sphere.
		if L.has("plaza"):
			var pr: Array = L["plaza"]
			var prr := Rect2(float(pr[0]), float(pr[1]), float(pr[2]) - float(pr[0]), float(pr[3]) - float(pr[1]))
			c.ground.flat(Vector3(prr.get_center().x, 0.018, prr.get_center().y), prr.size.x, prr.size.y, Color(0.42, 0.4, 0.38), 0.0, Vector2(1, 0))
			var sp := Vector3(-46.0, 0, 385.0)
			var pc := ctx_at(sp.x, sp.z)
			pc.props.cyl(sp + Vector3(0, 0.4, 0), 6.0, 6.2, 0.8, Color(0.45, 0.45, 0.47), 16)
			pc.glow.cyl(sp + Vector3(0, 0.82, 0), 5.6, 5.6, 0.04, Color(0.3, 0.55, 0.8), 16, Vector2(Props.K_ALWAYS, 0))
			pc.props.cyl(sp + Vector3(0, 1.6, 0), 0.5, 0.7, 1.6, Color(0.35, 0.3, 0.2), 8)
			pc.props.sphere(sp + Vector3(0, 4.0, 0), 2.6, Color(0.62, 0.48, 0.22), 12, 8, Vector2(0, 0.15))
			pc.solid(sp + Vector3(0, 0.6, 0), Vector3(12.0, 1.2, 12.0))
			pc.label(sp + Vector3(0, 1.2, 6.3), "THE SPHERE", 48, Color(0.95, 0.9, 0.75), 0.0, 40.0, 0.01)


func _rect_free_global(r: Rect2) -> bool:
	for id in WorldLayout.LANDMARKS.keys():
		var L: Dictionary = WorldLayout.LANDMARKS[id]
		var rr: Array = L["rect"]
		var lr := Rect2(float(rr[0]), float(rr[1]), float(rr[2]) - float(rr[0]), float(rr[3]) - float(rr[1]))
		if lr.grow(1.0).intersects(r):
			return false
		for did in WorldLayout.landmark_doors(L):
			var dw := WorldLayout.door_world(did)
			if dw.is_empty():
				continue
			var p: Vector3 = dw["pos"]
			var o: Vector3 = dw["out"]
			var a := Vector2(p.x, p.z)
			var e := a + Vector2(o.x, o.z) * 14.0
			if Rect2(minf(a.x, e.x) - 3.0, minf(a.y, e.y) - 3.0, absf(e.x - a.x) + 6.0, absf(e.y - a.y) + 6.0).intersects(r):
				return false
	for sid in WorldLayout.SUBWAYS.keys():
		var s: Dictionary = WorldLayout.SUBWAYS[sid]
		var r2: Array = s["rect"]
		if Rect2(float(r2[0]) - 2.0, float(r2[1]) - 2.0, float(r2[2]) - float(r2[0]) + 4.0, float(r2[3]) - float(r2[1]) + 8.0).intersects(r):
			return false
	return true


# -------------------------------------------------------------------- edges
func _edges() -> void:
	var wx := WorldLayout.WORLD_X
	var ex := WorldLayout.WORLD_XE
	# Waterfront promenades west and east + railing.
	for side in [-1.0, 1.0]:
		var xr: float = -860.0 if side < 0.0 else ex - 6.0
		var xc: float = -825.0 if side < 0.0 else ex - 41.0
		var z := WorldLayout.WORLD_ZN
		while z < WorldLayout.BOARD_Z0:
			var c := ctx_at(xr, z + 50.0)
			c.ground.flat(Vector3(xc, 0.01, z + 50.0), 70.0, 100.0, Color(0.28, 0.27, 0.26), 0.0, Vector2(1, 0))
			c.props.box(Vector3(xr, 0.55, z + 50.0), Vector3(0.1, 0.08, 100.0), Color(0.3, 0.3, 0.3))
			var k := 0.0
			while k < 100.0:
				c.props.box(Vector3(xr, 0.5, z + k), Vector3(0.08, 1.0, 0.08), Color(0.3, 0.3, 0.3))
				if int(k) % 40 == 0:
					Props.place(c, "park_lamp", Vector3(xr - side * 1.5, 0, z + k))
					Props.light_pool(c, Vector3(xr - side * 1.5, 0, z + k), 5.0, Color(1.0, 0.9, 0.7))
				k += 4.0
			z += 100.0
		# Docks cranes on the west side; container cranes at Hunts Point / LIC east.
		# (None on the east bank north of LIC: that's the airfield's approach.)
		var cranes: Array = [-560.0, -420.0, -200.0, -60.0] if side < 0.0 else [-700.0, 150.0, 330.0]
		var cxr: float = -830.0 if side < 0.0 else ex - 36.0
		for cz in cranes:
			var cc := ctx_at(cxr, cz)
			Props.place(cc, "crane", Vector3(cxr, 0, cz), -PI * 0.5 * side)
			cc.solid(Vector3(cxr - 3.0, 12.0, cz), Vector3(1.0, 24.0, 1.0))
			cc.solid(Vector3(cxr + 3.0, 12.0, cz), Vector3(1.0, 24.0, 1.0))
	# North edge: highway retaining wall with a strip of trees.
	var nz := WorldLayout.sz(0) - WorldLayout.ST_HW
	var x := -wx
	while x < ex:
		var c2 := ctx_at(x + 50.0, nz - 20.0)
		c2.ground.flat(Vector3(x + 50.0, 0.01, (nz + WorldLayout.WORLD_ZN) * 0.5), 100.0, nz - WorldLayout.WORLD_ZN, Color(0.14, 0.18, 0.12), 0.0, Vector2(1, 0))
		c2.facade.box(Vector3(x + 50.0, 5.0, WorldLayout.WORLD_ZN - 2.0), Vector3(100.0, 10.0, 4.0), Color(0.34, 0.33, 0.31), 0.0, Vector2(0, 0))
		for k in 3:
			var tx := x + 15.0 + float(k) * 32.0
			Props.place(c2, "tree_c", Vector3(tx, 0, nz - 30.0), 0.0, 1.3)
			c2.solid(Vector3(tx, 1.4, nz - 30.0), Vector3(0.45, 2.8, 0.45))
		x += 100.0
	# World boundary colliders.
	var zmid := (WorldLayout.WORLD_ZN + 1000.0) * 0.5
	var zlen := 1000.0 - WorldLayout.WORLD_ZN + 20.0
	var root_c := ctx_at(0, 0)
	root_c.solid(Vector3(-wx - 1.0, 10.0, zmid), Vector3(2.0, 40.0, zlen), 0.0, "bounds")
	root_c.solid(Vector3(ex + 1.0, 10.0, zmid), Vector3(2.0, 40.0, zlen), 0.0, "bounds")
	root_c.solid(Vector3((ex - wx) * 0.5, 10.0, WorldLayout.WORLD_ZN - 1.0), Vector3(ex + wx + 10.0, 40.0, 2.0), 0.0, "bounds")
	# Ocean: wall at the waterline except the pier.
	var oz := WorldLayout.BEACH_Z1 + 2.0
	root_c.solid(Vector3((-wx + WorldLayout.PIER_X0) * 0.5, 10.0, oz), Vector3(WorldLayout.PIER_X0 + wx, 40.0, 2.0), 0.0, "bounds")
	root_c.solid(Vector3((ex + WorldLayout.PIER_X1) * 0.5, 10.0, oz), Vector3(ex - WorldLayout.PIER_X1, 40.0, 2.0), 0.0, "bounds")
	# Water planes (rivers + ocean) in the shared water holder.
	var wb := MeshBatch.new()
	wb.flat(Vector3(-wx - 640.0, -0.4, zmid), 1270.0, zlen + 2600.0, Color(0.1, 0.2, 0.3))
	wb.flat(Vector3(ex + 640.0, -0.4, zmid), 1270.0, zlen + 2600.0, Color(0.1, 0.2, 0.3))
	wb.flat(Vector3((ex - wx) * 0.5, -0.4, 1600.0), ex + wx + 20.0, 1640.0, Color(0.1, 0.2, 0.3))
	wb.commit(_water_parent_holder(), Mats.water, 0.0, "Rivers")
	# Distant skylines across the water (cheap silhouettes with lit windows).
	var far := BuildCtx.new()
	var r2 := RandomNumberGenerator.new()
	r2.seed = 77
	for side in [-1.0, 1.0]:
		var z2 := WorldLayout.WORLD_ZN - 300.0
		while z2 < 900.0:
			var w := r2.randf_range(20.0, 60.0)
			var hh := r2.randf_range(15.0, 90.0)
			var bx: float = (-r2.randf_range(1080.0, 1250.0)) if side < 0.0 else ex + r2.randf_range(214.0, 384.0)
			_facade_box(far, Rect2(bx - w * 0.5, z2, w, w * 0.8), 0.0, hh, [3, 1, 4, 8][r2.randi() % 4], _palette("stone").darkened(0.3), r2.randf_range(1, 90))
			z2 += w * 0.9
	var fx := -1200.0
	while fx < ex + 400.0:
		var w3 := r2.randf_range(25.0, 60.0)
		var hh3 := r2.randf_range(10.0, 50.0)
		_facade_box(far, Rect2(fx, WorldLayout.WORLD_ZN - 150.0 - r2.randf() * 150.0, w3, w3), 0.0, hh3, [1, 2, 5][r2.randi() % 3], _palette("brick").darkened(0.3), r2.randf_range(1, 90))
		fx += w3 * 1.1
	far_skyline = far


var far_skyline: BuildCtx = null
## Landmarks tall enough to be seen from anywhere (Twin Towers, E Corp).
var landmark_far: BuildCtx = BuildCtx.new()
