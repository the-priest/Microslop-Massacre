class_name Regions
extends RefCounted
## The world beyond New York. Each region is its own map (a street grid the
## same CityBuilder fills in), loaded when you cross into it: drive the
## highway out of a city's travel gate, or fly a plane across the edge of its
## airspace. "nyc" is WorldLayout's own defaults and is never overridden here.
##
## The maps sit side by side in one shared world (WORLD offsets): New York in
## the south, about three kilometres of Pennsylvania farmland on I-80, then
## Chicago in the north. Their airspaces touch edge to edge, so a plane flies
## straight from one into the next with the same speed, height and heading.

const NAMES := {"nyc": "New York", "highway": "Interstate 80", "chicago": "Chicago"}

## Travel gates: drive into one and you're offered the road beyond it.
## to = [region, gate id on the other side]. "sign" is the green highway sign.
const GATES := {
	"nyc": {
		"nyc_west": {"pos": [-390.0, -1636.0], "r": 22.0, "to": ["highway", "hw_east"], "sign": "I-80 WEST  ·  CHICAGO", "yaw": 0.0},
	},
	"highway": {
		"hw_east": {"pos": [0.0, 860.0], "r": 24.0, "to": ["nyc", "nyc_west"], "sign": "I-80 EAST  ·  NEW YORK CITY", "yaw": PI, "arrive_yaw": 0.0},
		"hw_west": {"pos": [0.0, -860.0], "r": 24.0, "to": ["chicago", "chi_south"], "sign": "I-80 WEST  ·  CHICAGO", "yaw": 0.0, "arrive_yaw": PI},
	},
	"chicago": {
		"chi_south": {"pos": [20.0, 800.0], "r": 24.0, "to": ["highway", "hw_west"], "sign": "I-90 EAST  ·  NEW YORK", "yaw": PI, "arrive_yaw": 0.0},
	},
}

## Where you appear after driving through a gate (a little inside it, facing in).
const ARRIVE := {
	"nyc_west": {"pos": [-390.0, -1590.0], "yaw": PI},
	"hw_east": {"pos": [0.0, 800.0], "yaw": 0.0},
	"hw_west": {"pos": [0.0, -800.0], "yaw": PI},
	"chi_south": {"pos": [20.0, 745.0], "yaw": 0.0},
}

## Airspace per region (Rect2 x, z, w, d, local coordinates). In world
## coordinates (+ WORLD) they touch: fly across the line and you're over the
## next map. Leave one where nothing borders it and the plane turns you back.
const SKY := {
	"nyc": Rect2(-1700.0, -2500.0, 4300.0, 3900.0),
	"highway": Rect2(-2400.0, -900.0, 4800.0, 1800.0),
	"chicago": Rect2(-2300.0, -1500.0, 4600.0, 3000.0),
}

## Where each map's origin sits in the shared world (x, z).
const WORLD := {
	"nyc": Vector2(0.0, 0.0),
	"highway": Vector2(-390.0, -3400.0),
	"chicago": Vector2(-410.0, -5800.0),
}

## Silhouettes you see of a city from the other maps: its centre (local),
## how far its towers spread, how many, and how tall the tallest.
const SKYLINE := {
	"nyc": {"c": Vector2(250.0, -350.0), "spread": 1100.0, "n": 70, "h": 220.0},
	"chicago": {"c": Vector2(-60.0, -80.0), "spread": 650.0, "n": 50, "h": 200.0},
}

## Landing approach per region when you fly in: [x, altitude, z, heading].
const FLY_IN := {
	"nyc": [1570.0, 160.0, -500.0, 0.0],
	"chicago": [640.0, 150.0, 700.0, 0.0],
	"highway": [0.0, 160.0, 600.0, 0.0],
}

## Grid and geography for each non-NYC region (overrides WorldLayout).
const DEFS := {
	"highway": {
		"SEED": 8080, "BJ0": 0, "AX0": -300.0, "AXS": 300.0, "NA": 3, "SZ0": -900.0, "SZS": 300.0, "NS": 7,
		"NBI": 2, "NBJ": 6, "WORLD_X": 560.0, "WORLD_XE": 560.0, "WORLD_ZN": -940.0, "BEACH_Z1": 940.0,
		"START_POS": Vector3(0, 0, 800), "START_YAW": 0.0,
		"DISTRICT_NAMES": {"farm": "Interstate 80", "reststop": "Big Rig Rest Stop", "town": "Lennox, Pennsylvania"},
	},
	"chicago": {
		"SEED": 6060, "BJ0": 0, "AX0": -700.0, "AXS": 120.0, "NA": 13, "SZ0": -700.0, "SZS": 95.0, "NS": 16,
		"NBI": 12, "NBJ": 15, "WORLD_X": 760.0, "WORLD_XE": 860.0, "WORLD_ZN": -760.0, "BEACH_Z1": 820.0,
		"START_POS": Vector3(20, 0, 745), "START_YAW": 0.0,
		"AIRFIELD": {"bi0": 10, "bi1": 11, "bj0": 2, "bj1": 8}, "RUNWAY_X": 640.0, "RUNWAY_HW": 18.0, "RUNWAY_Z0": -470.0, "RUNWAY_Z1": 110.0,
		"DISTRICT_NAMES": {"loop": "The Loop", "river": "River North", "west": "West Loop", "south": "South Side", "lake": "Lakeshore", "airfield": "Meigs Field"},
	},
}

## Off: the NYC-only set pieces (Central Park, Coney, Steel Mountain, Fort Tryon).
const OFF := {"bi0": 99, "bi1": -1, "bj0": 99, "bj1": -1}


static func district(region: String, bi: int, bj: int) -> String:
	match region:
		"highway":
			if bj == 3:
				return "reststop"
			if bj == 5:
				return "town"
			return "farm"
		"chicago":
			if bi >= 10 and bj >= 2 and bj <= 8:
				return "airfield"
			if bi >= 10:
				return "lake"
			if bj <= 2:
				return "river"
			if bj >= 11:
				return "south"
			if bi <= 2:
				return "west"
			return "loop"
	return "les"


static func gates(region: String) -> Dictionary:
	return GATES.get(region, {})


static func sky(region: String) -> Rect2:
	return SKY.get(region, SKY["nyc"])


## Each map's built-up area (local Rect2): the countryside stops here.
const CITY := {
	"nyc": Rect2(-906.0, -1706.0, 2722.0, 2536.0),
	"highway": Rect2(-310.0, -910.0, 620.0, 1820.0),
	"chicago": Rect2(-800.0, -800.0, 1700.0, 1660.0),
}


## Is this point (local to `region`) dry land outside the city? New York has
## rivers east and west and the Atlantic south, so its country is north of it;
## Chicago has Lake Michigan to the east.
static func is_country(region: String, p: Vector2) -> bool:
	if (CITY.get(region, Rect2()) as Rect2).has_point(p):
		return false
	match region:
		"nyc":
			return p.y < -1706.0 and p.x > -1100.0 and p.x < 2000.0
		"chicago":
			return p.x < 920.0
	return true


## Local map position -> shared world position, and back.
static func to_world(region: String, p: Vector2) -> Vector2:
	return p + (WORLD.get(region, Vector2.ZERO) as Vector2)


static func to_local(region: String, w: Vector2) -> Vector2:
	return w - (WORLD.get(region, Vector2.ZERO) as Vector2)


## The map whose airspace holds world point `w` (not `except`), or "".
static func region_at(w: Vector2, except: String = "") -> String:
	for r in SKY.keys():
		if str(r) == except:
			continue
		if (SKY[r] as Rect2).has_point(to_local(str(r), w)):
			return str(r)
	return ""


static func region_name(region: String) -> String:
	return str(NAMES.get(region, region))
